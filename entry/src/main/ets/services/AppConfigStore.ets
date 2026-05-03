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
        baseUrl: this.store.getSync('controller.baseUrl', DEFAULT_SETTINGS.controller.baseUrl) as string,
        secret: this.store.getSync('controller.secret', DEFAULT_SETTINGS.controller.secret) as string
      },
      themeMode: this.store.getSync('themeMode', DEFAULT_SETTINGS.themeMode) as string,
      selectedPage: this.store.getSync('selectedPage', DEFAULT_SETTINGS.selectedPage) as string
    };
  }

  save(settings: AppSettings): void {
    this.store.putSync('controller.baseUrl', settings.controller.baseUrl);
    this.store.putSync('controller.secret', settings.controller.secret);
    this.store.putSync('themeMode', settings.themeMode);
    this.store.putSync('selectedPage', settings.selectedPage);
    this.store.flush();
  }
}
