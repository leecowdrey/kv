# kv - BASH Key-Value Store

## usage

Usage: kv [operation]
Operation:
   audit purge | read [event UUID] | count |ls
   cat [Key-Name] # encrpted value
   copy|cp [source Key-Name] [destination Key-Name]
   count [Key-Name]
   delete|rm [Key-Name] # + empty 1st child delete+audit+subscriptions
   dump [Key-Name]
   find {[Key-Name] | [Key{* ? []} ]
   get [Key-Name] # unencrypted value
   has [Key-Name]
   help
   is [Key-Name]
   link|ln [source Key-Name] [destination Key-Name]
   list [Key-Name] # full Key-Name returned
   ls [Key-Name] # short Key-Name returned
   modified ["HH:MM mm/dd/yyyy"] # default now - 1 minute
   move|mv [source Key-Name] [destination parent Key-Name]
   prune [Key-Name] # full cascade delete+no audit+no subscriptions
   put|set [Key-Name] [Key-Value]
   query [Key-Name] --key=Sub-Key-Name --value=Sub-Key-Value]
   subscribe|sub --key=[Key-Name] {--command=cmd | --callback=url | --signal=process-name | --fifo=fifo-name }
   subscriptions {--key=[Key-Name]}
   tree [Key-Name]
   unlink|uln [Key-Name]
   unsubscribe|unsub --key=[Key-Name]

