#!/bin/bash
kv prune
# root
kv put /system
kv put /system/audit
kv put /inventory
kv put /defaults
kv put /templates

# system-wide operational defaults
kv put /system/heartbeat/timeout "5"
kv put /system/heartbeat/ttl "10"
kv put /system/heartbeat/count "1"
kv put /system/heartbeat/interval "60"
kv put /system/ssh/timeout "5"
kv put /system/ssh/max-wait "300"
kv put /system/ssh/max-retries "3"
kv put /system/ssh/retry-interval "600"
kv put /system/audit/enable "true"
kv put /system/audit/days-to-keep "1"
kv put /system/audit/max-events "500"
kv put /system/audit/encrypt "true"
kv put /system/callback/timeout "5"
kv put /system/callback/max-wait "300"
kv put /system/callback/max-retries "3"

kv put /system/onboard/queue/interval "15"
kv put /system/onboard/queue/max-retries "3"
kv put /system/template/queue/interval "15"
kv put /system/template/queue/max-retries "3"
kv put /system/heartbeat/queue/interval "15"
kv put /system/heartbeat/queue/max-retries "3"
kv put /system/clissh/queue/interval "15"
kv put /system/clissh/queue/max-retries "3"
kv put /system/alarm/queue/interval "15"
kv put /system/alarm/queue/max-retries "3"
kv put /system/cli2kv/queue/interval "15"
kv put /system/cli2kv/queue/max-retries "3"
kv put /system/notification/queue/interval "15"
kv put /system/notification/queue/max-retries "3"
kv put /system/callback/queue/interval "15"
kv put /system/callback/queue/max-retries "3"

kv prune /system/queue
kv put /system/queue/onboard
kv put /system/queue/template
kv put /system/queue/clissh
kv put /system/queue/heartbeat
kv put /system/queue/alarm
kv put /system/queue/cli2kv
kv put /system/queue/notification
kv put /system/queue/callback

# /defaults/sku/${VENDOR}/${MODEL_FAMILY}/${MODEL_TYPE}/...

kv put /defaults/sku/CommScope/RMD/RD2322/vendor "CommScope"
kv put /defaults/sku/CommScope/RMD/RD2322/model-family "RMD"
kv put /defaults/sku/CommScope/RMD/RD2322/model-type "RD2322"
kv put /defaults/sku/CommScope/RMD/RD2322/firmware/min-version "RMD_V01.00.00.0271"
kv put /defaults/sku/CommScope/RMD/RD2322/firmware/min-name ""
kv put /defaults/sku/CommScope/RMD/RD2322/dhcpv4/options/1 "255.255.255.0" # subnet mask
kv put /defaults/sku/CommScope/RMD/RD2322/dhcpv4/options/3 "10.172.16.1" # list of routers
kv put /defaults/sku/CommScope/RMD/RD2322/dhcpv4/options/4 "10.1.1.1" # Time of Day (TOD) server
kv put /defaults/sku/CommScope/RMD/RD2322/dhcpv4/options/6 "10.171.1.1" # DNS server
kv put /defaults/sku/CommScope/RMD/RD2322/dhcpv4/options/7 "10.172.16.2" # log server
kv put /defaults/sku/CommScope/RMD/RD2322/dhcpv4/options/42 "10.172.16.2" # NTP server
kv put /defaults/sku/CommScope/RMD/RD2322/dhcpv4/options/60 "RMD" # client supplied vendor-defined
kv put /defaults/sku/CommScope/RMD/RD2322/dhcpv4/options/61 "...." # client supplied mac-address
kv put /defaults/sku/CommScope/RMD/RD2322/dhcpv4/options/67 "tftp://rmdmgr1:2597/rd2322.default.cfg" # bootfile URL <protocol> "://" <host> [":" <port> ] "/" <path> "/" <filename>
kv put /defaults/sku/CommScope/RMD/RD2322/dhcpv4/options/100 "EST5EDT4,M3.2.0/02:00,M11.1.0/02:00" # time zone
kv put /defaults/sku/CommScope/RMD/RD2322/dhcpv4/options/101 "America/New_York" # time zone
kv put /defaults/sku/CommScope/RMD/RD2322/cli/ssh-idle-timeout-duration "600"
kv put /defaults/sku/CommScope/RMD/RD2322/cli/ssh-idle-timeout "ip ssh idle-timeout"
kv put /defaults/sku/CommScope/RMD/RD2322/cli/enable-username "admin"
kv put /defaults/sku/CommScope/RMD/RD2322/cli/enable-password "admin"
kv put /defaults/sku/CommScope/RMD/RD2322/cli/erase-config "erase nvram"
kv put /defaults/sku/CommScope/RMD/RD2322/cli/reset-config "reset nvram"
kv put /defaults/sku/CommScope/RMD/RD2322/cli/save-config "write memory"
kv put /defaults/sku/CommScope/RMD/RD2322/cli/copy-config "copy running-config {{url}}"
kv put /defaults/sku/CommScope/RMD/RD2322/ssh/authentication-method "password"
kv put /defaults/sku/CommScope/RMD/RD2322/ssh/password/username "admin"
kv put /defaults/sku/CommScope/RMD/RD2322/ssh/password/password "admin"
kv put /defaults/sku/CommScope/RMD/RD2322/ssh/port "22"

