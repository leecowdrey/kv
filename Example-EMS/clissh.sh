#!/bin/bash
CLISSH_CLI="${0##*/}"
CLISSH_VERSION="0.0.1"
CLISSH_PATH=$(dirname "${0}")
CLISSH_WAIT_PID=0
CLISSH_PARENT_PID=$$
CLISSH_TMP="/tmp"
RETVAL=0
declare -a QUEUE

clean_exit() {
  echo "${CLISSH_CLI}: terminating"
  [[ ! ${CLISSH_WAIT_PID} -eq 0 ]] && kill -9 ${CLISSH_WAIT_PID} &> /dev/null 
  trap - INT
  unset QUEUE
  exit ${RETVAL}
}

cli() {
 local RETVAL=0
 local SSH_TIMEOUT=$(kv get /system/ssh/timeout)
 local SSH_MAXTIME=$(kv get /system/ssh/max-wait)
 local SSH_TIMEOUT=$(kv get /system/ssh/timeout)
 local SSH_MAXRETRIES=$(kv get /system/ssh/max-retries)
 local SSH_RETRY_INTERVAL=$(kv get /system/ssh/retry-interval)
 local RMD_HOST="${1}"
 local RMD_PORT=${2}
 local RMD_USER="${3}"
 local RMD_PASS="${4}"
 local RMD_CLI="${5}"

 if [[ -n "${RMD_HOST}" && -n "${RMD_PORT}" && -n "${RMD_USER}" && -n "${RMD_PASS}" ]] ; then
   local RMD_IP_LOOKUP=$(getent hosts ${RMD_HOST}|head -1|awk '{ print $1 }')
   local RMD_IP="${RMD_IP_LOOKUP:-$RMD_HOST}"
   if [[ ${RMD_IP} =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] ; then
     ping -c 1 -n -q ${RMD_IP} &>/dev/null
   else
     ping6 -c 1 -n -q ${RMD_IP} &>/dev/null
   fi
   RETVAL=$?
   if [ ${RETVAL} -eq 0 ] ; then
     ssh-keyscan -T ${SSH_MAXTIME} -H -p ${RMD_PORT} ${RMD_HOST} &>/dev/null
     RETVAL=$?
     if [ ${RETVAL} -eq 0 ] ; then
       local SSH_PID=$$
       #  local SED_FILE=$(mktemp -q -p ${TMP_DIR} ${TEMPLATE_CLI}.$$.XXXXXXXX)

       local SSH_STDOUT=$(mktemp -q -p ${TMP_DIR} ${CLISSH_CLI}.${SSH_PID}.$$.XXXXXXXX) # "${CLISSH_TMP}/${SSH_PID}.out"
       local SSH_OUTPUT=""
       local SSH_INPUT=$(mktemp -q -p ${TMP_DIR} ${CLISSH_CLI}.${SSH_PID}.$$.XXXXXXXX) # "${CLISSH_TMP}/${SSH_PID}.out" ${CLISSH_TMP}/${SSH_PID}.in"

       [[ -f "${SSH_INPUT}" ]] && rm -f ${SSH_INPUT} &> /dev/null
       if [ -f "${RMD_CLI}" ] ; then
         while IFS= read -r CLI_LINE ; do
           echo "${CLI_LINE}" >> ${SSH_INPUT}
         done < ${RMD_CLI}
       else
           echo "${RMD_CLI}" >> ${SSH_INPUT}
       fi
       echo "exit" >> ${SSH_INPUT}
       local SSH_STDIN=$(cat ${SSH_INPUT})

       eval "sleep ${SSH_TIMEOUT} && ssh -S ${CLISSH_TMP}/${RMD_HOST}.${SSH_PID} -O exit ${RMD_HOST} &>/dev/null" &>/dev/null &
       local SSH_KILL=$!

       sshpass -p ${RMD_PASS} \
           ssh -q \
           -o UserKnownHostsFile=/dev/null \
           -o StrictHostKeyChecking=no \
           -o ConnectTimeout=${SSH_TIMEOUT} \
           -o ConnectionAttempts=1 \
           -o UpdateHostKeys=no \
           -o VerifyHostKeyDNS=no \
           -o CheckHostIP=no \
           -o TCPKeepAlive=no \
           -o RequestTTY=yes \
           -S ${CLISSH_TMP}/${RMD_HOST}.${SSH_PID} \
           -M \
           -p ${RMD_PORT} \
           -l ${RMD_USER} \
           ${RMD_HOST} > ${SSH_STDOUT} 2>&1 <<EOS
${SSH_STDIN}
EOS
       RETVAL=$?
       [[ -f "${SSH_INPUT}" ]] && rm -f ${SSH_INPUT} &> /dev/null

       kill -0 ${SSH_KILL} &>/dev/null
       if [ $? -eq 0 ] ; then
         kill -2 ${SSH_KILL} &>/dev/null
       fi
       [[ -f "${SSH_STDOUT}" ]] && SSH_OUTPUT=$(cat ${SSH_STDOUT}) && rm -f ${SSH_STDOUT} &> /dev/null
       echo "${SSH_OUTPUT}"
     else
        RETVAL=1
     fi
   else
    RETVAL=1
   fi
 fi
 return ${RETVAL}
}

read_config() {
  local RETVAL=0
  cli "${1}" "${2}" "${3}" "${4}" "${5}"
  RETVAL=$?
  return ${RETVAL}
}

write_config() {
  local RETVAL=0
  echo "commit" >> ${5}
  echo "save" >> ${5}
  cli "${1}" "${2}" "${3}" "${4}" "${5}"
  RETVAL=$?
  return ${RETVAL}
}

process() {
  local RETVAL=0
  local Q_UUID="${1}"
  local Q_REQUEST_PATH=$(kv get /system/queue/clissh/${Q_UUID}/request-path)
  local Q_RESPONSE_PATH=$(kv get /system/queue/clissh/${Q_UUID}/response-path)
  local Q_ATTEMPT=$(kv get /system/queue/clissh/${Q_UUID}/worker/retry-attempt)
  local Q_MAX_RETRIES=$(kv get /system/onboard/queue/max-retries)

  [[ -z "${Q_ATTEMPT}" ]] && Q_ATTEMPT=0
  Q_ATTEMPT=$(( Q_ATTEMPT + 1 ))
  echo "${CLISSH_CLI}: processing ${Q_UUID} ${Q_ATTEMPT}/${Q_MAX_RETRIES}"
  kv put /system/queue/clissh/${Q_UUID}/worker/pid "$$"
  kv put /system/queue/clissh/${Q_UUID}/worker/host "$(hostname -f)"

  local Q_CLI=$(kv get /system/queue/clissh/${Q_UUID}/worker/cli)
  local Q_SSH_IP=$(kv get ${Q_REQUEST_PATH}/management/ip-address)
  local Q_SSH_PORT=$(kv get ${Q_REQUEST_PATH}/management/ssh/port)
  local Q_SSH_USERNAME=$(kv get ${Q_REQUEST_PATH}/management/ssh/password/username)
  local Q_SSH_PASSWORD=$(kv get ${Q_REQUEST_PATH}/management/ssh/password/password)

  if [ -f "${Q_CLI}" ] ; then
    echo "${CLISSH_CLI}: delivering ${Q_CLI} to ${Q_SSH_IP}:${Q_SSH_PORT}"
    #cli "${Q_SSH_IP}" "${Q_SSH_PORT}" "${Q_SSH_USERNAME}" "${Q_SSH_PASSWORD}" "${Q_CLI}"
    #RETVAL=$?
    if [ ${RETVAL} -eq 0 ] ; then
      kv put ${Q_RESPONSE_PATH} "true" && \
      kv put ${Q_REQUEST_PATH}/modified "$(date '+%s')" && \
      RETVAL=0
    else
      RETVAL=1
    fi
    rm -f ${Q_CLI} &> /dev/null
  else
    RETVAL=1
  fi

  if [ ${RETVAL} -eq 0 ] ; then
    kv put /system/queue/callback/${Q_UUID}/request-path "${Q_REQUEST_PATH}" && \
    kv put /system/queue/callback/${Q_UUID}/response-path "${Q_RESPONSE_PATH}" && \
    kv put /system/queue/callback/${Q_UUID}/worker/pid "" && \
    kv put /system/queue/callback/${Q_UUID}/worker/host "" && \
    kv put /system/queue/callback/${Q_UUID}/worker/retry-attempt "0" && \
    kv put /system/queue/callback/${Q_UUID}/worker/accepted "ready" && \
    kv prune /system/queue/clissh/${Q_UUID}
  else
    if [ ${Q_ATTEMPT} -lt ${Q_MAX_RETRIES} ] ; then
      echo "${CLISSH_CLI}: retrying ${Q_UUID} ${Q_ATTEMPT}/${Q_MAX_RETRIES}"
      kv put /system/queue/clissh/${Q_UUID}/worker/pid "" && \
      kv put /system/queue/clissh/${Q_UUID}/worker/host "" && \
      kv put /system/queue/clissh/${Q_UUID}/worker/retry-attempt "${Q_ATTEMPT}" && \
      kv put /system/queue/clissh/${Q_UUID}/worker/accepted "ready"
    else
      echo "${CLISSH_CLI}: failed ${Q_UUID} ${Q_ATTEMPT}/${Q_MAX_RETRIES}"
      kv put /system/queue/callback/${Q_UUID}/request-path "${Q_REQUEST_PATH}" && \
      kv put /system/queue/callback/${Q_UUID}/response-path "${Q_RESPONSE_PATH}" && \
      kv put /system/queue/callback/${Q_UUID}/worker/pid "" && \
      kv put /system/queue/callback/${Q_UUID}/worker/host "" && \
      kv put /system/queue/callback/${Q_UUID}/worker/retry-attempt "0" && \
      kv put /system/queue/callback/${Q_UUID}/worker/accepted "ready" && \
      kv prune /system/queue/clissh/${Q_UUID}
    fi
  fi
  echo "${CLISSH_CLI}: completed ${QUEUE[$Q]}"
  return ${RETVAL}
}

trap clean_exit INT
WAKE_INTERVAL=$(kv get /system/clissh/queue/interval)
while true ; do
  QUEUE=()
  readarray -t QUEUE < <(kv ls /system/queue/clissh)
  for ((Q = 0; Q < ${#QUEUE[@]}; ++Q)); do
    Q_IN_PROGRESS=$(kv get /system/queue/clissh/${QUEUE[$Q]}/worker/accepted)
    if [ -n "${Q_IN_PROGRESS}" ] ; then
      if [ "${Q_IN_PROGRESS,,}" == "ready" ] ; then
        kv put /system/queue/clissh/${QUEUE[$Q]}/worker/accepted "processing" && process "${QUEUE[$Q]}"
      fi
    fi
  done
  unset QUEUE

  sleep ${WAKE_INTERVAL} &>/dev/null &
  ONBOARD_WAIT_PID=$!
  wait ${ONBOARD_WAIT_PID}
done
clean_exit
