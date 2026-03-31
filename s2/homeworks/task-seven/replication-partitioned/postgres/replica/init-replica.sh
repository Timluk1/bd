#!/bin/bash
# Точка входа контейнера реплики (замена стандартного entrypoint в docker-compose).
# Если каталог данных пустой — один раз копирует кластер с primary через pg_basebackup и настраивает standby.
# Если данные уже есть (повторный запуск контейнера) — пропускает бэкап и сразу запускает PostgreSQL.
set -euo pipefail

export PGPASSWORD="${REPLICATION_PASSWORD}"

if [ ! -s "${PGDATA}/PG_VERSION" ]; then
  # PG_VERSION отсутствует или пуст — считаем каталог неинициализированным, очищаем на всякий случай.
  rm -rf "${PGDATA:?}/"*

  # Ждём, пока primary примет подключения от пользователя репликации (иначе pg_basebackup упадёт).
  until pg_isready -h "${PRIMARY_HOST}" -p "${PRIMARY_PORT}" -U "${REPLICATION_USER}"; do
    sleep 1
  done

  # Физический бэкап с потоковой передачей WAL: -Fp plain, -Xs включает поток WAL, -R пишет standby.signal и primary_conninfo.
  # -S — именованный слот на primary (WAL для этой реплики не отбрасывается преждевременно).
  pg_basebackup \
    -h "${PRIMARY_HOST}" \
    -p "${PRIMARY_PORT}" \
    -D "${PGDATA}" \
    -U "${REPLICATION_USER}" \
    -S "${REPLICATION_SLOT}" \
    -Fp \
    -Xs \
    -P \
    -R

  # Стандартные права на каталог данных кластера PostgreSQL.
  chmod 0700 "${PGDATA}"
fi

# Дальше — правка auto.conf под compose и запуск официального entrypoint образа postgres.
exec /usr/local/bin/docker-entrypoint-replica.sh
