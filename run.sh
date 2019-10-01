#!/bin/bash
set -euxo pipefail

action="$1"

shift

# Default options
host="localhost"
username="postgres"
database="postgres"
fqdn="$HOSTNAME"
snapshot="latest"

while getopts h:u:d:f:s: opt; do
  case $opt in
    h) host="$OPTARG";;
    u) username="$OPTARG";;
    d) database="$OPTARG";;
    f) fqdn="$OPTARG";;
    s) snapshot="$OPTARG";;
    *) exit 1
  esac
done

filename="/$database.psql"

backup() {
  pg_dump --host="$host" --username="$username" --create "$database" | \
    restic --option=s3.storage-class=INTELLIGENT_TIERING backup \
    --host="$fqdn" --stdin --stdin-filename="$filename"
}

restore() {
  psql --host="$host" --username="$username" <<EOF
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$database';
DROP DATABASE $database;
EOF

  restic dump "$snapshot" "$filename" | \
    psql --host="$host" --username="$username"
}

latest() {
  restic snapshots --host="$fqdn" --path="$filename" --json | jq -r '.[-1]|.id'
}

case $action in
  backup)
    backup
    ;;
  restore)
    if [ "$snapshot" == "latest" ]; then
      snapshot=$(latest)
    fi
    backup
    restore
    ;;
  *)
    exit 1
    ;;
esac
