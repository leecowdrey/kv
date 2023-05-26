#!/bin/bash
PING_INTERVAL=$(kv get /system/heartbeat/interval)

TENANT_ID="Charter"
REGION_ID="georgia"
ZONE_ID="headend"


E6000_ID=$(uuid)
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}
kv link /defaults/sku/CommScope/BigIron/E6000 /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/defaults
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/management/ip-address "10.172.0.9"
kv copy /defaults/sku/CommScope/BigIron/E6000/ssh/port /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/management/ssh/port
kv copy /defaults/sku/CommScope/BigIron/E6000/ssh/authentication-method /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/management/ssh/authentication-method
kv copy /defaults/sku/CommScope/BigIron/E6000/ssh/password/username /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/management/ssh/password/username
kv copy /defaults/sku/CommScope/BigIron/E6000/ssh/password/password /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/management/ssh/password/password
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/management/ssh/public-key/key-type "dsa"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/management/ssh/public-key/key-value "/store/${E6000_ID}/id_rsa.pem"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/management/ssh/host-based/key-type ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/management/ssh/host-based/key-value ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/management/ssh/fingerprint ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/management/snmp/community/read-only "ro"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/management/snmp/community/read-write "rw"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/management/snmp/community/trap "any"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/management/snmp/agent-version "v3"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/management/snmp/agent-port "161"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/management/role "ccap"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/management/onboarded "false"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/management/state ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/created "$(date '+%s')"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/modified ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/deleted ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/heartbeat/first ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/heartbeat/last ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/heartbeat/next-expected "$(date -d "+${PING_INTERVAL} minutes" '+%s')"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/config/history/to-keep "2"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/config/history/1/store "/store/${E6000_ID}/e6000-0000.ca00.0000.cfg.1"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/config/history/1/created "$(date '+%s')"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/config/history/1/modified ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/config/history/1/deleted ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/config/history/2/store "/store/${E6000_ID}/e6000-0000.ca00.0000.cfg.2"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/config/history/2/created ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/config/history/2/modified ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/config/history/2/deleted ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/heartbeat/first ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/heartbeat/last ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/heartbeat/next-expected "$(date -d "+${PING_INTERVAL} minutes" '+%s')"

kv link /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID} /inventory/${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}

./add_heartbeat.sh "${E6000_ID}" "/${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}" "/${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${E6000_ID}/management/state" "ready"

./cli2kv.sh --tenant=${TENANT_ID} --region=${REGION_ID} --zone=${ZONE_ID} --uuid=${E6000_ID} --cli=e6000.cli
