import { BasePage } from '../components/BasePage';

@Component
export struct PlaceholderPage {
  title: string = '';
  compact: boolean = false;

  build() {
    BasePage({ title: this.title, compact: this.compact }) {
      Column({ space: 12 }) {
        Text(`${this.title} page scaffold`)
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
}
