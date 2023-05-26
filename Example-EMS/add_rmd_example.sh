#!/bin/bash
PING_INTERVAL=$(kv get /system/heartbeat/interval)

TENANT_ID="Charter"
REGION_ID="Georgia"
ZONE_ID="Gainesville"
#RMD_ID="5aaf6a87-f9fd-44ad-8eea-c9d66e7b983a"
RMD_ID=$(uuid)
IP="${1:-29}"
echo "adding RMD ID# ${RMD_ID}"

# add device RMD_ID
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}
kv link /defaults/sku/CommScope/RMD/RD2322 /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/defaults
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/management/device-name "ARRIS RMD-${IP}"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/management/serial-number "20195PSD02${IP}"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/management/device-alias ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/management/ip-address "10.172.16.${IP}"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/management/mac-address "c4:24:a3:45:fc:${IP}"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/management/bootfile-url "tftp://rmdmgr1:2597/rd2322.c4.24.a3.45.fc.${IP}.cfg"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/management/state ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/management/onboarded "false" 
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/management/role "RMD"

kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/config/history/to-keep "2"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/config/history/1/store "/store/${RMD_ID}/rd2322.c4.24.a3.45.fc.${IP}.cfg.1"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/config/history/1/created "$(date '+%s')"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/config/history/1/modified ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/config/history/1/deleted ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/config/history/2/store "/store/${RMD_ID}/rd2322.c4.24.a3.45.fc.${IP}.cfg.2"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/config/history/2/created ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/config/history/2/modified ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/config/history/2/deleted ""

kv copy /defaults/sku/CommScope/RMD/RD2322/ssh/port /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/management/ssh/port
kv copy /defaults/sku/CommScope/RMD/RD2322/ssh/authentication-method /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/management/ssh/authentication-method
kv copy /defaults/sku/CommScope/RMD/RD2322/ssh/password/username /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/management/ssh/password/username
kv copy /defaults/sku/CommScope/RMD/RD2322/ssh/password/password /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/management/ssh/password/password

kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/management/ssh/public-key/key-type "rsa"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/management/ssh/public-key/key-value "/store/${RMD_ID}/id_rsa.ppk"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/management/ssh/host-based/key-type ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/management/ssh/host-based/key-value ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/management/ssh/fingerprint ""

kv copy /defaults/sku/CommScope/RMD/RD2322/cli/enable-username /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/management/cli/enable-username
kv copy /defaults/sku/CommScope/RMD/RD2322/cli/enable-password /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/management/cli/enable-password

kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/management/cli/copy-config-remote "copy running-config verbose tftp://rmdmgr1:2597/rmd.c4.24.a3.45.fc.${IP}.cfg"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/management/snmp/community/read-only "ro"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/management/snmp/community/read-write "rw"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/management/snmp/community/trap "any"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/management/snmp/agent-version "v3"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/management/snmp/agent-port "161"

kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/created "$(date '+%s')"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/modified ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/deleted ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/heartbeat/first ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/heartbeat/last ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/heartbeat/next-expected "$(date -d "+${PING_INTERVAL} minutes" '+%s')"

# update inventory
kv link /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID} /inventory/${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}

# VUE
#!/bin/bash
C=0
for ((V=24;V<26;V++)); do
    C=$(( C + 1))
 echo "${V}"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/channelId "${V}869c43-a3ff-9146-35ca-aa21701cdc${IP}"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/name "Group1_2130${V}"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/sessionId "8000006B"

    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/config/rfPortIndex "0"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/config/serviceGroups "63065${V}"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/config/rfChannelType "DsScQam"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/config/rfChannelIndex "32"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/config/adminState "up"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/config/rfMute "false"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/config/tsId "0"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/config/multicastIp "ff1e::8000:2${V}"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/config/sourceIp "fc00:d00:a:1b00::1${V}"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/config/frequency "2130000${V}"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/config/annex "B"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/config/modulationType "Qam256"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/config/interleaverDepth "I128-J1"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/config/symbolRateOverride "0"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/config/spectrumInversionEnabled "false"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/config/powerAdjust "0"

    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/statistics/state "Operational"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/statistics/session/outOfSequencePackets "0"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/statistics/session/inPackets "${IP}6075736"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/statistics/session/inDiscards "0"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/statistics/session/outPackets "0"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/statistics/session/outErrors "0"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/statistics/session/counterDiscontinuityTime "2020-10-09T19:${IP}:13-06:00"

    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/statistics/interface/outDiscards "0"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/statistics/interface/outErrors "0"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/statistics/interface/outPackets "${IP}5807957"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/statistics/interface/discontinuityTime "2020-10-09T19:${IP}:13-06:00"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/statistics/interface/operationalStatus "1"

    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/statistics/status/rfChannelType "DsScQam"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/statistics/status/rfChannelIndex "${IP}"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/statistics/status/frequency "2190000${IP}"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/statistics/status/ccapLcceIpAddress "fc00:d${V}:a:1b${IP}::150"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/statistics/status/rpdLcceIpAddress "fc00:d${V}:a:1b${IP}::10:2"
    kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/channels/${C}/statistics/status/direction "forward"
done

kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/status/rpdSystemUpTime "25947600"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/status/startUpNotifyDate "2020-10-09T21:${IP}:15.228272"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/status/state "Operational"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/status/numDsRfPorts "1"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/status/numUsRfPorts "2"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/status/numDsScQamChannels "160"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/status/allocatedDsScQamChannels "${IP}"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/status/numDsOob55d1Channels "1"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/status/allocatedDsOob55d1Channels "0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/status/numUsOob55d1Channels "3"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/status/allocatedUsOob55d1Channels "0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/status/numAsyncVideoChannels "0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/status/supportsUdpEncaps "false"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/status/minPowerAdjustScQam "-${IP}"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/status/maxPowerAdjustScQam "0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/status/maxFwdStaticPw "130"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/status/maxRetStaticPw "6"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/status/supportsMptDepiPw "true"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/vue/status/supportsMpt55d1RetPw "true"


#
# add to queue
kv put /system/queue/onboard/${RMD_ID} && \
kv put /system/queue/onboard/${RMD_ID}/request-path "/${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}" && \
kv put /system/queue/onboard/${RMD_ID}/response-path "/${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMD_ID}/management/state" && \
kv put /system/queue/onboard/${RMD_ID}/worker/pid "" && \
kv put /system/queue/onboard/${RMD_ID}/worker/host "" && \
kv put /system/queue/onboard/${RMD_ID}/worker/retry-attempt "0" && \
kv put /system/queue/onboard/${RMD_ID}/worker/accepted "ready"
RETVAL=$?

exit ${RETVAL}
