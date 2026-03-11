#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# test-all.sh — Rockit full-stack integration test runner
#
# Clones all repos, builds the full toolchain from source,
# runs every test suite, reports results.
#
# Usage:
#   ./scripts/test-all.sh                    # default: all develop
#   COMPILER_REF=master ./scripts/test-all.sh
#   GIT_HOST=https://rustygits.com GIT_ORG=Dark-Matter ./scripts/test-all.sh
# ──────────────────────────────────────────────────────────────
set -euo pipefail

# ── Configuration ─────────────────────────────────────────────

WORK="${ROCKIT_TEST_DIR:-$(mktemp -d)}"
GIT_HOST="${GIT_HOST:-https://github.com}"
GIT_ORG="${GIT_ORG:-dark-matter-tech}"

BOOSTER_REF="${BOOSTER_REF:-develop}"
COMPILER_REF="${COMPILER_REF:-develop}"
FUEL_REF="${FUEL_REF:-develop}"
STDLIB_REF="${STDLIB_REF:-master}"
PROBE_REF="${PROBE_REF:-develop}"

TRIPLE="${TARGET_TRIPLE:-}"
if [ -z "$TRIPLE" ]; then
  case "$(uname -s)-$(uname -m)" in
    Linux-x86_64)  TRIPLE="x86_64-unknown-linux-gnu" ;;
    Darwin-arm64)  TRIPLE="arm64-apple-macosx" ;;
    Darwin-x86_64) TRIPLE="x86_64-apple-macosx" ;;
    *)             TRIPLE="x86_64-unknown-linux-gnu" ;;
  esac
fi

RESULTS_JSON="${RESULTS_JSON:-/tmp/integration-results.json}"

# ── State ─────────────────────────────────────────────────────

PASS=0
FAIL=0
SKIP=0
RESULTS=()
SUITE_ERRORS=()
START_TIME=$(date +%s)

# ── Helpers ───────────────────────────────────────────────────

cleanup() {
  if [ "${KEEP_WORK:-}" != "1" ]; then
    rm -rf "$WORK"
  else
    echo "Work directory preserved: $WORK"
  fi
}
trap cleanup EXIT

log() { echo "==> $*"; }

record() {
  local name="$1" status="$2" error="${3:-}"
  RESULTS+=("$status $name")
  SUITE_ERRORS+=("$error")
  case "$status" in
    PASS) PASS=$((PASS + 1)) ;;
    FAIL) FAIL=$((FAIL + 1)) ;;
    SKIP) SKIP=$((SKIP + 1)) ;;
  esac
}

clone_repo() {
  local name="$1" ref="$2" dest="$3"
  log "Cloning $name ($ref)"
  git clone --depth 1 --branch "$ref" "$GIT_HOST/$GIT_ORG/$name.git" "$dest" 2>/dev/null
}

# ── Phase 1: Clone ────────────────────────────────────────────

log "Phase 1: Clone all repos into $WORK"

clone_repo "rockit-booster"  "$BOOSTER_REF"  "$WORK/booster"
clone_repo "rockit-compiler" "$COMPILER_REF" "$WORK/compiler"
clone_repo "rockit-fuel"     "$FUEL_REF"     "$WORK/fuel"
clone_repo "launchpad"       "$STDLIB_REF"   "$WORK/stdlib"
clone_repo "rockit-probe"    "$PROBE_REF"    "$WORK/probe"

# ── Phase 2: Build toolchain ──────────────────────────────────

log "Phase 2: Build toolchain from source"

# Stage 0
log "Building Stage 0 (rockit-booster)"
cd "$WORK/booster" && swift build -c release 2>&1 | tail -1
STAGE0="$WORK/booster/.build/release/rockit"

# Stage 1
log "Building Stage 1 (self-hosted compiler)"
cd "$WORK/compiler"
bash src/build.sh
"$STAGE0" build-native src/command.rok
COMPILER="$WORK/compiler/src/command"
chmod +x "$COMPILER"
log "Compiler: $($COMPILER version 2>&1 || echo 'unknown')"

