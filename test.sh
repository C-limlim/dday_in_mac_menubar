#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHECK_DIR="$(mktemp -d)"
trap 'rm -rf "$CHECK_DIR"' EXIT

swiftc -module-cache-path "$SCRIPT_DIR/DdayApp/.build/module-cache" \
  "$SCRIPT_DIR/DdayApp/Sources/DdayApp/DdayModel.swift" \
  "$SCRIPT_DIR/DdayApp/Sources/DdayApp/DdayDragHandle.swift" \
  "$SCRIPT_DIR/DdayApp/Tests/DdayModelSelfCheck/main.swift" \
  -o "$CHECK_DIR/dday-model-check"
"$CHECK_DIR/dday-model-check"
