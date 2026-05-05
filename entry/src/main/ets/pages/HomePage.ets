import { BasePage } from '../components/BasePage';
import { StatusCard } from '../components/StatusCard';
import { ErrorBanner } from '../components/ErrorBanner';
import { LoadingRow } from '../components/LoadingRow';

@Component
export struct HomePage {
  @Prop connectionState: string = 'disconnected';
  @Prop versionText: string = '-';
  @Prop modeText: string = '-';
  @Prop uploadRate: number = 0;
  @Prop downloadRate: number = 0;
  @Prop proxyGroupCount: number = 0;
  @Prop proxyCount: number = 0;
  @Prop lastError: string = '';
  @Prop compact: boolean = false;
  onConnect?: () => void;
  onRefresh?: () => void;
  onDisconnect?: () => void;

  private formatBytes(value: number): string {
    if (value < 1024) {
      return `${value} B`;
    }
    if (value < 1024 * 1024) {
      return `${(value / 1024).toFixed(1)} KB`;
    }
    return `${(value / 1024 / 1024).toFixed(1)} MB`;
  }

  private statusLabel(): string {
    if (this.connectionState === 'disconnected') {
      return 'Not connected';
    }
    if (this.connectionState === 'connecting') {
      return 'Connecting...';
    }
    if (this.connectionState === 'connected') {
      return 'Connected';
    }
    if (this.connectionState === 'refreshing') {
      return 'Refreshing...';
    }
    if (this.connectionState === 'failed') {
      return 'Connection failed';
    }
    return 'Not connected';
  }

  private isConnected(): boolean {
    return this.connectionState === 'connected' || this.connectionState === 'refreshing';
  }

  private canConnect(): boolean {
    return this.connectionState === 'disconnected' || this.connectionState === 'failed';
  }

  private canRefresh(): boolean {
    return this.connectionState === 'connected';
  }

  private canDisconnect(): boolean {
    return this.connectionState === 'connected' || this.connectionState === 'refreshing';
  }

  build() {
    BasePage({ title: 'Home', compact: this.compact }) {
      Column({ space: 16 }) {
        if (this.lastError.length > 0) {
          ErrorBanner({ message: this.lastError })
        }

        if (this.connectionState === 'connecting') {
          LoadingRow({ message: 'Connecting to Mihomo controller...' })
        }
        if (this.connectionState === 'refreshing') {
          LoadingRow({ message: 'Refreshing dashboard data...' })
        }

        if (this.compact) {
          Column({ space: 12 }) {
            StatusCard({
              title: 'Core',
              value: this.versionText,
              detail: this.statusLabel(),
              compact: true
            })
            StatusCard({
              title: 'Mode',
              value: this.modeText,
              detail: 'Current Mihomo outbound mode',
              compact: true
            })
            StatusCard({
              title: 'Traffic',
              value: `${this.formatBytes(this.downloadRate)}/s`,
              detail: `Up ${this.formatBytes(this.uploadRate)}/s`,
              compact: true
            })
          }
          .width('100%')
        } else {
          Row({ space: 16 }) {
            StatusCard({
              title: 'Core',
              value: this.versionText,
              detail: this.statusLabel()
            })
              .layoutWeight(1)
            StatusCard({
              title: 'Mode',
              value: this.modeText,
              detail: 'Current Mihomo outbound mode'
            })
              .layoutWeight(1)
            StatusCard({
              title: 'Traffic',
              value: `${this.formatBytes(this.downloadRate)}/s`,
              detail: `Up ${this.formatBytes(this.uploadRate)}/s`
            })
              .layoutWeight(1)
          }
          .width('100%')
        }

        if (this.compact) {
          Column({ space: 8 }) {
            Button('Connect')
              .type(ButtonType.Normal)
              .height(44)
              .borderRadius(8)
              .width('100%')
              .backgroundColor('#2268D8')
              .fontColor(Color.White)
              .enabled(this.canConnect())
              .opacity(this.canConnect() ? 1 : 0.4)
              .onClick((): void => {
                if (this.onConnect !== undefined) {
                  this.onConnect();
                }
              })

            Button('Refresh')
              .type(ButtonType.Normal)
              .height(44)
              .borderRadius(8)
              .width('100%')
              .backgroundColor('#2268D8')
              .fontColor(Color.White)
              .enabled(this.canRefresh())
              .opacity(this.canRefresh() ? 1 : 0.4)
              .onClick((): void => {
                if (this.onRefresh !== undefined) {
                  this.onRefresh();
                }
              })

            Button('Disconnect')
              .type(ButtonType.Normal)
              .height(44)
              .borderRadius(8)
              .width('100%')
              .backgroundColor('#C62828')
              .fontColor(Color.White)
              .enabled(this.canDisconnect())
              .opacity(this.canDisconnect() ? 1 : 0.4)
              .onClick((): void => {
                if (this.onDisconnect !== undefined) {
                  this.onDisconnect();
                }
              })
          }
          .width('100%')
        } else {
          Row({ space: 12 }) {
            Button('Connect')
              .type(ButtonType.Normal)
              .height(44)
              .borderRadius(8)
              .layoutWeight(1)
              .backgroundColor('#2268D8')
              .fontColor(Color.White)
              .enabled(this.canConnect())
              .opacity(this.canConnect() ? 1 : 0.4)
              .onClick((): void => {
                if (this.onConnect !== undefined) {
                  this.onConnect();
                }
              })

            Button('Refresh')
              .type(ButtonType.Normal)
              .height(44)
              .borderRadius(8)
              .layoutWeight(1)
              .backgroundColor('#2268D8')
              .fontColor(Color.White)
              .enabled(this.canRefresh())
              .opacity(this.canRefresh() ? 1 : 0.4)
              .onClick((): void => {
                if (this.onRefresh !== undefined) {
                  this.onRefresh();
                }
              })

            Button('Disconnect')
              .type(ButtonType.Normal)
              .height(44)
              .borderRadius(8)
              .layoutWeight(1)
              .backgroundColor('#C62828')
              .fontColor(Color.White)
              .enabled(this.canDisconnect())
              .opacity(this.canDisconnect() ? 1 : 0.4)
              .onClick((): void => {
                if (this.onDisconnect !== undefined) {
                  this.onDisconnect();
                }
              })
          }
          .width('100%')
        }

        if (this.isConnected()) {
          if (this.compact) {
            Column({ space: 12 }) {
              StatusCard({
                title: 'Groups',
                value: `${this.proxyGroupCount}`,
                detail: 'Proxy groups',
                compact: true
              })
              StatusCard({
                title: 'Nodes',
                value: `${this.proxyCount}`,
                detail: 'Leaf proxies',
                compact: true
              })
            }
            .width('100%')
          } else {
            Row({ space: 16 }) {
              StatusCard({
                title: 'Groups',
                value: `${this.proxyGroupCount}`,
                detail: 'Proxy groups'
              })
                .layoutWeight(1)
              StatusCard({
                title: 'Nodes',
                value: `${this.proxyCount}`,
                detail: 'Leaf proxies'
              })
                .layoutWeight(1)
            }
            .width('100%')
          }
        }
      }
      .width('100%')
    }
  }
}