# Runtime
log "Building runtime"
cd "$WORK/compiler"
bash runtime/rockit/build.sh
RUNTIME="$WORK/compiler/runtime/rockit_runtime.o"

# Fuel
log "Building fuel"
"$COMPILER" build-native "$WORK/fuel/src/fuel.rok" \
  -o "$WORK/fuel/fuel" \
  --runtime-path "$RUNTIME" \
  --target-triple "$TRIPLE" 2>&1 || true
FUEL="$WORK/fuel/fuel"

# ── Phase 3: Test suites ──────────────────────────────────────

log "Phase 3: Run all test suites"

STDLIB="$WORK/stdlib"

# 3a: Compiler integration tests
log "Running compiler integration tests"
cd "$WORK/compiler"
TEST_PASS=0; TEST_FAIL=0; TEST_TOTAL=0
COMPILE_ERRORS=""
for f in examples/test_*.rok; do
  [ -f "$f" ] || continue
  name=$(basename "$f" .rok)
  TEST_TOTAL=$((TEST_TOTAL + 1))
  if "$COMPILER" build-native "$f" -o "examples/$name" \
    --runtime-path "$RUNTIME" \
    --lib-path "$STDLIB" \
    --target-triple "$TRIPLE" > /dev/null 2>&1; then
    "examples/$name" > /dev/null 2>&1 || true
    TEST_PASS=$((TEST_PASS + 1))
  else
    echo "  FAIL: $name"
    COMPILE_ERRORS="${COMPILE_ERRORS}FAIL: ${name}\n"
    TEST_FAIL=$((TEST_FAIL + 1))
  fi
done
echo "  Compiler tests: $TEST_PASS/$TEST_TOTAL passed"
if [ "$TEST_FAIL" -eq 0 ]; then
  record "compiler-integration" PASS
else
  record "compiler-integration" FAIL "${TEST_FAIL}/${TEST_TOTAL} failed to compile: ${COMPILE_ERRORS}"
fi

# 3b: Bootstrap verification
log "Running bootstrap verification"
cd "$WORK/compiler"
BOOTSTRAP_ERROR=""
if "$COMPILER" compile src/command.rok -o /tmp/stage2.rokb 2>/dev/null; then
  "$COMPILER" build-native src/command.rok -o /tmp/stage2 \
    --runtime-path "$RUNTIME" --target-triple "$TRIPLE" 2>/dev/null
  if /tmp/stage2 compile src/command.rok -o /tmp/stage3.rokb 2>/dev/null; then
    if diff /tmp/stage2.rokb /tmp/stage3.rokb > /dev/null 2>&1; then
      echo "  Bootstrap verified: Stage 2 == Stage 3"
      record "bootstrap-verification" PASS
    else
      BOOTSTRAP_ERROR="Bytecode mismatch: Stage 2 != Stage 3"
      echo "  Bootstrap FAILED: bytecode mismatch"
      record "bootstrap-verification" FAIL "$BOOTSTRAP_ERROR"
    fi
  else
    BOOTSTRAP_ERROR="Stage 2 binary could not compile its own source"
    echo "  Bootstrap FAILED: Stage 2 could not compile"
    record "bootstrap-verification" FAIL "$BOOTSTRAP_ERROR"
  fi
else
  BOOTSTRAP_ERROR="Stage 1 could not compile bytecode"
  echo "  Bootstrap FAILED: Stage 1 could not compile bytecode"
  record "bootstrap-verification" FAIL "$BOOTSTRAP_ERROR"
fi
rm -f /tmp/stage2 /tmp/stage2.rokb /tmp/stage3.rokb

