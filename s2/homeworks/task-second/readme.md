# ДЗ 3 — Индексы (B-tree, Hash)

## Подготовка

В миграции `V3__indexes.sql` уже были созданы индексы, поэтому перед проверкой я их удалил:

| Индекс | Таблица | Тип | Столбец |
|--------|---------|-----|---------|
| `idx_track_search` | track | GIN | search_vector |
| `idx_comment_search` | comment | GIN | search_vector |
| `idx_track_metadata` | track | GIN | metadata |
| `idx_user_preferences` | "user" | GIN | preferences |
| `idx_comment_reactions` | comment | GIN | reactions |
| `idx_listening_context` | listening_history | GIN | context |
| `idx_track_tags` | track | GIN | tags |
| `idx_user_genres` | "user" | GIN | favorite_genres |
| `idx_listening_location` | listening_history | GiST | location |
| `idx_user_sub_period` | "user" | GiST | subscription_period |
| `idx_listening_duration` | listening_history | GiST | listen_duration |

```sql
DROP INDEX IF EXISTS idx_track_search;
DROP INDEX IF EXISTS idx_comment_search;
DROP INDEX IF EXISTS idx_track_metadata;
DROP INDEX IF EXISTS idx_user_preferences;
DROP INDEX IF EXISTS idx_comment_reactions;
DROP INDEX IF EXISTS idx_listening_context;
DROP INDEX IF EXISTS idx_track_tags;
DROP INDEX IF EXISTS idx_user_genres;
DROP INDEX IF EXISTS idx_listening_location;
DROP INDEX IF EXISTS idx_user_sub_period;
DROP INDEX IF EXISTS idx_listening_duration;
```

---

## Запрос 1 — оператор `=`

```sql
SELECT * FROM "user" WHERE country = 'US';
```

### Без индекса

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM "user" WHERE country = 'US';
```

```
Seq Scan on "user"  (cost=0.00..9153.00 rows=61683 width=167) (actual time=0.013..50.940 rows=62368 loops=1)
  Filter: ((country)::text = 'US'::text)
  Rows Removed by Filter: 187632
  Buffers: shared hit=3913 read=2115
Planning Time: 0.159 ms
Execution Time: 52.886 ms
```

Без индекса PostgreSQL делает `Seq Scan`, то есть проходит по всей таблице. Время выполнения получилось `52.9 ms`.

### С B-tree индексом

```sql
CREATE INDEX idx_user_country_btree ON "user" USING BTREE (country);
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM "user" WHERE country = 'US';
```

```
Bitmap Heap Scan on "user"  (cost=694.46..7493.50 rows=61683 width=167) (actual time=4.094..37.568 rows=62368 loops=1)
  Recheck Cond: ((country)::text = 'US'::text)
  Heap Blocks: exact=6028
    Buffers: shared hit=4009 read=2074
  ->  Bitmap Index Scan on idx_user_country_btree  (cost=0.00..679.04 rows=61683 width=0) (actual time=2.932..2.932 rows=62368 loops=1)
        Index Cond: ((country)::text = 'US'::text)
        Buffers: shared read=55
Planning Time: 0.318 ms
Execution Time: 41.255 ms
```

С `B-tree` индексом уже используется `Bitmap Index Scan`. Улучшение есть, но оно небольшое, потому что по условию находится много строк.

### С Hash индексом

```sql
DROP INDEX idx_user_country_btree;
CREATE INDEX idx_user_country_hash ON "user" USING HASH (country);
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM "user" WHERE country = 'US';
```

```
Bitmap Heap Scan on "user"  (cost=1970.04..8769.08 rows=61683 width=167) (actual time=2.585..17.889 rows=62368 loops=1)
  Recheck Cond: ((country)::text = 'US'::text)
  Heap Blocks: exact=6028
  Buffers: shared hit=6183
  ->  Bitmap Index Scan on idx_user_country_hash  (cost=0.00..1954.62 rows=61683 width=0) (actual time=1.877..1.877 rows=62368 loops=1)
        Index Cond: ((country)::text = 'US'::text)
        Buffers: shared hit=155
