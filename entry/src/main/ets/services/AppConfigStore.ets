import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { ControllerConfig } from '../models/MihomoModels';

export interface AppSettings {
  controller: ControllerConfig;
  themeMode: string;
  selectedPage: string;
}

const DEFAULT_SETTINGS: AppSettings = {
  controller: {
    baseUrl: 'http://127.0.0.1:9090',
    secret: ''
  },
  themeMode: 'system',
  selectedPage: 'home'
};

export class AppConfigStore {
  private store: preferences.Preferences;

  constructor(context: common.UIAbilityContext) {
    this.store = preferences.getPreferencesSync(context, { name: 'mihomo_verge_settings' });
  }

  load(): AppSettings {
    return {
      controller: {
        baseUrl: this.readString('controller.baseUrl', DEFAULT_SETTINGS.controller.baseUrl),
        secret: this.readString('controller.secret', DEFAULT_SETTINGS.controller.secret)
      },
      themeMode: this.readString('themeMode', DEFAULT_SETTINGS.themeMode),
      selectedPage: this.readString('selectedPage', DEFAULT_SETTINGS.selectedPage)
    };
  }

  save(settings: AppSettings): void {
    try {
      this.store.putSync('controller.baseUrl', settings.controller.baseUrl);
      this.store.putSync('controller.secret', settings.controller.secret);
      this.store.putSync('themeMode', settings.themeMode);
      this.store.putSync('selectedPage', settings.selectedPage);
      this.store.flush();
    } catch (_err) {
      throw new Error('Failed to save app settings');
    }
  }

  private readString(key: string, fallback: string): string {
    try {
      const value = this.store.getSync(key, fallback);
      return typeof value === 'string' ? value : fallback;
    } catch (_err) {
      return fallback;
    }
  }
}
