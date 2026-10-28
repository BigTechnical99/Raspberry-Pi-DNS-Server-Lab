#!/usr/bin/env bash
# Raspberry Pi DNS Security Lab — read-only health check
# Run on the Raspberry Pi: bash scripts/dns-health-check.sh
set -uo pipefail

DNS_SERVER="${DNS_SERVER:-127.0.0.1}"
UNBOUND_SERVER="${UNBOUND_SERVER:-127.0.0.1}"
UNBOUND_PORT="${UNBOUND_PORT:-5335}"
TEST_DOMAIN="${TEST_DOMAIN:-example.com}"
DNS_TIMEOUT="${DNS_TIMEOUT:-3}"
failures=0
warnings=0

ok()   { printf '[PASS] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*"; warnings=$((warnings + 1)); }
fail() { printf '[FAIL] %s\n' "$*"; failures=$((failures + 1)); }

check_service() {
  local label="$1" unit="$2"
  if ! command -v systemctl >/dev/null 2>&1; then
    warn "systemctl unavailable; cannot inspect $label"
  elif systemctl is-active --quiet "$unit"; then
    ok "$label service active ($unit)"
  else
    fail "$label service inactive or unavailable ($unit)"
  fi
}

check_dns() {
  local label="$1" host="$2" port="$3" output
  if ! command -v dig >/dev/null 2>&1; then
    warn "dig unavailable; skipping $label DNS test (install dnsutils)"
    return
  fi
  # +tries=1 and +time prevent long hangs when DNS is unavailable.
  if output=$(dig @"$host" -p "$port" "$TEST_DOMAIN" A +time="$DNS_TIMEOUT" +tries=1 +noall +comments +answer 2>&1); then
    if grep -q 'status: NOERROR' <<<"$output" && grep -Eq '[[:space:]]IN[[:space:]]+A[[:space:]]' <<<"$output"; then
      ok "$label resolved $TEST_DOMAIN via $host:$port"
    else
      fail "$label returned no successful A answer for $TEST_DOMAIN"
    fi
  else
    fail "$label query failed via $host:$port"
  fi
}

printf 'DNS infrastructure health check — %s\n' "$(date -Is)"
printf 'Hostname: %s\n' "$(hostname)"
printf '%s\n' '----------------------------------------'

check_service 'AdGuard Home' 'AdGuardHome.service'
check_service 'Unbound' 'unbound.service'
check_service 'SSH' 'ssh.service'
check_dns 'AdGuard Home' "$DNS_SERVER" 53
check_dns 'Unbound' "$UNBOUND_SERVER" "$UNBOUND_PORT"

if command -v uptime >/dev/null 2>&1; then
  printf '\nUptime: %s\n' "$(uptime -p)"
fi
if command -v free >/dev/null 2>&1; then
  printf '\nMemory:\n'
  free -h
fi
if command -v df >/dev/null 2>&1; then
  printf '\nRoot filesystem:\n'
  df -h /
fi
if [[ -r /sys/class/thermal/thermal_zone0/temp ]]; then
  temp_raw=$(< /sys/class/thermal/thermal_zone0/temp)
  if [[ "$temp_raw" =~ ^[0-9]+$ ]]; then
    printf '\nCPU temperature: %s.%s °C\n' "$((temp_raw / 1000))" "$(printf '%03d' "$((temp_raw % 1000))")"
  fi
else
  warn 'CPU temperature sensor not readable'
fi

printf '\nSummary: %s failure(s), %s warning(s)\n' "$failures" "$warnings"
if (( failures > 0 )); then
  exit 1
fi
exit 0
