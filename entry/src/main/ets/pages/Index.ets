import { common } from '@kit.AbilityKit';
import mediaquery from '@ohos.mediaquery';
import {
  CalculatedProxies,
  ConnectionState,
  ControllerConfig,
  MihomoBaseConfig,
  MihomoVersion,
  TrafficItem,
  VpnFlowState,
  VpnFlowError
} from '../models/MihomoModels';
import { AppConfigStore, AppSettings } from '../services/AppConfigStore';
import { MihomoApiService } from '../services/MihomoApiService';
import { MihomoWsSubscription } from '../services/MihomoWsService';
import { VpnRuntime } from '../services/VpnRuntime';
import { VpnStartupCoordinator } from '../services/VpnStartupCoordinator';
import { SubscriptionStore } from '../services/SubscriptionStore';
import { MihomoConfigService } from '../services/MihomoConfigService';
import { MihomoCoreRuntime } from '../services/MihomoCoreRuntime';
import { HomePage } from './HomePage';
import { ProxiesPage } from './ProxiesPage';
import { SettingsPage } from './SettingsPage';
import { ConnectionsPage } from './ConnectionsPage';
import { ProvidersPage } from './ProvidersPage';
import { ProfilesPage } from './ProfilesPage';
import { RulesPage } from './RulesPage';
import { LogsPage } from './LogsPage';
import { SubscriptionPage } from './SubscriptionPage';

interface NavItem {
  id: string;
  label: string;
}

const NAV_ITEMS: NavItem[] = [
  { id: 'home', label: 'Home' },
  { id: 'proxies', label: 'Proxies' },
  { id: 'providers', label: 'Providers' },
  { id: 'subscriptions', label: 'Subscriptions' },
  { id: 'profiles', label: 'Profiles' },
  { id: 'connections', label: 'Connections' },
  { id: 'rules', label: 'Rules' },
  { id: 'logs', label: 'Logs' },
  { id: 'settings', label: 'Settings' }
];

const COMPACT_QUERY = '(max-width: 720vp)';

@Entry
@Component
struct Index {
  @State private selectedPage: string = 'home';
  @State private controllerUrl: string = 'http://127.0.0.1:9090';
  @State private controllerSecret: string = '';
  @State private connectionState: string = ConnectionState.DISCONNECTED;
  @State private versionText: string = '-';
  @State private modeText: string = '-';
  @State private proxyGroupCount: number = 0;
  @State private proxyCount: number = 0;
  @State private uploadRate: number = 0;
  @State private downloadRate: number = 0;
  @State private proxyGroups: string[] = [];
  @State private calculatedProxies: CalculatedProxies | null = null;
  @State private lastError: string = '';
  @State private vpnFlowState: VpnFlowState = 'noSubscription';
  @State private vpnFlowError: VpnFlowError | null = null;
  @State private vpnNeedsCleanup: boolean = false;
  @State private devSectionExpanded: boolean = false;
  @State private compactLayout: boolean = false;

  private api?: MihomoApiService;
  private trafficWs: MihomoWsSubscription = new MihomoWsSubscription();
  private compactListener?: mediaquery.MediaQueryListener;
  private opVersion: number = 0;
  private vpnRuntime: VpnRuntime = new VpnRuntime();
  private coordinator: VpnStartupCoordinator = new VpnStartupCoordinator();
  private subStore?: SubscriptionStore;
  private configService?: MihomoConfigService;
  private coreRuntime?: MihomoCoreRuntime;

  aboutToAppear(): void {
    const context = this.getAbilityContext();
    const store = new AppConfigStore(context);
    const settings = store.load();
    this.controllerUrl = settings.controller.baseUrl;
    this.controllerSecret = settings.controller.secret;
    this.selectedPage = settings.selectedPage;
    this.api = new MihomoApiService(settings.controller);
    this.subStore = new SubscriptionStore(context);
    this.configService = new MihomoConfigService(context);
    this.coreRuntime = new MihomoCoreRuntime(context);
    this.coreRuntime.initRuntime();
    this.syncReady();
    const compactListener = this.getUIContext().getMediaQuery().matchMediaSync(COMPACT_QUERY);
    this.compactListener = compactListener;
    this.compactLayout = compactListener.matches;
    compactListener.on('change', (result: mediaquery.MediaQueryResult): void => {
      this.compactLayout = result.matches;
    });
  }

  aboutToDisappear(): void {
    if (this.compactListener !== undefined) {
      this.compactListener.off('change');
      this.compactListener = undefined;
    }
    this.trafficWs.close();
  }

