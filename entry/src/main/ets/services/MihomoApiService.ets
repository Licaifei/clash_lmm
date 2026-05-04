import { http } from '@kit.NetworkKit';
import {
  CalculatedProxies,
  ConnectionsResponse,
  ControllerConfig,
  DelayResponse,
  MihomoBaseConfig,
  MihomoVersion,
  ProxiesResponse,
  ProxyGroupItem,
  ProxyItem,
  ProxyProviderItem,
  ProxyProvidersResponse,
  RulesResponse
} from '../models/MihomoModels';

type JsonPayload = Object | string | null;

interface SelectNodePayload {
  name: string;
}

export class MihomoApiError extends Error {
  public statusCode: number;

  constructor(statusCode: number, message: string) {
    super(message);
    this.statusCode = statusCode;
  }
}

export class MihomoApiService {
  private config: ControllerConfig;

  constructor(config: ControllerConfig) {
    this.config = config;
  }

  setConfig(config: ControllerConfig): void {
    this.config = config;
  }

  async getVersion(): Promise<MihomoVersion> {
    return this.request<MihomoVersion>('GET', '/version');
  }

  async getBaseConfig(): Promise<MihomoBaseConfig> {
    const raw = await this.request<Record<string, Object | string | number | boolean>>('GET', '/configs');
    return {
      port: raw['port'] as number,
      mode: raw['mode'] as string,
      ipv6: raw['ipv6'] as boolean,
      mixedPort: raw['mixed-port'] as number,
      socksPort: raw['socks-port'] as number,
      redirPort: raw['redir-port'] as number,
      tproxyPort: raw['tproxy-port'] as number,
      externalController: raw['external-controller'] as string,
      secret: raw['secret'] as string
    };
  }

  async patchBaseConfig(payload: Object): Promise<void> {
    await this.request<void>('PATCH', '/configs', payload);
  }

  async getProxies(): Promise<ProxiesResponse> {
    return this.request<ProxiesResponse>('GET', '/proxies');
  }

  async getProxyProviders(): Promise<ProxyProvidersResponse> {
    return this.request<ProxyProvidersResponse>('GET', '/providers/proxies');
  }

  async getRules(): Promise<RulesResponse> {
    return this.request<RulesResponse>('GET', '/rules');
  }

  async getConnections(): Promise<ConnectionsResponse> {
    return this.request<ConnectionsResponse>('GET', '/connections');
  }

  async closeConnection(id: string): Promise<void> {
    await this.request<void>('DELETE', `/connections/${encodeURIComponent(id)}`);
  }

  async closeAllConnections(): Promise<void> {
    await this.request<void>('DELETE', '/connections');
  }

  async selectNodeForGroup(groupName: string, proxyName: string): Promise<void> {
    const payload: SelectNodePayload = { name: proxyName };
    await this.request<void>('PUT', `/proxies/${encodeURIComponent(groupName)}`, payload);
  }

  async delayProxyByName(name: string, url: string, timeout: number): Promise<DelayResponse> {
    const params = `url=${encodeURIComponent(url)}&timeout=${timeout}`;
    return this.request<DelayResponse>('GET', `/proxies/${encodeURIComponent(name)}/delay?${params}`);
  }

  async healthcheckProxyProvider(providerName: string): Promise<void> {
    await this.request<void>('PUT', `/providers/proxies/${encodeURIComponent(providerName)}/healthcheck`);
  }

  async updateProxyProvider(providerName: string): Promise<void> {
    await this.request<void>('PUT', `/providers/proxies/${encodeURIComponent(providerName)}`);
  }

  async calcuProxies(): Promise<CalculatedProxies> {
    const responses = await Promise.all([
      this.getProxies(),
      this.getProxyProviders()
    ]);
    const proxyResponse = responses[0] as ProxiesResponse;
    const providerResponse = responses[1] as ProxyProvidersResponse;
    const proxyRecord = proxyResponse.proxies;
    const providerMap: Record<string, ProxyItem> = {};

    Object.keys(providerResponse.providers).forEach((providerName: string): void => {
      const provider = providerResponse.providers[providerName] as ProxyProviderItem;
      provider.proxies.forEach((proxy: ProxyItem): void => {
        providerMap[proxy.name] = this.cloneProxy(proxy, providerName);
      });
    });

    const global = proxyRecord['GLOBAL'];
    const direct = proxyRecord['DIRECT'];
    const reject = proxyRecord['REJECT'];
    const groups: ProxyGroupItem[] = [];
    const proxyNames = Object.keys(proxyRecord);

    proxyNames.forEach((name: string): void => {
      const proxy = proxyRecord[name];
      if (proxy.name !== 'GLOBAL' && this.hasGroupChildren(proxy)) {
        groups.push(this.toGroupItem(proxy, proxyRecord, providerMap));
      }
    });

    let finalGroups = groups;
    if (global && global.all) {
      const globalGroups: ProxyGroupItem[] = [];
      const globalGroupNames: Record<string, boolean> = {};
      global.all.forEach((name: string): void => {
        const proxy = proxyRecord[name];
        if (proxy && this.hasGroupChildren(proxy)) {
          globalGroups.push(this.toGroupItem(proxy, proxyRecord, providerMap));
          globalGroupNames[proxy.name] = true;
        }
      });
      finalGroups = [];
      groups.forEach((group: ProxyGroupItem): void => {
        if (!globalGroupNames[group.name]) {
          finalGroups.push(group);
        }
      });
      finalGroups = finalGroups.concat(globalGroups);
    }

    const proxies: ProxyItem[] = [];
    if (direct) {
      proxies.push(direct);
    }
    if (reject) {
      proxies.push(reject);
    }
    proxyNames.forEach((name: string): void => {
      const proxy = proxyRecord[name];
      if (!this.hasGroupChildren(proxy) && proxy.name !== 'DIRECT' && proxy.name !== 'REJECT') {
        proxies.push(proxy);
      }
    });

    const result: CalculatedProxies = {
      groups: finalGroups,
      records: proxyRecord,
      proxies
    };
    if (global) {
      result.global = this.toGroupItem(global, proxyRecord, providerMap);
    }
    if (direct) {
      result.direct = direct;
    }
    return result;
  }

