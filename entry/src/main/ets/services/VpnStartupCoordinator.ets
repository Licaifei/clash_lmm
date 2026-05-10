import { VpnFlowState, VpnFlowResult, VpnFlowError, GeneratedConfig } from '../models/MihomoModels';
import { SubscriptionStore } from './SubscriptionStore';
import { MihomoConfigService } from './MihomoConfigService';
import { MihomoCoreRuntime } from './MihomoCoreRuntime';
import { VpnRuntime } from './VpnRuntime';
import { MihomoApiService } from './MihomoApiService';
import { AppConfigStore } from './AppConfigStore';

const CONTROLLER_RETRIES = 5;
const CONTROLLER_RETRY_MS = 500;

export class VpnStartupCoordinator {
  private flowId: number = 0;

  cancel(): void {
    ++this.flowId;
  }

  async startFlow(
    subStore: SubscriptionStore,
    configService: MihomoConfigService,
    configStore: AppConfigStore,
    coreRuntime: MihomoCoreRuntime,
    vpnRuntime: VpnRuntime,
    onPhaseChange: (state: VpnFlowState) => void
  ): Promise<VpnFlowResult> {
    const id = ++this.flowId;

    // 1. Validate subscription
    onPhaseChange('preparing');
    const active = subStore.getActive();
    if (active === null) {
      return {
        success: false,
        state: 'noSubscription',
        error: { phase: 'subscription', message: 'No subscription selected. Go to Subscriptions to add one.' }
      };
    }

    // 2. Generate config
    let generated: GeneratedConfig;
    try {
      generated = configService.generate(subStore, configStore);
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Config generation failed';
      return { success: false, state: 'failed', error: { phase: 'config', message: msg } };
    }
    if (id !== this.flowId) {
      return { success: false, state: 'ready' };
    }

    // 3. Start core
    onPhaseChange('coreStarting');
    const coreResult = await coreRuntime.start(configService);
    if (!coreResult.success) {
      return {
        success: false,
        state: 'failed',
        error: { phase: 'core', message: coreResult.error ?? 'Core failed to start' }
      };
    }
    if (id !== this.flowId) {
      await coreRuntime.stop();
      return { success: false, state: 'ready' };
    }

    // 4. Verify local controller
    const reachable = await this.verifyController(generated.controllerUrl, generated.controllerSecret);
    if (!reachable) {
      const cleanupResult = await coreRuntime.stop();
      if (id !== this.flowId) {
        return { success: false, state: 'ready' };
      }
      const cleanupFailed = !cleanupResult.success && cleanupResult.state !== 'stopped';
      return {
        success: false,
        state: 'failed',
        error: { phase: 'core', message: 'Local controller not reachable after core start' },
        cleanupFailed: cleanupFailed
      };
    }
    if (id !== this.flowId) {
      await coreRuntime.stop();
      return { success: false, state: 'ready' };
    }

    // 5. Start VPN tunnel
    onPhaseChange('requestingPermission');
    const vpnResult = await vpnRuntime.start(true);
    if (!vpnResult.success) {
      const cleanupResult = await coreRuntime.stop();
      if (id !== this.flowId) {
        return { success: false, state: 'ready' };
      }
      const cleanupFailed = !cleanupResult.success && cleanupResult.state !== 'stopped';
      return {
        success: false,
        state: 'failed',
        error: { phase: 'vpn', message: vpnResult.error ?? 'VPN tunnel failed' },
        cleanupFailed: cleanupFailed
      };
    }
    if (id !== this.flowId) {
      await vpnRuntime.stop();
      await coreRuntime.stop();
      return { success: false, state: 'ready' };
    }

    return {
      success: true,
      state: 'active',
      controllerUrl: generated.controllerUrl,
      controllerSecret: generated.controllerSecret
    };
  }

  async stopFlow(
    coreRuntime: MihomoCoreRuntime,
    vpnRuntime: VpnRuntime,
    onPhaseChange: (state: VpnFlowState) => void
  ): Promise<VpnFlowResult> {
    const id = ++this.flowId;
    onPhaseChange('stopping');

    const vpnResult = await vpnRuntime.stop();
    if (id !== this.flowId) {
      return { success: false, state: 'ready' };
    }

    const coreResult = await coreRuntime.stop();
    if (id !== this.flowId) {
      return { success: false, state: 'ready' };
    }

    if (!vpnResult.success && vpnResult.state !== 'stopped') {
      return {
        success: false,
        state: 'failed',
        error: { phase: 'vpn', message: vpnResult.error ?? 'VPN stop failed' }
      };
    }
    if (!coreResult.success && coreResult.state !== 'stopped') {
      return {
        success: false,
        state: 'failed',
        error: { phase: 'core', message: coreResult.error ?? 'Core stop failed' }
      };
    }

    return { success: true, state: 'ready' };
  }

  private async verifyController(url: string, secret: string): Promise<boolean> {
    const api = new MihomoApiService({ baseUrl: url, secret: secret });
    for (let i = 0; i < CONTROLLER_RETRIES; i++) {
      try {
        await api.getVersion();
        return true;
      } catch (_err) {
        if (i < CONTROLLER_RETRIES - 1) {
          await this.delay(CONTROLLER_RETRY_MS);
        }
      }
    }
    return false;
  }

  private delay(ms: number): Promise<void> {
    return new Promise<void>((resolve: () => void) => {
      setTimeout(resolve, ms);
    });
  }
}
