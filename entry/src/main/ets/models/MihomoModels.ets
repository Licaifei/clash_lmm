export enum ConnectionState {
  DISCONNECTED = 'disconnected',
  CONNECTING = 'connecting',
  CONNECTED = 'connected',
  REFRESHING = 'refreshing',
  FAILED = 'failed'
}

export interface ControllerConfig {
  baseUrl: string;
  secret: string;
}

export interface MihomoVersion {
  premium?: boolean;
  meta?: boolean;
  version?: string;
}

export interface MihomoBaseConfig {
  port?: number;
  mode?: string;
  ipv6?: boolean;
  mixedPort?: number;
  socksPort?: number;
  redirPort?: number;
  tproxyPort?: number;
  externalController?: string;
  secret?: string;
}

export interface ProxyHistory {
  time: string;
  delay: number;
}

export interface ProxyItem {
  name: string;
  type: string;
  udp?: boolean;
  xudp?: boolean;
  tfo?: boolean;
  mptcp?: boolean;
  smux?: boolean;
  history?: ProxyHistory[];
  all?: string[];
  now?: string;
  hidden?: boolean;
  icon?: string;
  provider?: string;
}

export interface ProxyGroupItem {
  name: string;
  type: string;
  udp?: boolean;
  xudp?: boolean;
  tfo?: boolean;
  mptcp?: boolean;
  smux?: boolean;
  history?: ProxyHistory[];
  all?: ProxyItem[];
  now?: string;
  hidden?: boolean;
  icon?: string;
  provider?: string;
}

export interface ProxiesResponse {
  proxies: Record<string, ProxyItem>;
}

export interface ProxyProviderItem {
  name: string;
  type: string;
  proxies: ProxyItem[];
  updatedAt: string;
  vehicleType: string;
}

export interface ProxyProvidersResponse {
  providers: Record<string, ProxyProviderItem>;
}

export interface RuleItem {
  type: string;
  payload: string;
  proxy: string;
}

export interface RulesResponse {
  rules: RuleItem[];
}

export interface ConnectionMetadata {
  network: string;
  type: string;
  host: string;
  sourceIP: string;
  sourcePort: string;
  destinationPort: string;
  destinationIP?: string;
  remoteDestination?: string;
  process?: string;
  processPath?: string;
}

export interface ConnectionItem {
  id: string;
  metadata: ConnectionMetadata;
  upload: number;
  download: number;
  start: string;
  chains: string[];
  rule: string;
  rulePayload: string;
}

export interface ConnectionsResponse {
  downloadTotal: number;
  uploadTotal: number;
  connections: ConnectionItem[];
}

export interface TrafficItem {
  up: number;
  down: number;
}

export interface MemoryItem {
  inuse: number;
  oslimit?: number;
}

export interface LogItem {
  type: string;
  payload: string;
  time?: string;
}

export interface DelayResponse {
  delay: number;
}

export interface CalculatedProxies {
  global?: ProxyGroupItem;
  direct?: ProxyItem;
  groups: ProxyGroupItem[];
  records: Record<string, ProxyItem>;
  proxies: ProxyItem[];
}

export interface SubscriptionProfile {
  id: string;
  name: string;
  sourceUrl: string;
  lastUpdated: string;
  byteSize: number;
  contentHash: string;
  detectedFormat: string;
  userInfo: string;
  note: string;
}

export interface SubscriptionState {
  subscriptions: SubscriptionProfile[];
  activeId: string;
}

export interface GeneratedConfig {
  path: string;
  controllerUrl: string;
  controllerSecret: string;
  mixedPort: number;
  timestamp: string;
}

export type CoreState = 'stopped' | 'starting' | 'running' | 'stopping' | 'failed' | 'missing';

export interface CoreStartResult {
  success: boolean;
  error?: string;
  state: CoreState;
}

export interface CoreInstallInfo {
  installed: boolean;
  artifactVersion: string;
  cpuAbi: string;
  sandboxPath: string;
  lastError: string;
}

export type VpnTunnelState =
  'stopped' | 'requestingPermission' | 'startingTunnel' | 'active' | 'stopping' | 'failed';

export interface VpnTunnelResult {
  success: boolean;
  error?: string;
  state: VpnTunnelState;
}
