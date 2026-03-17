#!/bin/bash
# Firewall for Claude Code in Docker
# Whitelists only the domains Claude needs; blocks everything else.
set -e

ALLOWED_DOMAINS=(
  "api.anthropic.com"
  "statsig.anthropic.com"
  "sentry.io"
  "registry.npmjs.org"
  "github.com"
)

# Resolve DNS for each domain and allow it
DNS_SERVER=$(grep nameserver /etc/resolv.conf | head -1 | awk '{print $2}')

# Allow loopback
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established connections
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow DNS
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# Allow each whitelisted domain
for domain in "${ALLOWED_DOMAINS[@]}"; do
  ips=$(getent hosts "$domain" 2>/dev/null | awk '{print $1}' || true)
  for ip in $ips; do
    iptables -A OUTPUT -d "$ip" -j ACCEPT
  done
done

# Default deny everything else
iptables -A OUTPUT -j REJECT

echo "Firewall active. Allowed: ${ALLOWED_DOMAINS[*]}"
