#!/usr/bin/env bash
# Build the us_dc_energy_forecast MySQL database from the SQL files in this repo.
# Usage: ./build_database.sh [mysql client options]
#   e.g. ./build_database.sh -u root -p
# The schema script drops and recreates the database, so re-running starts clean.
set -euo pipefail
cd "$(dirname "$0")"

# One connection for everything (one password prompt). utf8mb4 keeps characters
# such as "°" and "–" in scenario names intact.
{
  cat us_dc_energy_forecast_database.sql
  ls Forecast_SQL/[0-9]*.sql | sort -V | while read -r f; do
    cat "$f"
    echo
  done
} | mysql --default-character-set=utf8mb4 "$@"

echo "Database us_dc_energy_forecast built."