kv put /defaults/sku/CommScope/FastIron/ICX-7850/vendor "CommScope"
kv put /defaults/sku/CommScope/FastIron/ICX-7850/model-family "FastIron"
kv put /defaults/sku/CommScope/FastIron/ICX-7850/model-type "ICX-7850"
kv put /defaults/sku/CommScope/FastIron/ICX-7850/firmware/pri/min-version "08.0.30hT311"
kv put /defaults/sku/CommScope/FastIron/ICX-7850/firmware/pri/min-name "ICX78S08030h.bin"
kv put /defaults/sku/CommScope/FastIron/ICX-7850/firmware/sec/min-version "07.4.00jT311"
kv put /defaults/sku/CommScope/FastIron/ICX-7850/firmware/sec/min-name "ICX78S07400j.bin"
kv put /defaults/sku/CommScope/FastIron/ICX-7850/firmware/monitor/min-version "10.1.05T310"
kv put /defaults/sku/CommScope/FastIron/ICX-7850/firmware/monitor/min-name ""
kv put /defaults/sku/CommScope/FastIron/ICX-7850/dhcpv4/options/1 "255.255.255.0" # subnet mask
kv put /defaults/sku/CommScope/FastIron/ICX-7850/dhcpv4/options/3 "10.172.16.1" # list of routers
kv put /defaults/sku/CommScope/FastIron/ICX-7850/dhcpv4/options/4 "10.1.1.1" # Time of Day (TOD) server
kv put /defaults/sku/CommScope/FastIron/ICX-7850/dhcpv4/options/6 "10.171.1.1" # DNS server
kv put /defaults/sku/CommScope/FastIron/ICX-7850/dhcpv4/options/7 "10.172.16.2" # log server
kv put /defaults/sku/CommScope/FastIron/ICX-7850/dhcpv4/options/42 "10.172.16.2" # NTP server
kv put /defaults/sku/CommScope/FastIron/ICX-7850/dhcpv4/options/60 "ICX" # client supplied vendor-defined
kv put /defaults/sku/CommScope/FastIron/ICX-7850/dhcpv4/options/61 "...." # client supplied mac-address
kv put /defaults/sku/CommScope/FastIron/ICX-7850/dhcpv4/options/67 "tftp://icxmgr1:2597/icx7850.default.cfg" # bootfile URL <protocol> "://" <host> [":" <port> ] "/" <path> "/" <filename>
kv put /defaults/sku/CommScope/FastIron/ICX-7850/dhcpv4/options/100 "EST5EDT4,M3.2.0/02:00,M11.1.0/02:00" # time zone
kv put /defaults/sku/CommScope/FastIron/ICX-7850/dhcpv4/options/101 "America/New_York" # time zone
kv put /defaults/sku/CommScope/FastIron/ICX-7850/cli/enable-username "admin"
kv put /defaults/sku/CommScope/FastIron/ICX-7850/cli/enable-password "admin"
kv put /defaults/sku/CommScope/FastIron/ICX-7850/cli/erase-config "write erase"
kv put /defaults/sku/CommScope/FastIron/ICX-7850/cli/save-config "write mem"
kv put /defaults/sku/CommScope/FastIron/ICX-7850/cli/copy-config "copy running-config {{url}}"
kv put /defaults/sku/CommScope/FastIron/ICX-7850/ssh/authentication-method "password"
kv put /defaults/sku/CommScope/FastIron/ICX-7850/ssh/password/username "admin"
kv put /defaults/sku/CommScope/FastIron/ICX-7850/ssh/password/password "admin"
kv put /defaults/sku/CommScope/FastIron/ICX-7850/ssh/port "22"

