@Component
export struct StatusCard {
  title: string = '';
  value: string = '';
  detail: string = '';

  build() {
    Column({ space: 8 }) {
      Text(this.title)
        .fontSize(13)
        .fontColor('#5C6470')
      Text(this.value)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#171A1F')
      if (this.detail.length > 0) {
        Text(this.detail)
          .fontSize(12)
          .fontColor('#7B8491')
          .maxLines(2)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .padding(16)
    .borderRadius(8)
    .backgroundColor(Color.White)
    .border({ width: 1, color: '#E5E8EF' })
    .width('100%')
  }
}
