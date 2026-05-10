import VpnExtensionAbility from '@ohos.app.ability.VpnExtensionAbility';
import { BusinessError } from '@kit.BasicServicesKit';
import { vpnExtension } from '@kit.NetworkKit';
import type Want from '@ohos.app.ability.Want';

/**
 * Spec07: Real VPN tunnel lifecycle.
 *
 * Creates a VpnConnection with virtual address, DNS servers, and MTU.
 * Routes are added as a default IPv4 route (0.0.0.0/0) to catch-all traffic.
 *
 * PACKET BRIDGE NOTE:
 * VpnConnection.create(config) returns a vNIC file descriptor. Reading/writing
 * this fd to forward packets into the local Mihomo runtime requires a native
 * packet bridge (tun2socks or equivalent). The bridge is deferred to spec 07
 * completion via NAPI integration.
 *
 * The tunnel fd is stored on the extension instance; in onDestroy() the
 * connection is destroyed, which tears down the system VPN interface.
 */
export default class MihomoVpnExtension extends VpnExtensionAbility {
  private vpnConn?: vpnExtension.VpnConnection;
  private tunnelFd: number = -1;

  onCreate(want: Want): void {
    console.info('[MihomoVpnExtension] onCreate');
    this.initTunnel();
  }

  onDestroy(): void {
    console.info('[MihomoVpnExtension] onDestroy, fd:', this.tunnelFd);
    this.cleanup();
  }

  private initTunnel(): void {
    try {
      const conn = vpnExtension.createVpnConnection(this.context);
      this.vpnConn = conn;
      console.info('[MihomoVpnExtension] VpnConnection created');

      const config: vpnExtension.VpnConfig = {
        addresses: [{
          address: { address: '10.0.0.2', family: 1 },
          prefixLength: 24
        }],
        routes: [{
          interface: 'vpn0',
          destination: {
            address: { address: '0.0.0.0', family: 1 },
            prefixLength: 0
          },
          gateway: { address: '10.0.0.2', family: 1 },
          hasGateway: false,
          isDefaultRoute: true
        }],
        dnsAddresses: ['223.5.5.5', '114.114.114.114'],
        mtu: 1400,
        isIPv4Accepted: true,
        isIPv6Accepted: false,
        isBlocking: true
      };

      conn.create(config).then((fd) => {
        this.tunnelFd = fd as number;
        console.info('[MihomoVpnExtension] tunnel created, vNIC fd:', this.tunnelFd);
      }).catch((err: Error) => {
        const e = err as BusinessError;
        console.error('[MihomoVpnExtension] tunnel create failed:', e.code, e.message);
      });
    } catch (err) {
      const e = err as BusinessError;
      console.error('[MihomoVpnExtension] initTunnel failed:', e.code, e.message);
    }
  }

  private cleanup(): void {
    this.tunnelFd = -1;
    if (this.vpnConn !== undefined) {
      this.vpnConn.destroy().then(() => {
        console.info('[MihomoVpnExtension] VpnConnection destroyed');
      }).catch((err: Error) => {
        const e = err as BusinessError;
        console.warn('[MihomoVpnExtension] destroy failed:', e.code, e.message);
      });
      this.vpnConn = undefined;
    }
  }
}
