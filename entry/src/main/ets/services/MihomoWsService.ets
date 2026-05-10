import { BusinessError } from '@kit.BasicServicesKit';
import { webSocket } from '@kit.NetworkKit';
import { ControllerConfig } from '../models/MihomoModels';

export type MihomoWsTopic = 'traffic' | 'connections' | 'logs' | 'memory';
export type MihomoWsMessageHandler = (message: string) => void;
export type MihomoWsErrorHandler = (message: string) => void;

export class MihomoWsSubscription {
  private ws?: webSocket.WebSocket;
  private closed: boolean = true;

  connect(
    config: ControllerConfig,
    topic: MihomoWsTopic,
    onMessage: MihomoWsMessageHandler,
    onError?: MihomoWsErrorHandler,
    logLevel: string = 'info'
  ): void {
    this.close();
    this.closed = false;
    this.ws = webSocket.createWebSocket();
    const endpoint = this.resolveEndpoint(topic, logLevel);
    const url = `${this.toWsBaseUrl(config.baseUrl)}${endpoint}`;
    const header: Record<string, string> = {};
    if (config.secret.length > 0) {
      header['Authorization'] = `Bearer ${config.secret}`;
    }

    this.ws.on('message', (err: BusinessError, value: string | ArrayBuffer) => {
      if (err) {
        onError?.(err.message);
        return;
      }
      if (typeof value === 'string') {
        onMessage(value);
      }
    });
    this.ws.on('error', (err: BusinessError) => {
      if (!this.closed) {
        onError?.(err.message);
      }
    });
    this.ws.on('close', (_err: BusinessError) => {
      this.closed = true;
    });
    this.ws.connect(url, { header }, (err: BusinessError) => {
      if (err) {
        this.closed = true;
        onError?.(err.message);
      }
    });
  }

  close(): void {
    if (!this.ws) {
      return;
    }
    this.closed = true;
    const socket = this.ws;
    this.ws = undefined;
    socket.off('message');
    socket.off('error');
    socket.off('close');
    socket.close((_err: BusinessError, _value: boolean) => {});
  }

  private resolveEndpoint(topic: MihomoWsTopic, logLevel: string): string {
    switch (topic) {
      case 'traffic':
        return '/traffic';
      case 'connections':
        return '/connections';
      case 'memory':
        return '/memory';
      case 'logs':
        return `/logs?level=${encodeURIComponent(logLevel)}`;
      default:
        return '/traffic';
    }
  }

  private toWsBaseUrl(baseUrl: string): string {
    const trimmed = baseUrl.replace(/\/$/, '');
    if (trimmed.startsWith('https://')) {
      return trimmed.replace('https://', 'wss://');
    }
    if (trimmed.startsWith('http://')) {
      return trimmed.replace('http://', 'ws://');
    }
    return `ws://${trimmed}`;
  }
}
