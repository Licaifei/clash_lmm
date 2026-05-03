import { describe, it, expect } from '@ohos/hypium';
import {
  ControllerConfig,
  MihomoVersion,
  MihomoBaseConfig,
  ProxyItem,
  ProxyGroupItem,
  ProxiesResponse,
  ConnectionsResponse,
  RulesResponse,
  CalculatedProxies
} from '../main/ets/models/MihomoModels';

export default function MihomoModelsTest() {
  describe('MihomoModels', () => {
    // ControllerConfig
    it('ControllerConfig_should_have_baseUrl_and_secret', 0, () => {
      const config: ControllerConfig = {
        baseUrl: 'http://127.0.0.1:9090',
        secret: 'test-secret'
      };
      expect(config.baseUrl).assertEqual('http://127.0.0.1:9090');
      expect(config.secret).assertEqual('test-secret');
    });

    // MihomoVersion
    it('MihomoVersion_should_support_premium_and_meta_flags', 0, () => {
      const version: MihomoVersion = {
        premium: true,
        meta: true,
        version: 'v1.19.0'
      };
      expect(version.premium).assertTrue();
      expect(version.meta).assertTrue();
      expect(version.version).assertEqual('v1.19.0');
    });

    it('MihomoVersion_should_allow_optional_fields', 0, () => {
      const version: MihomoVersion = {};
      expect(version.version).assertUndefined();
      expect(version.premium).assertUndefined();
    });

    // MihomoBaseConfig
    it('MihomoBaseConfig_should_have_all_port_fields', 0, () => {
      const config: MihomoBaseConfig = {
        port: 7890,
        mode: 'rule',
        ipv6: false,
        mixedPort: 7891,
        socksPort: 7892,
        redirPort: 7893,
        tproxyPort: 7894,
        externalController: '127.0.0.1:9090',
        secret: 'secret'
      };
      expect(config.port).assertEqual(7890);
      expect(config.mode).assertEqual('rule');
      expect(config.mixedPort).assertEqual(7891);
    });

    // ProxyItem
    it('ProxyItem_should_have_all_required_fields', 0, () => {
      const proxy: ProxyItem = {
        name: '节点1',
        type: 'ss',
        udp: true,
        xudp: false,
        tfo: true,
        mptcp: false,
        smux: false,
        history: [{ time: '2024-01-01', delay: 100 }],
        all: ['节点A', '节点B'],
        now: '节点A',
        hidden: false,
        icon: 'icon_url',
        provider: 'provider1'
      };
      expect(proxy.name).assertEqual('节点1');
      expect(proxy.type).assertEqual('ss');
      expect(proxy.udp).assertTrue();
      expect(proxy.all?.length).assertEqual(2);
      expect(proxy.now).assertEqual('节点A');
    });

    // ProxyGroupItem
    it('ProxyGroupItem_should_extend_ProxyItem_with_all_as_ProxyItem_array', 0, () => {
      const group: ProxyGroupItem = {
        name: 'Proxy',
        type: 'select',
        all: [
          { name: '节点A', type: 'ss' },
          { name: '节点B', type: 'vmess' }
        ],
        now: '节点A'
      };
      expect(group.all?.length).assertEqual(2);
      expect(group.all?.[0].name).assertEqual('节点A');
    });

    // ProxiesResponse
    it('ProxiesResponse_should_map_proxy_names_to_ProxyItem', 0, () => {
      const response: ProxiesResponse = {
        proxies: {
          'GLOBAL': { name: 'GLOBAL', type: 'Selector', all: ['节点A'] },
          '节点A': { name: '节点A', type: 'ss' },
          'DIRECT': { name: 'DIRECT', type: 'Direct' }
        }
      };
      expect(Object.keys(response.proxies).length).assertEqual(3);
      expect(response.proxies['GLOBAL'].name).assertEqual('GLOBAL');
    });

    // ConnectionsResponse
    it('ConnectionsResponse_should_track_upload_download_totals', 0, () => {
      const response: ConnectionsResponse = {
        downloadTotal: 1024000,
        uploadTotal: 512000,
        connections: []
      };
      expect(response.downloadTotal).assertEqual(1024000);
      expect(response.uploadTotal).assertEqual(512000);
    });

    // CalculatedProxies
    it('CalculatedProxies_should_structured_proxies_into_groups_and_leaf_nodes', 0, () => {
      const calculated: CalculatedProxies = {
        global: { name: 'GLOBAL', type: 'Selector', all: [] },
        direct: { name: 'DIRECT', type: 'Direct' },
        groups: [
          { name: 'Proxy', type: 'select', all: [{ name: '节点A', type: 'ss' }] }
        ],
        records: {},
        proxies: [{ name: '节点A', type: 'ss' }]
      };
      expect(calculated.groups?.length).assertEqual(1);
      expect(calculated.proxies?.length).assertEqual(1);
      expect(calculated.global).assertDefine();
    });
  });
}
