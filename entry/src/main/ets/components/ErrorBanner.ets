@Component
export struct ErrorBanner {
  message: string = '';
  onDismiss?: () => void;

  build() {
    Row() {
      Text(this.message)
        .fontSize(13)
        .fontColor('#C62828')
        .layoutWeight(1)
        .maxLines(3)
      if (this.onDismiss !== undefined) {
        Text('✕')
          .fontSize(14)
          .fontColor('#C62828')
          .margin({ left: 8 })
          .onClick(() => {
            if (this.onDismiss !== undefined) {
              this.onDismiss();
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
}
