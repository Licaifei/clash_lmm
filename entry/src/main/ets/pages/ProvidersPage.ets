import { PlaceholderPage } from './PlaceholderPage';

@Component
export struct ProvidersPage {
  compact: boolean = false;

  build() {
    PlaceholderPage({ title: 'Providers', compact: this.compact })
  }
}
