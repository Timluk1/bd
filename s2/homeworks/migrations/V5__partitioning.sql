-- V5__partitioning.sql: секционирование (RANGE / LIST / HASH)
-- Создаём партицированные версии таблиц для демонстрации.
-- Оригинальные таблицы не трогаем, чтобы не ломать FK-связи.

CREATE TABLE listening_history_part (
    id              SERIAL,
    user_id         INT NOT NULL,
    track_id        INT NOT NULL,
    listened_at     TIMESTAMP NOT NULL,
    device          VARCHAR(50),
    platform        VARCHAR(20),
    completed       BOOLEAN NOT NULL DEFAULT true,
    quality         VARCHAR(10) NOT NULL DEFAULT 'normal'
) PARTITION BY RANGE (listened_at);

CREATE TABLE lh_part_2023 PARTITION OF listening_history_part
    FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');
CREATE TABLE lh_part_2024 PARTITION OF listening_history_part
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
CREATE TABLE lh_part_2025 PARTITION OF listening_history_part
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE INDEX idx_lh_part_listened_at ON listening_history_part (listened_at);
CREATE INDEX idx_lh_part_user_id ON listening_history_part (user_id);

-- Переливаем данные из оригинальной таблицы
INSERT INTO listening_history_part (user_id, track_id, listened_at, device, platform, completed, quality)
SELECT user_id, track_id, listened_at, device, platform, completed, quality
FROM listening_history
WHERE listened_at IS NOT NULL
  AND listened_at >= '2023-01-01' AND listened_at < '2026-01-01';

-- ===========================================
-- LIST: track_part по жанру (genre.name)
-- ===========================================
CREATE TABLE track_part (
    id               SERIAL,
    title            VARCHAR(100) NOT NULL,
    duration_seconds INT NOT NULL,
    artist_id        INT,
    album_id         INT,
    genre_name       VARCHAR(50) NOT NULL,
    play_count       INT NOT NULL DEFAULT 0,
    mood             VARCHAR(20)
) PARTITION BY LIST (genre_name);

CREATE TABLE track_part_rock    PARTITION OF track_part FOR VALUES IN ('Rock', 'rock');
CREATE TABLE track_part_pop     PARTITION OF track_part FOR VALUES IN ('Pop', 'pop');
CREATE TABLE track_part_hiphop  PARTITION OF track_part FOR VALUES IN ('Hip-Hop', 'hip-hop');
CREATE TABLE track_part_jazz    PARTITION OF track_part FOR VALUES IN ('Jazz', 'jazz');
CREATE TABLE track_part_other   PARTITION OF track_part DEFAULT;

CREATE INDEX idx_track_part_genre ON track_part (genre_name);
CREATE INDEX idx_track_part_artist ON track_part (artist_id);

-- Переливаем данные: подставляем genre.name
INSERT INTO track_part (title, duration_seconds, artist_id, album_id, genre_name, play_count, mood)
SELECT t.title, t.duration_seconds, t.artist_id, t.album_id,
       COALESCE(g.name, 'Other'), t.play_count, t.mood
FROM track t
LEFT JOIN genre g ON g.id = t.genre_id;

-- ===========================================
-- HASH: like_part по user_id
-- ===========================================
CREATE TABLE like_part (
    id         SERIAL,
    user_id    INT NOT NULL,
    track_id   INT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT now()
) PARTITION BY HASH (user_id);

-- ===========================================
-- Разбиваем на 4 партиции, для каждой партиции используем остаток от деления user_id на 4
-- ===========================================
CREATE TABLE like_part_p0 PARTITION OF like_part FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE like_part_p1 PARTITION OF like_part FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE like_part_p2 PARTITION OF like_part FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE like_part_p3 PARTITION OF like_part FOR VALUES WITH (MODULUS 4, REMAINDER 3);

CREATE INDEX idx_like_part_user ON like_part (user_id);

-- Переливаем данные из оригинальной таблицы
INSERT INTO like_part (user_id, track_id, created_at)
SELECT user_id, track_id, COALESCE(created_at, now())
FROM "like";
