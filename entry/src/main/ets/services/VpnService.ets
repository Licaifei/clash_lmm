import { vpnExtension } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import Want from '@ohos.app.ability.Want';

const VPN_EXTENSION_BUNDLE = 'com.example.clash_lmm';
const VPN_EXTENSION_ABILITY = 'MihomoVpnExtension';

export type VpnState = 'idle' | 'starting' | 'extensionActive' | 'stopping' | 'error';

export interface VpnStartResult {
  success: boolean;
  error?: string;
}

export class VpnService {
  private state: VpnState = 'idle';
  private lastError: string = '';

  getState(): VpnState {
    return this.state;
  }

  getLastError(): string {
    return this.lastError;
  }

  private buildWant(): Want {
    return {
      bundleName: VPN_EXTENSION_BUNDLE,
      abilityName: VPN_EXTENSION_ABILITY
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

  async start(): Promise<VpnStartResult> {
    if (this.state === 'starting' || this.state === 'extensionActive') {
      return { success: false, error: 'Extension is already starting or active' };
    }
    this.state = 'starting';
    this.lastError = '';
    try {
      await vpnExtension.startVpnExtensionAbility(this.buildWant());
      this.state = 'extensionActive';
      return { success: true };
    } catch (err) {
      const error = err as BusinessError;
      this.lastError = this.formatError(error.code, error.message);
      this.state = 'error';
      return { success: false, error: this.lastError };
    }
  }

  async stop(): Promise<VpnStartResult> {
    if (this.state === 'stopping' || this.state === 'idle') {
      return { success: false, error: 'Extension is not active' };
    }
    this.state = 'stopping';
    this.lastError = '';
    try {
      await vpnExtension.stopVpnExtensionAbility(this.buildWant());
      this.state = 'idle';
      return { success: true };
    } catch (err) {
      const error = err as BusinessError;
      this.lastError = this.formatError(error.code, error.message);
      this.state = 'error';
      return { success: false, error: this.lastError };
    }
  }
}
