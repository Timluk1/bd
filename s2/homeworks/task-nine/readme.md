# ДЗ 9 — OLAP-модель

Star-схема для OLTP музыкального стриминга в схеме `olap`. Используется PostgreSQL из `s2/homeworks/docker-compose.yml` (порт `5433`).

## Модель

**Вопросы:**
1. Динамика прослушиваний по дням
2. Топ треков и жанров
3. Активность пользователей по стране и подписке

**Факт:** `olap.fact_listening` ← `listening_history`  
**Зерно:** 1 строка = одно прослушивание

**Измерения:**

| Таблица | Аналог | Содержание |
|---------|--------|------------|
| `dim_date` | `dim_date` | календарь |
| `dim_user` | `dim_user` | пользователь, страна, подписка |
| `dim_track` | `dim_product` | трек, артист, альбом |
| `dim_genre` | `dim_category` | жанр |

```
                    dim_date
                       |
dim_user ---- fact_listening ---- dim_track
                       |
                    dim_genre
```

## Запуск

```bash
cd s2/homeworks
docker compose up -d pg flyway
```

Дальше по порядку (PowerShell):

```powershell
Get-Content task-nine/sql/00-seed-minimal.sql -Raw | docker compose exec -T pg psql -U user -d music
Get-Content task-nine/sql/01-olap-ddl.sql -Raw   | docker compose exec -T pg psql -U user -d music
Get-Content task-nine/sql/02-olap-etl.sql -Raw   | docker compose exec -T pg psql -U user -d music
Get-Content task-nine/sql/analytics.sql -Raw       | docker compose exec -T pg psql -U user -d music
```

`00-seed-minimal.sql` — тестовые данные, если в БД ещё пусто. Если уже есть seed из `task-first/seed.js`, этот шаг можно пропустить.

Подключение: `localhost:5433`, БД `music`, `user` / `password`.

## ETL

```
      tbl       | count
----------------+-------
 dim_date       |    15
 dim_user       |     5
 dim_track      |    10
 dim_genre      |     5
 fact_listening |    30
```

## Аналитические запросы

### 1. Прослушивания по дням

```sql
SELECT
    d.full_date,
    d.day_name,
    d.is_weekend,
    SUM(f.listen_count) AS total_listens,
    COUNT(DISTINCT f.user_key) AS unique_users,
    ROUND(100.0 * SUM(f.completed_count) / NULLIF(SUM(f.listen_count), 0), 1) AS completion_pct
FROM olap.fact_listening f
JOIN olap.dim_date d ON d.date_key = f.date_key
GROUP BY d.full_date, d.day_name, d.is_weekend, d.date_key
ORDER BY d.full_date;
```

```
 full_date  | day_name  | is_weekend | total_listens | unique_users | completion_pct
------------+-----------+------------+---------------+--------------+----------------
 2024-05-01 | Wednesday | f          |             4 |            3 |           75.0
 2024-05-02 | Thursday  | f          |             3 |            3 |          100.0
 2024-05-03 | Friday    | f          |             4 |            2 |           75.0
 2024-05-04 | Saturday  | t          |             4 |            2 |          100.0
 2024-05-05 | Sunday    | t          |             3 |            2 |           66.7
 2024-05-06 | Monday    | f          |             2 |            2 |          100.0
 2024-05-07 | Tuesday   | f          |             3 |            3 |          100.0
 2024-05-08 | Wednesday | f          |             2 |            2 |          100.0
 2024-05-09 | Thursday  | f          |             2 |            2 |          100.0
 2024-05-10 | Friday    | f          |             3 |            3 |           66.7
```

### 2. Топ треков и жанров

```sql
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
```

```
      title       |  artist_name   | genre_name | listens
------------------+----------------+------------+---------
 Get Lucky        | Daft Punk      | Electronic |       7
 HUMBLE.          | Kendrick Lamar | Hip-Hop    |       6
 bad guy          | Billie Eilish  | Pop        |       5
 Do I Wanna Know? | Arctic Monkeys | Rock       |       4
 Paranoid Android | Radiohead      | Rock       |       3
```

```sql
SELECT
    dg.genre_name,
    SUM(f.listen_count) AS listens,
    COUNT(DISTINCT f.user_key) AS unique_listeners
FROM olap.fact_listening f
JOIN olap.dim_genre dg ON dg.genre_key = f.genre_key
GROUP BY dg.genre_name
ORDER BY listens DESC;
```

```
 genre_name | listens | unique_listeners
------------+---------+------------------
 Rock       |       9 |                4
 Electronic |       8 |                5
 Hip-Hop    |       7 |                4
 Pop        |       6 |                3
```

### 3. Страна и подписка

```sql
SELECT
    du.country,
    du.subscription_name,
    COUNT(DISTINCT du.user_key) AS users,
    SUM(f.listen_count) AS total_listens,
    ROUND(SUM(f.listen_count)::numeric / NULLIF(COUNT(DISTINCT du.user_key), 0), 1) AS avg_listens_per_user,
    ROUND(100.0 * SUM(f.completed_count) / NULLIF(SUM(f.listen_count), 0), 1) AS completion_pct
FROM olap.fact_listening f
JOIN olap.dim_user du ON du.user_key = f.user_key
GROUP BY du.country, du.subscription_name
ORDER BY total_listens DESC;
```

```
 country | subscription_name | users | total_listens | avg_listens_per_user | completion_pct
---------+-------------------+-------+---------------+----------------------+----------------
 RU      | premium           |     1 |             9 |                  9.0 |          100.0
 RU      | free              |     1 |             6 |                  6.0 |           83.3
 US      | basic             |     1 |             6 |                  6.0 |           66.7
 UK      | premium           |     1 |             5 |                  5.0 |           80.0
 DE      | family            |     1 |             4 |                  4.0 |          100.0
```