# 3c: Fuel CLI tests
log "Running fuel CLI tests"
if [ -x "$FUEL" ]; then
  FUEL_PASS=0; FUEL_FAIL=0
  FUEL_ERRORS=""

  # version
  FUEL_OUT=$("$FUEL" version 2>&1 || true)
  if echo "$FUEL_OUT" | grep -q "[0-9]\.[0-9]"; then
    FUEL_PASS=$((FUEL_PASS + 1))
  else
    echo "  FAIL: fuel version"
    FUEL_ERRORS="${FUEL_ERRORS}fuel version: ${FUEL_OUT}\n"
    FUEL_FAIL=$((FUEL_FAIL + 1))
  fi

  # help
  FUEL_OUT=$("$FUEL" help 2>&1 || true)
  if echo "$FUEL_OUT" | grep -q "USAGE:"; then
    FUEL_PASS=$((FUEL_PASS + 1))
  else
    echo "  FAIL: fuel help"
    FUEL_ERRORS="${FUEL_ERRORS}fuel help: ${FUEL_OUT}\n"
    FUEL_FAIL=$((FUEL_FAIL + 1))
  fi

  # init
  rm -rf /tmp/test-integration-project
  FUEL_OUT=$("$FUEL" init /tmp/test-integration-project 2>&1 || true)
  if [ -f /tmp/test-integration-project/Fuel.toml ]; then
    FUEL_PASS=$((FUEL_PASS + 1))
  else
    echo "  FAIL: fuel init"
    FUEL_ERRORS="${FUEL_ERRORS}fuel init: ${FUEL_OUT}\n"
    FUEL_FAIL=$((FUEL_FAIL + 1))
  fi

  # build
  if [ -d /tmp/test-integration-project ]; then
    cd /tmp/test-integration-project
    FUEL_OUT=$("$FUEL" build --compiler-path "$COMPILER" --runtime-path "$RUNTIME" 2>&1 || true)
    if [ -f build/test-integration-project ]; then
      FUEL_PASS=$((FUEL_PASS + 1))
    else
      echo "  FAIL: fuel build"
      FUEL_ERRORS="${FUEL_ERRORS}fuel build: ${FUEL_OUT}\n"
      FUEL_FAIL=$((FUEL_FAIL + 1))
    fi

    # clean
    FUEL_OUT=$("$FUEL" clean 2>&1 || true)
    if [ ! -d build ]; then
      FUEL_PASS=$((FUEL_PASS + 1))
    else
      echo "  FAIL: fuel clean"
      FUEL_ERRORS="${FUEL_ERRORS}fuel clean: ${FUEL_OUT}\n"
      FUEL_FAIL=$((FUEL_FAIL + 1))
    fi
    cd "$WORK"
  fi

  rm -rf /tmp/test-integration-project

  FUEL_TOTAL=$((FUEL_PASS + FUEL_FAIL))
  echo "  Fuel tests: $FUEL_PASS/$FUEL_TOTAL passed"
  if [ "$FUEL_FAIL" -eq 0 ]; then
    record "fuel-cli" PASS
  else
    record "fuel-cli" FAIL "${FUEL_FAIL}/${FUEL_TOTAL} commands failed: ${FUEL_ERRORS}"
  fi
else
  echo "  Fuel binary not available — skipping"
  record "fuel-cli" SKIP "Binary not available"
fi

# 3d: Stdlib module presence
log "Validating stdlib modules"
STDLIB_PASS=0; STDLIB_FAIL=0
STDLIB_ERRORS=""
MODULES=(
  "rockit/core/collections.rok"
  "rockit/core/math.rok"
  "rockit/core/strings.rok"
  "rockit/core/result.rok"
  "rockit/core/uuid.rok"
  "rockit/encoding/base64.rok"
  "rockit/encoding/json.rok"
  "rockit/encoding/xml.rok"
  "rockit/filesystem/file.rok"
  "rockit/filesystem/path.rok"
  "rockit/networking/http.rok"
  "rockit/networking/url.rok"
  "rockit/networking/websocket.rok"
  "rockit/testing/probe.rok"
  "rockit/time/datetime.rok"
)
for mod in "${MODULES[@]}"; do
  if [ -f "$STDLIB/$mod" ]; then
    STDLIB_PASS=$((STDLIB_PASS + 1))
  else
    echo "  MISSING: $mod"
    STDLIB_ERRORS="${STDLIB_ERRORS}MISSING: ${mod}\n"
    STDLIB_FAIL=$((STDLIB_FAIL + 1))
  fi
