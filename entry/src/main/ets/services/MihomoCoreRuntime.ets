import { common } from '@kit.AbilityKit';
import fileIo from '@ohos.file.fs';
import { preferences } from '@kit.ArkData';
import resourceManager from '@ohos.resourceManager';
import { MihomoConfigService } from './MihomoConfigService';
import { CoreState, CoreStartResult, CoreInstallInfo } from '../models/MihomoModels';
import deviceInfo from '@ohos.deviceInfo';

const PREF_NAME = 'mihomo_core';
const KEY_INSTALL = 'core_install_info';
const RUNTIME_ARTIFACT = 'libmihomo.so';
const RUNTIME_DIR = '/mihomo/runtime';

/**
 * Spec06 Mihomo Core Runtime.
 *
 * HARMONYOS PLATFORM NOTE:
 * HarmonyOS apps cannot fork native child processes without platform-level privileges.
 * Actual core execution requires one of:
 *   a) NAPI-wrapped Mihomo core shared library (libmihomo.so + NAPI bindings)
 *   b) HarmonyOS system capability approval for native process execution
 *
 * Until the NAPI artifact is available, start() verifies config existence, validity,
 * and state machine correctness but returns failure with "Runtime artifact not
 * executable (NAPI library required)".
 *
 * The state machine, health check, idempotent start/stop, and UI integration are
 * fully wired so that plugging in the real NAPI start/stop calls is a minimal change.
 */
export class MihomoCoreRuntime {
  private context: common.UIAbilityContext;
  private state: CoreState = 'stopped';
  private lastError: string = '';
  private configPath: string = '';

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  getState(): CoreState {
    return this.state;
  }

  getLastError(): string {
    return this.lastError;
  }

  getConfigPath(): string {
    return this.configPath;
  }

  /**
   * First-run: record artifact info from bundled runtime.
   * Must be called at least once before start().
   */
  initRuntime(): CoreInstallInfo {
    const abi = deviceInfo.abiList;
    const runtimePath = this.context.filesDir + RUNTIME_DIR;
    const artifactPath = runtimePath + '/' + RUNTIME_ARTIFACT;
    const info: CoreInstallInfo = {
      installed: false,
      artifactVersion: 'unknown',
      cpuAbi: abi,
      sandboxPath: runtimePath,
      lastError: ''
    };
    try {
      fileIo.mkdirSync(runtimePath, true);
    } catch (_err) {
      info.lastError = 'Failed to create runtime directory';
      this.persistInstallInfo(info);
      this.state = 'missing';
      return info;
    }
    let exists = false;
    try {
      fileIo.accessSync(artifactPath);
      exists = true;
    } catch (_err) {
      exists = false;
    }
    if (!exists) {
      this.tryCopyFromRawfile(artifactPath);
    }
    info.installed = false;
    info.lastError = 'Explicit unsupported blocker: libmihomo.so NAPI start/stop bindings ' +
      'not yet integrated. Spec 06 requires a real NAPI or native runtime boundary before ' +
      'marking core as installed. Place libmihomo.so (arm64) in resources/rawfile/' +
      RUNTIME_ARTIFACT + ' and add NAPI mihomo_core_start/stop calls in executeStart/Stop.';
    this.persistInstallInfo(info);
    this.state = 'missing';
    return info;
  }

  private tryCopyFromRawfile(destPath: string): void {
    let fd = -1;
    try {
      const resMgr = this.context.resourceManager;
      const content = resMgr.getRawFileContentSync(RUNTIME_ARTIFACT);
      const f = fileIo.openSync(destPath,
        fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC | fileIo.OpenMode.WRITE_ONLY);
      fd = f.fd;
      fileIo.writeSync(fd, content.buffer as ArrayBuffer);
    } catch (_err) {
      // Artifact not in rawfile, continue with missing state
    } finally {
      if (fd >= 0) {
        try {
          fileIo.closeSync(fd);
        } catch (_err) {
          // close failed, ignore
        }
      }
    }
  }