kv put /defaults/sku/CommScope/FastIron/ICX-6430/vendor "CommScope"
kv put /defaults/sku/CommScope/FastIron/ICX-6430/model-family "FastIron"
kv put /defaults/sku/CommScope/FastIron/ICX-6430/model-type "ICX-6430"
kv put /defaults/sku/CommScope/FastIron/ICX-6430/firmware/pri/min-version "08.0.30hT311"
kv put /defaults/sku/CommScope/FastIron/ICX-6430/firmware/pri/min-name "ICX64S08030h.bin"
kv put /defaults/sku/CommScope/FastIron/ICX-6430/firmware/sec/min-version "07.4.00jT311"
kv put /defaults/sku/CommScope/FastIron/ICX-6430/firmware/sec/min-name "ICX64S07400j.bin"
kv put /defaults/sku/CommScope/FastIron/ICX-6430/firmware/monitor/min-version "10.1.05T310"
kv put /defaults/sku/CommScope/FastIron/ICX-6430/firmware/monitor/min-name ""
kv put /defaults/sku/CommScope/FastIron/ICX-6430/dhcpv4/options/1 "255.255.255.0" # subnet mask
kv put /defaults/sku/CommScope/FastIron/ICX-6430/dhcpv4/options/3 "10.172.16.1" # list of routers
kv put /defaults/sku/CommScope/FastIron/ICX-6430/dhcpv4/options/4 "10.1.1.1" # Time of Day (TOD) server
kv put /defaults/sku/CommScope/FastIron/ICX-6430/dhcpv4/options/6 "10.171.1.1" # DNS server
kv put /defaults/sku/CommScope/FastIron/ICX-6430/dhcpv4/options/7 "10.172.16.2" # log server
kv put /defaults/sku/CommScope/FastIron/ICX-6430/dhcpv4/options/42 "10.172.16.2" # NTP server
kv put /defaults/sku/CommScope/FastIron/ICX-6430/dhcpv4/options/60 "ICX" # client supplied vendor-defined
kv put /defaults/sku/CommScope/FastIron/ICX-6430/dhcpv4/options/61 "...." # client supplied mac-address
kv put /defaults/sku/CommScope/FastIron/ICX-6430/dhcpv4/options/67 "tftp://icxmgr1:2597/icx6430.default.cfg" # bootfile URL <protocol> "://" <host> [":" <port> ] "/" <path> "/" <filename>
kv put /defaults/sku/CommScope/FastIron/ICX-6430/dhcpv4/options/100 "EST5EDT4,M3.2.0/02:00,M11.1.0/02:00" # time zone
kv put /defaults/sku/CommScope/FastIron/ICX-6430/dhcpv4/options/101 "America/New_York" # time zone
kv put /defaults/sku/CommScope/FastIron/ICX-6430/cli/erase-config "write erase"
kv put /defaults/sku/CommScope/FastIron/ICX-6430/cli/enable-username "admin"
kv put /defaults/sku/CommScope/FastIron/ICX-6430/cli/enable-password "admin"
kv put /defaults/sku/CommScope/FastIron/ICX-6430/cli/erase-config "write erase"
kv put /defaults/sku/CommScope/FastIron/ICX-6430/cli/save-config "write mem"
kv put /defaults/sku/CommScope/FastIron/ICX-6430/cli/copy-config "copy running-config {{url}}"
kv put /defaults/sku/CommScope/FastIron/ICX-6430/ssh/authentication-method "password"
kv put /defaults/sku/CommScope/FastIron/ICX-6430/ssh/password/username "admin"
kv put /defaults/sku/CommScope/FastIron/ICX-6430/ssh/password/password "admin"
kv put /defaults/sku/CommScope/FastIron/ICX-6430/ssh/port "22"

