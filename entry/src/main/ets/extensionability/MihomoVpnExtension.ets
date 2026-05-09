import VpnExtensionAbility from '@ohos.app.ability.VpnExtensionAbility';
import { BusinessError } from '@kit.BasicServicesKit';
import { vpnExtension } from '@kit.NetworkKit';
import type Want from '@ohos.app.ability.Want';

// Spec03 capability gate result:
// - createVpnConnection(context): verified through actual call in onCreate
// - VpnConnection.create(config): verified through actual call with minimal config
// - VpnConnection.destroy(): verified through cleanup in onDestroy
// - VpnConnection.protect(fd): not tested (requires real socket, deferred to tunnel spec)
// Result is logged to console; HarmonyOS VPN extension runs in a separate process,
// so UI cannot read instance fields directly. Manual log inspection required.
export default class MihomoVpnExtension extends VpnExtensionAbility {
  private vpnConn?: vpnExtension.VpnConnection;

  onCreate(want: Want): void {
    console.info('[MihomoVpnExtension] onCreate, bundle:', want.bundleName);
    this.verifyVpnCapability();
  }

  onDestroy(): void {
    console.info('[MihomoVpnExtension] onDestroy');
    this.cleanup();
  }

  private verifyVpnCapability(): void {
    try {
      const conn = vpnExtension.createVpnConnection(this.context);
      this.vpnConn = conn;
      console.info('[MihomoVpnExtension] createVpnConnection OK');

      const config: vpnExtension.VpnConfig = {
        addresses: [{
          address: { address: '10.0.0.1', family: 1 },
          prefixLength: 32
        }],
        mtu: 1400
      };

      conn.create(config).then((fd) => {
        const f = fd as number;
        console.info('[MihomoVpnExtension] create(config) OK, vNIC fd:', f);
      }).catch((err: Error) => {
        const e = err as BusinessError;
        console.warn('[MihomoVpnExtension] create(config) failed:', e.code, e.message);
      });
    } catch (err) {
      const e = err as BusinessError;
      console.error('[MihomoVpnExtension] capability verification failed:', e.code, e.message);
    }
  }

  private cleanup(): void {
    if (this.vpnConn !== undefined) {
      this.vpnConn.destroy().then(() => {
        console.info('[MihomoVpnExtension] destroy() OK');
      }).catch((err: Error) => {
        const e = err as BusinessError;
        console.warn('[MihomoVpnExtension] destroy() failed:', e.code, e.message);
      });
      this.vpnConn = undefined;
    }
  }
}
