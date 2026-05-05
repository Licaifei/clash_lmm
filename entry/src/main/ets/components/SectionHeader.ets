@Component
export struct SectionHeader {
  title: string = '';
  action?: string;
  onAction?: () => void;

  build() {
    Row() {
      Text(this.title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#171A1F')
        .layoutWeight(1)
      if (this.action !== undefined && this.onAction !== undefined) {
        Text(this.action)
          .fontSize(12)
          .fontColor('#2268D8')
          .onClick(() => {
            if (this.onAction !== undefined) {
              this.onAction();
            }
          })
      }
    }
    .width('100%')
  }
}
