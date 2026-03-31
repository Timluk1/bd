#!/bin/bash
# Приводит postgresql.auto.conf и standby.signal в согласованное состояние для hot standby.
# Вызывается перед каждым стартом postgres в контейнере реплики (из docker-entrypoint-replica.sh).
# Нужен потому, что pg_basebackup -R мог записать другой primary_conninfo; здесь перезаписываем из переменных окружения.
set -euo pipefail

# Удаляем старые строки, чтобы не дублировать параметры при повторных запусках.
sed -i "/^primary_conninfo = /d" "$PGDATA/postgresql.auto.conf"
sed -i "/^primary_slot_name = /d" "$PGDATA/postgresql.auto.conf"
sed -i "/^hot_standby = /d" "$PGDATA/postgresql.auto.conf"
sed -i "/^default_transaction_read_only = /d" "$PGDATA/postgresql.auto.conf"

# primary_conninfo — куда стримить WAL; primary_slot_name — слот на мастере для этой реплики.
# hot_standby — разрешить подключения на чтение во время recovery; read_only — запрет записи на standby.
cat <<-CONF >> "$PGDATA/postgresql.auto.conf"
primary_conninfo = 'host=${PRIMARY_HOST} port=${PRIMARY_PORT} user=${REPLICATION_USER} password=${REPLICATION_PASSWORD}'
primary_slot_name = '${REPLICATION_SLOT}'
hot_standby = 'on'
default_transaction_read_only = 'on'
CONF

# Файл-маркер: при его наличии сервер стартует в режиме standby (реплика), а не как самостоятельный primary.
touch "$PGDATA/standby.signal"
