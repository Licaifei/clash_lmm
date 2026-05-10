@Component
export struct LoadingRow {
  message: string = '';

  build() {
    Row({ space: 8 }) {
      LoadingProgress()
        .width(16)
        .height(16)
      Text(this.message)
        .fontSize(13)
        .fontColor('#5C6470')
    }
    .width('100%')
    .padding(12)
  }
}