Planning Time: 0.121 ms
Execution Time: 19.886 ms
```

С `Hash` индексом запрос выполнился быстрее, чем с `B-tree`: `19.9 ms` против `41.3 ms`. Для точного сравнения по `=` он подходит лучше.

```sql
DROP INDEX idx_user_country_hash;
```

---

## Запрос 2 — оператор `>`

```sql
SELECT * FROM track WHERE play_count > 9000000;
```

### Без индекса

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM track WHERE play_count > 9000000;
```

```
Seq Scan on track  (cost=0.00..24600.00 rows=8624 width=247) (actual time=15.839..576.047 rows=8639 loops=1)
  Filter: (play_count > 9000000)
  Rows Removed by Filter: 241361
  Buffers: shared hit=5915 read=15560
Planning Time: 0.084 ms
Execution Time: 576.791 ms
```

Без индекса снова получается полный проход по таблице. Здесь это уже заметно дольше: `576.8 ms`.

### С B-tree индексом

```sql
CREATE INDEX idx_track_playcount_btree ON track USING BTREE (play_count);
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM track WHERE play_count > 9000000;
```

```
Bitmap Heap Scan on track  (cost=159.26..16534.92 rows=8624 width=247) (actual time=1.287..7.807 rows=8639 loops=1)
  Recheck Cond: (play_count > 9000000)
  Heap Blocks: exact=5968
  Buffers: shared hit=5738 read=256
  ->  Bitmap Index Scan on idx_track_playcount_btree  (cost=0.00..157.10 rows=8624 width=0) (actual time=0.644..0.645 rows=8639 loops=1)
        Index Cond: (play_count > 9000000)
        Buffers: shared read=26
Planning Time: 0.129 ms
Execution Time: 8.076 ms
```

С `B-tree` индексом запрос ускорился очень сильно: `8.1 ms` вместо `576.8 ms`. Для диапазонных условий такой индекс хорошо подходит.

### С Hash индексом

```sql
DROP INDEX idx_track_playcount_btree;
CREATE INDEX idx_track_playcount_hash ON track USING HASH (play_count);
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM track WHERE play_count > 9000000;
```

```
Seq Scan on track  (cost=0.00..24600.00 rows=8624 width=247) (actual time=1.133..94.822 rows=8639 loops=1)
  Filter: (play_count > 9000000)
  Rows Removed by Filter: 241361
  Buffers: shared hit=6288 read=15187
Planning Time: 0.168 ms
Execution Time: 95.399 ms
```

`Hash` индекс здесь не используется, потому что он не поддерживает оператор `>`.

```sql
DROP INDEX idx_track_playcount_hash;
```

---

## Запрос 3 — оператор `<`

```sql
SELECT * FROM track WHERE duration_seconds < 120;
```

### Без индекса

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM track WHERE duration_seconds < 120;
```

```
Seq Scan on track  (cost=0.00..24600.00 rows=39033 width=247) (actual time=1.630..123.213 rows=39222 loops=1)
  Filter: (duration_seconds < 120)
  Rows Removed by Filter: 210778
  Buffers: shared hit=6320 read=15155
Planning Time: 4.638 ms
Execution Time: 124.874 ms
```

Без индекса выполняется полный проход по таблице, время `124.9 ms`.

### С B-tree индексом

```sql
CREATE INDEX idx_track_duration_btree ON track USING BTREE (duration_seconds);
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM track WHERE duration_seconds < 120;
```

```
Bitmap Heap Scan on track  (cost=442.80..22863.12 rows=39033 width=247) (actual time=3.700..67.080 rows=39222 loops=1)
  Recheck Cond: (duration_seconds < 120)
  Heap Blocks: exact=11569
  Buffers: shared hit=5761 read=5843
  ->  Bitmap Index Scan on idx_track_duration_btree  (cost=0.00..433.04 rows=39033 width=0) (actual time=2.063..2.064 rows=39222 loops=1)
        Index Cond: (duration_seconds < 120)
        Buffers: shared read=35
