# Clash Verge HarmonyOS

Native ArkTS Mihomo controller UI for HarmonyOS.

## Project Structure

```
entry/src/main/ets/
  entryability/EntryAbility.ets     # App entry point
  pages/Index.ets                   # Main UI (navigation + pages)
  components/
    BasePage.ets                    # Page layout component
    StatusCard.ets                  # Status display card
  models/
    MihomoModels.ets                # TypeScript interfaces
  services/
    MihomoApiService.ets            # Mihomo HTTP API wrapper
    MihomoWsService.ets             # Mihomo WebSocket wrapper
    AppConfigStore.ets              # Preferences persistence

entry/src/test/                     # Unit tests (@ohos/hypium)
```

## Features (Roadmap)

- [x] Mihomo HTTP API wrapper (version, config, proxies, rules, connections, delay)
- [x] Mihomo WebSocket wrapper (traffic, connections, logs, memory streams)
- [x] App settings persistence (Preferences)
- [x] Controller settings (URL + secret)
- [x] Home dashboard (core version, mode, live traffic)
- [x] Proxies page (proxy groups, node list)
- [x] Settings page (controller configuration)
- [ ] Connections page
- [ ] Rules page
- [ ] Logs page
- [ ] Profiles management
- [ ] Provider management

## Architecture

This app operates in **external-controller mode**: it connects to an already-running Mihomo core over HTTP and WebSocket. It does NOT bundle or run Mihomo natively.

```
HarmonyOS App <--HTTP/WS--> Mihomo External Controller <--> Mihomo Core
```

## Development

- Uses **ArkTS / ArkUI** with **Stage model**
- Target devices: phone, tablet, 2in1
- Required permission: `ohos.permission.INTERNET`

## Migration

This project was migrated from `harmonyos/` subdirectory. See `harmonyos/README.md` for the original scaffold documentation.
