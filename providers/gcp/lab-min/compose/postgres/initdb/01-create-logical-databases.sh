#!/usr/bin/env sh
set -eu

create_database() {
  db_name="$1"

  psql --username "$POSTGRES_USER" --dbname postgres --tuples-only --command \
    "SELECT 1 FROM pg_database WHERE datname = '${db_name}'" | grep -q 1 && return 0

  psql --username "$POSTGRES_USER" --dbname postgres --command \
    "CREATE DATABASE \"${db_name}\" OWNER \"${POSTGRES_USER}\""
}

create_database "${DB_APP_NAME:-app_data}"
create_database "${DB_ISSUER_WALLET_NAME:-issuer_wallet}"
create_database "${DB_VERIFIER_WALLET_NAME:-verifier_wallet}"
