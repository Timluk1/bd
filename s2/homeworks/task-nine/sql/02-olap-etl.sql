-- ETL для основной БД проекта (порт 5433)
-- Перед повторным запуском очистите таблицы:
--   TRUNCATE olap.fact_listening, olap.dim_user, olap.dim_track, olap.dim_genre, olap.dim_date RESTART IDENTITY CASCADE;

INSERT INTO olap.dim_date (
    date_key, full_date, day_of_week, day_name,
    week_of_year, month_number, month_name,
    quarter_number, year_number, is_weekend
)
SELECT DISTINCT
    TO_CHAR(d::date, 'YYYYMMDD')::INTEGER,
    d::date,
    EXTRACT(ISODOW FROM d)::SMALLINT,
    TRIM(TO_CHAR(d, 'TMDay')),
    EXTRACT(WEEK FROM d)::SMALLINT,
    EXTRACT(MONTH FROM d)::SMALLINT,
    TRIM(TO_CHAR(d, 'TMMonth')),
    EXTRACT(QUARTER FROM d)::SMALLINT,
    EXTRACT(YEAR FROM d)::SMALLINT,
    EXTRACT(ISODOW FROM d) IN (6, 7)
FROM (
    SELECT listened_at::date AS d FROM listening_history
    UNION
    SELECT date_joined FROM "user" WHERE date_joined IS NOT NULL
) AS dates
ON CONFLICT (date_key) DO NOTHING;

INSERT INTO olap.dim_user (user_id, username, country, subscription_name, date_joined)
SELECT u.id, u.username, u.country, s.name, u.date_joined
FROM "user" u
LEFT JOIN subscription s ON s.id = u.subscription_id
ON CONFLICT (user_id) DO UPDATE SET
    username          = EXCLUDED.username,
    country           = EXCLUDED.country,
    subscription_name = EXCLUDED.subscription_name,
    date_joined       = EXCLUDED.date_joined;

INSERT INTO olap.dim_track (track_id, title, artist_name, album_title, duration_seconds)
SELECT t.id, t.title, a.name, al.title, t.duration_seconds
FROM track t
LEFT JOIN artist a  ON a.id  = t.artist_id
LEFT JOIN album al  ON al.id = t.album_id
ON CONFLICT (track_id) DO UPDATE SET
    title            = EXCLUDED.title,
    artist_name      = EXCLUDED.artist_name,
    album_title      = EXCLUDED.album_title,
    duration_seconds = EXCLUDED.duration_seconds;

INSERT INTO olap.dim_genre (genre_id, genre_name)
SELECT id, name FROM genre
ON CONFLICT (genre_id) DO UPDATE SET genre_name = EXCLUDED.genre_name;

INSERT INTO olap.fact_listening (
    listening_id, date_key, user_key, track_key, genre_key,
    device, platform, quality, completed, listen_count, completed_count
)
SELECT
    lh.id,
    TO_CHAR(lh.listened_at::date, 'YYYYMMDD')::INTEGER,
    du.user_key,
    dt.track_key,
    dg.genre_key,
    lh.device,
    lh.platform,
    COALESCE(lh.quality, 'normal'),
    COALESCE(lh.completed, true),
    1,
    CASE WHEN COALESCE(lh.completed, true) THEN 1 ELSE 0 END
FROM listening_history lh
JOIN olap.dim_user  du ON du.user_id  = lh.user_id
JOIN olap.dim_track dt ON dt.track_id = lh.track_id
JOIN track t           ON t.id        = lh.track_id
JOIN olap.dim_genre dg ON dg.genre_id = t.genre_id
ON CONFLICT (listening_id) DO NOTHING;
