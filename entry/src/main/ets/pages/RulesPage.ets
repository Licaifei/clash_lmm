import { PlaceholderPage } from './PlaceholderPage';

@Component
export struct RulesPage {
  compact: boolean = false;

  build() {
    PlaceholderPage({ title: 'Rules', compact: this.compact })
  }
}
