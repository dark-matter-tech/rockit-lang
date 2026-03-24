#!/usr/bin/env bash
# Rockit — Uninstall Script
# Dark Matter Tech
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/dark-matter-tech/rockit-lang/develop/scripts/uninstall.sh | bash

set -euo pipefail

PREFIX="${ROCKIT_PREFIX:-/usr/local}"
BIN_DIR="${PREFIX}/bin"
SHARE_DIR="${PREFIX}/share/rockit"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
RESET='\033[0m'

info()  { echo -e "${BOLD}==>${RESET} $1"; }
ok()    { echo -e "${GREEN}==>${RESET} $1"; }
warn()  { echo -e "${YELLOW}==>${RESET} $1"; }

echo ""
echo "  Rockit Uninstaller"
echo "  Dark Matter Tech"
echo ""

FOUND=false

if [ -f "${BIN_DIR}/rockit" ]; then
    FOUND=true
    info "Found rockit at ${BIN_DIR}/rockit"
fi
if [ -f "${BIN_DIR}/fuel" ]; then
    FOUND=true
    info "Found fuel at ${BIN_DIR}/fuel"
fi
if [ -d "${SHARE_DIR}" ]; then
    FOUND=true
    info "Found shared data at ${SHARE_DIR}"
fi

if [ "$FOUND" = false ]; then
    warn "Rockit does not appear to be installed at ${PREFIX}"
    echo ""
    exit 0
fi

echo ""
echo "  The following will be removed:"
[ -f "${BIN_DIR}/rockit" ] && echo "    ${BIN_DIR}/rockit"
[ -f "${BIN_DIR}/fuel" ]   && echo "    ${BIN_DIR}/fuel"
[ -d "${SHARE_DIR}" ]      && echo "    ${SHARE_DIR}/"
echo ""

read -p "  Continue? [y/N] " confirm
if [ "${confirm,,}" != "y" ]; then
    echo "  Cancelled."
    echo ""
    exit 0
fi

echo ""

if [ -f "${BIN_DIR}/rockit" ]; then
    sudo rm -f "${BIN_DIR}/rockit"
    ok "Removed ${BIN_DIR}/rockit"
fi

if [ -f "${BIN_DIR}/fuel" ]; then
    sudo rm -f "${BIN_DIR}/fuel"
    ok "Removed ${BIN_DIR}/fuel"
fi

if [ -d "${SHARE_DIR}" ]; then
    sudo rm -rf "${SHARE_DIR}"
    ok "Removed ${SHARE_DIR}"
fi

echo ""
ok "Rockit has been uninstalled."
echo ""