  private cloneProxy(proxy: ProxyItem, provider?: string): ProxyItem {
    const cloned: ProxyItem = {
      name: proxy.name,
      type: proxy.type
    };
    if (proxy.udp !== undefined) {
      cloned.udp = proxy.udp;
    }
    if (proxy.xudp !== undefined) {
      cloned.xudp = proxy.xudp;
    }
    if (proxy.tfo !== undefined) {
      cloned.tfo = proxy.tfo;
    }
    if (proxy.mptcp !== undefined) {
      cloned.mptcp = proxy.mptcp;
    }
    if (proxy.smux !== undefined) {
      cloned.smux = proxy.smux;
    }
    if (proxy.history !== undefined) {
      cloned.history = proxy.history;
    }
    if (proxy.all !== undefined) {
      cloned.all = proxy.all;
    }
    if (proxy.now !== undefined) {
      cloned.now = proxy.now;
    }
    if (proxy.hidden !== undefined) {
      cloned.hidden = proxy.hidden;
    }
    if (proxy.icon !== undefined) {
      cloned.icon = proxy.icon;
    }
    if (provider !== undefined) {
      cloned.provider = provider;
    } else if (proxy.provider !== undefined) {
      cloned.provider = proxy.provider;
    }
    return cloned;
  }

  private toGroupItem(
    proxy: ProxyItem,
    records: Record<string, ProxyItem>,
    providerMap: Record<string, ProxyItem>
  ): ProxyGroupItem {
    const children: ProxyItem[] = [];
    if (proxy.all !== undefined) {
      proxy.all.forEach((name: string): void => {
        children.push(this.resolveProxyItem(name, records, providerMap));
      });
    }
    const group: ProxyGroupItem = {
      name: proxy.name,
      type: proxy.type,
      all: children
    };
    if (proxy.udp !== undefined) {
      group.udp = proxy.udp;
    }
    if (proxy.xudp !== undefined) {
      group.xudp = proxy.xudp;
    }
    if (proxy.tfo !== undefined) {
      group.tfo = proxy.tfo;
    }
    if (proxy.mptcp !== undefined) {
      group.mptcp = proxy.mptcp;
    }
    if (proxy.smux !== undefined) {
      group.smux = proxy.smux;
    }
    if (proxy.history !== undefined) {
      group.history = proxy.history;
    }
    if (proxy.now !== undefined) {
      group.now = proxy.now;
    }
    if (proxy.hidden !== undefined) {
      group.hidden = proxy.hidden;
    }
    if (proxy.icon !== undefined) {
      group.icon = proxy.icon;
    }
    if (proxy.provider !== undefined) {
      group.provider = proxy.provider;
    }
    return group;
  }

  private resolveProxyItem(
    name: string,
    records: Record<string, ProxyItem>,
    providerMap: Record<string, ProxyItem>
  ): ProxyItem {
    if (records[name]) {
      return records[name];
    }
    if (providerMap[name]) {
      return providerMap[name];
    }
    const fallback: ProxyItem = {
      name: name,
      type: 'unknown',
      udp: false,
      xudp: false,
      tfo: false,
      mptcp: false,
      smux: false,
      history: []
    };
    return fallback;
  }

  private hasGroupChildren(proxy: ProxyItem): boolean {
    return proxy.all !== undefined && proxy.all.length > 0;
  }

  private async request<T>(method: string, path: string, body: JsonPayload = null): Promise<T> {
    const request = http.createHttp();
    const url = `${this.config.baseUrl.replace(/\/$/, '')}${path}`;
    const header: Record<string, string> = {
      'Accept': 'application/json'
    };
    if (this.config.secret.length > 0) {
      header['Authorization'] = `Bearer ${this.config.secret}`;
    }
    if (body !== null) {
      header['Content-Type'] = 'application/json';
    }

    try {
      const response = await request.request(url, {
        method: this.resolveMethod(method),
        expectDataType: http.HttpDataType.STRING,
        usingCache: false,
        readTimeout: 15000,
        connectTimeout: 8000,
        header,
        extraData: body === null ? undefined : JSON.stringify(body)
      });

      const status = response.responseCode;
      const raw = `${response.result ?? ''}`;
      if (status < 200 || status >= 300) {
        throw new MihomoApiError(status, raw.length > 0 ? raw : `Mihomo API request failed: ${status}`);
      }
      if (raw.length === 0) {
        return undefined as T;
      }
      return JSON.parse(raw) as T;
    } finally {
      request.destroy();
    }
  }

  private resolveMethod(method: string): http.RequestMethod {
    switch (method) {
      case 'GET':
        return http.RequestMethod.GET;
      case 'POST':
        return http.RequestMethod.POST;
      case 'PUT':
        return http.RequestMethod.PUT;
      case 'PATCH':
        return 'PATCH' as http.RequestMethod;
      case 'DELETE':
        return http.RequestMethod.DELETE;
      default:
        return http.RequestMethod.GET;
    }
  }
}
