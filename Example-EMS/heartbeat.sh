#!/bin/bash
HEARTBEAT_CLI="${0##*/}"
HEARTBEAT_VERSION="0.0.1"
HEARTBEAT_PATH=$(dirname "${0}")
HEARTBEAT_WAIT_PID=0
HEARTBEAT_PARENT_PID=$$
HEARTBEAT_TMP="/tmp"
RETVAL=0
declare -a QUEUE

clean_exit() {
  echo "${HEARTBEAT_CLI}: terminating"
  [[ ! ${HEARTBEAT_WAIT_PID} -eq 0 ]] && kill -9 ${HEARTBEAT_WAIT_PID} &> /dev/null 
  trap - INT
  unset QUEUE
  exit ${RETVAL}
}

process() {
  local RETVAL=0
  local Q_UUID="${1}"
  kv put /system/queue/heartbeat/${Q_UUID}/worker/pid "$$"
  kv put /system/queue/heartbeat/${Q_UUID}/worker/host "$(hostname -f)"
  local Q_REQUEST_PATH=$(kv get /system/queue/heartbeat/${Q_UUID}/request-path)
  local Q_RESPONSE_PATH=$(kv get /system/queue/heartbeat/${Q_UUID}/response-path)
  kv is ${Q_REQUEST_PATH}
  if [ $? -eq 0 ] ; then
    local PING_TIMEOUT=$(kv get /system/heartbeat/timeout)
    local PING_TTL=$(kv get /system/heartbeat/ttl)
    local PING_COUNT=$(kv get /system/heartbeat/count)
    local PING_INTERVAL=$(kv get /system/heartbeat/interval)
    local HOST=$(kv get ${Q_REQUEST_PATH}/management/ip-address)
    local CURRENT_ATTEMPT=$(date '+%s')
    local NEXT_ATTEMPT=$(( ${CURRENT_ATTEMPT} + ${PING_INTERVAL} ))

    local FIRST_ATTEMPT=$(kv get ${Q_REQUEST_PATH}/heartbeat/first)
    [[ -z "${FIRST_ATTEMPT}" ]] && FIRST_ATTEMPT=0
    local LAST_ATTEMPT=$(kv get ${Q_REQUEST_PATH}/heartbeat/last)
    [[ -z "${LAST_ATTEMPT}" ]] && LAST_ATTEMPT=0
    local NEXT_EXPECTED=$(kv get ${Q_REQUEST_PATH}/heartbeat/next-expected)
    [[ -z "${NEXT_EXPECTED}" ]] && NEXT_EXPECTED=${NEXT_ATTEMPT} && kv put ${Q_REQUEST_PATH}/heartbeat/next-expected "${NEXT_ATTEMPT}"
    local THRESHOLD_PING=$(kv get ${Q_REQUEST_PATH}/heartbeat/alarm/ping)

    ping -c ${PING_COUNT} -t ${PING_TTL} -W ${PING_TIMEOUT} ${HOST} &> /dev/null
    local PING_RETVAL=$?

    if [ ${PING_RETVAL} -eq 0 ] ; then
      RETVAL=0
      [[ ${FIRST_ATTEMPT} -eq 0 ]] && ( kv put ${Q_REQUEST_PATH}/heartbeat/first "${CURRENT_ATTEMPT}" && \
                                        kv put ${Q_REQUEST_PATH}/heartbeat/last "${CURRENT_ATTEMPT}" ) || \
                                        kv put ${Q_REQUEST_PATH}/heartbeat/last "${CURRENT_ATTEMPT}"
      kv put ${Q_REQUEST_PATH}/heartbeat/last "${CURRENT_ATTEMPT}" && \
      kv put ${Q_REQUEST_PATH}/heartbeat/next-expected "${NEXT_ATTEMPT}" && \
      kv put ${Q_REQUEST_PATH}/modified "$(date '+%s')" && \
      kv put ${Q_RESPONSE_PATH} "ok" && \
      kv put ${Q_REQUEST_PATH}/modified "$(date '+%s')" && \
      [[ ${THRESHOLD_PING} -ne 0 ]] && THRESHOLD_PING=0 && kv put ${Q_REQUEST_PATH}/heartbeat/alarm/ping ${THRESHOLD_PING} 
    else
      THRESHOLD_PING=$(( ${THRESHOLD_PING:-0} + 1 ))
      kv put ${Q_REQUEST_PATH}/heartbeat/next-expected "${NEXT_ATTEMPT}" && \
      kv put ${Q_REQUEST_PATH}/heartbeat/alarm/ping ${THRESHOLD_PING} && \
      kv put ${Q_REQUEST_PATH}/modified "$(date '+%s')" && \
      kv put ${Q_RESPONSE_PATH} "fail" && \
      kv put ${Q_REQUEST_PATH}/modified "$(date '+%s')"
      local MISSED_ATTEMPT=$(( LAST_ATTEMPT + PING_INTERVAL ))
      if (( MISSED_ATTEMPT < CURRENT_ATTEMPT )) ; then
        if [ ${FIRST_ATTEMPT} -gt 0 ] ; then
          echo "${HEARTBEAT_CLI}: ${Q_UUID} ${HOST} raising callback alarm"
          kv put /system/queue/callback/${Q_UUID}/request-path "${Q_REQUEST_PATH}" && \
          kv put /system/queue/callback/${Q_UUID}/response-path "${Q_RESPONSE_PATH}" && \
          kv put /system/queue/callback/${Q_UUID}/worker/pid "" && \
          kv put /system/queue/callback/${Q_UUID}/worker/host "" && \
          kv put /system/queue/callback/${Q_UUID}/worker/retry-attempt "0" && \
          kv put /system/queue/callback/${Q_UUID}/worker/accepted "ready"
        fi
      fi
    fi

    local RESULT=""
    [[ ${PING_RETVAL} -eq 0 ]] && RESULT="ok" || RESULT="fail"
    echo "${HEARTBEAT_CLI}: ${Q_UUID} ${HOST} / ?:${RESULT} / #:${THRESHOLD_PING} / F:${FIRST_ATTEMPT} / L:${LAST_ATTEMPT} / N:${NEXT_ATTEMPT}"
    kv put /system/queue/heartbeat/${Q_UUID}/worker/pid "" && \
    kv put /system/queue/heartbeat/${Q_UUID}/worker/host "" && \
    kv put /system/queue/heartbeat/${Q_UUID}/worker/retry-attempt "0" && \
    kv put /system/queue/heartbeat/${Q_UUID}/worker/accepted "ready"
  else
    echo "${HEARTBEAT_CLI}: ${Q_UUID} stale entry, pruning"
    kv prune /system/queue/heartbeat/${Q_UUID}
    kv is /system/queue/heartbeat/${Q_UUID} && kv prune /system/queue/heartbeat/${Q_UUID}
    RETVAL=0
  fi
  return ${RETVAL}
}

trap clean_exit INT
WAKE_INTERVAL=$(kv get /system/heartbeat/queue/interval)
while true ; do
  QUEUE=()
  readarray -t QUEUE < <(kv ls /system/queue/heartbeat)
  for ((Q = 0; Q < ${#QUEUE[@]}; ++Q)); do
    Q_IN_PROGRESS=$(kv get /system/queue/heartbeat/${QUEUE[$Q]}/worker/accepted)
    if [ -n "${Q_IN_PROGRESS}" ] ; then
      if [ "${Q_IN_PROGRESS,,}" == "ready" ] ; then
        kv put /system/queue/heartbeat/${QUEUE[$Q]}/worker/accepted "processing" && ( process "${QUEUE[$Q]}" & )
      fi
    fi
  done
  unset QUEUE

  sleep ${WAKE_INTERVAL} &>/dev/null &
  HEARTBEAT_WAIT_PID=$!
  wait ${HEARTBEAT_WAIT_PID}
done
clean_exit

