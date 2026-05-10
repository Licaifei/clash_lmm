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

## Test Files

```
entry/src/test/
  MihomoModels.test.ets           # Interface structure tests
  MihomoApiService.test.ets        # calcuProxies logic tests
  AppConfigStore.test.ets          # Settings interface tests
  ComponentsImport.test.ets        # Component import verification
```

Run tests with: `hvigor test` (device/emulator required)

## Commit History

1. `feat(models)`: Mihomo data models + tests
2. `feat(api)`: Mihomo HTTP API service + calcuProxies tests
3. `feat(ws)`: Mihomo WebSocket service
4. `feat(config)`: AppConfigStore persistence + tests
5. `feat(ui)`: BasePage + StatusCard components + tests
6. `feat(ui)`: Index page with full Mihomo Verge UI
7. `feat(config)`: INTERNET permission + app metadata
8. `docs`: README update
