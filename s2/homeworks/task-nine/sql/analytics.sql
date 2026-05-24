-- Аналитические запросы к star-схеме olap

\echo '=== 1. Динамика прослушиваний по дням ==='

SELECT
    d.full_date,
    d.day_name,
    d.is_weekend,
    SUM(f.listen_count)                              AS total_listens,
    COUNT(DISTINCT f.user_key)                       AS unique_users,
    ROUND(100.0 * SUM(f.completed_count) / NULLIF(SUM(f.listen_count), 0), 1)
                                                     AS completion_pct
FROM olap.fact_listening f
JOIN olap.dim_date d ON d.date_key = f.date_key
GROUP BY d.full_date, d.day_name, d.is_weekend, d.date_key
ORDER BY d.full_date;


\echo '=== 2. Топ-10 треков и топ жанров по прослушиваниям ==='

SELECT
    dt.title,
    dt.artist_name,
    dg.genre_name,
    SUM(f.listen_count) AS listens
FROM olap.fact_listening f
JOIN olap.dim_track dt ON dt.track_key = f.track_key
JOIN olap.dim_genre dg ON dg.genre_key = f.genre_key
GROUP BY dt.title, dt.artist_name, dg.genre_name
ORDER BY listens DESC
LIMIT 10;

SELECT
    dg.genre_name,
    SUM(f.listen_count) AS listens,
    COUNT(DISTINCT f.user_key) AS unique_listeners
FROM olap.fact_listening f
JOIN olap.dim_genre dg ON dg.genre_key = f.genre_key
GROUP BY dg.genre_name
ORDER BY listens DESC;


\echo '=== 3. Активность пользователей по стране и подписке ==='

SELECT
    du.country,
    du.subscription_name,
    COUNT(DISTINCT du.user_key)                      AS users,
    SUM(f.listen_count)                              AS total_listens,
    ROUND(SUM(f.listen_count)::numeric
          / NULLIF(COUNT(DISTINCT du.user_key), 0), 1)
                                                     AS avg_listens_per_user,
    ROUND(100.0 * SUM(f.completed_count) / NULLIF(SUM(f.listen_count), 0), 1)
                                                     AS completion_pct
FROM olap.fact_listening f
JOIN olap.dim_user du ON du.user_key = f.user_key
GROUP BY du.country, du.subscription_name
ORDER BY total_listens DESC;


\echo '=== 4. (доп.) Прослушивания по устройствам и платформам ==='

SELECT
    COALESCE(f.device, 'unknown')   AS device,
    COALESCE(f.platform, 'unknown') AS platform,
    SUM(f.listen_count)             AS listens
FROM olap.fact_listening f
GROUP BY f.device, f.platform
ORDER BY listens DESC;
