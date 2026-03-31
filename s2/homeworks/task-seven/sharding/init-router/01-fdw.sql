-- Подключаем расширение postgres_fdw
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Создаём foreign server для каждого шарда
CREATE SERVER shard1_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'shard1', port '5432', dbname 'shard_db');

CREATE SERVER shard2_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'shard2', port '5432', dbname 'shard_db');

-- Маппинг пользователей
CREATE USER MAPPING FOR postgres
    SERVER shard1_server
    OPTIONS (user 'postgres', password 'postgres');

CREATE USER MAPPING FOR postgres
    SERVER shard2_server
    OPTIONS (user 'postgres', password 'postgres');

-- Родительская партицированная таблица track на router
CREATE TABLE track (
    id               INT NOT NULL,
    title            VARCHAR(100) NOT NULL,
    duration_seconds INT NOT NULL,
    artist_id        INT,
    album_id         INT,
    genre            VARCHAR(50),
    play_count       INT NOT NULL DEFAULT 0,
    mood             VARCHAR(20)
) PARTITION BY RANGE (id);

-- Foreign-таблицы как партиции
CREATE FOREIGN TABLE track_shard1
    PARTITION OF track
    FOR VALUES FROM (1) TO (501)
    SERVER shard1_server
    OPTIONS (table_name 'track');

CREATE FOREIGN TABLE track_shard2
    PARTITION OF track
    FOR VALUES FROM (501) TO (1001)
    SERVER shard2_server
    OPTIONS (table_name 'track');
