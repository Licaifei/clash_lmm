@Builder
function DefaultPageContent() {}

@Component
export struct BasePage {
  title: string = '';
  @BuilderParam content: () => void = DefaultPageContent;

  build() {
    Column() {
      Row() {
        Text(this.title)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#171A1F')
      }
      .height(56)
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding({ left: 24, right: 24 })

      Column() {
        this.content()
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 24, right: 24, bottom: 24 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA')
  }
}
