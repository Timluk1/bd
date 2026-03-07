# ДЗ 4 — GIN, GiST индексы и JOIN-запросы

## Подготовка: удаление существующих индексов

В миграции `V3__indexes.sql` были созданы GIN и GiST индексы. Удаляем их перед тестированием, чтобы они не влияли на планировщик:

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

## GIN-индексы

### Запрос 1 — поиск по JSONB (`@>`, preferences)

```sql
SELECT id, username FROM "user" WHERE preferences @> '{"lang": "ja"}';
```

#### Без индекса

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT id, username FROM "user" WHERE preferences @> '{"lang": "ja"}';
```

```
Seq Scan on "user"  (cost=0.00..9153.00 rows=56300 width=15) (actual time=0.130..126.495 rows=56243 loops=1)
  Filter: (preferences @> '{"lang": "ja"}'::jsonb)
  Rows Removed by Filter: 193757
  Buffers: shared read=6028
Planning Time: 1.630 ms
Execution Time: 128.579 ms
```

> **Seq Scan**, 6028 буферов, **128.6 ms**. Все 250 000 строк проверяются последовательно.

#### С GIN индексом

```sql
CREATE INDEX idx_user_preferences ON "user" USING GIN (preferences);
EXPLAIN (ANALYZE, BUFFERS) SELECT id, username FROM "user" WHERE preferences @> '{"lang": "ja"}';
```

```
Bitmap Heap Scan on "user"  (cost=436.37..7168.12 rows=56300 width=15) (actual time=7.112..44.544 rows=56243 loops=1)
  Recheck Cond: (preferences @> '{"lang": "ja"}'::jsonb)
  Heap Blocks: exact=6028
  Buffers: shared hit=130 read=5964
  ->  Bitmap Index Scan on idx_user_preferences  (cost=0.00..422.29 rows=56300 width=0) (actual time=6.505..6.505 rows=56243 loops=1)
        Index Cond: (preferences @> '{"lang": "ja"}'::jsonb)
        Buffers: shared hit=66
Planning Time: 0.215 ms
Execution Time: 46.144 ms
```

> **Bitmap Index Scan** по GIN. Индекс читает **66 буферов**, затем heap scan. **46.1 ms** vs 128.6 ms — ускорение в **2.8 раза**. GIN индексирует все ключи и значения JSONB, оператор `@>` работает через индекс.

```sql
DROP INDEX idx_user_preferences;
```

---

### Запрос 2 — поиск по JSONB (`@>`, metadata)

```sql
SELECT id, title, metadata FROM track WHERE metadata @> '{"explicit": true}';
```

#### Без индекса

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT id, title, metadata FROM track WHERE metadata @> '{"explicit": true}';
```

```
Seq Scan on track  (cost=0.00..24605.00 rows=37918 width=70) (actual time=21.303..173.087 rows=45000 loops=1)
  Filter: (metadata @> '{"explicit": true}'::jsonb)
  Rows Removed by Filter: 205000
  Buffers: shared hit=330 read=21150
Planning Time: 0.494 ms
Execution Time: 175.371 ms
```

> **Seq Scan**, 21 480 буферов, **175.4 ms**. Полный перебор 250 000 строк.

#### С GIN индексом

```sql
CREATE INDEX idx_track_metadata ON track USING GIN (metadata);
EXPLAIN (ANALYZE, BUFFERS) SELECT id, title, metadata FROM track WHERE metadata @> '{"explicit": true}';
```

```
Bitmap Heap Scan on track  (cost=265.65..22794.23 rows=37918 width=70) (actual time=7.882..49.378 rows=45000 loops=1)
  Recheck Cond: (metadata @> '{"explicit": true}'::jsonb)
  Heap Blocks: exact=12128
  Buffers: shared hit=6335 read=5865 written=1
  ->  Bitmap Index Scan on idx_track_metadata  (cost=0.00..256.18 rows=37918 width=0) (actual time=6.730..6.731 rows=45000 loops=1)
        Index Cond: (metadata @> '{"explicit": true}'::jsonb)
        Buffers: shared hit=72
Planning Time: 0.334 ms
Execution Time: 50.848 ms
```

