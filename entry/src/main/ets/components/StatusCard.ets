@Component
export struct StatusCard {
  title: string = '';
  value: string = '';
  detail: string = '';
  compact: boolean = false;

  build() {
    Column({ space: this.compact ? 6 : 8 }) {
      Text(this.title)
        .fontSize(this.compact ? 12 : 13)
        .fontColor('#5C6470')
        .maxLines(1)
      Text(this.value)
        .fontSize(this.compact ? 18 : 24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#171A1F')
        .maxLines(1)
      if (this.detail.length > 0) {
        Text(this.detail)
          .fontSize(this.compact ? 11 : 12)
          .fontColor('#7B8491')
          .maxLines(2)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .padding(this.compact ? 12 : 16)
    .borderRadius(8)
    .backgroundColor(Color.White)
    .border({ width: 1, color: '#E5E8EF' })
    .width('100%')
  }
}
