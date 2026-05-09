import { SubscriptionStore } from '../services/SubscriptionStore';
import { common } from '@kit.AbilityKit';
import { MihomoConfigService } from '../services/MihomoConfigService';
import { SubscriptionProfile } from '../models/MihomoModels';
import { AppConfigStore, AppSettings } from '../services/AppConfigStore';
import { BasePage } from '../components/BasePage';
import { SectionHeader } from '../components/SectionHeader';
import { EmptyState } from '../components/EmptyState';
import { ErrorBanner } from '../components/ErrorBanner';

@Component
export struct SubscriptionPage {
  store?: SubscriptionStore;
  configService?: MihomoConfigService;
  @Prop compact: boolean = false;
  onConfigGenerated?: (url: string, secret: string) => void;

  @State private profiles: SubscriptionProfile[] = [];
  @State private activeId: string = '';
  @State private addUrl: string = '';
  @State private addName: string = '';
  @State private error: string = '';
  @State private loading: boolean = false;
  @State private adding: boolean = false;
  @State private generating: boolean = false;
  @State private genResult: string = '';

  aboutToAppear(): void {
    this.refreshList();
  }

  private refreshList(): void {
    if (this.store === undefined) {
      return;
    }
    const state = this.store.loadState();
    this.profiles = state.subscriptions;
    this.activeId = state.activeId;
  }

