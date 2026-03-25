# Rockit

A statically-typed, compiled, memory-safe programming language with Kotlin-like syntax, built for DO-178C DAL A certification readiness.

Rockit is designed to replace JavaScript, HTML, CSS, and the DOM as the foundational technology of the web platform. Zero dependency on any external language ecosystem. The compiler is fully self-hosted — Rockit compiles itself.

## Install

**macOS / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/dark-matter-tech/rockit-lang/develop/scripts/install.sh | bash
```

**Windows (PowerShell):**
```powershell
iwr -useb https://raw.githubusercontent.com/dark-matter-tech/rockit-lang/develop/scripts/install.ps1 | iex
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

See [Releases](https://github.com/dark-matter-tech/rockit-lang/releases) for downloads.

## DO-178C Safety Certification

Rockit is designed from the ground up for safety-critical software development. The compiler, runtime, and toolchain support DO-178C Design Assurance Level A (DAL A) — the highest level of safety assurance required for catastrophic failure conditions in avionics and aerospace systems.

### Safety Verification

The compiler includes a built-in safety verifier that enforces DAL A through DAL E constraints:

```bash
rockit build-native app.rok --safety dal-a
rockit build-native app.rok --safety dal-a --audit report.json
```

### What DAL A Enforces

| Violation | Objective | Rationale |
|-----------|-----------|-----------|
| Unbounded recursion | DO-178C 6.3.4f | Prevents stack overflow; unbounded depth makes WCET analysis impossible |
| Dynamic allocation | DO-178C 6.3.4b | Each malloc has variable cost; ARC retain/release overhead scales with object graph depth |
| Closures | DO-178C 6.3.4c | Hidden state capture introduces unpredictable ARC overhead and potential reference cycles |
| Exception handling | DO-178C 6.3.4d | Exception unwinding introduces non-deterministic control flow |
| Unbounded loops | DO-178C 6.3.4f | Unbounded iteration prevents WCET analysis |
| Dynamic strings | DO-178C 6.3.4b | String concatenation triggers hidden allocation |
| Async/await | DO-178C 6.3.4f | Non-deterministic scheduling where execution order depends on runtime task queue |
| Heap construction | DO-178C 6.3.4b | Class construction allocates on heap with per-object ARC overhead |

### DAL A-Ready Runtime

The Rockit runtime is written in Rockit itself using freestanding mode (`--no-runtime`) and designed for DO-178C DAL A:

- **Budget-tracked allocation** — hard memory limit enforced at runtime with deterministic panic on violation
- **Iterative ARC release** — work queue replaces recursive release chains (bounded by `RELEASE_QUEUE_CAP`)
- **Bounded hash map probing** — all linear probe loops capped at `MAP_MAX_PROBE` iterations
- **Fuel-bounded event loop** — cooperative scheduler limited to `EVENT_LOOP_MAX_TICKS`
- **Error code propagation** — deterministic error handling (replaces longjmp for DAL A builds)
- **LLVM debug metadata** — `DICompileUnit`, `DISubprogram`, `DILocation` with `!dbg` annotations for source-to-object traceability

### Audit Trail (DO-330)

The `--audit` flag generates a JSON report containing phase artifacts, timing, diagnostic counts, and safety verification results:

```json
{
  "compilerVersion": "0.1.0-alpha",
  "safetyLevel": "dal-a",
  "phases": [
    {"phase": "Lexer", "durationSeconds": 0.001, "diagnosticCount": 0},
    {"phase": "Parser", "durationSeconds": 0.003, "diagnosticCount": 0},
    {"phase": "SafetyVerification", "durationSeconds": 0.002, "diagnosticCount": 0}
  ]
}
```

### Freestanding Mode

For systems programming and safety-critical applications, Rockit supports `--no-runtime` freestanding compilation with `Ptr<T>`, `alloc`/`free`, `bitcast`, `unsafe` blocks, `loadByte`/`storeByte`, `extern` C functions, and `@CRepr` structs.

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
| [rockit-compiler](https://github.com/dark-matter-tech/rockit-compiler) | Stage 1 self-hosted compiler |
| [rockit-booster](https://github.com/dark-matter-tech/rockit-booster) | Stage 0 bootstrap compiler (Swift) |
| [rockit-fuel](https://github.com/dark-matter-tech/rockit-fuel) | Package manager |
| [launchpad](https://github.com/dark-matter-tech/launchpad) | Standard library |
| [rockit-runtime](https://github.com/dark-matter-tech/rockit-runtime) | Runtime (C + Rockit) |
| [rockit-probe](https://github.com/dark-matter-tech/rockit-probe) | Test framework |
| [rockit-lsp](https://github.com/dark-matter-tech/rockit-lsp) | Language server |

## Uninstall

**macOS / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/dark-matter-tech/rockit-lang/develop/scripts/uninstall.sh | bash
```

**Windows (PowerShell):**
```powershell
iwr -useb https://raw.githubusercontent.com/dark-matter-tech/rockit-lang/develop/scripts/uninstall.ps1 | iex
```

## License

Apache 2.0

# v0.3.1



