# kv - BASH Key-Value Store

## usage

```
$ kv [operation]
```

## Operation

- `append|concat [Key-Name] [Key-Value]`
- `audit purge | read [event UUID] | count |ls`
- `cat [Key-Name] # encrpted value`
- `copy|cp [source Key-Name] [destination Key-Name]`
- `count [Key-Name]`
- `delete|rm [Key-Name] # + empty 1st child delete+audit+subscriptions`
- `dump [Key-Name]`
- `find {[Key-Name] | [Key{* ? []} ]`
- `get [Key-Name] # unencrypted value`
- `has [Key-Name]`
- `help`
- `is [Key-Name]`
- `link|ln [source Key-Name] [destination Key-Name]`
- `list [Key-Name] # full Key-Name returned`
- `ls [Key-Name] # short Key-Name returned`
- `modified ["HH:MM mm/dd/yyyy"] # default now - 1 minute`
- `move|mv [source Key-Name] [destination parent Key-Name]`
- `prune [Key-Name] # full cascade delete+no audit+no subscriptions`
- `put|set [Key-Name] [Key-Value]`
- `query [Key-Name] --key=Sub-Key-Name --value=Sub-Key-Value]`
- `subscribe|sub --key=[Key-Name] {--command=cmd | --callback=url | --signal=process-name | --fifo=fifo-name }`
- `subscriptions {--key=[Key-Name]}`
- `tree [Key-Name]`
- `unlink|uln [Key-Name]`
- `unsubscribe|unsub --key=[Key-Name]`
- `version`

## Example

```
$ kv put /system/audit/days-to-keep 3
$ kv put /system/audit/enable true
$ kv put /system/audit/encrypt true
$ kv put /system/audit/max-events 100

$ kv ls /system/audit
days-to-keep
enable
encrypt
max-events

$ kv list /system/audit
/system/audit/days-to-keep
/system/audit/enable
/system/audit/encrypt
/system/audit/max-events

$ kv tree /system/audit
/system/audit
├── days-to-keep
├── enable
├── encrypt
└── max-events

$ kv get /system/audit/days-to-keep
3

$ kv put /system/audit/days-to-keep 36

$ kv get /system/audit/days-to-keep
36

$ kv append /system/audit/days-to-keep 5

$ kv get /system/audit/days-to-keep
365

$ kv find days-to-keep
/system/audit/days-to-keep

$ kv modified "22:50 05/19/2021"
/.audit/b63397cd-2276-4bf5-9386-fbd1293cee85
/system/audit/days-to-keep

```

## Example within BASH script

