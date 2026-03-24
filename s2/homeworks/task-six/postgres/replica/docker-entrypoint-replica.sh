#!/bin/bash
# Обёртка над стандартным docker-entrypoint.sh образа postgres для реплики.
# Сначала синхронизируем настройки standby с переменными окружения, затем запускаем сам PostgreSQL.
set -euo pipefail

/usr/local/bin/configure-standby.sh

# Официальный entrypoint образа postgres: инициализация при необходимости и exec postgres.
exec docker-entrypoint.sh postgres
