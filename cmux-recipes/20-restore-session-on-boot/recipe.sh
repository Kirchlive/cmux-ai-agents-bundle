#!/bin/bash
# Add to ~/.zshrc or ~/.bashrc
if command -v cmux >/dev/null 2>&1 && [ -S "${CMUX_SOCKET_PATH:-$HOME/.local/state/cmux/cmux-$(id -u).sock}" ]; then
  cmux restore-session 2>/dev/null || true
fi