```bash
#!/bin/bash
PING_INTERVAL=$(kv get /system/heartbeat/interval)

TENANT_ID="MSO"
REGION_ID="dc"
ZONE_ID="core"

# add 2 x spine
CIN_ID=$(uuid)
echo "Spine 1/2: ${CIN_ID}"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}
kv link /defaults/sku/Brocade/FastIron/ICX-7850 /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/defaults
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ip-address "10.172.10.4"
kv copy /defaults/sku/Brocade/FastIron/ICX-7850/ssh/port /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/port
kv copy /defaults/sku/Brocade/FastIron/ICX-7850/ssh/authentication-method /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/authentication-method
kv copy /defaults/sku/Brocade/FastIron/ICX-7850/ssh/password/username /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMCIN_IDDCIN_ID_ID}/management/ssh/password/username
kv copy /defaults/sku/Brocade/FastIron/ICX-7850/ssh/password/password /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/password/password
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/public-key/key-type "rsa"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/public-key/key-value "/store/${CIN_ID}/id_rsa.ppk"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/host-based/key-type ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/host-based/key-value ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/fingerprint ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/snmp/community/read-only "ro"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/snmp/community/read-write "rw"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/snmp/community/trap "any"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/snmp/agent-version "v3"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/snmp/agent-port "161"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/role "spine"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/state ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/mac-address "cc4e.24a4.18c0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/duplex "full"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/speed "10G"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/trunk "none"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/tag "true"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/pvid "0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/name ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/ip-address "10.172.16.4"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/subnet-mask "255.255.255.0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/subnet-bits "24"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/mac-address "cc4e.25a4.18c0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/duplex "full"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/speed "10G"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/trunk "none"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/tag "true"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/pvid "0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/name ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/ip-address "10.172.17.4"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/subnet-mask "255.255.255.0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/subnet-bits "24"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/created "$(date '+%s')"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/modified ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/deleted ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/heartbeat/first ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/heartbeat/last ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/heartbeat/next-expected "$(date -d "+${PING_INTERVAL} minutes" '+%s')"
kv link /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID} /inventory/${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}

CIN_ID=$(uuid)
echo "Spine 2/2: ${CIN_ID}"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}
kv link /defaults/sku/Brocade/FastIron/ICX-7850 /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/defaults
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ip-address "10.172.10.5"
kv copy /defaults/sku/Brocade/FastIron/ICX-7850/ssh/port /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/port
kv copy /defaults/sku/Brocade/FastIron/ICX-7850/ssh/authentication-method /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/authentication-method
kv copy /defaults/sku/Brocade/FastIron/ICX-7850/ssh/password/username /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMCIN_IDDCIN_ID_ID}/management/ssh/password/username
kv copy /defaMSOults/sku/Brocade/FastIron/ICX-7850/ssh/password/password /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/password/password
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/public-key/key-type "rsa"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/public-key/key-value "/store/${CIN_ID}/id_rsa.ppk"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/host-based/key-type ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/host-based/key-value ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/fingerprint ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/snmp/community/read-only "ro"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/snmp/community/read-write "rw"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/snmp/community/trap "any"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/snmp/agent-version "v3"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/snmp/agent-port "161"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/role "spine"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/state ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/mac-address "cc4e.24a5.19c0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/duplex "full"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/speed "10G"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/trunk "none"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/tag "true"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/pvid "0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/name ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/ip-address "10.172.16.5"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/subnet-mask "255.255.255.0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/subnet-bits "24"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/mac-address "cc4e.25a5.19c0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/duplex "full"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/speed "10G"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/trunk "none"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/tag "true"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/pvid "0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/name ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/ip-address "10.172.17.5"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/subnet-mask "255.255.255.0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/subnet-bits "24"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/created "$(date '+%s')"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/modified ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/deleted ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/heartbeat/first ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/heartbeat/last ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/heartbeat/next-expected "$(date -d "+${PING_INTERVAL} minutes" '+%s')"
kv link /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID} /inventory/${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}

# add 4 x leaf
CIN_ID=$(uuid)
echo "Leaf 1/4: ${CIN_ID}"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}
kv link /defaults/sku/Brocade/FastIron/ICX-7850 /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/defaults
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ip-address "10.172.10.6"
kv copy /defaults/sku/Brocade/FastIron/ICX-7850/ssh/port /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/port
kv copy /defaults/sku/Brocade/FastIron/ICX-7850/ssh/authentication-method /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/authentication-method
kv copy /defaults/sku/Brocade/FastIron/ICX-7850/ssh/password/username /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMCIN_IDDCIN_ID_ID}/management/ssh/password/username
kv copy /defaults/sku/Brocade/FastIron/ICX-7850/ssh/password/password /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/password/password
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/public-key/key-type "rsa"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/public-key/key-value "/store/${CIN_ID}/id_rsa.ppk"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/host-based/key-type ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/host-based/key-value ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/fingerprint ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/snmp/community/read-only "ro"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/snmp/community/read-write "rw"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/snmp/community/trap "any"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/snmp/agent-version "v3"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/snmp/agent-port "161"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/role "leaf"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/state ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/mac-address "cc4e.24a5.20c0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/duplex "full"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/speed "10G"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/trunk "none"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/tag "true"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/pvid "0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/name "primary"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/ip-address "10.172.16.6"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/subnet-mask "255.255.255.0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/subnet-bits "24"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/mac-address "cc4e.25a5.20c0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/duplex "full"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/speed "10G"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/trunk "none"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/tag "true"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/pvid "0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/name "secondary"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/ip-address "10.172.17.6"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/subnet-mask "255.255.255.0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/subnet-bits "24"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/created "$(date '+%s')"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/modified ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/deleted ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/heartbeat/first ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/heartbeat/last ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/heartbeat/next-expected "$(date -d "+${PING_INTERVAL} minutes" '+%s')"
kv link /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID} /inventory/${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}

CIN_ID=$(uuid)
echo "Leaf 2/4: ${CIN_ID}"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}
kv link /defaults/sku/Brocade/FastIron/ICX-7850 /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/defaults
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ip-address "10.172.10.7"
kv copy /defaults/sku/Brocade/FastIron/ICX-7850/ssh/port /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/port
kv copy /defaults/sku/Brocade/FastIron/ICX-7850/ssh/authentication-method /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/authentication-method
kv copy /defaults/sku/Brocade/FastIron/ICX-7850/ssh/password/username /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMCIN_IDDCIN_ID_ID}/management/ssh/password/username
kv copy /defaults/sku/Brocade/FastIron/ICX-7850/ssh/password/password /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/password/password
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/public-key/key-type "rsa"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/public-key/key-value "/store/${CIN_ID}/id_rsa.ppk"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/host-based/key-type ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/host-based/key-value ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/fingerprint ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/snmp/community/read-only "ro"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/snmp/community/read-write "rw"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/snmp/community/trap "any"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/snmp/agent-version "v3"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/snmp/agent-port "161"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/role "leaf"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/state ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/mac-address "cc4e.24a5.21c0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/duplex "full"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/speed "10G"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/trunk "none"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/tag "true"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/pvid "0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/name "primary"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/ip-address "10.172.16.7"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/subnet-mask "255.255.255.0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/subnet-bits "24"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/mac-address "cc4e.25a5.21c0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/duplex "full"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/speed "10G"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/trunk "none"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/tag "true"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/pvid "0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/name "secondary"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/ip-address "10.172.17.7"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/subnet-mask "255.255.255.0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/subnet-bits "24"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/created "$(date '+%s')"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/modified ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/deleted ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/heartbeat/first ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/heartbeat/last ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/heartbeat/next-expected "$(date -d "+${PING_INTERVAL} minutes" '+%s')"
kv link /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID} /inventory/${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}


CIN_ID=$(uuid)
echo "Leaf 3/4: ${CIN_ID}"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}
kv link /defaults/sku/Brocade/FastIron/ICX-7850 /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/defaults
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ip-address "10.172.10.8"
kv copy /defaults/sku/Brocade/FastIron/ICX-7850/ssh/port /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/port
kv copy /defaults/sku/Brocade/FastIron/ICX-7850/ssh/authentication-method /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/authentication-method
kv copy /defaults/sku/Brocade/FastIron/ICX-7850/ssh/password/username /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMCIN_IDDCIN_ID_ID}/management/ssh/password/username
kv copy /defaults/sku/Brocade/FastIron/ICX-7850/ssh/password/password /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/password/password
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/public-key/key-type "rsa"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/public-key/key-value "/store/${CIN_ID}/id_rsa.ppk"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/host-based/key-type ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/host-based/key-value ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/fingerprint ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/snmp/community/read-only "ro"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/snmp/community/read-write "rw"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/snmp/community/trap "any"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/snmp/agent-version "v3"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/snmp/agent-port "161"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/role "leaf"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/state ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/mac-address "cc4e.24a5.22c0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/duplex "full"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/speed "10G"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/trunk "none"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/tag "true"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/pvid "0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/name "primry"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/ip-address "10.172.16.8"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/subnet-mask "255.255.255.0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/subnet-bits "24"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/mac-address "cc4e.25a5.22c0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/duplex "full"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/speed "10G"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/trunk "none"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/tag "true"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/pvid "0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/name "secondary"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/ip-address "10.172.17.8"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/subnet-mask "255.255.255.0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/subnet-bits "24"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/created "$(date '+%s')"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/modified ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/deleted ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/heartbeat/first ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/heartbeat/last ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/heartbeat/next-expected "$(date -d "+${PING_INTERVAL} minutes" '+%s')"
kv link /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID} /inventory/${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}

CIN_ID=$(uuid)
echo "Leaf 4/4: ${CIN_ID}"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}
kv link /defaults/sku/Brocade/FastIron/ICX-7850 /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/defaults
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ip-address "10.172.10.9"
kv copy /defaults/sku/Brocade/FastIron/ICX-7850/ssh/port /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/port
kv copy /defaults/sku/Brocade/FastIron/ICX-7850/ssh/authentication-method /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/authentication-method
kv copy /defaults/sku/Brocade/FastIron/ICX-7850/ssh/password/username /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${RMCIN_IDDCIN_ID_ID}/management/ssh/password/username
kv copy /defaults/sku/Brocade/FastIron/ICX-7850/ssh/password/password /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/password/password
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/public-key/key-type "rsa"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/public-key/key-value "/store/${CIN_ID}/id_rsa.ppk"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/host-based/key-type ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/host-based/key-value ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/ssh/fingerprint ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/snmp/community/read-only "ro"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/snmp/community/read-write "rw"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/snmp/community/trap "any"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/snmp/agent-version "v3"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/snmp/agent-port "161"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/role "leaf"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/management/state ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/mac-address "cc4e.24a5.23c0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/duplex "full"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/speed "10G"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/trunk "none"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/tag "true"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/pvid "0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/name "primary"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/ip-address "10.172.16.9"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/subnet-mask "255.255.255.0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/1/subnet-bits "24"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/mac-address "cc4e.25a5.23c0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/duplex "full"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/speed "10G"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/trunk "none"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/tag "true"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/pvid "0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/name "secondary"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/ip-address "10.172.17.9"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/subnet-mask "255.255.255.0"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/config/interfaces/ethernet/1/1/2/subnet-bits "24"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/created "$(date '+%s')"
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/modified ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/deleted ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/heartbeat/first ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/heartbeat/last ""
kv put /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}/heartbeat/next-expected "$(date -d "+${PING_INTERVAL} minutes" '+%s')"
kv link /${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID} /inventory/${TENANT_ID}/${REGION_ID}/${ZONE_ID}/${CIN_ID}
```

