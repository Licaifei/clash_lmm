@Component
export struct EmptyState {
  message: string = '';

  build() {
    Column() {
      Text(this.message)
        .fontSize(14)
        .fontColor('#7B8491')
        .maxLines(3)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding(24)
    .alignItems(HorizontalAlign.Center)
  }
}
