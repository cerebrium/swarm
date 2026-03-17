#!/bin/bash
set -e

# Ensure the claude user owns their home config directory
sudo chown -R claude:claude /home/claude/.claude 2>/dev/null || true
sudo chown -R claude:claude /home/claude/.local 2>/dev/null || true

# Only enable firewall if explicitly requested
if [ "$ENABLE_FIREWALL" = "true" ]; then
  if sudo iptables -L >/dev/null 2>&1; then
    echo "Setting up firewall..."
    sudo /usr/local/bin/init-firewall.sh
  else
    echo "Warning: ENABLE_FIREWALL=true but no NET_ADMIN capability. Skipping."
  fi
fi

# If no arguments, start Claude Code interactively
if [ $# -eq 0 ]; then
  exec claude --dangerously-skip-permissions
else
  exec "$@"
fi
