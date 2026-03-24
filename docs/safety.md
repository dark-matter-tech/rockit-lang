# DO-178C Safety Certification

Rockit is designed for safety-critical software development. The compiler and runtime support DO-178C Design Assurance Levels A through E.

## Safety Verification

```bash
rockit build-native app.rok --safety dal-a
rockit build-native app.rok --safety dal-a --audit report.json
```

## Design Assurance Levels

### DAL A (Catastrophic)

Most restrictive. The compiler blocks:

| Violation | Rationale |
|-----------|-----------|
| Unbounded recursion | Stack overflow; WCET analysis impossible |
| Dynamic allocation | Variable-cost malloc; ARC overhead scales with object graph |
| Closures/lambdas | Hidden state capture; unpredictable ARC and reference cycles |
| Exception handling | Non-deterministic control flow via stack unwinding |
| Unbounded loops | Prevents WCET analysis |
| Dynamic string operations | Hidden allocation per concat/substring |
| Async/await | Non-deterministic scheduling |
| Heap object construction | Per-object ARC overhead and fragmentation |

### DAL B (Hazardous)
Allows bounded dynamic allocation and non-capturing closures. Blocks recursion, exceptions, async.

### DAL C (Major)
Allows exceptions and lambdas. Blocks unbounded recursion and loops.

### DAL D (Minor)
Allows async/await. Blocks unbounded recursion and loops.

### DAL E (No Effect)
No restrictions.

## DAL A-Ready Runtime

The Rockit runtime is written in Rockit using freestanding mode and designed for DAL A:

- **Budget-tracked allocation** — hard memory limit, deterministic panic on violation
- **Iterative ARC release** — work queue replaces recursive release chains
- **Bounded hash map probing** — all probe loops capped at MAX_PROBE iterations
- **Fuel-bounded event loop** — scheduler limited to MAX_TICKS
- **Error code propagation** — deterministic error handling for DAL A builds

## Audit Trail (DO-330)

The `--audit` flag generates a JSON report:

```bash
rockit build-native app.rok --safety dal-a --audit report.json
```

```json
{
  "compilerVersion": "0.1.0-alpha",
  "safetyLevel": "dal-a",
  "phases": [
    {"phase": "Lexer", "durationSeconds": 0.001, "diagnosticCount": 0},
    {"phase": "SafetyVerification", "durationSeconds": 0.002, "diagnosticCount": 0}
  ]
}
```

## LLVM Debug Metadata

The compiler emits full DO-178C traceability metadata:
- `DICompileUnit` — compilation unit info
- `DISubprogram` — function-level source mapping
- `DILocation` — line/column `!dbg` annotations on every instruction
- Source-to-object traceability for certification evidence

## Freestanding Mode

For systems programming without the standard runtime:

```bash
rockit build-native app.rok --no-runtime
```

Available primitives: `Ptr<T>`, `alloc`/`free`, `bitcast`, `unsafe` blocks, `loadByte`/`storeByte`, `extern` C functions, `@CRepr` structs.
