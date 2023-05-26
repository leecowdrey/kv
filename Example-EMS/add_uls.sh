#!/bin/bash
PING_INTERVAL=$(kv get /system/heartbeat/interval)
HOST="${1:-127.0.0.1}"

# ULS
ULS_UUID=$(uuid)
kv put /inventory/ULS/${ULS_UUID}/management/ip-address "${HOST}"  # ip-address, ipv6-address, fqdn etc.
kv put /inventory/ULS/${ULS_UUID}/management/state ""
kv put /inventory/ULS/${ULS_UUID}/created "$(date '+%s')"
kv put /inventory/ULS/${ULS_UUID}/modified ""
kv put /inventory/ULS/${ULS_UUID}/deleted ""
kv put /inventory/ULS/${ULS_UUID}/heartbeat/first ""
kv put /inventory/ULS/${ULS_UUID}/heartbeat/last ""
kv put /inventory/ULS/${ULS_UUID}/heartbeat/next-expected "$(date -d "+${PING_INTERVAL} minutes" '+%s')"

./add_heartbeat.sh "${ULS_UUID}" "/inventory/ULS/${ULS_UUID}" "/inventory/ULS/${ULS_UUID}/management/state" "ready"
