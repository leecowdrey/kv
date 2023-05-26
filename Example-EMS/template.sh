#!/bin/bash
TEMPLATE_CLI="${0##*/}"
TEMPLATE_VERSION="0.0.1"
TEMPLATE_PATH=$(dirname "${0}")
TEMPLATE_WAIT_PID=0
TEMPLATE_PARENT_PID=$$
TEMPLATE_TMP="/tmp"
RETVAL=0
declare -a QUEUE

generate_cli() {
  local RETVAL=0  
  local ROOT="${1}"
  local STATUS="${2}"
  local Q_UUID="${3}"
  local TEMPLATE="${4}"
  local CLI_OUTPUT="${5}"
  local EXISTING_STATUS=$(kv get ${STATUS})

  # extract tenant/region/zone/rmd-id
  local TENANT_ID=$(echo "${ROOT,,}"|cut -d "/" -f2)
  local REGION_ID=$(echo "${ROOT,,}"|cut -d "/" -f3)
  local ZONE_ID=$(echo "${ROOT,,}"|cut -d "/" -f4)
  local UUID=$(echo "${ROOT,,}"|cut -d "/" -f5)
  
  # prep 
  local SED_FILE=$(mktemp -q -p ${TEMPLATE_TMP} ${TEMPLATE_CLI}.$$.XXXXXXXX)
  [[ -f "${SED_FILE}" ]] && rm -f ${SED_FILE} &> /dev/null
  [[ -f "${CLI_OUTPUT}" ]] && rm -f ${CLI_OUTPUT} &> /dev/null
  touch ${CLI_OUTPUT}
  #
  declare -a LIST_OF_PARAMETERS

  if [ -f "${TEMPLATE}" ] ; then
    # single parameter mapping
    # template: {{ }}
    readarray -t LIST_OF_PARAMETERS < <(grep -oP '(?<={{).*?(?=}})' ${TEMPLATE})
    if [ ${#LIST_OF_PARAMETERS[@]} -gt 0 ] ; then
      for ((P = 0; P < ${#LIST_OF_PARAMETERS[@]}; ++P)); do
        local PARAM_NAME="${LIST_OF_PARAMETERS[$P]//\$\{TENANT_ID\}/${TENANT_ID}}"
        PARAM_NAME="${PARAM_NAME//\$\{REGION_ID\}/${REGION_ID}}"
        PARAM_NAME="${PARAM_NAME//\$\{ZONE_ID\}/${ZONE_ID}}"
        PARAM_NAME="${PARAM_NAME//\$\{UUID\}/${UUID}}"
        local PARAM_VALUE=$(kv get ${PARAM_NAME})
        echo "s\{{${LIST_OF_PARAMETERS[$P]}}}\\${PARAM_VALUE}\g" >> ${SED_FILE}
      done
      [[ -f "${CLI_OUTPUT}" ]] && rm -f ${CLI_OUTPUT} &> /dev/null
      [[ -f "${SED_FILE}" ]] && sed -f ${SED_FILE} ${TEMPLATE} >> ${CLI_OUTPUT} && RETVAL=$? || RETVAL=1
    else
      cat ${TEMPLATE} > ${CLI_OUTPUT} && RETVAL=$?
    fi
    unset LIST_OF_PARAMETERS

    # optional & multiple parameter instances mapping
    if [ ${RETVAL} -eq 0 ] ; then
      # KV: interface // cable-downstream // ds // scq // ?? // cable ?? frequency <value>
      # CLI: configure interface cable-downstream ds/scq/0 cable frequency 261000000
      # template [[ label-text|path-KV/? label-text|child-keyname label-text|child-keyname %|key-value]]
      # only one index (/?) can exist
      readarray -t LIST_OF_PARAMETERS < <(grep -oP '(?<=<<).*?(?=<<)' ${TEMPLATE})
      if [ ${#LIST_OF_PARAMETERS[@]} -gt 0 ] ; then
        for ((P = 0; P < ${#LIST_OF_PARAMETERS[@]}; ++P)); do
          local OM_DATA=$(mktemp -q -p ${TEMPLATE_TMP} ${TEMPLATE_CLI}.$$.XXXXXXXX)
          local KV_LINE="${LIST_OF_PARAMETERS[$P]//\$\{TENANT_ID\}/${TENANT_ID}}"
          KV_LINE="${KV_LINE//\$\{REGION_ID\}/${REGION_ID}}"
          KV_LINE="${KV_LINE//\$\{ZONE_ID\}/${ZONE_ID}}"
          KV_LINE="${KV_LINE//\$\{UUID\}/${UUID}}"
          local KV_LABEL=$(echo "${KV_LINE}"|cut -d"?" -f1)
          local KV_KEY=$(echo "${KV_LINE}"|cut -d"?" -f2|cut -d" " -f1)
          local KV_REST=$(echo "${KV_LINE}"|cut -d"?" -f2-|cut -d" " -f2-)
          declare -a KV_CHILDREN
          local KV_CLI_LINE=""
          local KV_CLI_QUERY=""
          readarray -t KV_CHILDREN < <(kv ls ${KV_KEY})
          for ((C = 0; C < ${#KV_CHILDREN[@]}; ++C)); do
            KV_CLI_LINE="${KV_LABEL}${KV_CHILDREN[$C]}"
            KV_CLI_QUERY="${KV_KEY}/${KV_CHILDREN[$C]}"
            declare -a KV_LEAF=( ${KV_REST} )
            for ((L = 0; L < ${#KV_LEAF[@]}; ++L)); do
              if [ "${KV_LEAF[$L]}" == "%" ] ; then
               KV_CLI_LINE+=" $(kv get ${KV_CLI_QUERY})"
              else
                KV_CLI_LINE+=" $(echo "${KV_LEAF[$L]}"|cut -d"?" -f1)"
                KV_CLI_QUERY+="/$(echo "${KV_LEAF[$L]}"|cut -d"?" -f2)"
              fi
            done
            [[ -n "${KV_CLI_LINE}" ]] && echo "${KV_CLI_LINE}" >> ${OM_DATA}
            unset KV_LEAF
          done
          unset KV_CHILDREN
          local OM_TMP=$(mktemp -q -p ${TEMPLATE_TMP} ${TEMPLATE_CLI}.$$.XXXXXXXX)
          while IFS= read -r OM_LINE; do
            # tbc: expand to check all array
            if [[ ${OM_LINE} =~ "<<${LIST_OF_PARAMETERS[$P]}<<" ]] ; then
              cat ${OM_DATA} >> ${OM_TMP}
            else
              echo "${OM_LINE}" >> ${OM_TMP}
            fi
          done < ${CLI_OUTPUT}        
          [[ -f "${OM_TMP}" ]] && cat ${OM_TMP} > ${CLI_OUTPUT} && RETVAL=$?
          [[ -f "${OM_TMP}" ]] && rm -f ${OM_TMP} &> /dev/null
          [[ -f "${OM_DATA}" ]] && rm -f ${OM_DATA} &> /dev/null
        done
        RETVAL=0    
      fi
    fi

    # nested list parameter instances mapping
    if [ ${RETVAL} -eq 0 ] ; then
      # CLI: configure access-list 1  permit 192.168.226.0 0.0.0.255
      # template: <>configure access-list ?/${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${UUID}/config/access-list ?.<>
      # ?. lowest key-name is found and both key-name and key-value output
      # KV: ../config/access-list/{rule#}/{entry#}/[permit|deny] = key-value
      declare -a LIST_OF_KV_QUERY
      declare -a LIST_OF_KV_CLI
      readarray -t LIST_OF_PARAMETERS < <(grep -oP '(?<=<>).*?(?=<>)' ${TEMPLATE})
      if [ ${#LIST_OF_PARAMETERS[@]} -gt 0 ] ; then
        for ((P = 0; P < ${#LIST_OF_PARAMETERS[@]}; ++P)); do
          local OM_DATA=$(mktemp -q -p ${TEMPLATE_TMP} ${TEMPLATE_CLI}.$$.XXXXXXXX)
          local KV_LINE="${LIST_OF_PARAMETERS[$P]//\$\{TENANT_ID\}/${TENANT_ID}}"
          KV_LINE="${KV_LINE//\$\{REGION_ID\}/${REGION_ID}}"
          KV_LINE="${KV_LINE//\$\{ZONE_ID\}/${ZONE_ID}}"
          KV_LINE="${KV_LINE//\$\{UUID\}/${UUID}}"

          local KV_LABEL=$(echo "${KV_LINE}"|cut -d"?" -f1)
          local KV_KEY=$(echo "${KV_LINE}"|cut -d"?" -f2|cut -d" " -f1)
          local KV_REST=$(echo "${KV_LINE}"|cut -d"?" -f2-|cut -d" " -f2-)
          declare -a KV_CHILDREN
          local KV_CLI_LINE=""
          local KV_CLI_QUERY=""
          readarray -t KV_CHILDREN < <(kv ls ${KV_KEY})
          for ((C = 0; C < ${#KV_CHILDREN[@]}; ++C)); do
            KV_CLI_LINE="${KV_LABEL}${KV_CHILDREN[$C]}"
            KV_CLI_QUERY="${KV_KEY}/${KV_CHILDREN[$C]}"
            declare -a KV_LEAF=( ${KV_REST} )
            for ((L = 0; L < ${#KV_LEAF[@]}; ++L)); do
              local OPTION=$(echo "${KV_LEAF[$L]}"|cut -d"?" -f2)
              if [ "${OPTION}" == "." ] ; then
                 walk_tree() {
                  local RETVAL=0
                  declare -a WT_LS
                  readarray -t WT_LS < <(kv ls ${1}) 
                  for ((K = 0; K < ${#WT_LS[@]}; K++)); do
                   if [[ $(kv count ${1}/${WT_LS[$K]}) -gt 0 ]] ; then
                    walk_tree "${1}/${WT_LS[$K]}" "${2} ${WT_LS[$K]}"
                   else
                    LIST_OF_KV_QUERY+=("${1}/${WT_LS[$K]}")
                    LIST_OF_KV_CLI+=("${2} ${WT_LS[$K]}")
                   fi                
                  done
                  unset WT_LS
                  return ${RETVAL}
                }
                declare -a KV_WILD_NESTED
                readarray -t KV_WILD_NESTED < <(kv ls ${KV_CLI_QUERY})
                for ((W = 0; W < ${#KV_WILD_NESTED[@]}; W++)); do
                    walk_tree "${KV_CLI_QUERY}/${KV_WILD_NESTED[$W]}" "${KV_CLI_LINE}"
                done
                unset KV_WILD_NESTED
              else
                KV_CLI_LINE+=" $(echo "${KV_LEAF[$L]}"|cut -d"?" -f1)"
                KV_CLI_QUERY+="/$(echo "${KV_LEAF[$L]}"|cut -d"?" -f2)"
              fi
            done
            unset KV_LEAF
          done
          #
          for ((Q = 0; Q < ${#LIST_OF_KV_QUERY[@]}; ++Q)); do
            local KV_VALUE=$(kv get ${LIST_OF_KV_QUERY[$Q]})
            echo "${LIST_OF_KV_CLI[$Q]} ${KV_VALUE}" >> ${OM_DATA}
          done
          #
          unset KV_CHILDREN
          local OM_TMP=$(mktemp -q -p ${TEMPLATE_TMP} ${TEMPLATE_CLI}.$$.XXXXXXXX)
          while IFS= read -r OM_LINE; do
            # tbc: expand to check all array
            if [[ ${OM_LINE} =~ "<>${LIST_OF_PARAMETERS[$P]}<>" ]] ; then
              cat ${OM_DATA} >> ${OM_TMP}
            else
              echo "${OM_LINE}" >> ${OM_TMP}
            fi
          done < ${CLI_OUTPUT}        
          [[ -f "${OM_TMP}" ]] && cat ${OM_TMP} > ${CLI_OUTPUT} && RETVAL=$?
          [[ -f "${OM_TMP}" ]] && rm -f ${OM_TMP} &> /dev/null
          [[ -f "${OM_DATA}" ]] && rm -f ${OM_DATA} &> /dev/null
        done
        RETVAL=0    
      fi
      unset LIST_OF_KV_QUERY
      unset LIST_OF_KV_CLI    
    fi

    # unescape strings (matches cli2kv escaped strings)
    [[ -f "${CLI_OUTPUT}" ]] && sed -i "s/\\\\\"/\"/g" ${CLI_OUTPUT} && RETVAL=$? || RETVAL=1
  else
    RETVAL=1
  fi

  [[ -f "${SED_FILE}" ]] && rm -f ${SED_FILE} &> /dev/null

  if [ ${RETVAL} -eq 0 ] ; then
    kv put ${STATUS} "true" && \
    kv put ${ROOT}/modified "$(date '+%s')"
    RETVAL=$?
  fi

  unset LIST_OF_PARAMETERS
  return ${RETVAL}
}

clean_exit() {
  echo "${TEMPLATE_CLI}: terminating"
  [[ ! ${TEMPLATE_WAIT_PID} -eq 0 ]] && kill -9 ${TEMPLATE_WAIT_PID} &> /dev/null 
  trap - INT
  unset QUEUE
  exit ${RETVAL}
}

process() {
  local RETVAL=0
  local Q_UUID="${1}"
  local Q_REQUEST_PATH=$(kv get /system/queue/template/${Q_UUID}/request-path)
  local Q_RESPONSE_PATH=$(kv get /system/queue/template/${Q_UUID}/response-path)
  local Q_ATTEMPT=$(kv get /system/queue/template/${Q_UUID}/worker/retry-attempt)
  local Q_MAX_RETRIES=$(kv get /system/onboard/queue/max-retries)

  [[ -z "${Q_ATTEMPT}" ]] && Q_ATTEMPT=0
  Q_ATTEMPT=$(( Q_ATTEMPT + 1 ))
  echo "${TEMPLATE_CLI}: processing ${Q_UUID} ${Q_ATTEMPT}/${Q_MAX_RETRIES}"
  kv put /system/queue/template/${Q_UUID}/worker/pid "$$"
  kv put /system/queue/template/${Q_UUID}/worker/host "$(hostname -f)"

  generate_cli "${Q_REQUEST_PATH}" "${Q_RESPONSE_PATH}" "${Q_UUID}" "${TEMPLATE_PATH}/RD2322.template" "${TEMPLATE_TMP}/${Q_UUID}-${Q_ATTEMPT}.cli" && \
  kv put ${Q_RESPONSE_PATH} "true" && \
  kv put ${Q_REQUEST_PATH}/modified "$(date '+%s')" && \
  RETVAL=0 || RETVAL=1

  if [ ${RETVAL} -eq 0 ] ; then
    kv put /system/queue/clissh/${Q_UUID}/request-path "${Q_REQUEST_PATH}" && \
    kv put /system/queue/clissh/${Q_UUID}/response-path "${Q_RESPONSE_PATH}" && \
    kv put /system/queue/clissh/${Q_UUID}/worker/cli "${TEMPLATE_TMP}/${Q_UUID}-${Q_ATTEMPT}.cli" && \
    kv put /system/queue/clissh/${Q_UUID}/worker/pid "" && \
    kv put /system/queue/clissh/${Q_UUID}/worker/host "" && \
    kv put /system/queue/clissh/${Q_UUID}/worker/retry-attempt "0" && \
    kv put /system/queue/clissh/${Q_UUID}/worker/accepted "ready" && \
    kv prune /system/queue/template/${Q_UUID}
  else
    if [ ${Q_ATTEMPT} -lt ${Q_MAX_RETRIES} ] ; then
      echo "${TEMPLATE_CLI}: retrying ${Q_UUID} ${Q_ATTEMPT}/${Q_MAX_RETRIES}"
      kv put /system/queue/template/${Q_UUID}/worker/pid "" && \
      kv put /system/queue/template/${Q_UUID}/worker/host "" && \
      kv put /system/queue/template/${Q_UUID}/worker/retry-attempt "${Q_ATTEMPT}" && \
      kv put /system/queue/template/${Q_UUID}/worker/accepted "ready"
    else
      echo "${TEMPLATE_CLI}: failed ${Q_UUID} ${Q_ATTEMPT}/${Q_MAX_RETRIES}"
      kv put /system/queue/callback/${Q_UUID}/request-path "${Q_REQUEST_PATH}" && \
      kv put /system/queue/callback/${Q_UUID}/response-path "${Q_RESPONSE_PATH}" && \
      kv put /system/queue/callback/${Q_UUID}/worker/pid "" && \
      kv put /system/queue/callback/${Q_UUID}/worker/host "" && \
      kv put /system/queue/callback/${Q_UUID}/worker/retry-attempt "0" && \
      kv put /system/queue/callback/${Q_UUID}/worker/accepted "ready" && \
      kv prune /system/queue/onboard/${Q_UUID}
    fi
  fi
  echo "${TEMPLATE_CLI}: completed ${QUEUE[$Q]}"
  return ${RETVAL}
}

trap clean_exit INT
WAKE_INTERVAL=$(kv get /system/template/queue/interval)
while true ; do
  QUEUE=()
  readarray -t QUEUE < <(kv ls /system/queue/template)
  for ((Q = 0; Q < ${#QUEUE[@]}; ++Q)); do
    Q_IN_PROGRESS=$(kv get /system/queue/template/${QUEUE[$Q]}/worker/accepted)
    if [ -n "${Q_IN_PROGRESS}" ] ; then
      if [ "${Q_IN_PROGRESS,,}" == "ready" ] ; then
        kv put /system/queue/template/${QUEUE[$Q]}/worker/accepted "processing" && process "${QUEUE[$Q]}"
      fi
    fi
  done
  unset QUEUE

  sleep ${WAKE_INTERVAL} &>/dev/null &
  ONBOARD_WAIT_PID=$!
  wait ${ONBOARD_WAIT_PID}
done
clean_exit
