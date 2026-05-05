import { BasePage } from '../components/BasePage';
import { ErrorBanner } from '../components/ErrorBanner';

@Component
export struct SettingsPage {
  @Prop controllerUrl: string = 'http://127.0.0.1:9090';
  @Prop controllerSecret: string = '';
  @Prop compact: boolean = false;
  onUrlChange?: (value: string) => void;
  onSecretChange?: (value: string) => void;
  onSave?: () => void;

  build() {
    BasePage({ title: 'Settings', compact: this.compact }) {
      Column({ space: 14 }) {
        Text('Controller URL')
          .fontSize(13)
          .fontColor('#5C6470')
          .width('100%')
        TextInput({ text: this.controllerUrl })
          .height(44)
          .width('100%')
          .onChange((value: string): void => {
            if (this.onUrlChange !== undefined) {
              this.onUrlChange(value);
            }
          })

        Text('Secret')
          .fontSize(13)
          .fontColor('#5C6470')
          .width('100%')
        TextInput({ text: this.controllerSecret })
          .height(44)
          .width('100%')
          .type(InputType.Password)
          .onChange((value: string): void => {
            if (this.onSecretChange !== undefined) {
              this.onSecretChange(value);
            }
          })

        Button('Save Settings')
          .type(ButtonType.Normal)
          .height(44)
          .borderRadius(8)
          .width(this.compact ? '100%' : 180)
          .backgroundColor('#2268D8')
          .fontColor(Color.White)
          .onClick((): void => {
            if (this.onSave !== undefined) {
              this.onSave();
            }
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
  }
}
