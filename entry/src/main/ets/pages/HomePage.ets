import { BasePage } from '../components/BasePage';
import { StatusCard } from '../components/StatusCard';
import { ErrorBanner } from '../components/ErrorBanner';
import { LoadingRow } from '../components/LoadingRow';
import { SectionHeader } from '../components/SectionHeader';
import { VpnFlowState, VpnFlowError } from '../models/MihomoModels';

@Component
export struct HomePage {
  @Prop vpnFlowState: VpnFlowState = 'noSubscription';
  @Prop vpnFlowError: VpnFlowError | null = null;
  @Prop vpnNeedsCleanup: boolean = false;
  @Prop connectionState: string = 'disconnected';
  @Prop versionText: string = '-';
  @Prop modeText: string = '-';
  @Prop uploadRate: number = 0;
  @Prop downloadRate: number = 0;
  @Prop proxyGroupCount: number = 0;
  @Prop proxyCount: number = 0;
  @Prop lastError: string = '';
  @Prop compact: boolean = false;
  @Prop devSectionExpanded: boolean = false;
  onStartVpn?: () => void;
  onStopVpn?: () => void;
  onDismissError?: () => void;
  onConnect?: () => void;
  onRefresh?: () => void;
  onDisconnect?: () => void;
  onToggleDevSection?: () => void;

  private formatBytes(value: number): string {
    if (value < 1024) {
      return `${value} B`;
    }
    if (value < 1024 * 1024) {
      return `${(value / 1024).toFixed(1)} KB`;
    }
    return `${(value / 1024 / 1024).toFixed(1)} MB`;
  }

  private vpnFlowLabel(): string {
    if (this.vpnFlowState === 'noSubscription') {
      return 'No subscription';
    }
    if (this.vpnFlowState === 'ready') {
      return 'Ready to connect';
    }
    if (this.vpnFlowState === 'preparing') {
      return 'Preparing...';
    }
    if (this.vpnFlowState === 'coreStarting') {
      return 'Starting Core...';
    }
    if (this.vpnFlowState === 'requestingPermission') {
      return 'Starting VPN...';
    }
    if (this.vpnFlowState === 'active') {
      return 'VPN Active';
    }
    if (this.vpnFlowState === 'stopping') {
      return 'Stopping...';
    }
    if (this.vpnFlowState === 'failed') {
      return 'Connection failed';
    }
    return 'Unknown';
  }

  private vpnFlowDetail(): string {
    if (this.vpnFlowState === 'noSubscription') {
      return 'Go to Subscriptions to add one';
    }
    if (this.vpnFlowState === 'ready') {
      return 'Tap Start to connect';
    }
    if (this.vpnFlowState === 'active') {
      return `Core ${this.versionText}  ·  ${this.modeText} mode`;
    }
    if (this.vpnFlowState === 'failed' && this.vpnFlowError !== null) {
      return this.vpnFlowError.message;
    }
    return '';
  }

  private isStartAction(): boolean {
    if (this.vpnFlowState === 'noSubscription' || this.vpnFlowState === 'ready') {
      return true;
    }
    if (this.vpnFlowState === 'failed') {
      return !this.vpnNeedsCleanup;
    }
    return false;
  }

  private isPrimaryEnabled(): boolean {
    return this.vpnFlowState === 'ready' ||
      this.vpnFlowState === 'active' ||
      this.vpnFlowState === 'failed';
  }

  private isTransitional(): boolean {
    return this.vpnFlowState === 'preparing' ||
      this.vpnFlowState === 'coreStarting' ||
      this.vpnFlowState === 'requestingPermission' ||
      this.vpnFlowState === 'stopping';
  }