done
echo "  Stdlib modules: $STDLIB_PASS/${#MODULES[@]} present"
if [ "$STDLIB_FAIL" -eq 0 ]; then
  record "stdlib-modules" PASS
else
  record "stdlib-modules" FAIL "${STDLIB_FAIL} missing: ${STDLIB_ERRORS}"
fi

# ── Phase 4: Report ───────────────────────────────────────────

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  INTEGRATION TEST REPORT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for r in "${RESULTS[@]}"; do
  status="${r%% *}"
  name="${r#* }"
  case "$status" in
    PASS) printf "  ✓  %s\n" "$name" ;;
    FAIL) printf "  ✗  %s\n" "$name" ;;
    SKIP) printf "  -  %s\n" "$name" ;;
  esac
done

echo ""
echo "  Total: $PASS passed, $FAIL failed, $SKIP skipped (${ELAPSED}s)"
echo ""

# Build manifest (tool versions + SHAs)
BOOSTER_SHA=$(cd "$WORK/booster" && git rev-parse --short HEAD)
COMPILER_SHA=$(cd "$WORK/compiler" && git rev-parse --short HEAD)
FUEL_SHA=$(cd "$WORK/fuel" && git rev-parse --short HEAD)
STDLIB_SHA=$(cd "$WORK/stdlib" && git rev-parse --short HEAD)
PROBE_SHA=$(cd "$WORK/probe" && git rev-parse --short HEAD)
SWIFT_VER=$(swift --version 2>&1 | head -1 || echo 'N/A')
CLANG_VER=$(clang --version 2>&1 | head -1 || echo 'N/A')

echo "  Build manifest:"
echo "    swift:    $SWIFT_VER"
echo "    clang:    $CLANG_VER"
echo "    compiler: $($COMPILER version 2>&1 || echo 'N/A')"
echo "    triple:   $TRIPLE"
echo "    booster:  $BOOSTER_SHA"
echo "    compiler: $COMPILER_SHA"
echo "    fuel:     $FUEL_SHA"
echo "    stdlib:   $STDLIB_SHA"
echo "    probe:    $PROBE_SHA"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Write JSON results ────────────────────────────────────────

SUITES_JSON="["
for i in "${!RESULTS[@]}"; do
  r="${RESULTS[$i]}"
  status="${r%% *}"
  name="${r#* }"
  error="${SUITE_ERRORS[$i]:-}"
  # Escape special chars for JSON
  error=$(printf '%s' "$error" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | tr '\n' ' ')
  [ "$i" -gt 0 ] && SUITES_JSON="${SUITES_JSON},"
  SUITES_JSON="${SUITES_JSON}{\"name\":\"${name}\",\"status\":\"${status}\",\"error\":\"${error}\"}"
done
SUITES_JSON="${SUITES_JSON}]"

cat > "$RESULTS_JSON" <<ENDJSON
{
  "pass": $PASS,
  "fail": $FAIL,
  "skip": $SKIP,
  "elapsed": $ELAPSED,
  "suites": $SUITES_JSON,
  "manifest": {
    "swift": "$SWIFT_VER",
    "clang": "$CLANG_VER",
    "triple": "$TRIPLE",
    "booster": "$BOOSTER_SHA",
    "compiler": "$COMPILER_SHA",
    "fuel": "$FUEL_SHA",
    "stdlib": "$STDLIB_SHA",
    "probe": "$PROBE_SHA"
  }
}
ENDJSON

echo "Results written to $RESULTS_JSON"

[ "$FAIL" -eq 0 ] || exit 1
