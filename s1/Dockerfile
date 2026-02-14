FROM postgres:16

# Установка необходимых пакетов для сборки
RUN apt-get update && apt-get install -y \
    postgresql-16-cron \
    && rm -rf /var/lib/apt/lists/*