Planning Time: 0.152 ms
Execution Time: 68.707 ms
```

`B-tree` снова используется, но выигрыш уже не такой большой: `68.7 ms` вместо `124.9 ms`.

### С Hash индексом

```sql
DROP INDEX idx_track_duration_btree;
CREATE INDEX idx_track_duration_hash ON track USING HASH (duration_seconds);
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM track WHERE duration_seconds < 120;
```

```
Seq Scan on track  (cost=0.00..24600.00 rows=39033 width=247) (actual time=1.791..101.148 rows=39222 loops=1)
  Filter: (duration_seconds < 120)
  Rows Removed by Filter: 210778
  Buffers: shared hit=12262 read=9213
Planning Time: 0.169 ms
Execution Time: 106.546 ms
```

С `Hash` индексом ситуация такая же: оператор `<` он не поддерживает.

```sql
DROP INDEX idx_track_duration_hash;
```

---

## Запрос 4 — `LIKE 'prefix%'` и `IN`

```sql
SELECT * FROM "user" WHERE username LIKE 'user\_1%' AND country IN ('US', 'UK', 'DE');
```

### Без индекса

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM "user" WHERE username LIKE 'user\_1%' AND country IN ('US', 'UK', 'DE');
```

```
Seq Scan on "user"  (cost=0.00..10090.50 rows=57007 width=167) (actual time=0.061..77.739 rows=57753 loops=1)
  Buffers: shared hit=1154 read=4880
  ->  Parallel Seq Scan on "user"  (cost=0.00..7720.71 rows=2159 width=167) (actual time=5.838..24.008 rows=19251 loops=3)
        Filter: (((username)::text ~~ 'user\_1%'::text) AND ((country)::text = ANY ('{US,UK,DE}'::text[])))
        Rows Removed by Filter: 192247
        Buffers: shared hit=128 read=5900
Planning Time: 0.109 ms
Execution Time: 79.382 ms
```

Без индексов PostgreSQL использует `Parallel Seq Scan`. Время выполнения около `79 ms`.

### С B-tree индексом

```sql
CREATE INDEX idx_user_username_btree ON "user" USING BTREE (username varchar_pattern_ops);
CREATE INDEX idx_user_country_btree ON "user" USING BTREE (country);
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM "user" WHERE username LIKE 'user\_1%' AND country IN ('US', 'UK', 'DE');
```

```
Bitmap Heap Scan on "user"  (cost=1333.52..9445.86 rows=57007 width=167) (actual time=6.829..98.667 rows=57753 loops=1)
  Recheck Cond: ((country)::text = ANY ('{US,UK,DE}'::text[]))
  Filter: ((username)::text ~~ 'user\_1%'::text)
  Rows Removed by Filter: 72089
  Heap Blocks: exact=6028
  Buffers: shared hit=290 read=5852
  ->  Bitmap Index Scan on idx_user_country_btree  (cost=0.00..1319.27 rows=128267 width=0) (actual time=6.021..6.022 rows=129842 loops=1)
        Index Cond: ((country)::text = ANY ('{US,UK,DE}'::text[]))
        Buffers: shared hit=2 read=112
Planning Time: 7.228 ms
Execution Time: 47.675 ms
```

Здесь реально помог индекс по `country`. Условие `IN` отработало через `B-tree`, а `LIKE` применился уже после чтения строк.

### С Hash индексом

```sql
DROP INDEX idx_user_username_btree;
DROP INDEX idx_user_country_btree;
CREATE INDEX idx_user_username_hash ON "user" USING HASH (username);
CREATE INDEX idx_user_country_hash ON "user" USING HASH (country);
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM "user" WHERE username LIKE 'user\_1%' AND country IN ('US', 'UK', 'DE');
```

```
Seq Scan on "user"  (cost=0.00..10090.50 rows=57007 width=167) (actual time=0.007..36.546 rows=57753 loops=1)
  Filter: (((username)::text ~~ 'user\_1%'::text) AND ((country)::text = ANY ('{US,UK,DE}'::text[])))
  Rows Removed by Filter: 192247
  Buffers: shared hit=6028
Planning Time: 0.142 ms
Execution Time: 29.897 ms
```

