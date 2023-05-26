#!/bin/bash
CLI2KV_CLI="${0##*/}"
CLI2KV_VERSION="0.0.1"
CLI2KV_PATH=$(dirname "${0}")
RETVAL=0
TMP_DIR="/tmp"
KV_DELIMITER="/"
BLOCK_START=0
BLOCK_END=0
TENANT_ID="charter"
REGION_ID="georgia"
ZONE_ID="gainesville"
UUID=$(uuid -v 4)
UUID_GENERATED=0
UUID_MODIFIED=1
CLI_CONFIG=""
CLI_LINE=""
RANGE=()
SUB_RANGE=()

declare -a CLI_TEXT
declare -a CLI_BLOCK

usage() {
  local RETVAL=0
  echo "Usage: ${CLI2KV_CLI} --tenant={TENANT_ID} \ "
  echo "                     --region={REGION_ID} \ "
  echo "                     --zone={ZONE_ID} \ " 
  echo "                     --uuid={UUID} \ "
  echo "                     --cli={CLI config file}"
  echo ""
  return ${RETVAL}
}

clean_sigint() {
  local RETVAL=0
  echo "${CLI2KV_CLI}: aborting"
  if compgen -G "${TMP_DIR}/${CLI2KV_CLI}.$$.????????" >/dev/null ; then
    rm -f "${TMP_DIR}/${CLI2KV_CLI}.$$.????????" &>/dev/null
  fi
  exit ${RETVAL}
}

load() {
  local RETVAL=0
  CLI_TEXT=()
  if [ -f "${1}" ] ; then
    readarray CLI_TEXT < ${1}
    RETVAL=0
  else
    RETVAL=1
  fi
  return ${RETVAL}
}

