import { PlaceholderPage } from './PlaceholderPage';

@Component
export struct ConnectionsPage {
  compact: boolean = false;

  build() {
    PlaceholderPage({ title: 'Connections', compact: this.compact })
  }
}