> **Bitmap Index Scan** по GIN. Индекс читает **72 буфера**. **50.8 ms** vs 175.4 ms — ускорение в **3.5 раза**.

```sql
DROP INDEX idx_track_metadata;
```

---

### Запрос 3 — поиск по массиву тегов (`@>`)

```sql
SELECT id, title, tags FROM track WHERE tags @> ARRAY['rock']::text[];
```

#### Без индекса

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT id, title, tags FROM track WHERE tags @> ARRAY['rock']::text[];
```

```
Seq Scan on track  (cost=0.00..24605.00 rows=31558 width=57) (actual time=0.500..99.794 rows=31250 loops=1)
  Filter: (tags @> '{rock}'::text[])
  Rows Removed by Filter: 218750
  Buffers: shared hit=305 read=21182
Planning Time: 0.311 ms
Execution Time: 101.033 ms
```

> **Seq Scan**, 21 487 буферов, **101 ms**. Полный перебор 250 000 строк.

#### С GIN индексом

```sql
CREATE INDEX idx_track_tags ON track USING GIN (tags);
EXPLAIN (ANALYZE, BUFFERS) SELECT id, title, tags FROM track WHERE tags @> ARRAY['rock']::text[];
```

```
Bitmap Heap Scan on track  (cost=219.58..23156.21 rows=31558 width=57) (actual time=5.183..45.550 rows=31250 loops=1)
  Recheck Cond: (tags @> '{rock}'::text[])
  Heap Blocks: exact=11152
  Buffers: shared hit=8919 read=2242
  ->  Bitmap Index Scan on idx_track_tags  (cost=0.00..211.69 rows=31558 width=0) (actual time=3.256..3.257 rows=31250 loops=1)
        Index Cond: (tags @> '{rock}'::text[])
        Buffers: shared hit=9
Planning Time: 0.542 ms
Execution Time: 47.283 ms
```

> **Bitmap Index Scan** по GIN. Индекс читает **9 буферов**. **47.3 ms** vs 101 ms — ускорение в **2.1 раза**. GIN на массивах поддерживает `@>`, `<@`, `&&`.

```sql
DROP INDEX idx_track_tags;
```

---

### Запрос 4 — пересечение массивов (`&&`)

```sql
SELECT id, username, favorite_genres FROM "user" WHERE favorite_genres && ARRAY[1, 5]::integer[];
```

#### Без индекса

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT id, username, favorite_genres FROM "user" WHERE favorite_genres && ARRAY[1, 5]::integer[];
```

```
Seq Scan on "user"  (cost=0.00..9153.00 rows=63867 width=44) (actual time=0.134..184.960 rows=66667 loops=1)
  Filter: (favorite_genres && '{1,5}'::integer[])
  Rows Removed by Filter: 183333
  Buffers: shared hit=14 read=6021 dirtied=1
Planning Time: 0.248 ms
Execution Time: 188.140 ms
```

> **Seq Scan**, 6035 буферов, **188.1 ms**. Полный перебор 250 000 пользователей.

#### С GIN индексом

```sql
CREATE INDEX idx_user_genres ON "user" USING GIN (favorite_genres);
EXPLAIN (ANALYZE, BUFFERS) SELECT id, username, favorite_genres FROM "user" WHERE favorite_genres && ARRAY[1, 5]::integer[];
```

```
Bitmap Heap Scan on "user"  (cost=443.10..7269.44 rows=63867 width=44) (actual time=4.837..48.995 rows=66667 loops=1)
  Recheck Cond: (favorite_genres && '{1,5}'::integer[])
  Heap Blocks: exact=6028
  Buffers: shared hit=17 read=6027 written=1751
  ->  Bitmap Index Scan on idx_user_genres  (cost=0.00..427.13 rows=63867 width=0) (actual time=4.211..4.211 rows=66667 loops=1)
        Index Cond: (favorite_genres && '{1,5}'::integer[])
        Buffers: shared hit=16
Planning Time: 0.210 ms
Execution Time: 51.186 ms
```

> **Bitmap Index Scan** по GIN. Индекс читает **16 буферов**. **51.2 ms** vs 188.1 ms — ускорение в **3.7 раза**. Оператор `&&` (overlap) эффективно использует GIN на массивах.

```sql
DROP INDEX idx_user_genres;
```

---