dump() {
  local RETVAL=0
  local CLI_LINES=${#CLI_TEXT[@]}
  for ((L = 0; L < ${#CLI_TEXT[@]}; ++L)); do
    echo -n -e "[${L}/$(( ${#CLI_TEXT[@]} - 1))]\t\t"
    echo "${CLI_TEXT[$L]}"
  done
  return ${RETVAL}
}

# local XX_TMP=$(mktemp -q -p ${TMP_DIR} ${CLI2KV_CLI}.$$.XXXXXXXX)
block_to_file() {
  local RETVAL=0
  local BLOCK_FILE="${1}"
  if [ -f "${1}" ] ; then 
    for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
      echo "${CLI_BLOCK[$B]}"|sed '/^$/d'|sed "s/^ *//g" >> ${BLOCK_FILE}
    done
    RETVAL=0
  else
    RETVAL=1
  fi
  return ${RETVAL}
}

block_to_file() {
  local RETVAL=0
  local CLI_FILE="${1}"
  if [ -f "${1}" ] ; then 
    echo "${CLI_TEXT[*]}" > ${CLI_FILE}
    RETVAL=0
  else
    RETVAL=1
  fi
  return ${RETVAL}
}

tidy() {
  local RETVAL=0
  local TMP_SRC=$(mktemp -q -p ${TMP_DIR} ${CLI2KV_CLI}.$$.XXXXXXXX)
  local TMP_DST=$(mktemp -q -p ${TMP_DIR} ${CLI2KV_CLI}.$$.XXXXXXXX)
  local SIZE_SRC=${#CLI_TEXT[@]}
  local SIZE_DST=0
  echo "${CLI_TEXT[*]}" > ${TMP_SRC}
  CLI_TEXT=()
  if [ -f "${TMP_SRC}" ] ; then
    # no multi whitepace strip as destroys multi-line banners
    grep -v -P "^configure$" ${TMP_SRC}|grep -P -v "^end$"|grep -P -v "#.*$" |sed 's/\"/\\"/ig'|sed "s/configure //ig"|sed '/^$/d'|sed "s/^ *//g" > ${TMP_DST}
    if [ -f "${TMP_DST}" ] ; then
      readarray CLI_TEXT < ${TMP_DST}
      RETVAL=$?
      SIZE_DST=${#CLI_TEXT[@]}
    else
      RETVAL=1
    fi
  else
    RETVAL=1
  fi
  [[ -f "${TMP_SRC}" ]] && rm -f ${TMP_SRC} &> /dev/null
  [[ -f "${TMP_DST}" ]] && rm -f ${TMP_DST} &> /dev/null
  return ${RETVAL}
}

squeeze() {
  local RETVAL=0
  local TMP_SRC=$(mktemp -q -p ${TMP_DIR} ${CLI2KV_CLI}.$$.XXXXXXXX)
  local TMP_DST=$(mktemp -q -p ${TMP_DIR} ${CLI2KV_CLI}.$$.XXXXXXXX)
  local SIZE_SRC=${#CLI_TEXT[@]}
  local SIZE_DST=0
  echo "${CLI_TEXT[*]}"|sed '/^$/d'|sed "s/^ *//g" > ${TMP_SRC}
  CLI_TEXT=()
  if [ -f "${TMP_SRC}" ] ; then
    # multi whitepace strip 
    cat ${TMP_SRC}|tr -s ' ' > ${TMP_DST}
    if [ -f "${TMP_DST}" ] ; then
      readarray CLI_TEXT < ${TMP_DST}
      RETVAL=$?
      SIZE_DST=${#CLI_TEXT[@]}
    else
      RETVAL=1
    fi
  else
    RETVAL=1
  fi
  [[ -f "${TMP_SRC}" ]] && rm -f ${TMP_SRC} &> /dev/null
  [[ -f "${TMP_DST}" ]] && rm -f ${TMP_DST} &> /dev/null
  return ${RETVAL}
}

extract_block() {
  local RETVAL=0
  local REGEX_START=$(echo "${1}"|sed 's/\//\\\//ig')
  local REGEX_END="${2}"
  local PREFIX="${3}"
  local SUFFIX="${4}"
  local TMP_DST=$(mktemp -q -p ${TMP_DIR} ${CLI2KV_CLI}.$$.XXXXXXXX)
  local TMP_BLK=$(mktemp -q -p ${TMP_DIR} ${CLI2KV_CLI}.$$.XXXXXXXX)
  echo "${CLI_TEXT[*]}"|sed '/^$/d'|sed "s/^ *//g"|sed -n "/${REGEX_START}/I,/${REGEX_END}/I{p}" > ${TMP_DST}
  if [ -f "${TMP_BLK}" ] ; then
    cat ${TMP_DST}|head -n 1|tail -n 1|sed "s/^/${PREFIX} /ig"|tr -s ' ' > ${TMP_BLK}
    if [ -f "${TMP_BLK}" ] ; then
      readarray CLI_BLOCK < ${TMP_BLK}
      RETVAL=$?
    else
      RETVAL=1
    fi
  else
    RETVAL=1
  fi
  [[ -f "${TMP_DST}" ]] && rm -f ${TMP_DST} &> /dev/null
  [[ -f "${TMP_BLK}" ]] && rm -f ${TMP_BLK} &> /dev/null
  return ${RETVAL}
}

extract_line() {
  local RETVAL=0
  local TMP_SRC=$(mktemp -q -p ${TMP_DIR} ${CLI2KV_CLI}.$$.XXXXXXXX)
  local TMP_DST=$(mktemp -q -p ${TMP_DIR} ${CLI2KV_CLI}.$$.XXXXXXXX)
  local TMP_BLK=$(mktemp -q -p ${TMP_DIR} ${CLI2KV_CLI}.$$.XXXXXXXX)
  echo "${CLI_TEXT[*]}"|sed '/^$/d'|sed "s/^ *//g" > ${TMP_SRC}
  if [ -f "${TMP_SRC}" ] ; then
    # save existing block array, remove blank lines
    [[ ${#CLI_BLOCK[@]} -gt 0 ]] && echo "${CLI_BLOCK[*]}"|sed '/^$/d' >> ${TMP_BLK}
    # no multi whitepace strip and destroys multi-line banners
    grep -i -P "${1}" ${TMP_SRC}|sed '/^$/d'|sed "s/^ *//g" >> ${TMP_BLK}
    if [ -f "${TMP_BLK}" ] ; then
      readarray CLI_BLOCK < ${TMP_BLK}
      RETVAL=$?
      # remove what was extracted from original and replace original
      grep -v -i -P "${1}" ${TMP_SRC}|sed '/^$/d'|sed "s/^ *//g" > ${TMP_DST}
      if [ -f "${TMP_DST}" ] ; then
        CLI_TEXT=()
        readarray CLI_TEXT < ${TMP_DST}
        RETVAL=$?
      else
        RETVAL=1
      fi
    else
      RETVAL=1
    fi
  else
    RETVAL=1
  fi
  [[ -f "${TMP_DST}" ]] && rm -f ${TMP_DST} &> /dev/null
  [[ -f "${TMP_SRC}" ]] && rm -f ${TMP_SRC} &> /dev/null
  [[ -f "${TMP_BLK}" ]] && rm -f ${TMP_BLK} &> /dev/null
  return ${RETVAL}
}

extract_simple() {
  local RETVAL=0
  local CLI_INSTRUCT="${1,,}"
  local EXTRACT=0
  local RTRIM=0
  local LTRIM=0
  local INDEX=1
  local KV_PATH=1
  local CLI_VALUE=""
  local KV_CFG_PATH=""
  local INDEX_LABEL=""
  shift
  while [ $# -gt 0 ] ; do
    local OPTION="${1,,}"
    if [ "${OPTION,,}" == "--nortrim" ] ; then
      RTRIM=1
    elif [ "${OPTION,,}" == "--noltrim" ] ; then
      LTRIM=1
    elif [ "${OPTION,,}" == "--novalue" ] ; then
      EXTRACT=1
    elif [[ ${OPTION,,} =~ "--path=" ]] ; then
      KV_CFG_PATH="${OPTION##*=}"
      KV_PATH=0
    elif [[ "${OPTION,,}" =~ "--index" ]] ; then
      INDEX_LABEL="${OPTION##*=}"
      INDEX=0
    else
      CLI_INSTRUCT+=" ${OPTION}"
    fi
    shift
  done
  if [[ ${CLI_LINE,,} =~ ${CLI_INSTRUCT,,} ]] ; then
    [[ ${KV_PATH} -ne 0 ]] && KV_CFG_PATH="${CLI_INSTRUCT// /$KV_DELIMITER}"
    if [ ${EXTRACT} -eq 0 ] ; then
      CLI_VALUE="${CLI_LINE#*$CLI_INSTRUCT }"
      [[ ${LTRIM} -eq 0 ]] && CLI_VALUE="${CLI_VALUE#"${CLI_VALUE%%[![:space:]]*}"}"
      [[ ${RTRIM} -eq 0 ]] && CLI_VALUE="${CLI_VALUE%"${CLI_VALUE##*[![:space:]]}"}"
    fi
    if [ ${INDEX} -eq 0 ] ; then
      local CURRENT_INDEX=$(kv count /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${UUID}/config/${KV_CFG_PATH})
      local NEXT_INDEX=$(( CURRENT_INDEX + 1 ))
      KV_CFG_PATH+="${KV_DELIMITER}${NEXT_INDEX}${KV_DELIMITER}${INDEX_LABEL}"
    fi
    kv put "/${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${UUID}/config/${KV_CFG_PATH,,}" "${CLI_VALUE}"
    RETVAL=$?
  fi
  return ${RETVAL}
}

extract_pair() {
  local RETVAL=0
  local CLI_INSTRUCT="${1,,}"
  local VERB_POSITION=0
  local VALUE_POSITION=0
  local KV_CFG_PATH=""
  local INDEX=1
  local INDEX_APPEND=1
  shift
  while [ $# -gt 0 ] ; do
    local OPTION="${1,,}"
    if [[ ${OPTION,,} =~ "--verb" ]] ; then
      VERB_POSITION=$(( ${OPTION##*=} - 1 ))
    elif [[ ${OPTION,,} =~ "--value" ]] ; then
      VALUE_POSITION=$(( ${OPTION##*=} - 1 ))
    elif [[ ${OPTION,,} =~ "--path=" ]] ; then
      KV_CFG_PATH="${OPTION##*=}"
    elif [[ ${OPTION,,} == "--append" ]] ; then
      INDEX_APPEND=0
    elif [[ "${OPTION,,}" == "--index" ]] ; then
      INDEX=0
    fi
    shift
  done
  if [[ ${CLI_LINE,,} =~ ${CLI_INSTRUCT,,} ]] ; then
    read -ra WORDS <<< "${CLI_LINE}"
    local CLI_VERB=${WORDS[$VERB_POSITION]}
    local CLI_VALUE=${WORDS[$VALUE_POSITION]}
    if [ ${INDEX} -eq 0 ] ; then
      local INDEX_POSITION=$(kv count /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${UUID}/config/${KV_CFG_PATH})
      [[ ${INDEX_APPEND} -eq 1 ]] && INDEX_POSITION=$(( INDEX_POSITION + 1 ))
      KV_CFG_PATH+="${KV_DELIMITER}${INDEX_POSITION}${KV_DELIMITER}${CLI_VERB}"
    else
      KV_CFG_PATH+="${KV_DELIMITER}${CLI_VERB}"
    fi
    kv put "/${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${UUID}/config/${KV_CFG_PATH,,}" "${CLI_VALUE}"
    RETVAL=$?
  fi
  return ${RETVAL}
}

extract_last_pair() {
  local RETVAL=0
  local INDEX=1
  local INDEX_LABEL=""
  local CLI_INSTRUCT="${1,,}"
  shift
  while [ $# -gt 0 ] ; do
    local OPTION=""
    if [[ "${OPTION,,}" =~ "--index=" ]] ; then
      INDEX=0
      INDEX_LABEL="${OPTION##*=}"
    else
      CLI_INSTRUCT+=" ${1,,}"
    fi
    shift
  done
  if [[ ${CLI_LINE,,} =~ ${CLI_INSTRUCT,,} ]] ; then
    read -ra WORDS <<< "${CLI_LINE}"
    local WORD_Z=${#WORDS[@]}
    local WORD_Y=$(( $WORD_Z - 1 ))
    local WORD_X=$(( $WORD_Y - 1 ))
    local LAST_CLI_VERB=${WORDS[$WORD_X]}
    local CLI_VALUE=${WORDS[$WORD_Y]}
    local KV_CFG_PATH="${CLI_INSTRUCT// /$KV_DELIMITER}"
    KV_CFG_PATH+="${KV_DELIMITER}${LAST_CLI_VERB}"
    if [ ${INDEX} -eq 0 ] ; then
      local CURRENT_INDEX=$(kv count /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${UUID}/config/${KV_CFG_PATH})
      local NEXT_INDEX=$(( CURRENT_INDEX + 1 ))
      KV_CFG_PATH+="${KV_DELIMITER}${NEXT_INDEX}${KV_DELIMITER}${INDEX_LABEL}"
    fi
    kv put "/${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${UUID}/config/${KV_CFG_PATH,,}" "${CLI_VALUE}"
    RETVAL=$?
  fi
  return ${RETVAL}
}

cfg_header() {
  local RETVAL=0
  if [ ${#CLI_TEXT[@]} -gt 0 ] ; then
    if [[ -v CLI_TEXT[0] ]] ; then
      if [[ ${CLI_TEXT[0]} =~ ^#[[:space:]]ChassisType=\<.* ]] ; then
        local CHASSIS_TYPE=$(echo "${CLI_TEXT[0]}"|cut -d"<" -f2|cut -d">" -f1)
        local SHELF_NAME=$(echo "${CLI_TEXT[0]}"|cut -d"<" -f3|cut -d">" -f1)
        local SHELF_SW_NAME=$(echo "${CLI_TEXT[0]}"|cut -d"<" -f4|cut -d">" -f1)
        local TIME_GENERATED=$(echo "${CLI_TEXT[0]}"|cut -d"<" -f5|cut -d">" -f1)
        kv put "/${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${UUID}/config/chassis-type" "${CHASSIS_TYPE}"
        kv put "/${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${UUID}/config/shelf/name" "${SHELF_NAME}"
        kv put "/${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${UUID}/config/shelf/software-version" "${SHELF_SW_NAME}"
        kv put "/${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${UUID}/config/time-generated" "${TIME_GENERATED}"
        RETVAL=0
      else
        RETVAL=1
      fi
    else
      RETVAL=1
    fi
  else
    RETVAL=1
  fi
  return ${RETVAL}
}

cfg_crypto_block() {
  local RETVAL=0
  local TMP_SRC=$(mktemp -q -p ${TMP_DIR} ${CLI2KV_CLI}.$$.XXXXXXXX)
  local TMP_BLK=$(mktemp -q -p ${TMP_DIR} ${CLI2KV_CLI}.$$.XXXXXXXX)
  local CERT_NAME="${1:-root}"
  local CERT_INDEX=1
  echo "${CLI_TEXT[*]}"|sed '/^$/d'|sed -e "s/^ *//g" > ${TMP_SRC}
  if [ -f "${TMP_SRC}" ] ; then
    sed -n "/crypto\sprivacy\sadd-certificate\s${CERT_NAME}\snsi\s${CERT_INDEX}/,/end$/{p}" ${TMP_SRC}|grep -v -P "^crypto\sprivacy\sadd-certificate\s${CERT_NAME}\snsi\s${CERT_INDEX}.*"|grep -v -P "^/end$"|sed '/^$/d'|sed "s/^ *//g" > ${TMP_BLK}
    if [ -f "${TMP_BLK}" ] ; then
      readarray CLI_BLOCK < ${TMP_BLK}
      for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
        local KV_CFG_PATH="credentials/certificate/${CERT_NAME}/nsi/${CERT_INDEX}"
        local CURRENT_INDEX=$(kv count /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${UUID}/config/${KV_CFG_PATH})
        local NEXT_INDEX=$(( CURRENT_INDEX + 1 ))
        kv put "/${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${UUID}/config/${KV_CFG_PATH,,}/${NEXT_INDEX}/line" "${CLI_BLOCK[$B]}"
      done
      RETVAL=0
    else
      RETVAL=1
    fi
  else
    RETVAL=1
  fi
  [[ -f "${TMP_SRC}" ]] && rm -f ${TMP_SRC} &> /dev/null
  [[ -f "${TMP_BLK}" ]] && rm -f ${TMP_BLK} &> /dev/null
  return ${RETVAL}
}

cfg_banner_block() {
  local RETVAL=0
  local BANNER_NAME="${1:-login}"
  local TMP_SRC=$(mktemp -q -p ${TMP_DIR} ${CLI2KV_CLI}.$$.XXXXXXXX)
  local TMP_BLK=$(mktemp -q -p ${TMP_DIR} ${CLI2KV_CLI}.$$.XXXXXXXX)

  echo "${CLI_TEXT[*]}"|sed '/^$/d'|sed -e "s/^ *//g" > ${TMP_SRC}
  if [ -f "${TMP_SRC}" ] ; then
    local EXISTS=$(grep -i -P "^banner\s{1,}${BANNER_NAME}.*$" ${TMP_SRC}|wc -l)
    if [[ ${EXISTS} -gt 0 ]] ; then
      sed -n "/banner\s${BANNER_NAME}.*/I,/end$/I{p}" ${TMP_SRC} | \
        grep -i -v -P "^banner\s{1,}${BANNER_NAME}.*$" | \
        grep -i -v -P "^/end$" | \
        sed '/^$/d' | \
        sed "s/^ *//g" > ${TMP_BLK}

      if [ -f "${TMP_BLK}" ] ; then
        readarray CLI_BLOCK < ${TMP_BLK}
        for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
          local KV_CFG_PATH="banner/${BANNER_NAME}"
          local CURRENT_INDEX=$(kv count /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${UUID}/config/${KV_CFG_PATH})
          local NEXT_INDEX=$(( CURRENT_INDEX + 1 ))
          kv put "/${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${UUID}/config/${KV_CFG_PATH,,}/${NEXT_INDEX}/line" "${CLI_BLOCK[$B]}"
        done
        RETVAL=0
      else
        RETVAL=1
      fi
    else
      RETVAL=1
    fi
  else
    RETVAL=1
  fi
  [[ -f "${TMP_SRC}" ]] && rm -f ${TMP_SRC} &> /dev/null
  [[ -f "${TMP_BLK}" ]] && rm -f ${TMP_BLK} &> /dev/null
  return ${RETVAL}
}

cfg_access_list() {
  local RETVAL=0
  local ACL_NUMBER="${1:-0}"
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_simple "access-list ${ACL_NUMBER} permit" --index=permit --nortrim --noltrim --path=access-list/${ACL_NUMBER}
    extract_simple "access-list ${ACL_NUMBER} deny" --index=deny --nortrim --noltrim --path=access-list/${ACL_NUMBER}
    extract_simple "access-list ${ACL_NUMBER} remark" --index=remark --nortrim --noltrim --path=access-list/${ACL_NUMBER}
    extract_simple "access-list ${ACL_NUMBER} enable-accounting" --index=enable-accounting --nortrim --noltrim --path=access-list/${ACL_NUMBER}
  done
  return ${RETVAL}
}

cfg_priv_exec_group() {
  # level between 0-15
  local RETVAL=0
  local LEVEL_NUMBER="${1:-0}"
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_simple "privilege exec level ${LEVEL_NUMBER} " --index=text --nortrim --noltrim --path=privilege/exec/level/${LEVEL_NUMBER}/line
  done
  RETVAL=0
  return ${RETVAL}
}


cfg_cable_modulation_profile() {
  local RETVAL=0
  local PROFILE="${1:-0}"
  local IUC="${2:-0}"
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_pair "cable modulation-profile ${PROFILE} iuc ${IUC} mod" --verb=6 --value=7 --path=cable/modulation-profile/${PROFILE}/iuc/${IUC}
    extract_pair "cable modulation-profile ${PROFILE} iuc ${IUC} mod" --verb=8 --value=9 --path=cable/modulation-profile/${PROFILE}/iuc/${IUC}/mod
    extract_pair "cable modulation-profile ${PROFILE} iuc ${IUC} mod" --verb=10 --value=11 --path=cable/modulation-profile/${PROFILE}/iuc/${IUC}/mod
    extract_pair "cable modulation-profile ${PROFILE} iuc ${IUC} mod" --verb=12 --value=13 --path=cable/modulation-profile/${PROFILE}/iuc/${IUC}/mod
    extract_pair "cable modulation-profile ${PROFILE} iuc ${IUC} mod" --verb=14 --value=15 --path=cable/modulation-profile/${PROFILE}/iuc/${IUC}/mod
    extract_pair "cable modulation-profile ${PROFILE} iuc ${IUC} mod" --verb=16 --value=17 --path=cable/modulation-profile/${PROFILE}/iuc/${IUC}/mod
    extract_pair "cable modulation-profile ${PROFILE} iuc ${IUC} mod" --verb=18 --value=19 --path=cable/modulation-profile/${PROFILE}/iuc/${IUC}/mod
    extract_pair "cable modulation-profile ${PROFILE} iuc ${IUC} mod" --verb=20 --value=21 --path=cable/modulation-profile/${PROFILE}/iuc/${IUC}/mod
    extract_pair "cable modulation-profile ${PROFILE} iuc ${IUC} mod" --verb=22 --value=23 --path=cable/modulation-profile/${PROFILE}/iuc/${IUC}/mod
    extract_pair "cable modulation-profile ${PROFILE} iuc ${IUC} mod" --verb=24 --value=25 --path=cable/modulation-profile/${PROFILE}/iuc/${IUC}/mod
    extract_pair "cable modulation-profile ${PROFILE} iuc ${IUC} mod" --verb=26 --value=27 --path=cable/modulation-profile/${PROFILE}/iuc/${IUC}/mod

    extract_pair "cable modulation-profile ${PROFILE} iuc ${IUC} pre-len" --verb=6 --value=7 --path=cable/modulation-profile/${PROFILE}/iuc/${IUC}
    extract_pair "cable modulation-profile ${PROFILE} iuc ${IUC} pre-len" --verb=8 --value=9 --path=cable/modulation-profile/${PROFILE}/iuc/${IUC}/pre-len
    extract_pair "cable modulation-profile ${PROFILE} iuc ${IUC} pre-len" --verb=10 --value=11 --path=cable/modulation-profile/${PROFILE}/iuc/${IUC}/pre-len
    extract_pair "cable modulation-profile ${PROFILE} iuc ${IUC} pre-len" --verb=12 --value=13 --path=cable/modulation-profile/${PROFILE}/iuc/${IUC}/pre-len
    extract_pair "cable modulation-profile ${PROFILE} iuc ${IUC} pre-len" --verb=14 --value=15 --path=cable/modulation-profile/${PROFILE}/iuc/${IUC}/pre-len
    extract_pair "cable modulation-profile ${PROFILE} iuc ${IUC} pre-len" --verb=16 --value=17 --path=cable/modulation-profile/${PROFILE}/iuc/${IUC}/pre-len
    extract_pair "cable modulation-profile ${PROFILE} iuc ${IUC} pre-len" --verb=18 --value=19 --path=cable/modulation-profile/${PROFILE}/iuc/${IUC}/pre-len
    extract_pair "cable modulation-profile ${PROFILE} iuc ${IUC} pre-len" --verb=20 --value=21 --path=cable/modulation-profile/${PROFILE}/iuc/${IUC}/pre-len
    extract_pair "cable modulation-profile ${PROFILE} iuc ${IUC} pre-len" --verb=22 --value=23 --path=cable/modulation-profile/${PROFILE}/iuc/${IUC}/pre-len
    extract_pair "cable modulation-profile ${PROFILE} iuc ${IUC} pre-len" --verb=24 --value=25 --path=cable/modulation-profile/${PROFILE}/iuc/${IUC}/pre-len
    extract_pair "cable modulation-profile ${PROFILE} iuc ${IUC} pre-len" --verb=26 --value=27 --path=cable/modulation-profile/${PROFILE}/iuc/${IUC}/pre-len

    extract_pair "cable modulation-profile ${PROFILE} iuc ${IUC} pre-type" --verb=6 --value=7 --path=cable/modulation-profile/${PROFILE}/iuc/${IUC}
    extract_pair "cable modulation-profile ${PROFILE} iuc ${IUC} pre-type" --verb=8 --value=9 --path=cable/modulation-profile/${PROFILE}/iuc/${IUC}/pre-type
    extract_pair "cable modulation-profile ${PROFILE} iuc ${IUC} pre-type" --verb=8 --value=9 --path=cable/modulation-profile/${PROFILE}/iuc/${IUC}/pre-type
    extract_pair "cable modulation-profile ${PROFILE} iuc ${IUC} pre-type" --verb=10 --value=11 --path=cable/modulation-profile/${PROFILE}/iuc/${IUC}/pre-type
  done
  RETVAL=0
  return ${RETVAL}
}

cfg_cable_filter_group() {
  local RETVAL=0
  local GROUP_NUMBER="${1:-0}"
  local INDEX_NUMBER="${2:-0}"
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_simple "cable filter group ${GROUP_NUMBER} index ${INDEX_NUMBER} src-port" --index=src-port --path=cable/filter/group/${GROUP_NUMBER}/index/${INDEX_NUMBER}
    extract_simple "cable filter group ${GROUP_NUMBER} index ${INDEX_NUMBER} dest-port" --index=dest-port --path=cable/filter/group/${GROUP_NUMBER}/index/${INDEX_NUMBER}
    extract_simple "cable filter group ${GROUP_NUMBER} index ${INDEX_NUMBER} ip-proto" --index=ip-proto --path=cable/filter/group/${GROUP_NUMBER}/index/${INDEX_NUMBER}
    extract_simple "cable filter group ${GROUP_NUMBER} index ${INDEX_NUMBER} match-action" --index=match-action --path=cable/filter/group/${GROUP_NUMBER}/index/${INDEX_NUMBER}
  done
  RETVAL=0
  return ${RETVAL}
}

cfg_dsq_ds_freq_list() {
  local RETVAL=0
  local LIST_NUMBER="${1:-0}"
  local INDEX_NUMBER="${2:-0}"
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_simple "cable dsg ds-frequency-list ${LIST_NUMBER} index ${INDEX_NUMBER} frequency"
  done
  RETVAL=0
  return ${RETVAL}
}

cfg_cable_load_balance() {
  local RETVAL=0
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_simple "cable load-balance downstream-start-threshold"
    extract_simple "cable load-balance upstream-start-threshold"
    extract_simple "cable load-balance utilization-modems-to-check"
    extract_simple "cable load-balance failed-list timeout"
    extract_simple "cable load-balance failed-list exclude-count"
    extract_simple "cable load-balance general-group-defaults" --no-value             
    extract_pair "cable load-balance rule" --verb=4 --value=5 --path=cable/load-balance/rule --index
    extract_pair "cable load-balance rule" --verb=6 --value=7 --path=cable/load-balance/rule --index --append
    extract_pair "cable load-balance include cm-mac" --verb=4 --value=5 --path=cable/load-balance/include --index
    extract_pair "cable load-balance include cm-mac" --verb=6 --value=7 --path=cable/load-balance/include --index --append
    extract_pair "cable load-balance include cm-mac" --verb=8 --value=9 --path=cable/load-balance/include --index --append
  done
  RETVAL=0
  return ${RETVAL}
}

cfg_license_type() {
  local RETVAL=0
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_pair "license type downstream-service-group key" --verb=4 --value=5 --path=license/downstream-service-group
    extract_pair "license type downstream-service-group key" --verb=6 --value=7 --path=license/downstream-service-group
    extract_pair "license type upstream-service-group key" --verb=4 --value=5 --path=license/upstream-service-group
    extract_pair "license type upstream-service-group key" --verb=6 --value=7 --path=license/upstream-service-group
    extract_pair "license type mac-docsis-ds-30-b key" --verb=4 --value=5 --path=license/mac-docsis-ds-30-b
    extract_pair "license type mac-docsis-ds-30-b key" --verb=6 --value=7 --path=license/mac-docsis-ds-30-b
    extract_pair "license type mac-docsis-us-30 key" --verb=4 --value=5 --path=license/mac-docsis-us-30
    extract_pair "license type mac-docsis-us-30 key" --verb=6 --value=7 --path=license/mac-docsis-us-30
    extract_pair "license type mac-docsis-ds-ofdm key" --verb=4 --value=5 --path=license/mac-docsis-ds-ofdm
    extract_pair "license type mac-docsis-ds-ofdm key" --verb=6 --value=7 --path=license/mac-docsis-ds-ofdm
    extract_pair "license type mac-docsis-us-ofdma key" --verb=4 --value=5 --path=license/mac-docsis-us-ofdma
    extract_pair "license type mac-docsis-us-ofdma key" --verb=6 --value=7 --path=license/mac-docsis-us-ofdma
    extract_pair "license type system-legal-intercept key" --verb=4 --value=5 --path=license/system-legal-intercept
    extract_pair "license type system-legal-intercept key" --verb=6 --value=7 --path=license/system-legal-intercept
    extract_pair "license type system-laes key" --verb=4 --value=5 --path=license/system-laes
    extract_pair "license type system-laes key" --verb=6 --value=7 --path=license/system-laes
    extract_pair "license type system-calea key" --verb=4 --value=5 --path=license/system-calea
    extract_pair "license type system-calea key" --verb=6 --value=7 --path=license/system-calea
    extract_pair "license type video-ncast-b key" --verb=4 --value=5 --path=license/video-ncast-b
    extract_pair "license type video-ncast-b key" --verb=6 --value=7 --path=license/video-ncast-b
    extract_pair "license type video-ncast-b spare-count" --verb=4 --value=5 --path=license/video-ncast-b
    extract_pair "license type docsis-upstream-30 key" --verb=4 --value=5 --path=license/docsis-upstream-30
    extract_pair "license type docsis-upstream-30 key" --verb=6 --value=7 --path=license/docsis-upstream-30
    extract_pair "license type docsis-upstream-30 spare-count" --verb=4 --value=5 --path=license/docsis-upstream-30
  done
  RETVAL=0
  return ${RETVAL}
}

cfg_line_vty_console() {
  local RETVAL=0
  local LINE_TYPE="${1,,:-console}"
  local LINE_NUMBER="${2:-0}"
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_simple "line ${LINE_TYPE} ${LINE_NUMBER} session-timeout"  --path=line/${LINE_TYPE}/${LINE_NUMBER}/session-timeout
    extract_simple "line ${LINE_TYPE} ${LINE_NUMBER} idle-timeout" --path=line/${LINE_TYPE}/${LINE_NUMBER}/idle-timeout
    extract_simple "line ${LINE_TYPE} ${LINE_NUMBER} width" --path=line/${LINE_TYPE}/${LINE_NUMBER}/width
    extract_simple "line ${LINE_TYPE} ${LINE_NUMBER} length" --path=line/${LINE_TYPE}/${LINE_NUMBER}/length
    extract_simple "line ${LINE_TYPE} ${LINE_NUMBER} password" --path=line/${LINE_TYPE}/${LINE_NUMBER}/password
    extract_pair "line ${LINE_TYPE} ${LINE_NUMBER} authentication" --verb=5 --value=6 --path=line/${LINE_TYPE}/${LINE_NUMBER}/authentication --index
    extract_pair "line ${LINE_TYPE} ${LINE_NUMBER} authorization" --verb=5 --value=6 --path=line/${LINE_TYPE}/${LINE_NUMBER}/authorization --index
  done
  RETVAL=0
  return ${RETVAL}
}

cfg_interface() {
  local RETVAL=0
  local DELETE=1
  local INT_TYPE="${1}"
  local INT_ID="${2}"
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    case ${INT_TYPE,,} in
      cable-downstream|cable-upstream)
        extract_pair "interface ${INT_TYPE} ${INT_ID} video service-group" --verb=5 --value=6 --path=interface/${INT_TYPE}/${INT_ID}/video/service-group --index
        extract_pair "interface ${INT_TYPE} ${INT_ID} video service-group" --verb=7 --value=8 --path=interface/${INT_TYPE}/${INT_ID}/video/service-group --index --append
        extract_pair "interface ${INT_TYPE} ${INT_ID} video virtual-edge" --verb=5 --value=6 --path=interface/${INT_TYPE}/${INT_ID}/video/virtual-edge --index
        extract_pair "interface ${INT_TYPE} ${INT_ID} video virtual-edge" --verb=7 --value=8 --path=interface/${INT_TYPE}/${INT_ID}/video/virtual-edge --index --append
        extract_simple "interface ${INT_TYPE} ${INT_ID} video subtype"
        extract_simple "interface ${INT_TYPE} ${INT_ID} video frequency"
        extract_simple "interface ${INT_TYPE} ${INT_ID} video udp-block"
        extract_simple "interface ${INT_TYPE} ${INT_ID} video interleave-depth"
        extract_simple "interface ${INT_TYPE} ${INT_ID} video" "no shutdown" --novalue
        extract_simple "interface ${INT_TYPE} ${INT_ID} cable" "no shutdown" --novalue
        extract_simple "interface ${INT_TYPE} ${INT_ID} cable" "cable-mac"
        extract_simple "interface ${INT_TYPE} ${INT_ID} cable" "channel-id"
        extract_simple "interface ${INT_TYPE} ${INT_ID} cable" "attribute-mask" "value"
        extract_simple "interface ${INT_TYPE} ${INT_ID} cable" "primary-capable"
        extract_simple "interface ${INT_TYPE} ${INT_ID} cable" "frequency"
        extract_simple "interface ${INT_TYPE} ${INT_ID} cable" "interleave-depth"
        extract_simple "interface ${INT_TYPE} ${INT_ID} cable" "power-adjust"
        extract_simple "interface ${INT_TYPE} ${INT_ID} cable" "max-round-trip-delay"
        extract_simple "interface ${INT_TYPE} ${INT_ID} cable" "modulation"
        extract_simple "interface ${INT_TYPE} ${INT_ID} cable" "voice-limits"
        extract_simple "interface ${INT_TYPE} ${INT_ID} cable dsg" "vsp-list"
        extract_simple "interface ${INT_TYPE} ${INT_ID} cable dsg" "ds-frequency-list"
        extract_simple "interface ${INT_TYPE} ${INT_ID} cable dsg" "timer-list"
        extract_simple "interface ${INT_TYPE} ${INT_ID} cable dsg" "dcd-enable"
        extract_pair "interface ${INT_TYPE} ${INT_ID} cable voice-limmits allowed-total" --verb=6 --value=7 --path=interface/${INT_TYPE}/${INT_ID}/cable/voice/voice-limits
        extract_pair "interface ${INT_TYPE} ${INT_ID} cable voice-limmits allowed-total" --verb=8 --value=9 --path=interface/${INT_TYPE}/${INT_ID}/cable/voice/voice-limits
        extract_pair "interface ${INT_TYPE} ${INT_ID} cable voice-limmits allowed-total" --verb=10 --value=11 --path=interface/${INT_TYPE}/${INT_ID}/cable/voice/voice-limits
        extract_pair "interface ${INT_TYPE} ${INT_ID} cable voice-limmits allowed-total" --verb=12 --value=13 --path=interface/${INT_TYPE}/${INT_ID}/cable/voice/voice-limits
        extract_pair "interface ${INT_TYPE} ${INT_ID} cable voice-limmits allowed-total" --verb=13 --value=14 --path=interface/${INT_TYPE}/${INT_ID}/cable/voice/voice-limits
        extract_last_pair "interface ${INT_TYPE} ${INT_ID} dsg cable"
        extract_last_pair "interface ${INT_TYPE} ${INT_ID} cable"
        ;;
      ethernet)
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "description"
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "pre-shared-key" "cak"
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "pre-shared-key" "encrypted-cak"
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "macsec" "mode"
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "fec"
        extract_pair "interface ${INT_TYPE} ${INT_ID} ip address" --verb=5 --value=6 --path=interface/${INT_TYPE}/${INT_ID}/ip
        extract_pair "interface ${INT_TYPE} ${INT_ID} ip address" --verb=5 --value=7 --path=interface/${INT_TYPE}/${INT_ID}/ip/mask
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "ip vrf"
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "ipv6 address"
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "ipv6 enable" --novalue
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "shutdown" --novalue
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "no shutdown" --novalue
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "no gratuitous-arp" --novalue
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "gratuitous-arp" --novalue
        # need to add access-group, directed-broadcast, igmp, inband, pim, rip, unreachables, vrf
        ;;
      link-aggregate)
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "description"
        extract_pair "interface ${INT_TYPE} ${INT_ID} ip address" --verb=5 --value=6 --path=interface/${INT_TYPE}/${INT_ID}/ip
        extract_pair "interface ${INT_TYPE} ${INT_ID} ip address" --verb=5 --value=7 --path=interface/${INT_TYPE}/${INT_ID}/ip/mask
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "ipv6 address"
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "ipv6 enable" --novalue
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "shutdown" --novalue
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "no shutdown" --novalue
          ;;
      loopback)
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "description"
        extract_pair "interface ${INT_TYPE} ${INT_ID} ip address" --verb=5 --value=6 --path=interface/${INT_TYPE}/${INT_ID}/ip
        extract_pair "interface ${INT_TYPE} ${INT_ID} ip address" --verb=5 --value=7 --path=interface/${INT_TYPE}/${INT_ID}/ip/mask
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "ipv6 address"
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "ipv6 enable" --novalue
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "shutdown" --novalue
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "no shutdown" --novalue
          ;;
      mgmt)
        extract_last_pair "interface ${INT_TYPE} ${INT_ID}" "ip dhcp"
        extract_last_pair "interface ${INT_TYPE} ${INT_ID}" "ipv6" "dhcp"
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "shutdown" --novalue
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "no shutdown" --novalue
          ;;
      null)
        extract_last_pair "interface ${INT_TYPE} ${INT_ID}" "ip"
        extract_last_pair "interface ${INT_TYPE} ${INT_ID}" "ipv6" "icmp unreachables"
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "shutdown" --novalue
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "no shutdown" --novalue
          ;;
      cable-mac)
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "description"
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "cable" "freq-us-max"
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "cable" "us-freq-range"
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "cable" "tftp-enforce" --novalue
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "cable" "dynamic-secret"
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "cable" "cm-ip-prov-mode"
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "cable" "verbose-cm-rcp" --novalue
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "cable" "dynamic-rcc" --novalue
        extract_last_pair "interface ${INT_TYPE} ${INT_ID}" "cable" "upstream-bonding-group"
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "cable" "mult-tx-chl-mode" --novalue
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "cable" "upstream" "ranging-poll"
        extract_pair "interface ${INT_TYPE} ${INT_ID} cable cm-status event-type" --verb=6 --value=7 --path=interface/${INT_TYPE}/${INT_ID}/cable/cm-status/event-type
        extract_pair "interface ${INT_TYPE} ${INT_ID} cable cm-status event-type" --verb=8 --value=9 --path=interface/${INT_TYPE}/${INT_ID}/cable/cm-status/event-type --append
        extract_pair "interface ${INT_TYPE} ${INT_ID} ip address" --verb=5 --value=6 --path=interface/${INT_TYPE}/${INT_ID}/ip
        extract_pair "interface ${INT_TYPE} ${INT_ID} ip address" --verb=5 --value=7 --path=interface/${INT_TYPE}/${INT_ID}/ip/mask
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "ipv6 address"
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "ipv6 enable" --novalue
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "shutdown" --novalue
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "no shutdown" --novalue
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "proxy-arp" --novalue
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "restricted-proxy-arp" --novalue
        ;;
      rpd)
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "description"
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "ds-conn" "0" # ....
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "ds-conn" "1" # ....
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "shutdown" --novalue
        extract_simple "interface ${INT_TYPE} ${INT_ID}" "no shutdown" --novalue
        ;;
      *) 
        ;;
    esac
  done
  RETVAL=0
  return ${RETVAL}
}

cfg_console() {
  local RETVAL=0
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_simple "console enable" --novalue
  done
  RETVAL=0
  return ${RETVAL}
}

cfg_clock() {
  local RETVAL=0
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_simple "clock" "mode"
  done
  RETVAL=0
  return ${RETVAL}
}

cfg_video_global() {
  local RETVAL=0
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    # specific to RPD not available on RMD
    extract_simple "video global" "interval" "pat"
    extract_simple "video global" "interval" "pmt"
    extract_simple "video global" "jitter-depth"
    extract_simple "video global" "over-subscription"
    extract_simple "video global" "fast-psi-update"
    extract_simple "video global" "tsid-uniqueness"
    extract_simple "video global" "erm-protocol"
    extract_simple "video global" "erm-session" "server-port"
    extract_simple "video global" "pid-remap-scheme"
    extract_simple "video global" "pre-encrypt-detect"
    extract_simple "video global" "program-conflict"
    extract_simple "video global" "timeout" "vod-session" "close"
    extract_simple "video global" "timeout" "multicast-session" "close"
    extract_simple "video global" "max-programs"
    extract_simple "video global" "generate-tbvod-empty-sdt"
    extract_simple "video global" "udp-port-offset"
    extract_simple "video global" "base-remap-pid"
    extract_simple "video global" "multicast"
    extract_simple "video global" "scs" "codeword" 
    extract_simple "video global" "scs" "ecmg-channel-id-start"
  done
  RETVAL=0
  return ${RETVAL}
}

cfg_ofdm_global() {
  local RETVAL=0
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
      extract_simple "ofdm global" "plc-dpd-ocd-interval"
      extract_simple "ofdm global" "profile0-dpd-interval"
      extract_simple "ofdm global" "enable-short-codewords" --novalue
  done
  RETVAL=0
  return ${RETVAL}
}

cfg_ofdm_profile_mgmt() {
  local RETVAL=0
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_simple "ofdm profile-mgmt" "modulation-margin" "16qam" "mer-adjust"
    extract_simple "ofdm profile-mgmt" "modulation-margin" "32qam" "mer-adjust"
    extract_simple "ofdm profile-mgmt" "modulation-margin" "64qam" "mer-adjust"
    extract_simple "ofdm profile-mgmt" "modulation-margin" "128qam" "mer-adjust" 
    extract_simple "ofdm profile-mgmt" "modulation-margin" "256qam" "mer-adjust" 
    extract_simple "ofdm profile-mgmt" "modulation-margin" "512qam" "mer-adjust" 
    extract_simple "ofdm profile-mgmt" "modulation-margin" "1024am" "mer-adjust" 
    extract_simple "ofdm profile-mgmt" "threshold" 
    extract_simple "ofdm profile-mgmt" "retry-interval" 
    extract_simple "ofdm profile-mgmt" "guard-time" 
    extract_simple "ofdm profile-mgmt" "max-retries" 
  done
  RETVAL=0
  return ${RETVAL}
}

cfg_ip_ssh() {
  local RETVAL=0
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_simple "ip ssh" "port"
    extract_simple "ip ssh" "idle-timeout"
    extract_simple "ip ssh" "max-clients"
    extract_simple "ip ssh"  "no" "password-auth-req" --novalue
    extract_simple "ip ssh" "public-key-auth" --novalue
    extract_simple "ip ssh" "no" "public-key-auth-req" --novalue
    extract_simple "ip ssh" "no" "public-key-auth-first" --novalue
    extract_simple "ip ssh" "max-auth-fail"
    extract_simple "ip ssh" "login" --novalue
    extract_simple "ip ssh" "sftp" --novalue
    extract_simple "ip ssh" "key-source" "certificate"
    extract_simple "ip ssh" "ciphers" --nortrim --noltrim
    extract_simple "ip ssh" "no" "port-forwarding" --novalue
    extract_simple "ip ssh" "key-exchange"
    extract_simple "ip ssh" "shutdown" --novalue
    extract_simple "ip ssh" "password-auth" --novalue
    extract_simple "ip ssh" "public-key-auth" --novalue
    extract_simple "ip ssh" "idle-timeout"
  done
  RETVAL=0
  return ${RETVAL}
}

cfg_snmp_server() {
  local RETVAL=0
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_last_pair "snmp-server card-trap-inh" "slot"
    extract_last_pair "snmp-server card-trap-inh" "ethernet"
    extract_last_pair "snmp-server port-trap-inh" "mgmt"
    extract_simple "snmp-server data" "snmp-agent" "max-read-ahead"
    extract_simple "snmp-server data" "snmp-agent" "refresh-time"
    extract_simple "snmp-server data" "max-read-ahead"
    extract_simple "snmp-server data" "refresh-time"
    extract_simple "snmp-server contact"
    extract_simple "snmp-server location"
    extract_simple "snmp-server enable traps"
  done
  RETVAL=0
  return ${RETVAL}
}

cfg_ntp() {
  local RETVAL=0
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_pair "ntp server" --verb=2 --value=3 --path=ntp/server --index
    extract_pair "ntp server" --verb=4 --value=5 --path=ntp/server --index --append
    extract_pair "ntp server" --verb=6 --value=7 --path=ntp/server --index --append
    extract_pair "ntp server" --verb=8 --value=9 --path=ntp/server --index --append
    extract_pair "ntp server" --verb=10 --value=11 --path=ntp/server --index --append
    extract_simple "ntp" "authentication" 
    extract_simple "ntp" "maxpoll"
  done
  RETVAL=0
  return ${RETVAL}
}

cfg_overlay_downstream() {
  local RETVAL=0
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_simple "overlay downstream" "attenuator"
    extract_simple "overlay downstream" "hysteresis"
    extract_simple "overlay downstream" "optical-agc" "attenuator-reference"
    extract_simple "overlay downstream" "optical-agc" "input-power-reference"
    extract_simple "overlay downstream" "optical-agc" "enable"
    extract_simple "overlay downstream" "enable"
  done
  RETVAL=0
  return ${RETVAL}
}

cfg_overlay_upstream() {
  local RETVAL=0
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_simple "overlay upstream" "enable"
  done
  RETVAL=0
  return ${RETVAL}
}

cfg_rpd_global() {
  local RETVAL=0
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_simple "rpd global" "cin-if-timeout"
    extract_simple "rpd global" "core-type"
    extract_simple "rpd global" "l2tpv3-hello-interval"
    extract_simple "rpd global" "l2tpv3-retries"
    extract_simple "rpd global" "l2tpv3-setup-wait-time"
    extract_simple "rpd global" "gcp-keepalive-interval"
    extract_simple "rpd global" "gcp-keepalive-timeout"
    extract_simple "rpd global" "max-mtu"
    extract_simple "rpd global" "status-refresh-interval"
    extract_simple "rpd global" "enet_port addr-timeout"
    extract_simple "rpd global" "mulicast" "no" --novalue
    extract_simple "rpd global" "mulicast" "auto-switchback" --novalue
    extract_last_pair "rpd global" "ptp" 
    extract_pair "rpd global min-mcast-session-id" --verb=3 --value=4 --path=rpd/global/min-mcast-session-id
    extract_pair "rpd global min-mcast-session-id" --verb=5 --value=6 --path=rpd/global/max-mcast-session-id
  done
  RETVAL=0
  return ${RETVAL}
}

cfg_username() {
  local RETVAL=0
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_pair "username" --verb=1 --value=2 --path=credentials/users --index
    extract_pair "username" --verb=3 --value=4 --path=credentials/users --index --append
    extract_pair "username" --verb=5 --value=6 --path=credentials/users --index --append
  done
  RETVAL=0
  return ${RETVAL}
}


cfg_l2vpn() {
  local RETVAL=0
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_simple "l2vpn" "forwarding"
    extract_simple "l2vpn cm" "capability" "esafe-ident"
    extract_simple "l2vpn cm" "capability" "dut-filter"
    extract_simple "l2vpn network-interface" "dot1ad" "ethertype"
  done
  RETVAL=0
  return ${RETVAL}
}

cfg_enable_encrypted_password() {
  local RETVAL=0
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_pair "enable encrypted-password" --verb=2 --value=3 --path=credentials/enable --index
    extract_pair "enable encrypted-password" --verb=4 --value=5 --path=credentials/enable --index --append
  done
  RETVAL=0
  return ${RETVAL}
}

cfg_interface_downstream() {
  local RETVAL=0
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_simple "interface downstream-overlay" "enable"
    extract_simple "interface downstream-overlay" "attenuator"
    extract_simple "interface downstream-overlay" "hysteresis"
    extract_simple "interface downstream-overlay" "agc" "enable"
  done
  RETVAL=0
  return ${RETVAL}
}

cfg_interface_upstream() {
  local RETVAL=0
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_simple "interface upstream-overlay" "enable"
    extract_simple "interface upstream-overlay" "attenuator"
    extract_simple "interface upstream-overlay" "hysteresis"
    extract_simple "interface upstream-overlay" "agc" "enable"
  done
  RETVAL=0
  return ${RETVAL}
}

cfg_cable_enable_trap() {
  local RETVAL=0
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_last_pair "cable" "enable-trap"
    extract_simple "cable" "enable-trap" "cmonoff-noification" --novalue
    extract_simple "cable" "enable-trap" "cminit-reg-notification" --novalue
  done
  RETVAL=0
  return ${RETVAL}
}

cfg_ip() {
  local RETVAL=0
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_simple "ip bootfile"
    extract_simple "ip" "unreachables" --novalue
    extract_simple "ip" "multicast" "cable-mac-fwd-all-ds"
    extract_simple "ip igmp" "query-robustness-varable"
    extract_simple "ip" "domain-lookup" --novalue
    extract_last_pair "ip" "fqdn-cache"
    extract_pair "ip proto-throttle-rate" --verb=2 --value=3 --path=ip
    extract_pair "ip proto-throttle-rate" --verb=3 --value=4 --path=ip/proto-throttle-rate --append
  done
  RETVAL=0
  return ${RETVAL}
}

cfg_ipv6() {
  local RETVAL=0
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_pair "ipv6 proto-throttle-rate" --verb=2 --value=3 --path=ipv6
    extract_pair "ipv6 proto-throttle-rate" --verb=3 --value=4 --path=ipv6/proto-throttle-rate --append
    extract_last_pair "ipv6 icmp" "unreachables" --novalue
    extract_last_pair "ipv6 icmp" "too-big" --novalue
    extract_last_pair "ipv6 icmp" "param-problem" --novalue
    extract_last_pair "ipv6 icmp" "time-exceeded"
    extract_simple "ipv6" "hop-limit"
    extract_simple "ipv6" "nd" "timeout"
    extract_last_pair "ipv6 nd state" "searching"
    extract_last_pair "ipv6 nd state" "not-present"
    extract_simple "ipv6" "pd-route-injection" --novalue
    extract_simple "ipv6" "prefix-stability" --novalue
    extract_simple "ipv6 dhcp relay" "source-interface"
    extract_simple "ipv6 dhcp relay" "use-link-address" --novalue
    extract_simple "ipv6 mldv2" "query-robustness-varable"
  done
  RETVAL=0
  return ${RETVAL}
}

cfg_router_ospf() {
  local RETVAL=0
  local VRF="${1}"
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_simple "router ospf vrf" "${VRF}" "router-id"
    extract_simple "router ospf vrf" "${VRF}" "no shutdown" --novalue
    extract_simple "router ospf vrf" "${VRF}" "compatible"
    extract_simple "router ospf vrf" "${VRF}" "graceful-restart" "grace-period"
    extract_pair "router ospf vrf ${VRF} network" --verb=5 --value=6 --path=router/ospf/vrf/${VRF}/route
    extract_pair "router ospf vrf ${VRF} network" --verb=5 --value=7 --path=router/ospf/vrf/${VRF}/route/network --append
    extract_pair "router ospf vrf ${VRF} network" --verb=8 --value=9 --path=router/ospf/vrf/${VRF}/route/network --append
    extract_pair "router ospf vrf ${VRF} redistribute connected" --verb=7 --value=8 --path=router/ospf/vrf/${VRF}/redistribute/connected
    extract_pair "router ospf vrf ${VRF} redistribute connected" --verb=9 --value=10 --path=router/ospf/vrf/${VRF}/redistribute/connected
  done
  RETVAL=0
  return ${RETVAL}
}


cfg_packetcable() {
  local RETVAL=0
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_last_pair "packetcable" "dqos" "timer"
    extract_last_pair "packetcable" "eventmsg" "retry"
    extract_simple "packetcable" "dqos" "shutdown" --novalue
  done
  RETVAL=0
  return ${RETVAL}
}

cfg_cable() {
  local RETVAL=0
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_pair "cable shared-secret" --verb=2 --value=3 --path=cable/secrets/primary --index
    extract_pair "cable shared-secret" --verb=2 --value=4 --path=cable/secrets/primary --index --append
    extract_pair "cable shared-secondary-secret" --verb=2 --value=3 --path=cable/secrets/secondary --index
    extract_pair "cable shared-secondary-secret" --verb=2 --value=4 --path=cable/secrets/secondary --index --append
    extract_simple "cable flap-list" "power-adjust" "threshold"
    extract_simple "cable flap-list" "insertion-time"
    extract_simple "cable host" "authorization"
    extract_last_pair "cable modem" "vendor"
    extract_simple "no" "cable modem" "remote-query" --novalue
    extract_last_pair "cable modem" "energy-mgmt"
    extract_last_pair "cable" "privacy"
    extract_last_pair "cable" "source-verify" "leasequery"
    extract_last_pair "cable" "proto-throttle-rate"
    extract_simple "cable modem" "deny" --index=mac-address --path=cable/modem/deny
    extract_last_pair "cable submgmt" "default" "dut-filter-group" "cm"
    extract_simple "cable submgmt" "default" "max-cpe"
    extract_simple "cable submgmt" "default" "v6-max-cpe"
    extract_simple "cable submgmt" "default" "active"
    extract_simple "cable submgmt" "default" "learnable" --novalue
    extract_last_pair "cable admission-control" "multicast"
    extract_simple "cable global" --index=global --path=cable/globals --nortrim
    extract_simple "cable metering" "enable" --novalue
    extract_simple "cable metering" "mode"
    extract_pair "cable metering collector" --verb=4 --value=5 --path=cable/metering/collector --index
    extract_pair "cable metering session" --verb=6 --value=7 --path=cable/metering/session/service/samis-1 --index
    extract_pair "cable metering report-cycle set" --verb=4 --value=5 --path=cable/metering/report-cycle --index
    extract_pair "cable metering report-cycle set" --verb=6 --value=7 --path=cable/metering/report-cycle --index --append
    extract_pair "cable metering report-cycle set" --verb=8 --value=9 --path=cable/metering/report-cycle --index --append
  done
  RETVAL=0
  return ${RETVAL}
}

cfg_banner() {
  local RETVAL=0
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_simple "banner mode"
    extract_pair "no banner login" --verb=3 --value=1 --path=banner
    extract_pair "no banner motd" --verb=3 --value=1 --path=banner
  done
  RETVAL=0
  return ${RETVAL}
}

cfg_operation_mode() {
  local RETVAL=0
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_simple "operation mode" --index=mode --path=operation/modes
  done
  RETVAL=0
  return ${RETVAL}
}

cfg_crypto() {
  local RETVAL=0
  for ((B = 0; B < ${#CLI_BLOCK[@]}; ++B)); do
    CLI_LINE="${CLI_BLOCK[$B]}"
    extract_last_pair "crypto" "isakmp"
    extract_last_pair "crypto" "ipsec" "security-association" "lifetime"
  done
  RETVAL=0
  return ${RETVAL}
}

cfg_other() {
  local RETVAL=0
  for ((B = 0; B < ${#CLI_TEXT[@]}; ++B)); do
    CLI_LINE="${CLI_TEXT[$B]}"
    extract_simple "dot1x" "enable" --novalue
    extract_simple "shelfname"
    extract_simple "hostname"
    extract_simple "lacp" "system-priority"
    extract_simple "prompt"
    extract_simple "lldp"
    extract_last_pair "rpd dscp" "traffic-type"
    extract_simple "arp" "gratuitous-interval"
    extract_last_pair "logging" "rpd"
    extract_simple "aging state" "searching cable" "unicast"
    extract_last_pair "counts collection" "rate"
    extract_simple "operation-mode"
    extract_simple "intra-node-cabling-mode"
  done
  RETVAL=0
  return ${RETVAL}
}

if [ $# -eq 0 ] ; then
    usage
    exit 0
fi

trap clean_sigint INT

while [ $# -gt 0 ] ; do
  OPTION="${1}"
  case "${OPTION}" in
      --tenant=*)
          TENANT_ID="${OPTION##*=}"
          ;;
      --region=*)
          REGION_ID="${OPTION##*=}"
          ;;
      --zone=*)
          ZONE_ID="${OPTION##*=}"
          ;;
      --uuid=*)
          UUID="${OPTION##*=}"
          UUID_GENERATED=1
          ;;
      --cli=*)
          CLI_CONFIG="${OPTION##*=}"
          ;;
      *)
          ;;
  esac
  shift
done

#echo "tenant: ${TENANT_ID}"
#echo "region: ${REGION_ID}"
#echo "zone:   ${ZONE_ID}"
#echo "uuid:   ${UUID}"
#echo "cli:    ${CLI_CONFIG}"

if [[ -n "${TENANT_ID}" && -n "${REGION_ID}" && -n "${ZONE_ID}" && -n "${UUID}" && -n "${CLI_CONFIG}" ]] ; then
#  cfg_other && RETVAL=$? || RETVAL=1
  if [ -f "${CLI_CONFIG}" ] ; then
    load ${CLI_CONFIG}
    if [ $? -eq 0 ] ; then
      cfg_header
      tidy
      cfg_banner_block "login"
      cfg_banner_block "motd"
      squeeze

      RANGE=$(grep -i -P "^(configure\s{1,})?crypto\s{1,}privacy\s{1,}add-certificate\s{1,}.*$" ${CLI_CONFIG}|sed "s/configure //ig"|cut -d" " -f4|sort -u)
      for T in ${RANGE}; do
        CLI_BLOCK=()
        cfg_crypto_block "${T}"
      done

      # restructure blocks
      RANGE=$(grep -i -P "^(configure\s{1,})?interface\s{1,}cable-downstream\s{1,}.*$" ${CLI_CONFIG}|sed "s/configure //ig"|cut -d" " -f3|sort -u -r)
      for T in ${RANGE}; do
        CLI_BLOCK=()
        extract_block "^interface\scable-downstream\s${T}\s.*" "exit$"
        extract_line "^interface\scable-downstream\s${T}\s.*" "exit$"
        cfg_interface "cable-downstream" "${T}"
      done
      RANGE=$(grep -i -P "^(configure\s{1,})?interface\s{1,}cable-upstream\s{1,}.*$" ${CLI_CONFIG}|sed "s/configure //ig"|cut -d"/" -f3|sort -u -r)
      for T in ${RANGE}; do
        CLI_BLOCK=()
        extract_block "^interface\scable-upstream${T}\s.*" "exit$"
        extract_line "^interface\s{1,}cable-upstream\s{1,}${T}\s{1,}.*$"
        cfg_interface "cable-upstream" "${T}"
      done

      RANGE=$(grep -i -P "^(configure\s{1,})?cable\s{1,}modulation-profile\s{1,}.*$" ${CLI_CONFIG}|sed "s/configure //ig"|cut -d" " -f3|sort -u -g -r)
      for T in ${RANGE}; do
        SUB_RANGE=$(grep -i -P "^(configure\s{1,})?cable\s{1,}modulation-profile\s${T}\s{1,}iuc\s{1,}.*$" ${CLI_CONFIG}|sed "s/configure //ig"|cut -d" " -f5|sort -u -g -r)
        for S in ${SUB_RANGE}; do
          CLI_BLOCK=()
          extract_line "^cable\s{1,}modulation-profile\s{1,}${T}\s{1,}iuc\s{1,}${S}\s{1,}.*$"
          cfg_cable_modulation_profile "${T}" "${S}"
        done
      done 

      RANGE=$(grep -i -P "^(configure\s{1,})?ofdm\s{1,}modulation-profile\s{1,}.*$" ${CLI_CONFIG}|sed "s/configure //ig"|cut -d" " -f3|sort -u -g -r)
      for T in ${RANGE}; do
        CLI_BLOCK=()
        extract_block "^ofdm\smodulation-profile\s${T}\s.*" "exit$"
        extract_line "^ofdm\s{1,}modulation-profile\s{1,}${T}.*$"
        # todo
      done
      RANGE=$(grep -i -P "^(configure\s{1,})?interface\s{1,}mgmt\s{1,}.*$" ${CLI_CONFIG}|sed "s/configure //ig"|cut -d" " -f3|sort -u -r)
      for T in ${RANGE}; do
        CLI_BLOCK=()
        extract_block "^interface\smgmt\s{1,}${T}\s.*" "exit$"
        extract_line "^interface\s{1,}mgmt\s{1,}${T}\s{1,}.*$"
        cfg_interface "mgmt" "${T}"
      done
      RANGE=$(grep -i -P "^(configure\s{1,})?interface\s{1,}null\s{1,}.*$" ${CLI_CONFIG}|cut -d" " -f3|sed "s/configure //ig"|sort -u -r)
      for T in ${RANGE}; do
        CLI_BLOCK=()
        extract_block "^interface\snull\s${T}\s.*" "exit$"
        extract_line "^interface\s{1,}null\s{1,}${T}\s{1,}.*" "^exit$"
        cfg_interface "null" "${T}"
      done
      RANGE=$(grep -i -P "^(configure\s{1,})?interface\s{1,}ethernet\s{1,}.*$" ${CLI_CONFIG}|sed "s/configure //ig"|cut -d" " -f3|sort -u -r)
      for T in ${RANGE}; do
        CLI_BLOCK=()
        extract_block "^interface\sethernet\s${T}\s.*" "exit$"
        extract_line "^interface\s{1,}ethernet\s{1,}${T}\s{1,}.*$"
        cfg_interface "ethernet" "${T}"
      done
      RANGE=$(grep -i -P "^(configure\s{1,})?interface\s{1,}loopback\s{1,}(.*)" ${CLI_CONFIG}|sed "s/configure //ig"|cut -d" " -f3|sort -u -r)
      for T in ${RANGE}; do
        CLI_BLOCK=()
        extract_block "^interface\sloopback\s${T}\s.*" "exit$"
        extract_line "^interface\s{1,}loopback\s{1,}${T}.*$"
        cfg_interface "loopback" "${T}"
      done
      RANGE=$(grep -i -P "^(configure\s{1,})?interface\s{1,}link-aggregate\s{1,}.*$" ${CLI_CONFIG}|sed "s/configure //ig"|cut -d" " -f4|sort -u -r)
      for T in ${RANGE}; do
        CLI_BLOCK=()
        extract_block "^interface\slink-aggregate\s${T}\s.*" "exit$"
        extract_line "^interface\s{1,}link-aggregate\s{1,}${T}.*$"
        cfg_interface "link-aggregate" "${T}"
      done
      RANGE=$(grep -i -P "^(configure\s{1,})?interface\s{1,}cable-mac\s{1,}.*$" ${CLI_CONFIG}|sed "s/configure //ig"|cut -d" " -f3|sort -u -r)
      for T in ${RANGE}; do
        CLI_BLOCK=()
        extract_block "^interface\scable-mac\s${T}\s.*" "exit$"
        extract_line "^interface\s{1,}cable-mac\s{1,}${T}\s{1,}.*$"
        cfg_interface "cable-mac" "${T}"
      done
      RANGE=$(grep -i -P "^(configure\s{1,})?interface\s{1,}rpd\s{1,}\"(.*)\"\s{1,}.*$" ${CLI_CONFIG}|sed "s/configure //ig"|cut -d"\"" -f2-|sort -u -r)
      for T in ${RANGE}; do
        CLI_BLOCK=()
        extract_block "^interface\srpd\s\"${T}\"\s.*" "exit$"
        extract_line "^interface\s{1,}rpd\"${T}\"\s{1,}.*$"
        cfg_interface "rpd" "\"${T}\""
      done
      RANGE=$(grep -i -P "^(configure\s{1,})?cable\s{1,}fibre-node\s{1,}.*$" ${CLI_CONFIG}|sed "s/configure //ig"|cut -d"\"" -f2|sort -u -r)
      for T in ${RANGE}; do
        CLI_BLOCK=()
        extract_block "^cable\sfibre-node\s\"${T}\"\s.*" "exit$"
        extract_line "^cable\s{1,}fibre-node\s{1,}\"${T}\"\s{1,}.*$"
        #tbc
      done

      # common prefixes
      RANGE=$(grep -i -P "^(configure\s{1,})?line\s{1,}console\s{1,}.*$" ${CLI_CONFIG}|sed "s/configure //ig"|cut -d" " -f3|sort -u -r)
      for T in ${RANGE}; do
        CLI_BLOCK=()
        extract_line "^line\s{1,}console\s{1,}${T}.*$"
        cfg_line_vty_console "console" "${T}"
      done 

      RANGE=$(grep -i -P "^(configure\s{1,})?line\s{1,}vty\s{1,}.*$" ${CLI_CONFIG}|sed "s/configure //ig"|cut -d" " -f3|sort -u -r)
      for T in ${RANGE}; do
        CLI_BLOCK=()
        extract_line "^line\s{1,}vty\s{1,}${T}\s{1,}.*$"
        cfg_line_vty_console "vty" "${T}"
      done 

      RANGE=$(grep -i -P "^(configure\s{1,})?access-list\s{1,}(\d{1,})\s{1,}(permit|deny|remark|enable-accounting)\s{1,}.*$" ${CLI_CONFIG}|sed "s/configure //ig"|cut -d" " -f2|sort -u -g -r)
      for T in ${RANGE}; do
        CLI_BLOCK=()
        extract_line "^access-list\s{1,}${T}\s{1,}(permit|deny|remark|enable-accounting)\s{1,}.*$"
        cfg_access_list "${T}"
      done 

      RANGE=$(grep -i -P "^(configure\s{1,})?cable\s{1,}filter\s{1,}group\s{1,}(\d{1,})\s{1,}index\s{1,}.*$" ${CLI_CONFIG}|sed "s/configure //ig"|cut -d" " -f4|sort -u -g -r)
      for T in ${RANGE}; do
        SUB_RANGE=$(grep -i -P "^(configure\s{1,})?cable\s{1,}filter\s{1,}group\s{1,}${T}\s{1,}index\s{1,}.*$" ${CLI_CONFIG}|sed "s/configure //ig"|cut -d" " -f6|sort -u -g -r)
        for S in ${SUB_RANGE}; do
          CLI_BLOCK=()
          extract_line "^cable\s{1,}filter\s{1,}group\s{1,}${T}\s{1,}index\s{1,}${S}\s{1,}.*$"
          cfg_cable_filter_group "${T}" "${S}"
        done
      done 

      RANGE=$(grep -i -P "^(configure\s{1,})?cable\s{1,}dsg\s{1,}ds-frequency-list\s{1,}(\d{1,})\s{1,}index\s{1,}\d{1,}\s{1,}frequency\s{1,}(\d{1,})$" ${CLI_CONFIG}|sed "s/configure //ig"|cut -d" " -f4|sort -u -g -r)
      for T in ${RANGE}; do
        SUB_RANGE=$(grep -i -P "^(configure\s{1,})?cable\s{1,}dsg\s{1,}ds-frequency-list\s{1,}${T}\s{1,}index\s{1,}\d{1,}\s{1,}frequency\s{1,}.*$" ${CLI_CONFIG}|sed "s/configure //ig"|cut -d" " -f6|sort -u -g -r)
        for S in ${SUB_RANGE}; do
          CLI_BLOCK=()
          extract_line "^cable\s{1,}dsg\s{1,}ds-frequency-list\s{1,}${T}\s{1,}index\s{1,}${S}\s{1,}frequency\s{1,}.*$"
          cfg_dsq_ds_freq_list "${T}" "${S}"
        done
      done 

      RANGE=$(grep -i -P "^(configure\s{1,})?privilege\s{1,}exec\s{1,}level\s{1,}.*$" ${CLI_CONFIG}|sed "s/^configure //ig"|cut -d" " -f4|sort -u -g -r)
      for T in ${RANGE}; do
        CLI_BLOCK=()
        extract_line "^privilege\s{1,}exec\s{1,}level\s{1,}${T}\s{1,}.*$"
        cfg_priv_exec_group "${T}"
      done 


      RANGE=$(grep -i -P "^(configure\s{1,})?router\s{1,}ospf\s{1,}vrf\s{1,}.*$" ${CLI_CONFIG}|sed "s/^configure //ig"|cut -d" " -f4|sort -u -r)
      for T in ${RANGE}; do
        CLI_BLOCK=()
        extract_line "^router\s{1,}ospf\s{1,}vrf\s{1,}${T}\s{1,}.*$"
        cfg_router_ospf "${T}"
      done

      # singular
      CLI_BLOCK=()
      extract_line "^license\s{1,}type\s{1,}.*$"
      cfg_license_type
      
      CLI_BLOCK=()
      extract_line "^console\s{1,}enable.*$"
      cfg_console

      CLI_BLOCK=()
      extract_line "^ip\s{1,}ssh\s{1,}.*$"
      cfg_ip_ssh

      CLI_BLOCK=()
      extract_line "^video\s{1,}global\s{1,}.*$"
      cfg_video_global

      CLI_BLOCK=()
      extract_line ^"ofdm\s{1,}profile-mgmt\s{1,}.*$"
      cfg_ofdm_profile_mgmt

      CLI_BLOCK=()
      extract_line "^ofdm\s{1,}global\s{1,}.*$"
      cfg_ofdm_global

      CLI_BLOCK=()
      extract_line "^rpd\s{1,}global\s{1,}.*$"
      cfg_rpd_global

      CLI_BLOCK=()
      extract_line "^snmp\s{1,}server\s{1,}.*$"
      cfg_snmp_server

      CLI_BLOCK=()
      extract_line "^cable\s{1,}load-balance\s{1,}.*$"
      cfg_cable_load_balance

      CLI_BLOCK=()
      extract_line "^username\s{1,}.*$"
      cfg_username

      CLI_BLOCK=()
      extract_line "^ntp\s{1,}.*$"
      cfg_ntp

      CLI_BLOCK=()
      extract_line "^overlay\s{1,}downstream\s{1,}.*$"
      cfg_overlay_downstream

      CLI_BLOCK=()
      extract_line "^overlay\s{1,}upstream\s{1,}.*$"
      cfg_overlay_upstream

      CLI_BLOCK=()
      extract_line "^clock\s{1,}mode\s{1,}.*$"
      cfg_clock

      CLI_BLOCK=()
      extract_line "^interface\s{1,}downstream-overlay\s{1,}.*$"
      cfg_interface_downstream

      CLI_BLOCK=()
      extract_line "^interface\s{1,}upstream-overlay\s{1,}.*$"
      cfg_interface_upstream

      CLI_BLOCK=()
      extract_line "^cable\s{1,}enable-trap\s{1,}.*$" 
      cfg_cable_enable_trap

      CLI_BLOCK=()
      extract_line "^l2vpn.*\s{1,}"
      cfg_l2vpn

      CLI_BLOCK=()
      extract_line "^ip\s{1,}.*$"
      cfg_ip

      CLI_BLOCK=()
      extract_line "^ipv6\s{1,}.*$"
      cfg_ipv6

      CLI_BLOCK=()
      extract_line "^packetcable\s{1,}.*$"
      cfg_packetcable

      CLI_BLOCK=()
      extract_line "^cable\s{1,}.*$"
      cfg_cable

      CLI_BLOCK=()
      extract_line "^banner\s{1,}.*$"
      extract_line "^no\s{1,}banner\s{1,}.*$"
      cfg_banner

      CLI_BLOCK=()
      extract_line "^operation\s{1,}mode\s{1,}.*$"
      cfg_operation_mode

      CLI_BLOCK=()
      extract_line "^crypto\s{1,}.*$"
      cfg_crypto

      CLI_BLOCK=()
      extract_line "^slot\s{1,}.*$"
      #cfg_slot

      # process everything else
      cfg_other

      RETVAL=$?

      # updated modified timestamp (once not for every kv change)
      kv put "/${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${UUID}/modified" "$(date '+%s')"

      #dump
    fi
  else
    RETVAL=1
  fi
else
  RETVAL=1
fi

unset CLI_TEXT
unset CLI_BLOCK

trap - INT

exit ${RETVAL}
