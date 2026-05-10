import { PlaceholderPage } from './PlaceholderPage';

@Component
export struct LogsPage {
  compact: boolean = false;

  build() {
    PlaceholderPage({ title: 'Logs', compact: this.compact })
  }
}
