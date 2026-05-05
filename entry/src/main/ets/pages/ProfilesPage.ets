import { PlaceholderPage } from './PlaceholderPage';

@Component
export struct ProfilesPage {
  compact: boolean = false;

  build() {
    PlaceholderPage({ title: 'Profiles', compact: this.compact })
  }
}