  loadInstallInfo(): CoreInstallInfo | null {
    try {
      const store = preferences.getPreferencesSync(this.context, { name: PREF_NAME });
      const raw = store.getSync(KEY_INSTALL, '') as string;
      if (raw.length === 0) {
        return null;
      }
      const info = JSON.parse(raw) as CoreInstallInfo;
      if (typeof info.installed !== 'boolean' || typeof info.sandboxPath !== 'string') {
        return null;
      }
      return info;
    } catch (_err) {
      return null;
    }
  }

  /**
   * Start local Mihomo Core with the generated config.
   * Idempotent: if already starting or running, returns early without side effects.
   */
  async start(configService: MihomoConfigService): Promise<CoreStartResult> {
    if (this.state === 'running' || this.state === 'starting') {
      return { success: false, error: 'Core is already starting or running', state: this.state };
    }
    this.state = 'starting';
    this.lastError = '';
    const generated = configService.loadGeneratedConfig();
    if (generated === null) {
      this.state = 'stopped';
      this.lastError = 'No generated config found. Generate config first.';
      return { success: false, error: this.lastError, state: this.state };
    }
    this.configPath = generated.path;
    try {
      const content = fileIo.readTextSync(this.configPath);
      if (content.length === 0) {
        this.state = 'stopped';
        this.lastError = 'Generated config is empty';
        return { success: false, error: this.lastError, state: this.state };
      }
    } catch (_err) {
      this.state = 'stopped';
      this.lastError = 'Generated config file not found or unreadable';
      return { success: false, error: this.lastError, state: this.state };
    }
    const installInfo = this.loadInstallInfo();
    if (installInfo === null || !installInfo.installed) {
      this.state = 'missing';
      this.lastError = 'Runtime artifact not installed. Call initRuntime() first.';
      return { success: false, error: this.lastError, state: this.state };
    }
    const result = await this.executeStart();
    if (result.success) {
      this.state = 'running';
    } else {
      this.state = 'failed';
      this.lastError = result.error !== undefined ? result.error : 'Unknown startup error';
    }
    return { success: result.success, error: result.error, state: this.state };
  }

  /**
   * Stop local Mihomo Core.
   * Idempotent: if already stopped or stopping, returns early.
   */
  async stop(): Promise<CoreStartResult> {
    if (this.state === 'stopped' || this.state === 'stopping') {
      return { success: false, error: 'Core is not running', state: this.state };
    }
    this.state = 'stopping';
    this.lastError = '';
    const result = await this.executeStop();
    this.state = 'stopped';
    this.configPath = '';
    if (!result.success && result.error !== undefined) {
      this.lastError = result.error;
    }
    return { success: result.success, error: result.error, state: this.state };
  }

  /**
   * PLATFORM GATE: Replace this with real NAPI start call when runtime artifact is available.
   *
   * When the NAPI library is in place, implementation steps are:
   * 1. NAPI mihomo_core_start(configPath)
   * 2. Poll local external-controller (127.0.0.1:9090) for readiness
   *    - GET /version, retry up to 5s with 500ms intervals
   * 3. On connection refused / timeout → report port conflict or startup failure
   * 4. On 200 OK → return success with running state
   */
  private async executeStart(): Promise<CoreStartResult> {
    if (this.state !== 'starting') {
      return { success: false, error: 'Core not in starting state', state: this.state };
    }
    return {
      success: false,
      error: 'Runtime artifact not executable (NAPI library required). ' +
        'Bundle libmihomo.so with NAPI bindings to enable local core execution.',
      state: this.state
    };
  }

  /**
   * PLATFORM GATE: Replace this with real NAPI stop call when runtime artifact is available.
   */
  private async executeStop(): Promise<CoreStartResult> {
    // TODO: NAPI mihomo_core_stop()
    return { success: true, state: 'stopped' };
  }

  private persistInstallInfo(info: CoreInstallInfo): void {
    try {
      const store = preferences.getPreferencesSync(this.context, { name: PREF_NAME });
      store.putSync(KEY_INSTALL, JSON.stringify(info));
      store.flush();
    } catch (_err) {
      // install info is advisory, log but don't throw
    }
  }
}