kv put /defaults/sku/CommScope/FastIron/ICX-6450/vendor "CommScope"
kv put /defaults/sku/CommScope/FastIron/ICX-6450/model-family "FastIron"
kv put /defaults/sku/CommScope/FastIron/ICX-6450/model-type "ICX-6450"
kv put /defaults/sku/CommScope/FastIron/ICX-6450/firmware/pri/min-version "08.0.30hT311"
kv put /defaults/sku/CommScope/FastIron/ICX-6450/firmware/pri/min-name "ICX64S08030h.bin"
kv put /defaults/sku/CommScope/FastIron/ICX-6450/firmware/sec/min-version "07.4.00jT311"
kv put /defaults/sku/CommScope/FastIron/ICX-6450/firmware/sec/min-name "ICX64S07400j.bin"
kv put /defaults/sku/CommScope/FastIron/ICX-6450/firmware/monitor/min-version "10.1.05T310"
kv put /defaults/sku/CommScope/FastIron/ICX-6450/firmware/monitor/min-name ""
kv put /defaults/sku/CommScope/FastIron/ICX-6450/dhcpv4/options/1 "255.255.255.0" # subnet mask
kv put /defaults/sku/CommScope/FastIron/ICX-6450/dhcpv4/options/3 "10.172.16.1" # list of routers
kv put /defaults/sku/CommScope/FastIron/ICX-6450/dhcpv4/options/4 "10.1.1.1" # Time of Day (TOD) server
kv put /defaults/sku/CommScope/FastIron/ICX-6450/dhcpv4/options/6 "10.171.1.1" # DNS server
kv put /defaults/sku/CommScope/FastIron/ICX-6450/dhcpv4/options/7 "10.172.16.2" # log server
kv put /defaults/sku/CommScope/FastIron/ICX-6450/dhcpv4/options/42 "10.172.16.2" # NTP server
kv put /defaults/sku/CommScope/FastIron/ICX-6450/dhcpv4/options/60 "ICX" # client supplied vendor-defined
kv put /defaults/sku/CommScope/FastIron/ICX-6450/dhcpv4/options/61 "...." # client supplied mac-address
kv put /defaults/sku/CommScope/FastIron/ICX-6450/dhcpv4/options/67 "tftp://icxmgr1:2597/icx6450.default.cfg" # bootfile URL <protocol> "://" <host> [":" <port> ] "/" <path> "/" <filename>
kv put /defaults/sku/CommScope/FastIron/ICX-6450/dhcpv4/options/100 "EST5EDT4,M3.2.0/02:00,M11.1.0/02:00" # time zone
kv put /defaults/sku/CommScope/FastIron/ICX-6450/dhcpv4/options/101 "America/New_York" # time zone
kv put /defaults/sku/CommScope/FastIron/ICX-6450/cli/enable-username "admin"
kv put /defaults/sku/CommScope/FastIron/ICX-6450/cli/enable-password "admin"
kv put /defaults/sku/CommScope/FastIron/ICX-6450/cli/erase-config "write erase"
kv put /defaults/sku/CommScope/FastIron/ICX-6450/cli/save-config "write mem"
kv put /defaults/sku/CommScope/FastIron/ICX-6450/cli/copy-config "copy running-config {{url}}"
kv put /defaults/sku/CommScope/FastIron/ICX-6450/ssh/authentication-method "password"
kv put /defaults/sku/CommScope/FastIron/ICX-6450/ssh/password/username "admin"
kv put /defaults/sku/CommScope/FastIron/ICX-6450/ssh/password/password "admin"
kv put /defaults/sku/CommScope/FastIron/ICX-6450/ssh/port "22"

