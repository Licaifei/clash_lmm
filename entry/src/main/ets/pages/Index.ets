import { common } from '@kit.AbilityKit';
import mediaquery from '@ohos.mediaquery';
import {
  CalculatedProxies,
  ControllerConfig,
  MihomoBaseConfig,
  MihomoVersion,
  TrafficItem
} from '../models/MihomoModels';
import { AppConfigStore, AppSettings } from '../services/AppConfigStore';
import { MihomoApiService } from '../services/MihomoApiService';
import { MihomoWsSubscription } from '../services/MihomoWsService';
import { HomePage } from './HomePage';
import { ProxiesPage } from './ProxiesPage';
import { SettingsPage } from './SettingsPage';
import { ConnectionsPage } from './ConnectionsPage';
import { ProvidersPage } from './ProvidersPage';
import { ProfilesPage } from './ProfilesPage';
import { RulesPage } from './RulesPage';
import { LogsPage } from './LogsPage';

interface NavItem {
  id: string;
  label: string;
}

const NAV_ITEMS: NavItem[] = [
  { id: 'home', label: 'Home' },
  { id: 'proxies', label: 'Proxies' },
  { id: 'providers', label: 'Providers' },
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
  @State private statusText: string = 'Not connected';
  @State private versionText: string = '-';
  @State private modeText: string = '-';
  @State private proxyGroupCount: number = 0;
  @State private proxyCount: number = 0;
  @State private uploadRate: number = 0;
  @State private downloadRate: number = 0;
  @State private proxyGroups: string[] = [];
  @State private lastError: string = '';
  @State private compactLayout: boolean = false;

  private api?: MihomoApiService;
  private trafficWs: MihomoWsSubscription = new MihomoWsSubscription();
  private compactListener?: mediaquery.MediaQueryListener;

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext;
    const store = new AppConfigStore(context);
    const settings = store.load();
    this.controllerUrl = settings.controller.baseUrl;
    this.controllerSecret = settings.controller.secret;
    this.selectedPage = settings.selectedPage;
    this.api = new MihomoApiService(settings.controller);
    this.compactListener = mediaquery.matchMediaSync(COMPACT_QUERY);
    this.compactLayout = this.compactListener.matches;
    this.compactListener.on('change', (result: mediaquery.MediaQueryResult): void => {
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

        Text(this.statusText)
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
            versionText: this.versionText,
            modeText: this.modeText,
            uploadRate: this.uploadRate,
            downloadRate: this.downloadRate,
            proxyGroupCount: this.proxyGroupCount,
            proxyCount: this.proxyCount,
            statusText: this.statusText,
            lastError: this.lastError,
            compact: this.compactLayout,
            onConnectAndRefresh: (): void => {
              this.connectAndRefresh();
            }
          })
        } else if (this.selectedPage === 'proxies') {
          ProxiesPage({
            proxyGroupCount: this.proxyGroupCount,
            proxyCount: this.proxyCount,
            compact: this.compactLayout,
            proxyGroups: this.proxyGroups
          })
        } else if (this.selectedPage === 'providers') {
          ProvidersPage({ compact: this.compactLayout })
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

  private async connectAndRefresh(): Promise<void> {
    try {
      const config = this.currentControllerConfig();
      this.api = new MihomoApiService(config);
      const responses = await Promise.all([
        this.api.getVersion(),
        this.api.getBaseConfig(),
        this.api.calcuProxies()
      ]);
      const version = responses[0];
      const baseConfig = responses[1];
      const proxies = responses[2];
      this.applyVersion(version);
      this.applyBaseConfig(baseConfig);
      this.applyProxies(proxies);
      this.startTraffic(config);
      this.statusText = 'Connected';
      this.lastError = '';
      this.persistSettings();
    } catch (error) {
      this.statusText = this.formatError(error);
      this.lastError = this.formatError(error);
    }
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
      this.statusText = `Traffic stream failed: ${message}`;
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
  }

  private saveSettings(): void {
    this.api = new MihomoApiService(this.currentControllerConfig());
    this.statusText = 'Settings saved';
    this.persistSettings();
  }

  private currentControllerConfig(): ControllerConfig {
    return {
      baseUrl: this.controllerUrl,
      secret: this.controllerSecret
    };
  }

  private persistSettings(): void {
    const context = getContext(this) as common.UIAbilityContext;
    const store = new AppConfigStore(context);
    const settings: AppSettings = {
      controller: this.currentControllerConfig(),
      themeMode: 'system',
      selectedPage: this.selectedPage
    };
    store.save(settings);
  }

  private formatError(error: Object): string {
    if (error instanceof Error) {
      return error.message;
    }
    return `${error}`;
  }
}
