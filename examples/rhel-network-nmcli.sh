#!/usr/bin/env bash
set -euo pipefail

IFACE="${IFACE:-ens160}"
CON_NAME="${CON_NAME:-primary-static}"
ADDRESS="${ADDRESS:-192.0.2.30/24}"
GATEWAY="${GATEWAY:-192.0.2.1}"
DNS_SERVERS="${DNS_SERVERS:-192.0.2.53 192.0.2.54}"
DNS_SEARCH="${DNS_SEARCH:-corp.example.com}"

command -v nmcli >/dev/null 2>&1 || {
  echo "nmcli is required" >&2
  exit 1
}

if ! nmcli -t -f DEVICE device status | grep -Fxq "${IFACE}"; then
  echo "Interface ${IFACE} was not found" >&2
  exit 1
fi

CURRENT="$(nmcli -g GENERAL.CONNECTION device show "${IFACE}" | head -n1)"

if [[ -z "${CURRENT}" || "${CURRENT}" == "--" ]]; then
  sudo nmcli connection add \
    type ethernet \
    ifname "${IFACE}" \
    con-name "${CON_NAME}" \
    ipv4.method manual \
    ipv4.addresses "${ADDRESS}" \
    ipv4.gateway "${GATEWAY}" \
    ipv4.dns "${DNS_SERVERS}" \
    ipv4.dns-search "${DNS_SEARCH}" \
    ipv6.method disabled
else
  CON_NAME="${CURRENT}"
  sudo nmcli connection modify "${CON_NAME}" \
    connection.interface-name "${IFACE}" \
    ipv4.method manual \
    ipv4.addresses "${ADDRESS}" \
    ipv4.gateway "${GATEWAY}" \
    ipv4.dns "${DNS_SERVERS}" \
    ipv4.dns-search "${DNS_SEARCH}" \
    ipv6.method disabled
fi

sudo nmcli connection up "${CON_NAME}"

nmcli device status
nmcli connection show "${CON_NAME}"
ip -brief address show dev "${IFACE}"
ip route