  build() {
    Row() {
      Column() {
        Text('Mihomo Verge')
          .fontSize(this.compactLayout ? 14 : 20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#171A1F')
          .maxLines(this.compactLayout ? 2 : 1)
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ bottom: this.compactLayout ? 12 : 16 })

        ForEach(NAV_ITEMS, (item: NavItem) => {
          Button(item.label)
            .type(ButtonType.Normal)
            .stateEffect(true)
            .fontSize(this.compactLayout ? 12 : 16)
            .fontColor(this.selectedPage === item.id ? Color.White : '#313842')
            .backgroundColor(this.selectedPage === item.id ? '#2268D8' : '#EEF1F6')
            .borderRadius(8)
            .width('100%')
            .height(this.compactLayout ? 34 : 42)
            .margin({ bottom: this.compactLayout ? 7 : 8 })
            .onClick(() => {
              this.selectedPage = item.id;
              this.persistSettings();
            });
        }, (item: NavItem) => item.id)

        Blank()

        Text(this.statusLabel())
          .fontSize(this.compactLayout ? 10 : 12)
          .fontColor('#5C6470')
          .maxLines(3)
          .textAlign(TextAlign.Center)
          .width('100%')
      }
      .width(this.compactLayout ? 116 : 220)
      .height('100%')
      .padding(this.compactLayout ? 10 : 20)
      .backgroundColor(Color.White)
      .border({ width: 1, color: '#E5E8EF' })

      Column() {
        if (this.selectedPage === 'home') {
          HomePage({
            vpnFlowState: this.vpnFlowState,
            vpnFlowError: this.vpnFlowError,
            vpnNeedsCleanup: this.vpnNeedsCleanup,
            connectionState: this.connectionState,
            versionText: this.versionText,
            modeText: this.modeText,
            uploadRate: this.uploadRate,
            downloadRate: this.downloadRate,
            proxyGroupCount: this.proxyGroupCount,
            proxyCount: this.proxyCount,
            lastError: this.lastError,
            compact: this.compactLayout,
            devSectionExpanded: this.devSectionExpanded,
            onStartVpn: (): void => {
              this.handleStartVpn();
            },
            onStopVpn: (): void => {
              this.handleStopVpn();
            },
            onDismissError: (): void => {
              this.vpnFlowError = null;
            },
            onConnect: (): void => {
              this.connect();
            },
            onRefresh: (): void => {
              this.refresh();
            },
            onDisconnect: (): void => {
              this.disconnect();
            },
            onToggleDevSection: (): void => {
              this.devSectionExpanded = !this.devSectionExpanded;
            }
          })
        } else if (this.selectedPage === 'proxies') {
          ProxiesPage({
            groups: this.calculatedProxies?.groups ?? [],
            api: this.api,
            compact: this.compactLayout,
            onRefreshProxies: async (): Promise<void> => {
              await this.refreshProxiesOnly();
            }
          })
        } else if (this.selectedPage === 'providers') {
          ProvidersPage({ compact: this.compactLayout })
        } else if (this.selectedPage === 'subscriptions') {
          SubscriptionPage({
            store: this.subStore,
            configService: this.configService,
            compact: this.compactLayout,
            onConfigGenerated: (url: string, secret: string): void => {
              this.controllerUrl = url;
              this.controllerSecret = secret;
              this.api = new MihomoApiService({ baseUrl: url, secret: secret });
            },
            onSubscriptionChanged: (): void => {
              this.syncReady();
            }
          })
        } else if (this.selectedPage === 'profiles') {
          ProfilesPage({ compact: this.compactLayout })
        } else if (this.selectedPage === 'connections') {
          ConnectionsPage({ compact: this.compactLayout })
        } else if (this.selectedPage === 'rules') {
          RulesPage({ compact: this.compactLayout })
        } else if (this.selectedPage === 'logs') {
          LogsPage({ compact: this.compactLayout })
        } else if (this.selectedPage === 'settings') {
          SettingsPage({
            controllerUrl: this.controllerUrl,
            controllerSecret: this.controllerSecret,
            compact: this.compactLayout,
            onUrlChange: (value: string): void => {
              this.controllerUrl = value;
            },
            onSecretChange: (value: string): void => {
              this.controllerSecret = value;
            },
            onSave: (): void => {
              this.saveSettings();
            }
          })
        }
      }
      .layoutWeight(1)
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  private statusLabel(): string {
    if (this.connectionState === ConnectionState.DISCONNECTED) {
      return 'Disconnected';
    }
    if (this.connectionState === ConnectionState.CONNECTING) {
      return 'Connecting...';
    }
    if (this.connectionState === ConnectionState.CONNECTED) {
      return 'Connected';
    }
    if (this.connectionState === ConnectionState.REFRESHING) {
      return 'Refreshing...';
    }
    if (this.connectionState === ConnectionState.FAILED) {
      return 'Failed';
    }
    return 'Disconnected';
  }

  private async connect(): Promise<void> {
    if (this.connectionState !== ConnectionState.DISCONNECTED &&
      this.connectionState !== ConnectionState.FAILED) {
      return;
    }
    this.api = new MihomoApiService(this.currentControllerConfig());
    await this.fetchDashboard();
  }

  private async refresh(): Promise<void> {
    if (this.connectionState !== ConnectionState.CONNECTED) {
      return;
    }
    if (this.api === undefined) {
      return;
    }
    this.connectionState = ConnectionState.REFRESHING;
    this.lastError = '';
    const token = ++this.opVersion;
    try {
      const responses = await Promise.all([
        this.api.getVersion(),
        this.api.getBaseConfig(),
        this.api.calcuProxies()
      ]);
      if (token !== this.opVersion) {
        return;
      }
      this.applyVersion(responses[0]);
      this.applyBaseConfig(responses[1]);
      this.applyProxies(responses[2]);
      this.connectionState = ConnectionState.CONNECTED;
    } catch (error) {
      if (token !== this.opVersion) {
        return;
      }
      this.connectionState = ConnectionState.CONNECTED;
      this.lastError = this.formatError(error);
    }
  }

  private disconnect(): void {
    ++this.opVersion;
    this.trafficWs.close();
    this.uploadRate = 0;
    this.downloadRate = 0;
    this.lastError = '';
    this.connectionState = ConnectionState.DISCONNECTED;
  }

  private startTraffic(config: ControllerConfig): void {
    this.trafficWs.connect(config, 'traffic', (message: string): void => {
      try {
        const traffic = JSON.parse(message) as TrafficItem;
        this.uploadRate = traffic.up;
        this.downloadRate = traffic.down;
      } catch (_error) {
        // Ignore invalid traffic messages
      }
    }, (message: string): void => {
      this.lastError = `Traffic stream failed: ${message}`;
    });
  }

  private applyVersion(version: MihomoVersion): void {
    this.versionText = version.version ?? 'unknown';
  }

  private applyBaseConfig(config: MihomoBaseConfig): void {
    this.modeText = config.mode ?? '-';
  }

  private applyProxies(proxies: CalculatedProxies): void {
    this.proxyGroupCount = proxies.groups.length;
    this.proxyCount = proxies.proxies.length;
    this.proxyGroups = proxies.groups.map((group) => group.name);
    this.calculatedProxies = proxies;
  }

  private syncReady(): void {
    if (this.vpnFlowState === 'active' || this.vpnFlowState === 'preparing' ||
      this.vpnFlowState === 'coreStarting' || this.vpnFlowState === 'requestingPermission' ||
      this.vpnFlowState === 'stopping' || this.vpnNeedsCleanup) {
      return;
    }
    if (this.subStore === undefined) {
      this.vpnFlowState = 'noSubscription';
      return;
    }
    const active = this.subStore.getActive();
    this.vpnFlowState = active !== null ? 'ready' : 'noSubscription';
    this.vpnFlowError = null;
  }

  private async handleStartVpn(): Promise<void> {
    if (this.vpnFlowState === 'active' || this.vpnFlowState === 'preparing' ||
      this.vpnFlowState === 'coreStarting' || this.vpnFlowState === 'requestingPermission' ||
      this.vpnFlowState === 'stopping') {
      return;
    }
    if (this.subStore === undefined || this.configService === undefined ||
      this.coreRuntime === undefined) {
      return;
    }
    this.coordinator.cancel();
    this.vpnFlowError = null;
    this.vpnNeedsCleanup = false;

    const ctx = this.getAbilityContext();
    const configStore = new AppConfigStore(ctx);

    const result = await this.coordinator.startFlow(
      this.subStore,
      this.configService,
      configStore,
      this.coreRuntime,
      this.vpnRuntime,
      (state: VpnFlowState): void => {
        this.vpnFlowState = state;
      }
    );

    if (!result.success) {
      this.vpnFlowState = 'failed';
      this.vpnFlowError = result.error ?? { phase: 'core', message: 'Unknown error' };
      if (result.cleanupFailed === true) {
        this.vpnNeedsCleanup = true;
      }
      return;
    }

    const generated = this.configService.loadGeneratedConfig();
    if (generated !== null) {
      this.controllerUrl = generated.controllerUrl;
      this.controllerSecret = generated.controllerSecret;
      this.api = new MihomoApiService({
        baseUrl: generated.controllerUrl,
        secret: generated.controllerSecret
      });
    }
    const dashboardOk = await this.fetchDashboard();
    if (!dashboardOk) {
      const cleanupResult = await this.coordinator.stopFlow(
        this.coreRuntime!,
        this.vpnRuntime,
        (_state: VpnFlowState): void => {}
      );
      ++this.opVersion;
      this.trafficWs.close();
      this.uploadRate = 0;
      this.downloadRate = 0;
      this.connectionState = ConnectionState.DISCONNECTED;
      if (!cleanupResult.success) {
        this.vpnNeedsCleanup = true;
        this.vpnFlowState = 'failed';
        this.vpnFlowError = cleanupResult.error ??
          { phase: 'core', message: 'Cleanup after dashboard failure failed' };
      } else {
        this.vpnFlowState = 'failed';
        this.vpnFlowError = { phase: 'dashboard', message: this.lastError.length > 0 ? this.lastError : 'Dashboard connection failed' };
      }
      return;
    }
    this.vpnFlowState = 'active';
  }

  private async handleStopVpn(): Promise<void> {
    if (this.vpnFlowState !== 'active' && this.vpnFlowState !== 'failed') {
      return;
    }
    if (this.coreRuntime === undefined) {
      return;
    }
    this.coordinator.cancel();
    this.vpnFlowError = null;
    this.vpnNeedsCleanup = false;

    ++this.opVersion;
    this.trafficWs.close();
    this.uploadRate = 0;
    this.downloadRate = 0;

    const result = await this.coordinator.stopFlow(
      this.coreRuntime,
      this.vpnRuntime,
      (state: VpnFlowState): void => {
        this.vpnFlowState = state;
      }
    );

    if (!result.success) {
      this.vpnNeedsCleanup = true;
      this.vpnFlowState = 'failed';
      this.vpnFlowError = result.error ?? { phase: 'core', message: 'Stop failed' };
      return;
    }

    this.vpnFlowState = 'ready';
    this.connectionState = ConnectionState.DISCONNECTED;
    this.versionText = '-';
    this.modeText = '-';
    this.proxyGroupCount = 0;
    this.proxyCount = 0;
    this.lastError = '';
  }

  private async fetchDashboard(): Promise<boolean> {
    if (this.api === undefined) {
      return false;
    }
    this.connectionState = ConnectionState.CONNECTING;
    this.lastError = '';
    const token = ++this.opVersion;
    try {
      const config = this.currentControllerConfig();
      const responses = await Promise.all([
        this.api.getVersion(),
        this.api.getBaseConfig(),
        this.api.calcuProxies()
      ]);
      if (token !== this.opVersion) {
        return false;
      }
      this.applyVersion(responses[0]);
      this.applyBaseConfig(responses[1]);
      this.applyProxies(responses[2]);
      this.startTraffic(config);
      this.connectionState = ConnectionState.CONNECTED;
      this.persistSettings();
      return true;
    } catch (error) {
      if (token !== this.opVersion) {
        return false;
      }
      this.connectionState = ConnectionState.FAILED;
      this.lastError = this.formatError(error);
      return false;
    }
  }

  private async refreshProxiesOnly(): Promise<void> {
    if (this.api === undefined) {
      return;
    }
    const token = ++this.opVersion;
    try {
      const proxies = await this.api.calcuProxies();
      if (token !== this.opVersion) {
        return;
      }
      this.applyProxies(proxies);
    } catch (error) {
      if (token !== this.opVersion) {
        return;
      }
      const errMsg = this.formatError(error);
      this.lastError = errMsg;
      throw new Error(errMsg);
    }
  }

  private saveSettings(): void {
    ++this.opVersion;
    this.trafficWs.close();
    this.uploadRate = 0;
    this.downloadRate = 0;
    this.lastError = '';
    this.api = new MihomoApiService(this.currentControllerConfig());
    this.persistSettings();
    this.connectionState = ConnectionState.DISCONNECTED;
  }

  private currentControllerConfig(): ControllerConfig {
    return {
      baseUrl: this.controllerUrl,
      secret: this.controllerSecret
    };
  }

  private persistSettings(): void {
    const context = this.getAbilityContext();
    const store = new AppConfigStore(context);
    const settings: AppSettings = {
      controller: this.currentControllerConfig(),
      themeMode: 'system',
      selectedPage: this.selectedPage
    };
    store.save(settings);
  }

  private getAbilityContext(): common.UIAbilityContext {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) {
      throw new Error('Ability context is not available');
    }
    return context as common.UIAbilityContext;
  }

  private formatError(error: Object): string {
    if (error instanceof Error) {
      return error.message;
    }
    return `${error}`;
  }
}
