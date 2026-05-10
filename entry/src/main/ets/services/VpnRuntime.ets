import { vpnExtension } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import Want from '@ohos.app.ability.Want';
import { VpnTunnelState, VpnTunnelResult } from '../models/MihomoModels';

const VPN_BUNDLE = 'com.example.clash_lmm';
const VPN_ABILITY = 'MihomoVpnExtension';

/**
 * Spec07 VpnRuntime.
 *
 * PLATFORM NOTE:
 * startVpnExtensionAbility() resolves when the system starts the extension,
 * but VpnConnection.create(config) runs asynchronously inside the extension
 * process. No cross-process status channel exists to confirm tunnel creation.
 *
 * Until a NAPI packet bridge (tun2socks or Mihomo TUN) is integrated and can
 * signal tunnel readiness across processes, start() fails after extension
 * launch with a documented bridge blocker.
 */
export class VpnRuntime {
  private state: VpnTunnelState = 'stopped';
  private lastError: string = '';

  getState(): VpnTunnelState {
    return this.state;
  }

  getLastError(): string {
    return this.lastError;
  }

  async start(isCoreRunning: boolean): Promise<VpnTunnelResult> {
    if (!isCoreRunning) {
      return { success: false, error: 'Mihomo Core is not running. Start Core first.', state: this.state };
    }
    if (this.state === 'active' || this.state === 'requestingPermission' ||
      this.state === 'startingTunnel') {
      return { success: false, error: 'VPN is already starting or active', state: this.state };
    }
    this.state = 'requestingPermission';
    this.lastError = '';
    try {
      await vpnExtension.startVpnExtensionAbility(this.buildWant());
    } catch (err) {
      const e = err as BusinessError;
      this.lastError = this.formatError(e.code, e.message);
      this.state = 'failed';
      return { success: false, error: this.lastError, state: this.state };
    }
    this.state = 'startingTunnel';
    try {
      await vpnExtension.stopVpnExtensionAbility(this.buildWant());
    } catch (_err) {
      // Best-effort teardown: the extension may not have finished onCreate yet
    }
    this.state = 'stopped';
    this.lastError = 'Packet bridge unavailable: NAPI tun2socks or Mihomo TUN integration ' +
      'required to forward vNIC traffic to the local core. VPN extension started but tunnel ' +
      'is not active.';
    return { success: false, error: this.lastError, state: this.state };
  }

  async stop(): Promise<VpnTunnelResult> {
    if (this.state === 'stopped' || this.state === 'stopping') {
      return { success: false, error: 'VPN is not active', state: this.state };
    }
    this.state = 'stopping';
    this.lastError = '';
    try {
      await vpnExtension.stopVpnExtensionAbility(this.buildWant());
      this.state = 'stopped';
      return { success: true, state: this.state };
    } catch (err) {
      const e = err as BusinessError;
      this.lastError = this.formatError(e.code, e.message);
      this.state = 'failed';
      return { success: false, error: this.lastError, state: this.state };
    }
  }

  private buildWant(): Want {
    return {
      bundleName: VPN_BUNDLE,
      abilityName: VPN_ABILITY
    };
  }

  private formatError(code: number, message: string): string {
    if (code === 2203001) {
      return 'VPN permission denied or another VPN is active';
    }
    if (code === 2203002) {
      return 'VPN extension already exists, stop first';
    }
    return message + ' (code: ' + code + ')';
  }
}