kv put /defaults/sku/CommScope/BigIron/E6000/vendor "CommScope"
kv put /defaults/sku/CommScope/BigIron/E6000/model-family "BigIron"
kv put /defaults/sku/CommScope/BigIron/E6000/model-type "E6000"
kv put /defaults/sku/CommScope/BigIron/E6000/firmware/min-version "RMD_V01.00.00.0271"
kv put /defaults/sku/CommScope/BigIron/E6000/firmware/min-name ""
kv put /defaults/sku/CommScope/BigIron/E6000/cli/enable-username "admin"
kv put /defaults/sku/CommScope/BigIron/E6000/cli/enable-password "admin"
kv put /defaults/sku/CommScope/BigIron/E6000/cli/erase-config "erase nvram"
kv put /defaults/sku/CommScope/BigIron/E6000/cli/reset-config "reset nvram"
kv put /defaults/sku/CommScope/BigIron/E6000/cli/save-config "write memory"
kv put /defaults/sku/CommScope/BigIron/E6000/cli/copy-config "copy running-config verbose {{url}}"
kv put /defaults/sku/CommScope/BigIron/E6000/ssh/authentication-method "password"
kv put /defaults/sku/CommScope/BigIron/E6000/ssh/password/username "admin"
kv put /defaults/sku/CommScope/BigIron/E6000/ssh/password/password "admin"
kv put /defaults/sku/CommScope/BigIron/E6000/ssh/port "22"

kv put /defaults/sku/CommScope/CNS/VUE/vendor "CommScope"
kv put /defaults/sku/CommScope/CNS/VUE/model-family "CNS"
kv put /defaults/sku/CommScope/CNS/VUE/model-type "VUE"
kv put /defaults/sku/CommScope/CNS/VUE/network/packets/maximum-pipe-bit-rate "0"
kv put /defaults/sku/CommScope/CNS/VUE/network/packets/bandwidth-in-use "0"
kv put /defaults/sku/CommScope/CNS/VUE/network/packets/output-ts-rates "0" # outputTsRates = dataRates + outputTsInsertionRates + nullPacketRates
kv put /defaults/sku/CommScope/CNS/VUE/network/packets/output-ts-insertion-rates "0"
kv put /defaults/sku/CommScope/CNS/VUE/network/packets/null-packet-rates "0"
kv put /defaults/sku/CommScope/CNS/VUE/network/packets/data-rates "0"
kv put /defaults/sku/CommScope/CNS/VUE/network/packets/average/total-abr-packet-rate "0"
kv put /defaults/sku/CommScope/CNS/VUE/network/packets/average/total-udp-packet-rate "0"
kv put /defaults/sku/CommScope/CNS/VUE/accp/auxCoreId "000000123465",
kv put /defaults/sku/CommScope/CNS/VUE/accp/auxCoreName "stclara1E2E_VUE_Aux"
kv put /defaults/sku/CommScope/CNS/VUE/accp/gcpKeepAliveInterval "3"
kv put /defaults/sku/CommScope/CNS/VUE/accp/gcpKeepAliveTimeout "10"
kv put /defaults/sku/CommScope/CNS/VUE/accp/gcpIpAddress "fc00:d00:a:1b00::150"
kv put /defaults/sku/CommScope/CNS/VUE/accp/statPollingInterval "60"
kv put /defaults/sku/CommScope/CNS/VUE/accp/statPollingEnabled "true"
kv put /defaults/sku/CommScope/CNS/VUE/accp/gcpRecoverActionRetry "16"
kv put /defaults/sku/CommScope/CNS/VUE/accp/gcpRecoverActionDelay "30"
kv put /defaults/sku/CommScope/CNS/VUE/accp/gcpReconnectTimeout "30"

