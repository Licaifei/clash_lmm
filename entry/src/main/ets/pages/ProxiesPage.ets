import { MihomoApiService } from '../services/MihomoApiService';
import { ProxyGroupItem, ProxyItem } from '../models/MihomoModels';
import { BasePage } from '../components/BasePage';
import { SectionHeader } from '../components/SectionHeader';
import { EmptyState } from '../components/EmptyState';
import { ErrorBanner } from '../components/ErrorBanner';

const DELAY_URL = 'https://www.gstatic.com/generate_204';
const DELAY_TIMEOUT = 5000;

@Component
export struct ProxiesPage {
  @Prop groups: ProxyGroupItem[] = [];
  api?: MihomoApiService;
  @Prop compact: boolean = false;
  onRefreshProxies?: () => Promise<void>;

  @State private selectedGroupName: string = '';
  @State private delayMap: Record<string, number> = {};
  @State private activeNode: string = '';
  @State private activeAction: string = '';
  @State private error: string = '';

  private effectiveGroup(): ProxyGroupItem {
    if (this.groups.length === 0) {
      return this.emptyGroup();
    }
    if (this.selectedGroupName.length > 0) {
      for (let i = 0; i < this.groups.length; i++) {
        if (this.groups[i].name === this.selectedGroupName) {
          return this.groups[i];
        }
      }
    }
    return this.groups[0];
  }

  private emptyGroup(): ProxyGroupItem {
    return { name: '', type: '', all: [] };
  }

  private isSelected(group: ProxyGroupItem, name: string): boolean {
    return group.now !== undefined && group.now === name;
  }

  private delayText(name: string): string {
    const val = this.delayMap[name];
    if (val !== undefined) {
      return val + ' ms';
    }
    return '-';
  }

  private isActing(name: string, action: string): boolean {
    return this.activeNode === name && this.activeAction === action;
  }

  private recordDelay(name: string, delay: number): void {
    const newMap: Record<string, number> = {};
    const keys = Object.keys(this.delayMap);
    for (let i = 0; i < keys.length; i++) {
      newMap[keys[i]] = this.delayMap[keys[i]];
    }
    newMap[name] = delay;
    this.delayMap = newMap;
  }

  private async selectNode(groupName: string, proxyName: string): Promise<void> {
    if (this.api === undefined) {
      return;
    }
    this.activeNode = proxyName;
    this.activeAction = 'selecting';
    this.error = '';
    try {
      await this.api.selectNodeForGroup(groupName, proxyName);
    } catch (err) {
      this.activeNode = '';
      this.activeAction = '';
      this.error = this.formatError(err);
      return;
    }
    await this.doRefresh();
    this.activeNode = '';
    this.activeAction = '';
  }

  private async doRefresh(): Promise<void> {
    if (this.onRefreshProxies !== undefined) {
      try {
        await this.onRefreshProxies();
      } catch (err) {
        this.error = this.formatError(err);
      }
    }
  }

  private async testDelay(proxyName: string): Promise<void> {
    if (this.api === undefined) {
      return;
    }
    this.activeNode = proxyName;
    this.activeAction = 'testing';
    this.error = '';
    try {
      const result = await this.api.delayProxyByName(proxyName, DELAY_URL, DELAY_TIMEOUT);
      this.recordDelay(proxyName, result.delay);
      this.activeNode = '';
      this.activeAction = '';
    } catch (err) {
      this.activeNode = '';
      this.activeAction = '';
      this.error = this.formatError(err);
    }
  }

  private formatError(err: Object): string {
    if (err instanceof Error) {
      return err.message;
    }
    return '' + err;
  }

