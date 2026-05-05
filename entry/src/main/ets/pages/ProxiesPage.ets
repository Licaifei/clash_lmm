import { BasePage } from '../components/BasePage';
import { StatusCard } from '../components/StatusCard';
import { EmptyState } from '../components/EmptyState';

@Component
export struct ProxiesPage {
  @Prop proxyGroupCount: number = 0;
  @Prop proxyCount: number = 0;
  @Prop compact: boolean = false;
  @Prop proxyGroups: string[] = [];

  build() {
    BasePage({ title: 'Proxies', compact: this.compact }) {
      Column({ space: 12 }) {
        if (this.proxyGroups.length === 0) {
          EmptyState({ message: 'No proxy groups loaded. Connect and refresh to load proxies.' })
        } else {
          if (this.compact) {
            Column({ space: 12 }) {
              StatusCard({
                title: 'Groups',
                value: `${this.proxyGroupCount}`,
                detail: 'Selectable proxy groups',
                compact: true
              })
              StatusCard({
                title: 'Nodes',
                value: `${this.proxyCount}`,
                detail: 'Leaf proxy nodes',
                compact: true
              })
            }
            .width('100%')
          } else {
            Row({ space: 16 }) {
              StatusCard({
                title: 'Groups',
                value: `${this.proxyGroupCount}`,
                detail: 'Selectable proxy groups'
              })
                .layoutWeight(1)
              StatusCard({
                title: 'Nodes',
                value: `${this.proxyCount}`,
                detail: 'Leaf proxy nodes'
              })
                .layoutWeight(1)
            }
          }

          List() {
            ForEach(this.proxyGroups, (name: string) => {
              ListItem() {
                Row() {
                  Text(name)
                    .fontSize(16)
                    .fontColor('#171A1F')
                  Blank()
                  Text('Select')
                    .fontSize(12)
                    .fontColor('#2268D8')
                }
                .height(48)
                .padding({ left: 16, right: 16 })
                .backgroundColor(Color.White)
                .borderRadius(8)
                .border({ width: 1, color: '#E5E8EF' })
              }
            }, (name: string) => name)
          }
          .width('100%')
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
    }
  }
}