  private validateUrl(value: string): string {
    const trimmed = value.trim();
    if (trimmed.length === 0) {
      return 'URL is required';
    }
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return 'URL must start with http:// or https://';
    }
    return '';
  }

  private async handleAdd(): Promise<void> {
    if (this.store === undefined) {
      return;
    }
    const urlError = this.validateUrl(this.addUrl);
    if (urlError.length > 0) {
      this.error = urlError;
      return;
    }
    const url = this.addUrl.trim();
    const name = this.addName.trim().length > 0 ? this.addName.trim() : url;
    this.adding = true;
    this.error = '';
    try {
      await this.store.addSubscription(url, name);
      this.addUrl = '';
      this.addName = '';
      this.refreshList();
    } catch (err) {
      this.error = this.formatError(err);
    }
    this.adding = false;
  }

  private async handleUpdate(id: string): Promise<void> {
    if (this.store === undefined) {
      return;
    }
    this.loading = true;
    this.error = '';
    try {
      await this.store.updateSubscription(id);
      this.refreshList();
    } catch (err) {
      this.error = this.formatError(err);
    }
    this.loading = false;
  }

  private handleDelete(id: string): void {
    if (this.store === undefined) {
      return;
    }
    this.store.deleteSubscription(id);
    this.refreshList();
    this.error = '';
  }

  private handleSelect(id: string): void {
    if (this.store === undefined) {
      return;
    }
    try {
      this.store.selectSubscription(id);
      this.activeId = id;
      this.error = '';
    } catch (err) {
      this.error = this.formatError(err);
    }
  }

  private handleGenerate(): void {
    if (this.store === undefined || this.configService === undefined) {
      return;
    }
    this.generating = true;
    this.error = '';
    this.genResult = '';
    try {
      const ctx = this.getAppContext();
      if (ctx === undefined) {
        this.error = 'Failed to get application context';
        this.generating = false;
        return;
      }
      const configStore = new AppConfigStore(ctx);
      const config = this.configService.generate(this.store, configStore);
      this.genResult = 'Config generated: ' + config.path;
      if (this.onConfigGenerated !== undefined) {
        this.onConfigGenerated(config.controllerUrl, config.controllerSecret);
      }
    } catch (err) {
      this.error = this.formatError(err);
    }
    this.generating = false;
  }

  private getAppContext(): common.UIAbilityContext | undefined {
    const ctx = this.getUIContext().getHostContext();
    if (ctx === undefined) {
      return undefined;
    }
    return ctx as common.UIAbilityContext;
  }

  private formatError(err: Object): string {
    if (err instanceof Error) {
      return err.message;
    }
    return '' + err;
  }

  build() {
    BasePage({ title: 'Subscriptions', compact: this.compact }) {
      Column({ space: 12 }) {
        if (this.error.length > 0) {
          ErrorBanner({ message: this.error })
        }

        SectionHeader({ title: 'Add Subscription' })

        Text('Subscription URL')
          .fontSize(13)
          .fontColor('#5C6470')
          .width('100%')
        TextInput({ text: this.addUrl, placeholder: 'https://example.com/sub' })
          .height(40)
          .width('100%')
          .fontSize(14)
          .onChange((value: string): void => {
            this.addUrl = value;
          })

        Text('Name (optional)')
          .fontSize(13)
          .fontColor('#5C6470')
          .width('100%')
        TextInput({ text: this.addName, placeholder: 'My Subscription' })
          .height(40)
          .width('100%')
          .fontSize(14)
          .onChange((value: string): void => {
            this.addName = value;
          })

        Button('Add Subscription')
          .type(ButtonType.Normal)
          .height(40)
          .borderRadius(8)
          .width(this.compact ? '100%' : 200)
          .backgroundColor('#2268D8')
          .fontColor(Color.White)
          .enabled(!this.adding)
          .onClick((): void => {
            this.handleAdd();
          })

        if (this.adding) {
          Text('Fetching subscription...')
            .fontSize(12)
            .fontColor('#5C6470')
        }

        SectionHeader({ title: 'Config Generation' })

        Button('Generate Config')
          .type(ButtonType.Normal)
          .height(40)
          .borderRadius(8)
          .width(this.compact ? '100%' : 200)
          .backgroundColor('#2E7D32')
          .fontColor(Color.White)
          .enabled(!this.generating)
          .onClick((): void => {
            this.handleGenerate();
          })

        if (this.generating) {
          Text('Generating config...')
            .fontSize(12)
            .fontColor('#5C6470')
        }
        if (this.genResult.length > 0) {
          Text(this.genResult)
            .fontSize(12)
            .fontColor('#2E7D32')
        }

        SectionHeader({ title: 'Saved (' + this.profiles.length + ')' })

        if (this.profiles.length === 0) {
          EmptyState({ message: 'No subscriptions. Add a subscription URL above.' })
        } else {
          List() {
            ForEach(this.profiles, (profile: SubscriptionProfile) => {
              ListItem() {
                Column({ space: 6 }) {
                  Row() {
                    Text(profile.name)
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#171A1F')
                      .layoutWeight(1)
                      .maxLines(1)
                    if (profile.id === this.activeId) {
                      Text('Active')
                        .fontSize(10)
                        .fontColor('#2E7D32')
                        .backgroundColor('#E8F5E9')
                        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                        .borderRadius(4)
                    }
                  }
                  .width('100%')

                  Row({ space: 8 }) {
                    Text(profile.detectedFormat)
                      .fontSize(11)
                      .fontColor('#7B8491')
                    Text('·')
                      .fontSize(11)
                      .fontColor('#A0A7B0')
                    Text(this.formatSize(profile.byteSize))
                      .fontSize(11)
                      .fontColor('#7B8491')
                    Text('·')
                      .fontSize(11)
                      .fontColor('#A0A7B0')
                    Text(profile.lastUpdated.substring(0, 10))
                      .fontSize(11)
                      .fontColor('#7B8491')
                  }

                  Row({ space: 6 }) {
                    if (profile.id !== this.activeId) {
                      Button('Select')
                        .type(ButtonType.Normal)
                        .height(26)
                        .fontSize(10)
                        .borderRadius(4)
                        .padding({ left: 8, right: 8 })
                        .backgroundColor('#E8F0FE')
                        .fontColor('#2268D8')
                        .onClick((): void => {
                          this.handleSelect(profile.id);
                        })
                    }
                    Button('Update')
                      .type(ButtonType.Normal)
                      .height(26)
                      .fontSize(10)
                      .borderRadius(4)
                      .padding({ left: 8, right: 8 })
                      .backgroundColor('#EEF1F6')
                      .fontColor('#313842')
                      .enabled(!this.loading)
                      .onClick((): void => {
                        this.handleUpdate(profile.id);
                      })
                    Button('Delete')
                      .type(ButtonType.Normal)
                      .height(26)
                      .fontSize(10)
                      .borderRadius(4)
                      .padding({ left: 8, right: 8 })
                      .backgroundColor('#FFEBEE')
                      .fontColor('#C62828')
                      .onClick((): void => {
                        this.handleDelete(profile.id);
                      })
                  }
                }
                .padding(12)
                .backgroundColor(Color.White)
                .borderRadius(8)
                .border({ width: 1, color: '#E5E8EF' })
              }
              .margin({ bottom: 6 })
            }, (profile: SubscriptionProfile) => profile.id)
          }
          .width('100%')
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
    }
  }

  private formatSize(bytes: number): string {
    if (bytes < 1024) {
      return bytes + ' B';
    }
    if (bytes < 1024 * 1024) {
      return (bytes / 1024).toFixed(1) + ' KB';
    }
    return (bytes / 1024 / 1024).toFixed(1) + ' MB';
  }
}