  private showDashboard(): boolean {
    return this.vpnFlowState === 'active' && this.connectionState === 'connected';
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
        // VPN Flow Status
        StatusCard({
          title: 'VPN',
          value: this.vpnFlowLabel(),
          detail: this.vpnFlowDetail(),
          compact: this.compact
        })

        // Loading during transitions
        if (this.isTransitional()) {
          LoadingRow({ message: this.vpnFlowLabel() })
        }

        // Error panel on failure
        if (this.vpnFlowState === 'failed' && this.vpnFlowError !== null) {
          Column({ space: 8 }) {
            Text('Failed at: ' + this.vpnFlowError.phase)
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#C62828')
              .width('100%')
            Text(this.vpnFlowError.message)
              .fontSize(12)
              .fontColor('#C62828')
              .maxLines(4)
              .width('100%')
            Row({ space: 8 }) {
              Button('Dismiss')
                .type(ButtonType.Normal)
                .height(28)
                .borderRadius(4)
                .fontSize(11)
                .backgroundColor('#FFEBEE')
                .fontColor('#C62828')
                .onClick((): void => {
                  if (this.onDismissError !== undefined) {
                    this.onDismissError();
                  }
                })
              Button(this.vpnNeedsCleanup ? 'Retry Stop' : 'Retry')
                .type(ButtonType.Normal)
                .height(28)
                .borderRadius(4)
                .fontSize(11)
                .backgroundColor('#C62828')
                .fontColor(Color.White)
                .onClick((): void => {
                  if (this.vpnNeedsCleanup) {
                    if (this.onStopVpn !== undefined) {
                      this.onStopVpn();
                    }
                  } else {
                    if (this.onStartVpn !== undefined) {
                      this.onStartVpn();
                    }
                  }
                })
            }
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#FFEBEE')
          .borderRadius(8)
          .border({ width: 1, color: '#FFCDD2' })
        }

        // Primary VPN button
        if (this.isStartAction()) {
          Button(this.vpnFlowState === 'noSubscription' ? 'Import a Subscription' : 'Start VPN')
            .type(ButtonType.Normal)
            .height(48)
            .borderRadius(8)
            .width('100%')
            .backgroundColor('#2E7D32')
            .fontColor(Color.White)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .enabled(this.vpnFlowState !== 'noSubscription')
            .opacity(this.vpnFlowState === 'ready' || this.vpnFlowState === 'failed' ? 1 : 0.4)
            .onClick((): void => {
              if (this.onStartVpn !== undefined && this.vpnFlowState !== 'noSubscription') {
                this.onStartVpn();
              }
            })
        } else {
          Button('Stop VPN')
            .type(ButtonType.Normal)
            .height(48)
            .borderRadius(8)
            .width('100%')
            .backgroundColor('#C62828')
            .fontColor(Color.White)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .enabled(this.isPrimaryEnabled())
            .opacity(this.isPrimaryEnabled() ? 1 : 0.4)
            .onClick((): void => {
              if (this.onStopVpn !== undefined) {
                this.onStopVpn();
              }
            })
        }

        // Dashboard cards (only when active + connected)
        if (this.showDashboard()) {
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

        // Developer section toggle
        SectionHeader({
          title: 'Developer',
          action: this.devSectionExpanded ? 'Hide' : 'Show',
          onAction: (): void => {
            if (this.onToggleDevSection !== undefined) {
              this.onToggleDevSection();
            }
          }
        })

        // Developer section content
        if (this.devSectionExpanded) {
          Column({ space: 12 }) {
            if (this.lastError.length > 0) {
              ErrorBanner({ message: this.lastError })
            }

            if (this.connectionState === 'connecting') {
              LoadingRow({ message: 'Connecting to controller...' })
            }
            if (this.connectionState === 'refreshing') {
              LoadingRow({ message: 'Refreshing dashboard...' })
            }

            if (this.compact) {
              Column({ space: 8 }) {
                Button('Connect')
                  .type(ButtonType.Normal)
                  .height(40)
                  .borderRadius(8)
                  .width('100%')
                  .backgroundColor('#2268D8')
                  .fontColor(Color.White)
                  .fontSize(13)
                  .enabled(this.canConnect())
                  .opacity(this.canConnect() ? 1 : 0.4)
                  .onClick((): void => {
                    if (this.onConnect !== undefined) {
                      this.onConnect();
                    }
                  })

                Button('Refresh')
                  .type(ButtonType.Normal)
                  .height(40)
                  .borderRadius(8)
                  .width('100%')
                  .backgroundColor('#2268D8')
                  .fontColor(Color.White)
                  .fontSize(13)
                  .enabled(this.canRefresh())
                  .opacity(this.canRefresh() ? 1 : 0.4)
                  .onClick((): void => {
                    if (this.onRefresh !== undefined) {
                      this.onRefresh();
                    }
                  })

                Button('Disconnect')
                  .type(ButtonType.Normal)
                  .height(40)
                  .borderRadius(8)
                  .width('100%')
                  .backgroundColor('#C62828')
                  .fontColor(Color.White)
                  .fontSize(13)
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
                  .height(40)
                  .borderRadius(8)
                  .layoutWeight(1)
                  .backgroundColor('#2268D8')
                  .fontColor(Color.White)
                  .fontSize(13)
                  .enabled(this.canConnect())
                  .opacity(this.canConnect() ? 1 : 0.4)
                  .onClick((): void => {
                    if (this.onConnect !== undefined) {
                      this.onConnect();
                    }
                  })

                Button('Refresh')
                  .type(ButtonType.Normal)
                  .height(40)
                  .borderRadius(8)
                  .layoutWeight(1)
                  .backgroundColor('#2268D8')
                  .fontColor(Color.White)
                  .fontSize(13)
                  .enabled(this.canRefresh())
                  .opacity(this.canRefresh() ? 1 : 0.4)
                  .onClick((): void => {
                    if (this.onRefresh !== undefined) {
                      this.onRefresh();
                    }
                  })

                Button('Disconnect')
                  .type(ButtonType.Normal)
                  .height(40)
                  .borderRadius(8)
                  .layoutWeight(1)
                  .backgroundColor('#C62828')
                  .fontColor(Color.White)
                  .fontSize(13)
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

            Text('Controller: ' + this.statusLabel())
              .fontSize(12)
              .fontColor('#5C6470')
              .width('100%')
          }
          .width('100%')
        }
      }
      .width('100%')
    }
  }
}
