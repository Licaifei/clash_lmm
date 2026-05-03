import { http } from '@kit.NetworkKit';
import {
  CalculatedProxies,
  ConnectionsResponse,
  ControllerConfig,
  DelayResponse,
  MihomoBaseConfig,
  MihomoVersion,
  ProxiesResponse,
  ProxyItem,
  ProxyProviderItem,
  ProxyProvidersResponse,
  RulesResponse
} from '../models/MihomoModels';

type JsonValue = Record<string, Object | string | number | boolean | null> | string | null;

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

  async patchBaseConfig(payload: Record<string, Object | string | number | boolean>): Promise<void> {
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
    await this.request<void>('PUT', `/proxies/${encodeURIComponent(groupName)}`, { name: proxyName });
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
    const [proxyResponse, providerResponse] = await Promise.all([
      this.getProxies(),
      this.getProxyProviders()
    ]);
    const proxyRecord = proxyResponse.proxies ?? {};
    const providerMap: Record<string, ProxyItem> = {};

    Object.keys(providerResponse.providers ?? {}).forEach((providerName: string) => {
      const provider = providerResponse.providers[providerName] as ProxyProviderItem;
      (provider.proxies ?? []).forEach((proxy: ProxyItem) => {
        providerMap[proxy.name] = Object.assign({}, proxy, { provider: providerName });
      });
    });

    const generateItem = (name: string): ProxyItem => {
      if (proxyRecord[name]) {
        return proxyRecord[name];
      }
      if (providerMap[name]) {
        return providerMap[name];
      }
      return { name, type: 'unknown', udp: false, xudp: false, tfo: false, mptcp: false, smux: false, history: [] };
    };

    const global = proxyRecord['GLOBAL'];
    const direct = proxyRecord['DIRECT'];
    const reject = proxyRecord['REJECT'];
    let groups = Object.keys(proxyRecord)
      .map((name: string) => proxyRecord[name])
      .filter((proxy: ProxyItem) => proxy.name !== 'GLOBAL' && !!proxy.all && proxy.all.length > 0)
      .map((proxy: ProxyItem) => Object.assign({}, proxy, {
        all: (proxy.all ?? []).map((name: string) => generateItem(name))
      }));

    if (global && global.all) {
      const globalGroups = global.all
        .map((name: string) => proxyRecord[name])
        .filter((proxy: ProxyItem | undefined) => !!proxy && !!proxy.all && proxy.all.length > 0)
        .map((proxy: ProxyItem) => Object.assign({}, proxy, {
          all: (proxy.all ?? []).map((name: string) => generateItem(name))
        }));
      const globalGroupNames = new Set<string>(globalGroups.map((group: ProxyItem) => group.name));
      groups = groups.filter((group: ProxyItem) => !globalGroupNames.has(group.name)).concat(globalGroups);
    }

    const proxies = [direct, reject]
      .concat(Object.keys(proxyRecord)
        .map((name: string) => proxyRecord[name])
        .filter((proxy: ProxyItem) => !proxy.all?.length && proxy.name !== 'DIRECT' && proxy.name !== 'REJECT'))
      .filter((proxy?: ProxyItem) => !!proxy) as ProxyItem[];

    return {
      global: global ? Object.assign({}, global, { all: (global.all ?? []).map((name: string) => generateItem(name)) }) : undefined,
      direct,
      groups,
      records: proxyRecord,
      proxies
    };
  }

  private async request<T>(method: string, path: string, body: JsonValue = null): Promise<T> {
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