  build() {
    BasePage({ title: 'Proxies', compact: this.compact }) {
      Column({ space: 12 }) {
        if (this.error.length > 0) {
          ErrorBanner({ message: this.error })
        }

        Row() {
          SectionHeader({ title: 'Groups (' + this.groups.length + ')' })
            .layoutWeight(1)
          Button('Refresh')
            .type(ButtonType.Normal)
            .height(32)
            .fontSize(12)
            .borderRadius(6)
            .backgroundColor('#2268D8')
            .fontColor(Color.White)
            .onClick((): void => {
              this.doRefresh();
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        if (this.groups.length === 0) {
          EmptyState({ message: 'No proxy groups. Connect and refresh to load proxies.' })
        } else if (this.compact) {
          this.CompactGroupList()
        } else {
          this.WideGroupList()
        }
      }
      .width('100%')
      .height('100%')
    }
  }

  @Builder
  private CompactGroupList() {
    Column({ space: 10 }) {
      Scroll() {
        Row({ space: 6 }) {
          ForEach(this.groups, (group: ProxyGroupItem) => {
            Button(group.name)
              .type(ButtonType.Normal)
              .height(32)
              .fontSize(11)
              .borderRadius(6)
              .padding({ left: 10, right: 10 })
              .fontColor(this.effectiveGroup().name === group.name ? Color.White : '#313842')
              .backgroundColor(this.effectiveGroup().name === group.name ? '#2268D8' : '#EEF1F6')
              .onClick(() => {
                this.selectedGroupName = group.name;
              })
          }, (group: ProxyGroupItem) => group.name)
        }
        .padding({ left: 2, right: 2 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')

      this.NodeList(this.effectiveGroup())
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private WideGroupList() {
    Row({ space: 12 }) {
      List() {
        ForEach(this.groups, (group: ProxyGroupItem) => {
          ListItem() {
            Column({ space: 4 }) {
              Text(group.name)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#171A1F')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Row({ space: 6 }) {
                Text(group.type)
                  .fontSize(11)
                  .fontColor('#7B8491')
                Text('•')
                  .fontSize(11)
                  .fontColor('#7B8491')
                Text(group.now !== undefined ? group.now : 'none')
                  .fontSize(11)
                  .fontColor('#5C6470')
                  .maxLines(1)
              }
              Text((group.all !== undefined ? group.all.length : 0) + ' nodes')
                .fontSize(10)
                .fontColor('#A0A7B0')
            }
            .alignItems(HorizontalAlign.Start)
            .padding(12)
            .borderRadius(8)
            .backgroundColor(this.effectiveGroup().name === group.name ? '#E8F0FE' : Color.White)
            .border({
              width: 1,
              color: this.effectiveGroup().name === group.name ? '#2268D8' : '#E5E8EF'
            })
            .onClick(() => {
              this.selectedGroupName = group.name;
            })
          }
          .margin({ bottom: 6 })
        }, (group: ProxyGroupItem) => group.name)
      }
      .width(200)
      .height('100%')

      this.NodeList(this.effectiveGroup())
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private NodeList(group: ProxyGroupItem) {
    Column({ space: 10 }) {
      Row() {
        Column({ space: 2 }) {
          Text(group.name)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#171A1F')
          Row({ space: 8 }) {
            Text(group.type)
              .fontSize(12)
              .fontColor('#5C6470')
            if (group.now !== undefined) {
              Text('→ ' + group.now)
                .fontSize(12)
                .fontColor('#2268D8')
                .maxLines(1)
            }
          }
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      List() {
        ForEach(group.all !== undefined ? group.all : [], (node: ProxyItem) => {
          ListItem() {
            Column({ space: 8 }) {
              Row() {
                if (this.isSelected(group, node.name)) {
                  Text('✓')
                    .fontSize(14)
                    .fontColor('#2E7D32')
                    .margin({ right: 6 })
                }
                Text(node.name)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#171A1F')
                  .layoutWeight(1)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(this.delayText(node.name))
                  .fontSize(12)
                  .fontColor('#7B8491')
                  .fontWeight(FontWeight.Medium)
              }
              .width('100%')

              Row({ space: 6 }) {
                Text(node.type)
                  .fontSize(11)
                  .fontColor('#7B8491')
                if (node.provider !== undefined && node.provider.length > 0) {
                  Text('| ' + node.provider)
                    .fontSize(11)
                    .fontColor('#A0A7B0')
                    .maxLines(1)
                }
                Blank()
                Button('Test')
                  .type(ButtonType.Normal)
                  .height(28)
                  .fontSize(10)
                  .borderRadius(4)
                  .padding({ left: 8, right: 8 })
                  .backgroundColor('#EEF1F6')
                  .fontColor('#313842')
                  .enabled(!this.isActing(node.name, 'testing'))
                  .onClick(() => {
                    this.testDelay(node.name);
                  })
                Button('Select')
                  .type(ButtonType.Normal)
                  .height(28)
                  .fontSize(10)
                  .borderRadius(4)
                  .padding({ left: 8, right: 8 })
                  .backgroundColor(this.isSelected(group, node.name) ? '#E8F5E9' : '#2268D8')
                  .fontColor(this.isSelected(group, node.name) ? '#2E7D32' : Color.White)
                  .enabled(!this.isActing(node.name, 'selecting') && !this.isSelected(group, node.name))
                  .onClick(() => {
                    this.selectNode(group.name, node.name);
                  })
              }
              .width('100%')
            }
            .padding(12)
            .backgroundColor(Color.White)
            .borderRadius(8)
            .border({ width: 1, color: '#E5E8EF' })
          }
          .margin({ bottom: 6 })
        }, (node: ProxyItem) => node.name)
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }
}