`Hash` индексы тут пользы не дали. Для `LIKE` они не подходят, и в этом плане PostgreSQL их не использовал.

```sql
DROP INDEX idx_user_username_hash;
DROP INDEX idx_user_country_hash;
```

---

## Запрос 5 — `LIKE '%suffix'`

```sql
SELECT * FROM track WHERE title LIKE '%60';
```

### Без индекса

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM track WHERE title LIKE '%60';
```

```
Gather  (cost=1000.00..24029.58 rows=2525 width=247) (actual time=6.293..48.907 rows=2500 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  Buffers: shared hit=7647 read=13828
  ->  Parallel Seq Scan on track  (cost=0.00..22777.08 rows=1052 width=247) (actual time=5.723..44.409 rows=833 loops=3)
        Filter: ((title)::text ~~ '%60'::text)
        Rows Removed by Filter: 82500
        Buffers: shared hit=326 read=21149
Planning Time: 0.094 ms
Execution Time: 27.961 ms
```

Без индекса получаем `Parallel Seq Scan`, время `27.961 ms`.

### С B-tree индексом

```sql
CREATE INDEX idx_track_title_btree ON track USING BTREE (title);
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM track WHERE title LIKE '%60';
```

```
Gather  (cost=1000.00..24029.58 rows=2525 width=247) (actual time=88.325..310.106 rows=2500 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  Buffers: shared hit=7861 read=13614
  ->  Parallel Seq Scan on track  (cost=0.00..22777.08 rows=1052 width=247) (actual time=38.980..299.580 rows=833 loops=3)
        Filter: ((title)::text ~~ '%60'::text)
        Rows Removed by Filter: 82500
        Buffers: shared hit=4952 read=16523
Planning Time: 0.373 ms
Execution Time: 26.843 ms
```

`B-tree` индекс не помог, потому что шаблон начинается с `%`. В таком виде индекс не используется.

### С Hash индексом

```sql
DROP INDEX idx_track_title_btree;
CREATE INDEX idx_track_title_hash ON track USING HASH (title);
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM track WHERE title LIKE '%60';
```

```
Gather  (cost=1000.00..24029.58 rows=2525 width=247) (actual time=8.824..79.025 rows=2500 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  Buffers: shared hit=8011 read=13464
  ->  Parallel Seq Scan on track  (cost=0.00..22777.08 rows=1052 width=247) (actual time=2.973..44.681 rows=833 loops=3)
        Filter: ((title)::text ~~ '%60'::text)
        Rows Removed by Filter: 82500
        Buffers: shared hit=8011 read=13464
Planning Time: 0.123 ms
Execution Time: 23.366 ms
```

`Hash` индекс тоже не используется, потому что `LIKE` он не поддерживает.

---

## Краткое сравнение

| # | Оператор | Без индекса | B-tree | Hash |
|---|----------|-------------|--------|------|
| 1 | `=` | Seq Scan, 52.9 ms | Bitmap Index Scan, 41.3 ms | Bitmap Index Scan, 19.9 ms |
| 2 | `>` | Seq Scan, 576.8 ms | Bitmap Index Scan, 8.1 ms | Seq Scan, 95.4 ms |
| 3 | `<` | Seq Scan, 124.9 ms | Bitmap Index Scan, 68.7 ms | Seq Scan, 106.5 ms |
| 4 | `LIKE 'prefix%'` + `IN` | Par. Seq Scan, 79.4 ms | Bitmap Index Scan, 47.7 ms | Seq Scan, 29.9 ms |
| 5 | `LIKE '%suffix'` | Par. Seq Scan, 28.0 ms | Par. Seq Scan, 26.8 ms | Par. Seq Scan, 23.4 ms |

### Выводы

- `B-tree` оказался самым универсальным вариантом. Он подходит для `=`, диапазонов и части строковых условий вроде `LIKE 'prefix%'`.
- `Hash` имеет смысл в основном для точного сравнения по `=`.
- Для `LIKE '%...'` ни `B-tree`, ни `Hash` не подходят. Здесь нужен другой тип индекса, например `GIN` с `pg_trgm`.

---