### Запрос 5 — полнотекстовый поиск по комментариям (`@@`)

```sql
SELECT id, content FROM comment WHERE search_vector @@ to_tsquery('english', 'amazing & track');
```

#### Без индекса

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT id, content FROM comment WHERE search_vector @@ to_tsquery('english', 'amazing & track');
```

```
Gather  (cost=1000.00..12753.98 rows=2409 width=30) (actual time=21.719..106.528 rows=25000 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  Buffers: shared hit=8692 read=1519
  ->  Parallel Seq Scan on comment  (cost=0.00..11513.08 rows=1004 width=30) (actual time=13.466..95.351 rows=8333 loops=3)
        Filter: (search_vector @@ '''amaz'' & ''track'''::tsquery)
        Rows Removed by Filter: 75000
        Buffers: shared hit=8692 read=1519
Planning Time: 3.331 ms
Execution Time: 108.033 ms
```

> **Parallel Seq Scan**, **108 ms**. Все 250 000 комментариев проверяются параллельно.

#### С GIN индексом

```sql
CREATE INDEX idx_comment_search ON comment USING GIN (search_vector);
EXPLAIN (ANALYZE, BUFFERS) SELECT id, content FROM comment WHERE search_vector @@ to_tsquery('english', 'amazing & track');
```

```
Bitmap Heap Scan on comment  (cost=42.71..5722.81 rows=2409 width=30) (actual time=3.149..28.798 rows=25000 loops=1)
  Recheck Cond: (search_vector @@ '''amaz'' & ''track'''::tsquery)
  Heap Blocks: exact=5814
  Buffers: shared hit=58 read=5776
  ->  Bitmap Index Scan on idx_comment_search  (cost=0.00..42.11 rows=2409 width=0) (actual time=2.375..2.376 rows=25000 loops=1)
        Index Cond: (search_vector @@ '''amaz'' & ''track'''::tsquery)
        Buffers: shared hit=20
Planning Time: 0.660 ms
Execution Time: 29.691 ms
```

> **Bitmap Index Scan** по GIN. Индекс читает **20 буферов**. **29.7 ms** vs 108 ms — ускорение в **3.6 раза**. GIN строит инвертированный индекс по лексемам — пересечение `'amaz' & 'track'` выполняется быстро.

```sql
DROP INDEX idx_comment_search;
```

---

## GiST-индексы

### Запрос 1 — точка в окружности (геометрия, `<@`)

```sql
SELECT id, user_id, location FROM listening_history WHERE location <@ circle '((37.6173, 55.7558), 5)';
```

#### Без индекса

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT id, user_id, location FROM listening_history WHERE location <@ circle '((37.6173, 55.7558), 5)';
```

```
Gather  (cost=1000.00..6969.08 rows=250 width=24) (actual time=2.341..84.686 rows=261 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  Buffers: shared hit=1 read=4641
  ->  Parallel Seq Scan on listening_history  (cost=0.00..5944.08 rows=104 width=24) (actual time=2.694..78.453 rows=87 loops=3)
        Filter: (location <@ '<(37.6173,55.7558),5>'::circle)
        Rows Removed by Filter: 83245
        Buffers: shared hit=1 read=4641
Planning Time: 2.797 ms
Execution Time: 84.796 ms
```

> **Parallel Seq Scan**, 4642 буфера, **84.8 ms**. Каждая точка проверяется на попадание в окружность.

#### С GiST индексом

```sql
CREATE INDEX idx_listening_location ON listening_history USING GIST (location);
EXPLAIN (ANALYZE, BUFFERS) SELECT id, user_id, location FROM listening_history WHERE location <@ circle '((37.6173, 55.7558), 5)';
```

```
Bitmap Heap Scan on listening_history  (cost=10.22..821.52 rows=250 width=24) (actual time=0.198..1.600 rows=261 loops=1)
  Recheck Cond: (location <@ '<(37.6173,55.7558),5>'::circle)
  Heap Blocks: exact=252
  Buffers: shared hit=19 read=242
  ->  Bitmap Index Scan on idx_listening_location  (cost=0.00..10.16 rows=250 width=0) (actual time=0.149..0.150 rows=261 loops=1)
        Index Cond: (location <@ '<(37.6173,55.7558),5>'::circle)
        Buffers: shared read=9
Planning Time: 0.260 ms
Execution Time: 1.653 ms
```

> **Bitmap Index Scan** по GiST. Индекс читает **9 буферов**, heap — 252. **1.65 ms** vs 84.8 ms — ускорение в **51 раз**. GiST строит R-дерево по точкам — пространственные запросы выполняются значительно быстрее.

```sql
DROP INDEX idx_listening_location;
```

---

### Запрос 2 — поиск ближайших точек (KNN, `<->`)

```sql
SELECT id, user_id, location, location <-> point '(37.6173, 55.7558)' AS dist
FROM listening_history
WHERE location IS NOT NULL
ORDER BY location <-> point '(37.6173, 55.7558)'
LIMIT 10;
```

#### Без индекса

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT id, user_id, location, location <-> point '(37.6173, 55.7558)' AS dist
FROM listening_history WHERE location IS NOT NULL
ORDER BY location <-> point '(37.6173, 55.7558)' LIMIT 10;
```

```
Limit  (cost=8825.11..8826.28 rows=10 width=32) (actual time=35.689..37.769 rows=10 loops=1)
  Buffers: shared hit=171 read=4545
  ->  Gather Merge  (cost=8825.11..29551.22 rows=177640 width=32) (actual time=35.687..37.764 rows=10 loops=1)
        Workers Planned: 2
        Workers Launched: 2
        Buffers: shared hit=171 read=4545
        ->  Sort  (cost=7825.08..8047.13 rows=88820 width=32) (actual time=32.602..32.607 rows=9 loops=3)
              Sort Key: ((location <-> '(37.6173,55.7558)'::point))
              Sort Method: top-N heapsort  Memory: 26kB
              Buffers: shared hit=171 read=4545
              ->  Parallel Seq Scan on listening_history  (cost=0.00..5905.72 rows=88820 width=32) (actual time=0.018..21.513 rows=70921 loops=3)
                    Filter: (location IS NOT NULL)
                    Rows Removed by Filter: 12411
                    Buffers: shared hit=97 read=4545
Planning Time: 0.427 ms
Execution Time: 37.825 ms
```

> **Parallel Seq Scan + Sort**, 4716 буферов, **37.8 ms**. Все строки сканируются, сортируются по расстоянию и берутся топ-10.

#### С GiST индексом

```sql
CREATE INDEX idx_listening_location ON listening_history USING GIST (location);
EXPLAIN (ANALYZE, BUFFERS) SELECT id, user_id, location, location <-> point '(37.6173, 55.7558)' AS dist
FROM listening_history WHERE location IS NOT NULL
ORDER BY location <-> point '(37.6173, 55.7558)' LIMIT 10;
```

```
Limit  (cost=0.28..1.68 rows=10 width=32) (actual time=0.126..0.148 rows=10 loops=1)
  Buffers: shared hit=10 read=5
  ->  Index Scan using idx_listening_location on listening_history  (cost=0.28..29732.45 rows=213163 width=32) (actual time=0.125..0.145 rows=10 loops=1)
        Index Cond: (location IS NOT NULL)
        Order By: (location <-> '(37.6173,55.7558)'::point)
        Buffers: shared hit=10 read=5
Planning Time: 0.186 ms
Execution Time: 0.170 ms
```

> **Index Scan** по GiST с KNN-оптимизацией. Всего **15 буферов**. **0.17 ms** vs 37.8 ms — ускорение в **222 раза**. GiST поддерживает ORDER BY `<->` — вместо сортировки всех строк индекс сразу возвращает ближайшие.

```sql
DROP INDEX idx_listening_location;
```

---

### Запрос 3 — подписка содержит дату (range, `@>`)

```sql
SELECT id, username, subscription_period FROM "user" WHERE subscription_period @> '2024-02-25'::date;
```

#### Без индекса

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT id, username, subscription_period FROM "user" WHERE subscription_period @> '2024-02-25'::date;
```

```
Seq Scan on "user"  (cost=0.00..9153.00 rows=11038 width=29) (actual time=0.073..39.389 rows=9810 loops=1)
  Filter: (subscription_period @> '2024-02-25'::date)
  Rows Removed by Filter: 240190
  Buffers: shared hit=3430 read=2598
Planning Time: 0.311 ms
Execution Time: 39.756 ms
```

> **Seq Scan**, 6028 буферов, **39.8 ms**. Все 250 000 пользователей проверяются последовательно.

#### С GiST индексом

```sql
CREATE INDEX idx_user_sub_period ON "user" USING GIST (subscription_period);
EXPLAIN (ANALYZE, BUFFERS) SELECT id, username, subscription_period FROM "user" WHERE subscription_period @> '2024-02-25'::date;
```

```
Bitmap Heap Scan on "user"  (cost=373.83..6659.10 rows=11038 width=29) (actual time=2.827..16.163 rows=9810 loops=1)
  Recheck Cond: (subscription_period @> '2024-02-25'::date)
  Heap Blocks: exact=5276
  Buffers: shared hit=3160 read=2190
  ->  Bitmap Index Scan on idx_user_sub_period  (cost=0.00..371.07 rows=11038 width=0) (actual time=1.989..1.990 rows=9810 loops=1)
        Index Cond: (subscription_period @> '2024-02-25'::date)
        Buffers: shared hit=74
Planning Time: 0.278 ms
Execution Time: 16.536 ms
```

> **Bitmap Index Scan** по GiST. Индекс читает **74 буфера**. **16.5 ms** vs 39.8 ms — ускорение в **2.4 раза**. GiST строит дерево по интервалам — containment `@>` работает эффективно.

```sql
DROP INDEX idx_user_sub_period;
```

---

### Запрос 4 — пересечение range-диапазонов (`&&`, int4range)

```sql
SELECT id, user_id, listen_duration FROM listening_history WHERE listen_duration && int4range(580, 600);
```

#### Без индекса

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT id, user_id, listen_duration FROM listening_history WHERE listen_duration && int4range(580, 600);
```

```
Seq Scan on listening_history  (cost=0.00..7766.95 rows=8750 width=22) (actual time=0.016..53.132 rows=8780 loops=1)
  Filter: (listen_duration && '[580,600)'::int4range)
  Rows Removed by Filter: 241216
  Buffers: shared hit=586 read=4056
Planning Time: 0.167 ms
Execution Time: 53.511 ms
```

> **Seq Scan**, 4642 буфера, **53.5 ms**. Полный перебор 250 000 строк.

#### С GiST индексом

```sql
CREATE INDEX idx_listening_duration ON listening_history USING GIST (listen_duration);
EXPLAIN (ANALYZE, BUFFERS) SELECT id, user_id, listen_duration FROM listening_history WHERE listen_duration && int4range(580, 600);
```

```
Bitmap Heap Scan on listening_history  (cost=336.10..5151.40 rows=8750 width=22) (actual time=21.265..37.964 rows=8780 loops=1)
  Recheck Cond: (listen_duration && '[580,600)'::int4range)
  Heap Blocks: exact=3952
  Buffers: shared hit=1584 read=3927 written=1
  ->  Bitmap Index Scan on idx_listening_duration  (cost=0.00..333.91 rows=8750 width=0) (actual time=20.902..20.903 rows=8780 loops=1)
        Index Cond: (listen_duration && '[580,600)'::int4range)
        Buffers: shared hit=1559
Planning Time: 0.089 ms
Execution Time: 38.296 ms
```

> **Bitmap Index Scan** по GiST. **38.3 ms** vs 53.5 ms — ускорение в **1.4 раза**. Оператор `&&` (overlap) на range-типах поддерживается GiST.

```sql
DROP INDEX idx_listening_duration;
```

---

### Запрос 5 — подписки, пересекающиеся с периодом (`&&`, daterange)

```sql
SELECT id, username, subscription_period FROM "user" WHERE subscription_period && daterange('2024-02-25', '2024-02-28');
```

#### Без индекса

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT id, username, subscription_period FROM "user" WHERE subscription_period && daterange('2024-02-25', '2024-02-28');
```

```
Seq Scan on "user"  (cost=0.00..9153.00 rows=11038 width=29) (actual time=0.050..41.288 rows=9810 loops=1)
  Filter: (subscription_period && '[2024-02-25,2024-02-28)'::daterange)
  Rows Removed by Filter: 240190
  Buffers: shared hit=3462 read=2566
Planning Time: 0.158 ms
Execution Time: 41.730 ms
```

> **Seq Scan**, 6028 буферов, **41.7 ms**. Полный перебор 250 000 пользователей.

#### С GiST индексом

```sql
CREATE INDEX idx_user_sub_period ON "user" USING GIST (subscription_period);
EXPLAIN (ANALYZE, BUFFERS) SELECT id, username, subscription_period FROM "user" WHERE subscription_period && daterange('2024-02-25', '2024-02-28');
```

```
Bitmap Heap Scan on "user"  (cost=373.83..6659.10 rows=11038 width=29) (actual time=2.924..7.856 rows=9810 loops=1)
  Recheck Cond: (subscription_period && '[2024-02-25,2024-02-28)'::daterange)
  Heap Blocks: exact=5276
  Buffers: shared hit=5350
  ->  Bitmap Index Scan on idx_user_sub_period  (cost=0.00..371.07 rows=11038 width=0) (actual time=2.234..2.235 rows=9810 loops=1)
        Index Cond: (subscription_period && '[2024-02-25,2024-02-28)'::daterange)
        Buffers: shared hit=74
Planning Time: 0.171 ms
Execution Time: 8.205 ms
```

> **Bitmap Index Scan** по GiST. Индекс читает **74 буфера**. **8.2 ms** vs 41.7 ms — ускорение в **5.1 раза**.

```sql
DROP INDEX idx_user_sub_period;
```

---

## Восстановление индексов

После тестирования восстанавливаем все индексы из миграции:

```sql
CREATE INDEX idx_track_search ON track USING GIN (search_vector);
CREATE INDEX idx_comment_search ON comment USING GIN (search_vector);
CREATE INDEX idx_track_metadata ON track USING GIN (metadata);
CREATE INDEX idx_user_preferences ON "user" USING GIN (preferences);
CREATE INDEX idx_comment_reactions ON comment USING GIN (reactions);
CREATE INDEX idx_listening_context ON listening_history USING GIN (context);
CREATE INDEX idx_track_tags ON track USING GIN (tags);
CREATE INDEX idx_user_genres ON "user" USING GIN (favorite_genres);
CREATE INDEX idx_listening_location ON listening_history USING GIST (location);
CREATE INDEX idx_user_sub_period ON "user" USING GIST (subscription_period);
CREATE INDEX idx_listening_duration ON listening_history USING GIST (listen_duration);
```

---

## JOIN-запросы

### JOIN 1 — пользователи с подписками

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM "user" u
JOIN subscription s ON s.id = u.subscription_id;
```

```
  Hash Join  (cost=19.23..9210.26 rows=250000 width=337) (actual time=0.031..95.638 rows=250000 loops=1)                                                                                                                                          
    Hash Cond: (u.subscription_id = s.id)
    Buffers: shared hit=6029                                                                                                                                                                                                                      
    ->  Seq Scan on "user" u  (cost=0.00..8528.00 rows=250000 width=167) (actual time=0.012..19.423 rows=250000 loops=1)                                                                                                                          
          Buffers: shared hit=6028                                                                                                                                                                                                                
    ->  Hash  (cost=14.10..14.10 rows=410 width=170) (actual time=0.006..0.008 rows=5 loops=1)                                                                                                                                                    
          Buckets: 1024  Batches: 1  Memory Usage: 9kB                                                                                                                                                                                            
          Buffers: shared hit=1                                                                                                                                                                                                                   
          ->  Seq Scan on subscription s  (cost=0.00..14.10 rows=410 width=170) (actual time=0.002..0.003 rows=5 loops=1)                                                                                                                         
                Buffers: shared hit=1                                                                                                                                                                                                             
  Planning:                                                                                                                                                                                                                                       
    Buffers: shared hit=301                                                                                                                                                                                                                       
  Planning Time: 0.604 ms                                                                                                                                                                                                                         
  Execution Time: 103.907 ms     
```

> PostgreSQL выбрал `Hash Join`. Таблица `subscription` маленькая, поэтому по ней была построена hash-таблица, а затем к ней были присоединены строки из `"user"` по полю `subscription_id`. Основная стоимость здесь приходится на `Seq Scan` таблицы `"user"`, потому что в запросе нет фильтра и читаются все 250000 строк.

---

### JOIN 2 — история прослушиваний с треками

```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT lh.user_id, t.id, t.title FROM listening_history lh
JOIN track t ON t.id = lh.track_id;
```

```
  Nested Loop  (cost=0.01..13507.39 rows=249996 width=20) (actual time=0.081..116.067 rows=249996 loops=1)
    Buffers: shared hit=5346 read=1070
    ->  Seq Scan on listening_history lh  (cost=0.00..7141.96 rows=249996 width=8) (actual time=0.031..35.004 rows=249996 loops=1)
          Buffers: shared hit=3572 read=1070
    ->  Memoize  (cost=0.01..0.39 rows=1 width=16) (actual time=0.000..0.000 rows=1 loops=249996)
          Cache Key: lh.track_id                                                                                                                                                                                                                  
          Cache Mode: logical                                                                                                                                                                                                                     
          Hits: 249123  Misses: 873  Evictions: 0  Overflows: 0  Memory Usage: 98kB                                                                                                                                                               
          Buffers: shared hit=1774                                                                                                                                                                                                                
          ->  Index Scan using idx_track_id on track t  (cost=0.00..0.38 rows=1 width=16) (actual time=0.004..0.004 rows=1 loops=873)                                                                                                             
                Index Cond: (id = lh.track_id)                                                                                                                                                                                                    
                Buffers: shared hit=1774                                                                                                                                                                                                          
  Planning:                                                                                                                                                                                                                                       
    Buffers: shared hit=236                                                                                                                                                                                                                       
  Planning Time: 0.552 ms                                                                                                                                                                                                                         
  Execution Time: 123.894 ms  
```

> Здесь используется `Nested Loop`. Сначала PostgreSQL читает всю таблицу `listening_history`, а потом для каждой строки подбирает запись из `track` по `track_id`. Чтобы не выполнять один и тот же поиск много раз, используется `Memoize`: индексный поиск по `track` реально выполнился только для новых значений ключа, а остальные обращения были взяты из кэша.

---

### JOIN 3 — артисты и связанные пользователи

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT ar.id, ar.name, u.username
FROM artist ar
JOIN "user" u ON u.id = ar.user_id;
```

```
Nested Loop  (cost=0.43..1331.75 rows=5000 width=26) (actual time=0.054..6.498 rows=275 loops=1)
  Buffers: shared hit=1204
  ->  Seq Scan on artist ar  (cost=0.00..154.00 rows=5000 width=19) (actual time=0.009..0.386 rows=5000 loops=1)
        Buffers: shared hit=104
  ->  Memoize  (cost=0.43..3.83 rows=1 width=15) (actual time=0.001..0.001 rows=0 loops=5000)
        Cache Key: ar.user_id
        Cache Mode: logical
        Hits: 4724  Misses: 276  Evictions: 0  Overflows: 0  Memory Usage: 32kB
        Buffers: shared hit=1100
        ->  Index Scan using user_pkey on "user" u  (cost=0.42..3.82 rows=1 width=15) (actual time=0.017..0.017 rows=1 loops=276)
              Index Cond: (id = ar.user_id)
              Buffers: shared hit=1100
Planning:
  Buffers: shared hit=260
Planning Time: 0.564 ms
Execution Time: 6.561 ms
```

> PostgreSQL снова выбрал `Nested Loop`. Сначала читается таблица `artist`, а затем для каждого значения `user_id` ищется пользователь по первичному ключу. За счёт `Memoize` одинаковые значения `user_id` не ищутся повторно: из 5000 обращений только 276 потребовали реальный `Index Scan`, остальные были взяты из кэша.

---

### JOIN 4 — альбомы и артисты

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT a.id, a.title, ar.name
FROM album a
JOIN artist ar ON ar.id = a.artist_id;
```

```
Hash Join  (cost=216.50..716.18 rows=25000 width=26) (actual time=2.931..18.820 rows=25000 loops=1)
  Hash Cond: (a.artist_id = ar.id)
  Buffers: shared hit=105 read=183
  ->  Seq Scan on album a  (cost=0.00..434.00 rows=25000 width=19) (actual time=0.051..12.314 rows=25000 loops=1)
        Buffers: shared hit=1 read=183
  ->  Hash  (cost=154.00..154.00 rows=5000 width=15) (actual time=2.852..2.853 rows=5000 loops=1)
        Buckets: 8192  Batches: 1  Memory Usage: 299kB
        Buffers: shared hit=104
        ->  Seq Scan on artist ar  (cost=0.00..154.00 rows=5000 width=15) (actual time=0.025..2.136 rows=5000 loops=1)
              Buffers: shared hit=104
Planning:
  Buffers: shared hit=207
Planning Time: 0.557 ms
Execution Time: 19.581 ms
```

> Здесь используется `Hash Join`. PostgreSQL прочитал таблицу `artist`, построил по ней hash-таблицу, а затем последовательно прошёл по `album` и сопоставил строки по `artist_id`. Для такого соединения план получился простым и быстрым.

---

### JOIN 5 — комментарии и пользователи

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.id, c.content, u.username
FROM comment c
JOIN "user" u ON u.id = c.user_id;
```

```
Nested Loop  (cost=0.43..19127.73 rows=250000 width=41) (actual time=70.154..322.768 rows=250000 loops=1)
  Buffers: shared hit=4082 read=9761
  ->  Seq Scan on comment c  (cost=0.00..12711.00 rows=250000 width=34) (actual time=69.201..222.180 rows=250000 loops=1)
        Buffers: shared hit=450 read=9761
  ->  Memoize  (cost=0.43..0.55 rows=1 width=15) (actual time=0.000..0.000 rows=1 loops=250000)
        Cache Key: c.user_id
        Cache Mode: logical
        Hits: 249092  Misses: 908  Evictions: 0  Overflows: 0  Memory Usage: 103kB
        Buffers: shared hit=3632
        ->  Index Scan using user_pkey on "user" u  (cost=0.42..0.54 rows=1 width=15) (actual time=0.006..0.006 rows=1 loops=908)
              Index Cond: (id = c.user_id)
              Buffers: shared hit=3632
Planning:
  Buffers: shared hit=233
Planning Time: 2.282 ms
Execution Time: 332.023 ms
```

> PostgreSQL выбрал `Nested Loop` с `Memoize`. Сначала была прочитана вся таблица `comment`, после чего для каждого `user_id` искался пользователь по первичному ключу. Повторяющиеся значения `user_id` кэшируются, поэтому из 250000 обращений только 908 потребовали реальный поиск по индексу.

---

## Сравнительная таблица — GIN

| # | Оператор | Без индекса | С GIN | Ускорение |
|---|----------|-------------|-------|-----------|
| 1 | `@>` (JSONB, preferences) | Seq Scan, 128.6 ms | Bitmap Index Scan, 46.1 ms | **2.8×** |
| 2 | `@>` (JSONB, metadata) | Seq Scan, 175.4 ms | Bitmap Index Scan, 50.8 ms | **3.5×** |
| 3 | `@>` (array, tags) | Seq Scan, 101.0 ms | Bitmap Index Scan, 47.3 ms | **2.1×** |
| 4 | `&&` (array, genres) | Seq Scan, 188.1 ms | Bitmap Index Scan, 51.2 ms | **3.7×** |
| 5 | `@@` (tsvector, FTS) | Par. Seq Scan, 108.0 ms | Bitmap Index Scan, 29.7 ms | **3.6×** |

## Сравнительная таблица — GiST

| # | Оператор | Без индекса | С GiST | Ускорение |
|---|----------|-------------|--------|-----------|
| 1 | `<@` (point in circle) | Par. Seq Scan, 84.8 ms | Bitmap Index Scan, 1.65 ms | **51×** |
| 2 | `<->` (KNN, ORDER BY) | Par. Seq Scan + Sort, 37.8 ms | Index Scan, 0.17 ms | **222×** |
| 3 | `@>` (daterange containment) | Seq Scan, 39.8 ms | Bitmap Index Scan, 16.5 ms | **2.4×** |
| 4 | `&&` (int4range overlap) | Seq Scan, 53.5 ms | Bitmap Index Scan, 38.3 ms | **1.4×** |
| 5 | `&&` (daterange overlap) | Seq Scan, 41.7 ms | Bitmap Index Scan, 8.2 ms | **5.1×** |
