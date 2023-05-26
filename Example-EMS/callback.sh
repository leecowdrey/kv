#!/bin/bash
CALLBACK_CLI="${0##*/}"
CALLBACK_VERSION="0.0.1"
CALLBACK_PATH=$(dirname "${0}")
CALLBACK_WAIT_PID=0
CALLBACK_PARENT_PID=$$
CALLBACK_TMP="/tmp"
RETVAL=0
declare -a QUEUE

clean_exit() {
  echo "${CALLBACK_CLI}: terminating"
  [[ ! ${CALLBACK_WAIT_PID} -eq 0 ]] && kill -9 ${CALLBACK_WAIT_PID} &> /dev/null 
  trap - INT
  unset QUEUE
  exit ${RETVAL}
}

# 1: URL http{s}://{user:pass@}x.x.x.x{:80}/path
# 2: KV name
callback_post() {
 local RETVAL=0
 if [ $# -eq 0 ] ; then
   RETVAL=1
 else
   local CURL_TMP=$(mktemp -q -p ${CALLBACK_TMP} ${CALLBACK_CLI}.$$.XXXXXXXX)
   CURL_HTTP_CODE=$(/usr/bin/curl -s \
   -o ${CURL_TMP} \
   -w '%{http_code}' \
   --insecure \
   --connect-timeout 5 \
   --max-time 30 \
   --user-agent "${CALLBACK_CLI}/${CALLBACK_VERSION}" \
   -H "Cache-control: no-cache" \
   -H "Accept: application/json" \
   -H "Content-Type: application/json" \
   -d "{\"${CALLBACK_CLI}\":\"${2,,}\"}" \
   --location --request POST \
   "${1,,}" )
   RETVAL=$?
   [[ "${CURL_HTTP_CODE:0:1}" == "2" ]] && RETVAL=0 || RETVAL=1
   [[ -f "${CURL_TMP}" ]] && rm -f ${CURL_TMP} &> /dev/null
  fi
  return ${RETVAL}
}

process() {
  local RETVAL=0
  local Q_UUID="${1}"
  local Q_REQUEST_PATH=$(kv get /system/queue/callback/${Q_UUID}/request-path)
  local Q_RESPONSE_PATH=$(kv get /system/queue/callback/${Q_UUID}/response-path)
  local Q_ATTEMPT=$(kv get /system/queue/callback/${Q_UUID}/worker/retry-attempt)
  local Q_MAX_RETRIES=$(kv get /system/onboard/queue/max-retries)

  [[ -z "${Q_ATTEMPT}" ]] && Q_ATTEMPT=0
  Q_ATTEMPT=$(( Q_ATTEMPT + 1 ))
  echo "${CALLBACK_CLI}: processing ${Q_UUID} ${Q_ATTEMPT}/${Q_MAX_RETRIES}"
  kv put /system/queue/callback/${Q_UUID}/worker/pid "$$"
  kv put /system/queue/callback/${Q_UUID}/worker/host "$(hostname -f)"

  callback_post "${Q_CALLBACK_URL}" "${Q_STATUS}"  && \
  kv put ${Q_RESPONSE_PATH} "true" && \
  kv put ${Q_REQUEST_PATH}/modified "$(date '+%s')" && \
  echo "${CALLBACK_CLI}: delivered callback to ${Q_CALLBACK_URL}" && \
  RETVAL=0 || RETVAL=1
  RETVAL=$?

  if [ ${RETVAL} -eq 0 ] ; then
#    kv put /system/queue/callback/${Q_UUID}/worker/status "pending"
    kv prune /system/queue/callback/${Q_UUID}
  else
    if [ ${Q_ATTEMPT} -lt ${Q_MAX_RETRIES} ] ; then
      echo "${CALLBACK_CLI}: retrying ${Q_UUID} ${Q_ATTEMPT}/${Q_MAX_RETRIES}"
      kv put /system/queue/callback/${Q_UUID}/worker/pid "" && \
      kv put /system/queue/callback/${Q_UUID}/worker/host "" && \
      kv put /system/queue/callback/${Q_UUID}/worker/retry-attempt "${Q_ATTEMPT}" && \
      kv put /system/queue/callback/${Q_UUID}/worker/accepted "ready"
    else
      echo "${CALLBACK_CLI}: failed ${Q_UUID} ${Q_ATTEMPT}/${Q_MAX_RETRIES}"
      kv prune /system/queue/onboard/${Q_UUID}
    fi
  fi
  echo "${CALLBACK_CLI}: completed ${Q_UUID}"
  return ${RETVAL}
}

trap clean_exit INT
WAKE_INTERVAL=$(kv get /system/callback/queue/interval)
while true ; do
  QUEUE=()
  readarray -t QUEUE < <(kv ls /system/queue/callback)
  for ((Q = 0; Q < ${#QUEUE[@]}; ++Q)); do
    Q_IN_PROGRESS=$(kv get /system/queue/callback/${QUEUE[$Q]}/worker/accepted)
    if [ -n "${Q_IN_PROGRESS}" ] ; then
      if [ "${Q_IN_PROGRESS,,}" == "ready" ] ; then
        kv put /system/queue/callback/${QUEUE[$Q]}/worker/accepted "processing" && process "${QUEUE[$Q]}"
      fi
    fi
  done
  unset QUEUE

  sleep ${WAKE_INTERVAL} &>/dev/null &
  ONBOARD_WAIT_PID=$!
  wait ${ONBOARD_WAIT_PID}
done
clean_exit
