#!/bin/bash
RETVAL=0
ID="${1}"
REQUEST="${2}"
RESPONSE="${3}"
ACCEPTED="${4:-ready}"
PING_INTERVAL=$(kv get /system/heartbeat/interval)

# add heartbeat structure to source if not already there
kv is ${REQUEST}/management/ip-address || kv put ${REQUEST}/management/ip-address ""
kv is ${REQUEST}/heartbeat/first || kv put ${REQUEST}/heartbeat/first ""
kv is ${REQUEST}/heartbeat/last || kv put ${REQUEST}/heartbeat/last ""
kv is ${REQUEST}/heartbeat/next-expected || kv put ${REQUEST}/heartbeat/next-expected "$(date -d "+${PING_INTERVAL} minutes" '+%s')"

# ensure response path exists
kv is ${RESPONSE} || kv put ${RESPONSE} ""

kv put /system/queue/heartbeat/${ID} && \
kv put /system/queue/heartbeat/${ID}/request-path "${REQUEST}" && \
kv put /system/queue/heartbeat/${ID}/response-path "${RESPONSE}" && \
kv put /system/queue/heartbeat/${ID}/worker/pid "" && \
kv put /system/queue/heartbeat/${ID}/worker/host "" && \
kv put /system/queue/heartbeat/${ID}/worker/retry-attempt "0" && \
kv put /system/queue/heartbeat/${ID}/worker/accepted "${ACCEPTED,,}"
RETVAL=$?

exit ${RETVAL}
