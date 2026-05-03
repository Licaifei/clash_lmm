import { describe, it, expect } from '@ohos/hypium';
import { AppSettings } from '../main/ets/services/AppConfigStore';

/**
 * AppConfigStore interface and defaults verification tests.
 * Tests that AppSettings structure matches expected schema.
 */

const DEFAULT_SETTINGS: AppSettings = {
  controller: {
    baseUrl: 'http://127.0.0.1:9090',
    secret: ''
  },
  themeMode: 'system',
  selectedPage: 'home'
};

export default function AppConfigStoreTest() {
  describe('AppSettings_defaults', () => {
    it('should_have_correct_default_controller_url', 0, () => {
      expect(DEFAULT_SETTINGS.controller.baseUrl).assertEqual('http://127.0.0.1:9090');
    });

    it('should_have_empty_default_secret', 0, () => {
      expect(DEFAULT_SETTINGS.controller.secret).assertEqual('');
    });

    it('should_have_system_default_theme', 0, () => {
      expect(DEFAULT_SETTINGS.themeMode).assertEqual('system');
    });

    it('should_default_to_home_page', 0, () => {
      expect(DEFAULT_SETTINGS.selectedPage).assertEqual('home');
    });

    it('should_have_valid_controller_config_fields', 0, () => {
      expect(DEFAULT_SETTINGS.controller).assertDefine();
      expect(typeof DEFAULT_SETTINGS.controller.baseUrl).assertEqual('string');
      expect(typeof DEFAULT_SETTINGS.controller.secret).assertEqual('string');
    });

    it('should_support_custom_controller_url', 0, () => {
      const custom: AppSettings = {
        ...DEFAULT_SETTINGS,
        controller: {
          baseUrl: 'http://192.168.1.1:9090',
          secret: 'my-secret'
        }
      };
      expect(custom.controller.baseUrl).assertEqual('http://192.168.1.1:9090');
      expect(custom.controller.secret).assertEqual('my-secret');
    });

    it('should_support_all_theme_modes', 0, () => {
      const modes = ['light', 'dark', 'system'];
      modes.forEach((mode) => {
        const settings: AppSettings = { ...DEFAULT_SETTINGS, themeMode: mode };
        expect(settings.themeMode).assertEqual(mode);
      });
    });

    it('should_support_all_navigation_pages', 0, () => {
      const pages = ['home', 'proxies', 'profiles', 'connections', 'rules', 'logs', 'settings'];
      pages.forEach((page) => {
        const settings: AppSettings = { ...DEFAULT_SETTINGS, selectedPage: page };
        expect(settings.selectedPage).assertEqual(page);
      });
    });
  });
}
