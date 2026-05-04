@Builder
function DefaultPageContent() {}

@Component
export struct BasePage {
  title: string = '';
  compact: boolean = false;
  @BuilderParam content: () => void = DefaultPageContent;

  build() {
    Column() {
      Row() {
        Text(this.title)
          .fontSize(this.compact ? 20 : 22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#171A1F')
          .maxLines(1)
      }
      .height(this.compact ? 52 : 56)
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding({ left: this.compact ? 16 : 24, right: this.compact ? 16 : 24 })

      Column() {
        this.content()
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: this.compact ? 16 : 24, right: this.compact ? 16 : 24, bottom: 24 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA')
  }
}
