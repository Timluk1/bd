#!/bin/bash
# Скрипт первичной инициализации мастера PostgreSQL.
# Запускается образом postgres один раз при первом создании кластера (docker-entrypoint-initdb.d).
# Назначение: завести пользователя репликации, слоты для физической репликации и правила pg_hba,
# чтобы standby мог подключаться по сети.
set -euo pipefail

# Роль с правом REPLICATION — ею пользуется pg_basebackup и потоковая репликация на standby.
# Слоты фиксируют позицию в WAL для каждой реплики, чтобы primary не удалял WAL, пока реплика не догонит.
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-SQL
  CREATE ROLE ${REPLICATION_USER} WITH REPLICATION LOGIN PASSWORD '${REPLICATION_PASSWORD}';
  SELECT pg_create_physical_replication_slot('standby1_slot');
SQL

# Разрешаем подключения для репликации и обычных клиентов с любых адресов (в учебном compose; в проде сузить сеть).
cat <<-HBA >> "$PGDATA/pg_hba.conf"
host replication ${REPLICATION_USER} 0.0.0.0/0 md5
host all all 0.0.0.0/0 md5
HBA
