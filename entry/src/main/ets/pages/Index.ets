import { common } from '@kit.AbilityKit';
import mediaquery from '@ohos.mediaquery';
import { BasePage } from '../components/BasePage';
import { StatusCard } from '../components/StatusCard';
import { CalculatedProxies, ControllerConfig, MihomoBaseConfig, MihomoVersion, TrafficItem } from '../models/MihomoModels';
import { AppConfigStore, AppSettings } from '../services/AppConfigStore';
import { MihomoApiService } from '../services/MihomoApiService';
import { MihomoWsSubscription } from '../services/MihomoWsService';

interface NavItem {
  id: string;
  label: string;
}

const NAV_ITEMS: NavItem[] = [
  { id: 'home', label: 'Home' },
  { id: 'proxies', label: 'Proxies' },
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
          this.HomeContent()
        } else if (this.selectedPage === 'proxies') {
          this.ProxiesContent()
        } else if (this.selectedPage === 'settings') {
          this.SettingsContent()
        } else {
          this.PlaceholderContent(this.currentTitle())
        }
      }
      .layoutWeight(1)
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private HomeContent() {
    BasePage({ title: 'Home', compact: this.compactLayout }) {
      Column({ space: 16 }) {
        if (this.compactLayout) {
          Column({ space: 12 }) {
            StatusCard({ title: 'Core', value: this.versionText, detail: this.statusText, compact: true })
            StatusCard({ title: 'Mode', value: this.modeText, detail: 'Current Mihomo outbound mode', compact: true })
            StatusCard({ title: 'Traffic', value: `${this.formatBytes(this.downloadRate)}/s`, detail: `Up ${this.formatBytes(this.uploadRate)}/s`, compact: true })
          }
          .width('100%')
        } else {
          Row({ space: 16 }) {
            StatusCard({ title: 'Core', value: this.versionText, detail: this.statusText })
              .layoutWeight(1)
            StatusCard({ title: 'Mode', value: this.modeText, detail: 'Current Mihomo outbound mode' })
              .layoutWeight(1)
            StatusCard({ title: 'Traffic', value: `${this.formatBytes(this.downloadRate)}/s`, detail: `Up ${this.formatBytes(this.uploadRate)}/s` })
              .layoutWeight(1)
          }
          .width('100%')
        }

        Button('Connect and Refresh')
          .type(ButtonType.Normal)
          .height(44)
          .borderRadius(8)
          .width(this.compactLayout ? '100%' : 220)
          .backgroundColor('#2268D8')
          .fontColor(Color.White)
          .onClick(() => {
            this.connectAndRefresh();
          })
      }
      .width('100%')
    }
  }

  @Builder
  private ProxiesContent() {
    BasePage({ title: 'Proxies', compact: this.compactLayout }) {
      Column({ space: 12 }) {
        if (this.compactLayout) {
          Column({ space: 12 }) {
            StatusCard({ title: 'Groups', value: `${this.proxyGroupCount}`, detail: 'Selectable proxy groups', compact: true })
            StatusCard({ title: 'Nodes', value: `${this.proxyCount}`, detail: 'Leaf proxy nodes', compact: true })
          }
          .width('100%')
        } else {
          Row({ space: 16 }) {
            StatusCard({ title: 'Groups', value: `${this.proxyGroupCount}`, detail: 'Selectable proxy groups' })
              .layoutWeight(1)
            StatusCard({ title: 'Nodes', value: `${this.proxyCount}`, detail: 'Leaf proxy nodes' })
              .layoutWeight(1)
          }
        }

        List() {
          ForEach(this.proxyGroups, (name: string) => {
            ListItem() {
              Row() {
                Text(name)
                  .fontSize(16)
                  .fontColor('#171A1F')
                Blank()
                Text('Select')
                  .fontSize(12)
                  .fontColor('#2268D8')
              }
              .height(48)
              .padding({ left: 16, right: 16 })
              .backgroundColor(Color.White)
              .borderRadius(8)
              .border({ width: 1, color: '#E5E8EF' })
            }
          }, (name: string) => name)
        }
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  private SettingsContent() {
    BasePage({ title: 'Settings', compact: this.compactLayout }) {
      Column({ space: 14 }) {
        Text('Controller URL')
          .fontSize(13)
          .fontColor('#5C6470')
          .width('100%')
        TextInput({ text: this.controllerUrl })
          .height(44)
          .width('100%')
          .onChange((value: string) => {
            this.controllerUrl = value;
          })

        Text('Secret')
          .fontSize(13)
          .fontColor('#5C6470')
          .width('100%')
        TextInput({ text: this.controllerSecret })
          .height(44)
          .width('100%')
          .type(InputType.Password)
          .onChange((value: string) => {
            this.controllerSecret = value;
          })

        Button('Save Settings')
          .type(ButtonType.Normal)
          .height(44)
          .borderRadius(8)
          .width(this.compactLayout ? '100%' : 180)
          .backgroundColor('#2268D8')
          .fontColor(Color.White)
          .onClick(() => {
            this.persistSettings();
            this.api = new MihomoApiService(this.currentControllerConfig());
            this.statusText = 'Settings saved';
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
  }

  @Builder
  private PlaceholderContent(title: string) {
    BasePage({ title: title, compact: this.compactLayout }) {
      Column({ space: 12 }) {
        Text(`${title} page scaffold`)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
        Text('Next step: wire this page to the corresponding Mihomo endpoint and shared store.')
          .fontSize(14)
          .fontColor('#5C6470')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
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
      this.persistSettings();
    } catch (error) {
      this.statusText = this.formatError(error);
    }
  }

  private startTraffic(config: ControllerConfig): void {
    this.trafficWs.connect(config, 'traffic', (message: string) => {
      try {
        const traffic = JSON.parse(message) as TrafficItem;
        this.uploadRate = traffic.up;
        this.downloadRate = traffic.down;
      } catch (_error) {
        this.statusText = 'Ignored invalid traffic message';
      }
    }, (message: string) => {
      this.statusText = `Traffic stream failed: ${message}`;
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

  private currentTitle(): string {
    const current = NAV_ITEMS.find((item: NavItem) => item.id === this.selectedPage);
    return current?.label ?? 'Page';
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

  private formatBytes(value: number): string {
    if (value < 1024) {
      return `${value} B`;
    }
    if (value < 1024 * 1024) {
      return `${(value / 1024).toFixed(1)} KB`;
    }
    return `${(value / 1024 / 1024).toFixed(1)} MB`;
  }

  private formatError(error: Object): string {
    if (error instanceof Error) {
      return error.message;
    }
    return `${error}`;
  }
}
