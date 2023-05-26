#!/bin/bash
ONBOARD_CLI="${0##*/}"
ONBOARD_VERSION="0.0.1"
ONBOARD_PATH=$(dirname "${0}")
ONBOARD_WAIT_PID=0
ONBOARD_PARENT_PID=$$
ONBOARD_TMP="/tmp"
RETVAL=0
declare -a QUEUE

clean_exit() {
  echo "${ONBOARD_CLI}: terminating"
  [[ ! ${ONBOARD_WAIT_PID} -eq 0 ]] && kill -9 ${ONBOARD_WAIT_PID} &> /dev/null 
  trap - INT
  unset QUEUE
  exit ${RETVAL}
}

process() {
  local RETVAL=0
  local Q_UUID="${1}"
  local Q_REQUEST_PATH=$(kv get /system/queue/onboard/${Q_UUID}/request-path)
  local Q_RESPONSE_PATH=$(kv get /system/queue/onboard/${Q_UUID}/response-path)
  local ONBOARDED=$(kv get ${Q_REQUEST_PATH}/management/onboarded)
  local Q_ATTEMPT=$(kv get /system/queue/onboard/${Q_UUID}/worker/retry-attempt)
  local Q_MAX_RETRIES=$(kv get /system/onboard/queue/max-retries)

  [[ -z "${Q_ATTEMPT}" ]] && Q_ATTEMPT=0
  Q_ATTEMPT=$(( Q_ATTEMPT + 1 ))
  echo "${ONBOARD_CLI}: processing ${Q_UUID} ${Q_ATTEMPT}/${Q_MAX_RETRIES}"
  kv put /system/queue/onboard/${Q_UUID}/worker/pid "$$"
  kv put /system/queue/onboard/${Q_UUID}/worker/host "$(hostname -f)"

  echo "${ONBOARD_CLI}: checking ${Q_REQUEST_PATH}"
  if [ "${ONBOARDED,,}" == "false" ] ; then
    local RMD_MAC_ADDRESS=$(kv get ${Q_REQUEST_PATH}/management/mac-address)
    local RMD_BOOTFILE=$(kv get ${Q_REQUEST_PATH}/management/bootfile)
    local RMD_MODEL_TYPE=$(kv get ${Q_REQUEST_PATH}/defaults/model-type)
    echo "${ONBOARD_CLI}: onboarding ${Q_REQUEST_PATH}-${RMD_MAC_ADDRESS}"
    #
    # do something for onboarding
    # 
    kv put ${Q_REQUEST_PATH}/management/onboarded "true"
    kv put ${Q_REQUEST_PATH}/modified "$(date '+%s')"
    echo "${ONBOARD_CLI}: onboarded ${Q_UUID}"

    # now move to next stage
    kv put ${Q_RESPONSE_PATH} "true" && \
    kv put ${Q_REQUEST_PATH}/modified "$(date '+%s')"
    RETVAL=$?
  elif [ "${ONBOARDED,,}" == "true" ] ; then
     RETVAL=0
  else
     RETVAL=1
  fi

  if [ ${RETVAL} -eq 0 ] ; then
    kv put /system/queue/template/${Q_UUID}/request-path "${Q_REQUEST_PATH}" && \
    kv put /system/queue/template/${Q_UUID}/response-path "${Q_RESPONSE_PATH}" && \
    kv put /system/queue/template/${Q_UUID}/worker/pid "" && \
    kv put /system/queue/template/${Q_UUID}/worker/host "" && \
    kv put /system/queue/template/${Q_UUID}/worker/retry-attempt "0" && \
    kv put /system/queue/template/${Q_UUID}/worker/accepted "ready" && \
    kv prune /system/queue/onboard/${Q_UUID}

    #
    # add to heartbeat
    kv put /system/queue/heartbeat/${Q_UUID}/request-path "${Q_REQUEST_PATH}" && \
    kv put /system/queue/heartbeat/${Q_UUID}/response-path "${Q_RESPONSE_PATH}" && \
    kv put /system/queue/heartbeat/${Q_UUID}/worker/pid "" && \
    kv put /system/queue/heartbeat/${Q_UUID}/worker/host "" && \
    kv put /system/queue/heartbeat/${Q_UUID}/worker/retry-attempt "0" && \
    kv put /system/queue/heartbeat/${Q_UUID}/worker/accepted "ready"

  else
    if [ ${Q_ATTEMPT} -lt ${Q_MAX_RETRIES} ] ; then
      echo "${ONBOARD_CLI}: retrying ${Q_UUID} ${Q_ATTEMPT}/${Q_MAX_RETRIES}"
      kv put /system/queue/onboard/${Q_UUID}/worker/pid "" && \
      kv put /system/queue/onboard/${Q_UUID}/worker/host "" && \
      kv put /system/queue/onboard/${Q_UUID}/worker/retry-attempt "${Q_ATTEMPT}" && \
      kv put /system/queue/onboard/${Q_UUID}/worker/accepted "ready"
    else
      echo "${ONBOARD_CLI}: failed ${Q_UUID} ${Q_ATTEMPT}/${Q_MAX_RETRIES}"
      kv put /system/queue/callback/${Q_UUID}/request-path "${Q_REQUEST_PATH}" && \
      kv put /system/queue/callback/${Q_UUID}/response-path "${Q_RESPONSE_PATH}" && \
      kv put /system/queue/callback/${Q_UUID}/worker/pid "" && \
      kv put /system/queue/callback/${Q_UUID}/worker/host "" && \
      kv put /system/queue/callback/${Q_UUID}/worker/retry-attempt "0" && \
      kv put /system/queue/callback/${Q_UUID}/worker/accepted "ready" && \
      kv prune /system/queue/onboard/${Q_UUID}
    fi
  fi
  echo "${ONBOARD_CLI}: completed ${Q_UUID}"
  return ${RETVAL}
}

trap clean_exit INT
WAKE_INTERVAL=$(kv get /system/onboard/queue/interval)
while true ; do
  QUEUE=()
  readarray -t QUEUE < <(kv ls /system/queue/onboard)
  for ((Q = 0; Q < ${#QUEUE[@]}; ++Q)); do
    Q_IN_PROGRESS=$(kv get /system/queue/onboard/${QUEUE[$Q]}/worker/accepted)
    if [ -n "${Q_IN_PROGRESS}" ] ; then
      if [ "${Q_IN_PROGRESS,,}" == "ready" ] ; then
        kv put /system/queue/onboard/${QUEUE[$Q]}/worker/accepted "processing" && process "${QUEUE[$Q]}"
      fi
    fi
  done
  unset QUEUE

  sleep ${WAKE_INTERVAL} &>/dev/null &
  ONBOARD_WAIT_PID=$!
  wait ${ONBOARD_WAIT_PID}
done
clean_exit
