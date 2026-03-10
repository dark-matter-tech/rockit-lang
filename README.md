# Rockit

A statically-typed, compiled, memory-safe programming language.

Rockit is designed to replace JavaScript, HTML, CSS, and the DOM as the foundational technology of the web platform. Zero dependency on any external language ecosystem.

## Install

**macOS / Linux:**
```bash
curl -fsSL https://rustygits.com/Dark-Matter/rockit-lang/raw/branch/develop/scripts/install.sh | bash
```

**Windows (PowerShell):**
```powershell
iwr -useb https://rustygits.com/Dark-Matter/rockit-lang/raw/branch/develop/scripts/install.ps1 | iex
```

## Get Started

```bash
fuel init my-app
cd my-app
fuel build
fuel run
```

## What's in the Toolchain

| Component | Description |
|-----------|-------------|
| `rockit` | The Rockit compiler (self-hosted) |
| `fuel` | Package manager |
| `stdlib` | Standard library (22 modules) |
| `rockit_runtime.o` | Prebuilt runtime |

## Prebuilt Downloads

| Platform | Status |
|----------|--------|
| Linux x86_64 | Prebuilt |
| macOS arm64 | Prebuilt |
| macOS x86_64 | Prebuilt |
| Windows x86_64 | Prebuilt |

See [Releases](https://rustygits.com/Dark-Matter/rockit-lang/releases) for downloads.

## Standard Library

22 modules. Import with `import rockit.<domain>.<module>`.

| Module | Import | Standard |
|--------|--------|----------|
| Collections | `rockit.core.collections` | -- |
| Math | `rockit.core.math` | -- |
| Strings | `rockit.core.strings` | -- |
| Result | `rockit.core.result` | -- |
| UUID | `rockit.core.uuid` | RFC 9562 |
| Base64 | `rockit.encoding.base64` | RFC 4648 |
| HPACK | `rockit.encoding.hpack` | RFC 7541 |
| JSON | `rockit.encoding.json` | RFC 8259 |
| XML | `rockit.encoding.xml` | W3C XML 1.0 |
| File I/O | `rockit.filesystem.file` | -- |
| Path | `rockit.filesystem.path` | -- |
| HTTP | `rockit.networking.http` | RFC 9110 |
| HTTP/2 | `rockit.networking.http2` | RFC 9113 |
| URL | `rockit.networking.url` | RFC 3986 |
| WebSocket | `rockit.networking.websocket` | RFC 6455 |
| TLS | `rockit.security.tls` | RFC 8446 |
| Crypto | `rockit.security.crypto` | FIPS 180-4 |
| X.509 | `rockit.security.x509` | RFC 5280 |
| PEM | `rockit.security.pem` | RFC 7468 |
| Probe | `rockit.testing.probe` | -- |
| DateTime | `rockit.time.datetime` | ISO 8601 |

## Component Repos

| Repo | Description |
|------|-------------|
| [rockit-compiler](https://rustygits.com/Dark-Matter/rockit-compiler) | Stage 1 self-hosted compiler |
| [rockit-booster](https://rustygits.com/Dark-Matter/rockit-booster) | Stage 0 bootstrap compiler (Swift) |
| [fuel](https://rustygits.com/Dark-Matter/fuel) | Package manager |
| [launchpad](https://github.com/dark-matter-tech/launchpad) | Standard library |

## Uninstall

**macOS / Linux:**
```bash
curl -fsSL https://rustygits.com/Dark-Matter/rockit-lang/raw/branch/develop/scripts/uninstall.sh | bash
```

**Windows (PowerShell):**
```powershell
iwr -useb https://rustygits.com/Dark-Matter/rockit-lang/raw/branch/develop/scripts/uninstall.ps1 | iex
```

## License

Apache 2.0
