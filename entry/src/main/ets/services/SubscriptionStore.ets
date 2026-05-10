import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import fileIo from '@ohos.file.fs';
import { http } from '@kit.NetworkKit';
import { SubscriptionProfile, SubscriptionState } from '../models/MihomoModels';

const STORE_NAME = 'mihomo_subscriptions';
const KEY_PROFILES = 'subscription.profiles';
const KEY_ACTIVE_ID = 'subscription.activeId';

const UA_SUBSCRIPTION = 'clash-verge/1.0';
const ACCEPT_YAML = 'application/x-yaml, text/yaml, text/plain';

export class SubscriptionStore {
  private store: preferences.Preferences;
  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
    this.store = preferences.getPreferencesSync(context, { name: STORE_NAME });
  }

  loadState(): SubscriptionState {
    let raw = '[]';
    let activeId = '';
    try {
      raw = this.store.getSync(KEY_PROFILES, '[]') as string;
      activeId = this.store.getSync(KEY_ACTIVE_ID, '') as string;
    } catch (_err) {
      return { subscriptions: [], activeId: '' };
    }
    let profiles: SubscriptionProfile[];
    try {
      const parsed = JSON.parse(raw) as Object;
      if (Array.isArray(parsed)) {
        profiles = parsed as SubscriptionProfile[];
      } else {
        profiles = [];
      }
    } catch (_err) {
      profiles = [];
    }
    profiles = profiles.filter((p) => this.isValidProfile(p));
    if (activeId.length > 0) {
      let found = false;
      for (let i = 0; i < profiles.length; i++) {
        if (profiles[i].id === activeId) {
          found = true;
          break;
        }
      }
      if (!found) {
        activeId = '';
      }
    }
    return { subscriptions: profiles, activeId: activeId };
  }

  private isValidProfile(p: SubscriptionProfile): boolean {
    if (p === null || p === undefined) {
      return false;
    }
    if (typeof p.id !== 'string' || p.id.length === 0) {
      return false;
    }
    if (typeof p.name !== 'string' || typeof p.sourceUrl !== 'string' ||
      typeof p.lastUpdated !== 'string' || typeof p.detectedFormat !== 'string') {
      return false;
    }
    if (typeof p.byteSize !== 'number') {
      return false;
    }
    return true;
  }

  getActive(): SubscriptionProfile | null {
    const state = this.loadState();
    if (state.activeId.length === 0) {
      return null;
    }
    for (let i = 0; i < state.subscriptions.length; i++) {
      if (state.subscriptions[i].id === state.activeId) {
        return state.subscriptions[i];
      }
    }
    return null;
  }

  private validateUrl(url: string): string {
    const trimmed = url.trim();
    if (trimmed.length === 0) {
      throw new Error('URL is required');
    }
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      throw new Error('URL must start with http:// or https://');
    }
    return trimmed;
  }

  async addSubscription(url: string, name: string): Promise<SubscriptionProfile> {
    const validUrl = this.validateUrl(url);
    const content = await this.fetchSubscription(validUrl);
    const format = this.detectFormat(content);
    if (format === 'unsupported') {
      throw new Error('Unsupported subscription format');
    }
    const id = this.newId();
    const profile: SubscriptionProfile = {
      id: id,
      name: name,
      sourceUrl: validUrl,
      lastUpdated: new Date().toISOString(),
      byteSize: content.length,
      contentHash: '',
      detectedFormat: format,
      userInfo: '',
      note: ''
    };
    this.writeContent(id, content);
    const state = this.loadState();
    state.subscriptions.push(profile);
    this.saveState(state);
    return profile;
  }

  async updateSubscription(id: string): Promise<SubscriptionProfile> {
    const preState = this.loadState();
    const preIdx = this.findIndex(preState, id);
    if (preIdx < 0) {
      throw new Error('Subscription not found');
    }
    const storedUrl = preState.subscriptions[preIdx].sourceUrl;
    const validUrl = this.validateUrl(storedUrl);
    const content = await this.fetchSubscription(validUrl);
    const format = this.detectFormat(content);
    if (format === 'unsupported') {
      throw new Error('Unsupported subscription format');
    }
    const state = this.loadState();
    const idx = this.findIndex(state, id);
    if (idx < 0) {
      throw new Error('Subscription was deleted');
    }
    const profile = state.subscriptions[idx];
    this.writeContent(id, content);
    profile.lastUpdated = new Date().toISOString();
    profile.byteSize = content.length;
    profile.detectedFormat = format;
    this.saveState(state);
    return profile;
  }

  deleteSubscription(id: string): void {
    const state = this.loadState();
    state.subscriptions = state.subscriptions.filter((p) => p.id !== id);
    if (state.activeId === id) {
      state.activeId = state.subscriptions.length > 0 ? state.subscriptions[0].id : '';
    }
    this.deleteContent(id);
    this.saveState(state);
  }

  selectSubscription(id: string): void {
    const state = this.loadState();
    const idx = this.findIndex(state, id);
    if (idx < 0) {
      throw new Error('Subscription not found');
    }
    state.activeId = id;
    this.saveState(state);
  }

  loadContent(id: string): string {
    const path = this.contentPath(id);
    try {
      return fileIo.readTextSync(path);
    } catch (_err) {
      return '';
    }
  }

  private contentPath(id: string): string {
    const dir = this.context.filesDir + '/subscriptions';
    try {
      fileIo.mkdirSync(dir, true);
    } catch (_err) {
      throw new Error('Failed to prepare subscription storage');
    }
    return dir + '/' + id + '.yaml';
  }

  private writeContent(id: string, content: string): void {
    const path = this.contentPath(id);
    let fd = -1;
    try {
      const f = fileIo.openSync(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC | fileIo.OpenMode.WRITE_ONLY);
      fd = f.fd;
      fileIo.writeSync(fd, content);
    } catch (_err) {
      throw new Error('Failed to write subscription content');
    } finally {
      if (fd >= 0) {
        try {
          fileIo.closeSync(fd);
        } catch (_err) {
        }
      }
    }
  }

  private deleteContent(id: string): void {
    const path = this.contentPath(id);
    try {
      fileIo.unlinkSync(path);
    } catch (_err) {
      // File may not exist, ignore
    }
  }

  private async fetchSubscription(url: string): Promise<string> {
    const req = http.createHttp();
    try {
      const response = await req.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        readTimeout: 30000,
        connectTimeout: 10000,
        header: {
          'User-Agent': UA_SUBSCRIPTION,
          'Accept': ACCEPT_YAML
        }
      });
      const status = response.responseCode;
      if (status < 200 || status >= 300) {
        throw new Error('HTTP ' + status);
      }
      return response.result as string;
    } catch (err) {
      if (err instanceof Error && err.message.startsWith('HTTP ')) {
        throw err;
      }
      throw new Error('Failed to fetch subscription');
    } finally {
      req.destroy();
    }
  }

  private detectFormat(content: string): string {
    const trimmed = content.trim();
    if (trimmed.length === 0) {
      return 'unsupported';
    }
    if (trimmed.startsWith('proxies:') || trimmed.startsWith('proxy-groups:') ||
      trimmed.startsWith('rules:') || trimmed.includes('proxy:')) {
      return 'clash-yaml';
    }
    if (trimmed.startsWith('mixed-port:') || trimmed.startsWith('port:') ||
      trimmed.startsWith('socks-port:') || trimmed.startsWith('allow-lan:')) {
      return 'clash-yaml';
    }
    if (trimmed.startsWith('ss://') || trimmed.startsWith('vmess://') ||
      trimmed.startsWith('trojan://') || trimmed.startsWith('vless://')) {
      return 'unsupported';
    }
    return 'unsupported';
  }

  private saveState(state: SubscriptionState): void {
    try {
      this.store.putSync(KEY_PROFILES, JSON.stringify(state.subscriptions));
      this.store.putSync(KEY_ACTIVE_ID, state.activeId);
      this.store.flush();
    } catch (_err) {
      throw new Error('Failed to save subscription metadata');
    }
  }

  private newId(): string {
    return Date.now().toString(36) + Math.random().toString(36).substring(2, 8);
  }

  private findIndex(state: SubscriptionState, id: string): number {
    for (let i = 0; i < state.subscriptions.length; i++) {
      if (state.subscriptions[i].id === id) {
        return i;
      }
    }
    return -1;
  }
}
