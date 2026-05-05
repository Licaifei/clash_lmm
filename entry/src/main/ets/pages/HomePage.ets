import { BasePage } from '../components/BasePage';
import { StatusCard } from '../components/StatusCard';
import { ErrorBanner } from '../components/ErrorBanner';

@Component
export struct HomePage {
  @Prop versionText: string = '-';
  @Prop modeText: string = '-';
  @Prop uploadRate: number = 0;
  @Prop downloadRate: number = 0;
  @Prop proxyGroupCount: number = 0;
  @Prop proxyCount: number = 0;
  @Prop statusText: string = 'Not connected';
  @Prop lastError: string = '';
  @Prop compact: boolean = false;
  onConnectAndRefresh?: () => void;

  private formatBytes(value: number): string {
    if (value < 1024) {
      return `${value} B`;
    }
    if (value < 1024 * 1024) {
      return `${(value / 1024).toFixed(1)} KB`;
    }
    return `${(value / 1024 / 1024).toFixed(1)} MB`;
  }

  build() {
    BasePage({ title: 'Home', compact: this.compact }) {
      Column({ space: 16 }) {
        if (this.lastError.length > 0) {
          ErrorBanner({ message: this.lastError })
        }

        if (this.compact) {
          Column({ space: 12 }) {
            StatusCard({
              title: 'Core',
              value: this.versionText,
              detail: this.statusText,
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
              detail: this.statusText
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

        Button('Connect and Refresh')
          .type(ButtonType.Normal)
          .height(44)
          .borderRadius(8)
          .width(this.compact ? '100%' : 220)
          .backgroundColor('#2268D8')
          .fontColor(Color.White)
          .onClick((): void => {
            if (this.onConnectAndRefresh !== undefined) {
              this.onConnectAndRefresh();
            }
          })

        if (this.versionText !== '-' && this.versionText !== 'unknown') {
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
