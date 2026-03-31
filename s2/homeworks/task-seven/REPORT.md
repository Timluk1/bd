# Домашняя работа 7 — Отчёт

## Часть 1. Секционирование: RANGE / LIST / HASH

Секционирование реализовано через миграцию `V5__partitioning.sql`. Запуск основного стенда:

```bash
cd s2/homeworks && docker compose up -d
```

Flyway автоматически применяет миграцию. Подключение:

```bash
docker exec -it homeworks-pg-1 psql -U user -d music
```

### 1.1 RANGE: listening_history_part по listened_at

**Запрос с фильтром (partition pruning):**

```sql
EXPLAIN ANALYZE
SELECT * FROM listening_history_part
WHERE listened_at BETWEEN '2024-01-01' AND '2024-12-31';
```

```
 Bitmap Heap Scan on lh_part_2024 listening_history_part  (cost=4.17..9.51 rows=2 width=235) (actual time=0.012..0.013 rows=0 loops=1)
   Recheck Cond: ((listened_at >= '2024-01-01 00:00:00') AND (listened_at <= '2024-12-31 00:00:00'))
   ->  Bitmap Index Scan on lh_part_2024_listened_at_idx  (cost=0.00..4.17 rows=2 width=0) (actual time=0.003..0.003 rows=0 loops=1)
         Index Cond: ((listened_at >= '2024-01-01 00:00:00') AND (listened_at <= '2024-12-31 00:00:00'))
 Planning Time: 7.769 ms
 Execution Time: 0.046 ms
```

PostgreSQL обратился только к партиции `lh_part_2024`. Партиции `lh_part_2023` и `lh_part_2025` были полностью отсечены — их нет в плане.

| Вопрос | Ответ |
|---|---|
| Partition pruning | **Да** — сканируется только `lh_part_2024` |
| Партиций в плане | **1** из 3 |
| Используется ли индекс | **Да** — `Bitmap Index Scan` по `lh_part_2024_listened_at_idx` |

**Запрос без фильтра (pruning отсутствует):**

```sql
EXPLAIN ANALYZE SELECT * FROM listening_history_part;
```

```
 Append  (cost=0.00..43.95 rows=930 width=235) (actual time=0.012..0.013 rows=0 loops=1)
   ->  Seq Scan on lh_part_2023 listening_history_part_1  (cost=0.00..13.10 rows=310 width=235) (actual time=0.008..0.008 rows=0 loops=1)
   ->  Seq Scan on lh_part_2024 listening_history_part_2  (cost=0.00..13.10 rows=310 width=235) (actual time=0.002..0.002 rows=0 loops=1)
   ->  Seq Scan on lh_part_2025 listening_history_part_3  (cost=0.00..13.10 rows=310 width=235) (actual time=0.001..0.001 rows=0 loops=1)
 Planning Time: 3.210 ms
 Execution Time: 0.042 ms
```

Без фильтра по `listened_at` PostgreSQL вынужден сканировать все 3 партиции через `Seq Scan`. Partition pruning невозможен — планировщик не знает, какие партиции можно отсечь.

### 1.2 LIST: track_part по genre_name

```sql
EXPLAIN ANALYZE
SELECT * FROM track_part WHERE genre_name = 'Rock';
```

```
 Index Scan using track_part_rock_genre_name_idx on track_part_rock track_part  (cost=0.14..8.16 rows=1 width=414) (actual time=0.005..0.005 rows=0 loops=1)
   Index Cond: ((genre_name)::text = 'Rock'::text)
 Planning Time: 4.035 ms
 Execution Time: 0.042 ms
```

PostgreSQL обратился только к партиции `track_part_rock`. Партиции `track_part_pop`, `track_part_hiphop`, `track_part_jazz`, `track_part_other` отсечены.

| Вопрос | Ответ |
|---|---|
| Partition pruning | **Да** — сканируется только `track_part_rock` |
| Партиций в плане | **1** из 5 |
| Используется ли индекс | **Да** — `Index Scan` по `track_part_rock_genre_name_idx` |

### 1.3 HASH: like_part по user_id

```sql
EXPLAIN ANALYZE
SELECT * FROM like_part WHERE user_id = 7;
```

```
 Bitmap Heap Scan on like_part_p3 like_part  (cost=4.21..14.37 rows=8 width=20) (actual time=0.009..0.010 rows=0 loops=1)
   Recheck Cond: (user_id = 7)
   ->  Bitmap Index Scan on like_part_p3_user_id_idx  (cost=0.00..4.21 rows=8 width=0) (actual time=0.002..0.002 rows=0 loops=1)
         Index Cond: (user_id = 7)
 Planning Time: 0.833 ms
 Execution Time: 0.044 ms
```

PostgreSQL вычислил хеш `user_id = 7`, определил что он попадает в партицию `like_part_p3` (MODULUS 4, REMAINDER 3) и обратился только к ней.

| Вопрос | Ответ |
|---|---|
| Partition pruning | **Да** — сканируется только `like_part_p3` |
| Партиций в плане | **1** из 4 |
| Используется ли индекс | **Да** — `Bitmap Index Scan` по `like_part_p3_user_id_idx` |

---

## Часть 2. Секционирование и физическая репликация

### 2.1 Проверка секций на репликах

Поднят кластер из 3 инстансов: `primary` (порт 5433), `standby1` (порт 5434), `standby2` (порт 5435). На primary создана секционированная таблица `listening_history` с партициями `listening_history_2024` и `listening_history_2025`.

```bash
cd task-seven/replication-partitioned && docker compose up -d
```

Проверяем структуру на primary:

```bash
docker exec replication-partitioned-primary-1 psql -U postgres -d app_db -c "\d+ listening_history"
```

```
Partitioned table "public.listening_history"
Partition key: RANGE (listened_at)
Indexes:
    "idx_lh_listened_at" btree (listened_at)
Partitions: listening_history_2024 FOR VALUES FROM ('2024-01-01 00:00:00') TO ('2025-01-01 00:00:00'),
            listening_history_2025 FOR VALUES FROM ('2025-01-01 00:00:00') TO ('2026-01-01 00:00:00')
```

Проверяем на standby1 — структура идентична:

```bash
docker exec replication-partitioned-standby1-1 psql -U postgres -d app_db -c "\d+ listening_history"
```

```
Partitioned table "public.listening_history"
Partition key: RANGE (listened_at)
Indexes:
    "idx_lh_listened_at" btree (listened_at)
Partitions: listening_history_2024 FOR VALUES FROM ('2024-01-01 00:00:00') TO ('2025-01-01 00:00:00'),
            listening_history_2025 FOR VALUES FROM ('2025-01-01 00:00:00') TO ('2026-01-01 00:00:00')
```

Проверяем данные на реплике — родительская таблица `listening_history`:

```bash
docker exec replication-partitioned-standby1-1 psql -U postgres -d app_db -c "SELECT * FROM listening_history;"
```

```
 id | user_id | track_id |     listened_at     |  device   | platform | completed | quality
----+---------+----------+---------------------+-----------+----------+-----------+---------
  1 |       1 |       10 | 2024-05-01 12:00:00 | iPhone 14 | mobile   | t         | normal
  2 |       2 |       20 | 2025-03-15 18:30:00 | Chrome    | web      | t         | normal
(2 rows)
```

Партиция `listening_history_2024`:

```bash
docker exec replication-partitioned-standby1-1 psql -U postgres -d app_db -c "SELECT * FROM listening_history_2024;"
```

```
 id | user_id | track_id |     listened_at     |  device   | platform | completed | quality
----+---------+----------+---------------------+-----------+----------+-----------+---------
  1 |       1 |       10 | 2024-05-01 12:00:00 | iPhone 14 | mobile   | t         | normal
(1 row)
```

Партиция `listening_history_2025`:

```bash
docker exec replication-partitioned-standby1-1 psql -U postgres -d app_db -c "SELECT * FROM listening_history_2025;"
```

```
 id | user_id | track_id |     listened_at     |  device   | platform | completed | quality
----+---------+----------+---------------------+-----------+----------+-----------+---------
  2 |       2 |       20 | 2025-03-15 18:30:00 | Chrome    | web      | t         | normal
(1 row)
```

Секции, индексы и данные полностью реплицировались на standby. Каждая строка попала в свою партицию по значению `listened_at`.

### 2.2 Почему репликация "не знает" про секции?

Физическая репликация работает на уровне **WAL (Write-Ahead Log)** — она побайтово копирует изменения страниц данных с primary на standby. WAL оперирует физическими блоками (page-level changes), а не логическими объектами (таблицы, партиции, constraints). Реплика получает точную физическую копию кластера через `pg_basebackup` и поддерживает её в актуальном состоянии потоком WAL-записей. Секции появляются на реплике как побочный эффект полной копии — репликация не различает обычные таблицы и партиции.

---

## Часть 3. Логическая репликация и секционирование

Поднят стенд из двух инстансов:

```bash
cd task-seven/logical-partitioned && docker compose up -d
```

- `pg-publisher` (порт 5433) — источник данных, `wal_level=logical`
- `pg-subscriber` (порт 5434) — получатель

На обоих серверах создана одинаковая секционированная таблица `listening_history` с партициями `listening_history_2024` и `listening_history_2025`. На publisher созданы две публикации с разными режимами:

```
 pubname  | pubviaroot | tablename
----------+------------+------------------------
 pub_leaf | f          | listening_history_2024
 pub_leaf | f          | listening_history_2025
 pub_root | t          | listening_history
```

`pub_root` (`pubviaroot = t`) публикует родительскую таблицу `listening_history`. `pub_leaf` (`pubviaroot = f`) публикует конкретные партиции `listening_history_2024` и `listening_history_2025`.

### 3.1 Начальное состояние до создания подписки

**Publisher** — данные есть (вставлены при инициализации):

```
        tableoid        | id | user_id | track_id |     listened_at     |  device   | platform | completed | quality
------------------------+----+---------+----------+---------------------+-----------+----------+-----------+---------
 listening_history_2024 |  1 |       1 |       10 | 2024-06-01 14:00:00 | iPhone 14 | mobile   | t         | high
 listening_history_2025 |  2 |       2 |       20 | 2025-02-15 20:30:00 | Chrome    | web      | t         | normal
```

**Subscriber** — таблица пуста:

```
 tableoid | id | user_id | track_id | listened_at | device | platform | completed | quality
----------+----+---------+----------+-------------+--------+----------+-----------+---------
(0 rows)
```

Данных нет, потому что логическая репликация **не передаёт данные автоматически при старте**. Для начала передачи нужно явно создать `SUBSCRIPTION`. Кроме того, логическая репликация **не реплицирует DDL** — схему таблиц и партиции нужно создавать на subscriber вручную (сделано через init-скрипт `01-schema.sql`).

### 3.2 `publish_via_partition_root = true`

Создаём подписку на публикацию `pub_root`:

```sql
CREATE SUBSCRIPTION sub_root
    CONNECTION 'host=pg-publisher port=5432 dbname=app_db user=postgres password=postgres'
    PUBLICATION pub_root;
```

Данные реплицировались на subscriber:

```
        tableoid        | id | user_id | track_id |     listened_at     |  device   | platform | completed | quality
------------------------+----+---------+----------+---------------------+-----------+----------+-----------+---------
 listening_history_2024 |  1 |       1 |       10 | 2024-06-01 14:00:00 | iPhone 14 | mobile   | t         | high
 listening_history_2025 |  2 |       2 |       20 | 2025-02-15 20:30:00 | Chrome    | web      | t         | normal
```

Колонка `tableoid::regclass` подтверждает: данные автоматически разложились по правильным партициям. Строка за 2024 попала в `listening_history_2024`, строка за 2025 — в `listening_history_2025`.

Вставляем новую запись на publisher для проверки потоковой репликации:

```sql
-- на publisher:
INSERT INTO listening_history (user_id, track_id, listened_at, device, platform, quality)
VALUES (3, 30, '2025-08-20 10:00:00', 'Android', 'mobile', 'lossless');
```

Проверяем на subscriber — новая строка появилась и попала в `listening_history_2025`:

```
        tableoid        | id | user_id | track_id |     listened_at     |  device   | platform | completed | quality
------------------------+----+---------+----------+---------------------+-----------+----------+-----------+----------
 listening_history_2024 |  1 |       1 |       10 | 2024-06-01 14:00:00 | iPhone 14 | mobile   | t         | high
 listening_history_2025 |  2 |       2 |       20 | 2025-02-15 20:30:00 | Chrome    | web      | t         | normal
 listening_history_2025 |  3 |       3 |       30 | 2025-08-20 10:00:00 | Android   | mobile   | t         | lossless
```

При `publish_via_partition_root = true` publisher отправляет данные от имени **родительской таблицы** `listening_history`. Subscriber получает строку, видит что `listening_history` — партицированная таблица, и сам маршрутизирует запись в нужную партицию по значению `listened_at`.

### 3.3 `publish_via_partition_root = false`

Удаляем предыдущую подписку, очищаем данные и подписываемся на `pub_leaf`:

```sql
-- на subscriber:
DROP SUBSCRIPTION sub_root;
TRUNCATE listening_history;

CREATE SUBSCRIPTION sub_leaf
    CONNECTION 'host=pg-publisher port=5432 dbname=app_db user=postgres password=postgres'
    PUBLICATION pub_leaf;
```

Проверяем данные — `SELECT tableoid::regclass, * FROM listening_history`:

```
        tableoid        | id | user_id | track_id |     listened_at     |  device   | platform | completed | quality
------------------------+----+---------+----------+---------------------+-----------+----------+-----------+----------
 listening_history_2024 |  1 |       1 |       10 | 2024-06-01 14:00:00 | iPhone 14 | mobile   | t         | high
 listening_history_2025 |  2 |       2 |       20 | 2025-02-15 20:30:00 | Chrome    | web      | t         | normal
 listening_history_2025 |  3 |       3 |       30 | 2025-08-20 10:00:00 | Android   | mobile   | t         | lossless
```

Результат тот же, но механизм другой: `pub_leaf` публикует конкретные партиции (`listening_history_2024`, `listening_history_2025`), а не родительскую таблицу. Subscriber ищет таблицы с такими именами и вставляет данные напрямую, без маршрутизации.

### 3.4 Сравнение режимов

| | `publish_via_partition_root = true` | `publish_via_partition_root = false` |
|---|---|---|
| Что публикуется | Родительская таблица `listening_history` | Конкретные партиции `listening_history_2024`, `listening_history_2025` |
| Маршрутизация на subscriber | Автоматическая — subscriber сам раскладывает по партициям | Прямая вставка — subscriber ищет таблицу по имени партиции |
---

## Часть 4. Шардирование через postgres_fdw

### 4.1 Архитектура

Поднят стенд из 3 инстансов PostgreSQL:

- `pg-shard1` (порт 5433) — хранит треки с `id` от 1 до 500
- `pg-shard2` (порт 5434) — хранит треки с `id` от 501 до 1000
- `pg-router` (порт 5435) — маршрутизатор, подключается к шардам через `postgres_fdw`

На router создана партицированная таблица `track` с двумя foreign-партициями:

```
Partitioned table "public.track"
Partition key: RANGE (id)
Partitions: track_shard1 FOR VALUES FROM (1) TO (501),
            track_shard2 FOR VALUES FROM (501) TO (1001)
```

`track_shard1` и `track_shard2` — это `FOREIGN TABLE`, которые ссылаются на реальные таблицы `track` на соответствующих шардах. Router не хранит данные локально — все данные физически находятся на шардах.

### 4.2 Простой запрос на все данные

```sql
EXPLAIN ANALYZE SELECT * FROM track;
```

```
 Append  (cost=100.00..233.09 rows=374 width=414) (actual time=1.194..2.192 rows=8 loops=1)
   ->  Foreign Scan on track_shard1 track_1  (cost=100.00..115.61 rows=187 width=414) (actual time=1.193..1.194 rows=4 loops=1)
   ->  Foreign Scan on track_shard2 track_2  (cost=100.00..115.61 rows=187 width=414) (actual time=0.994..0.995 rows=4 loops=1)
 Planning Time: 1.596 ms
 Execution Time: 19.541 ms
```

В плане видно `Append` с двумя `Foreign Scan` — PostgreSQL отправил `SELECT` на оба шарда и объединил результаты. Всего получено 8 строк: 4 с shard1 + 4 с shard2.

| Вопрос | Ответ |
|---|---|
| Partition pruning | **Нет** — нет фильтра по `id`, сканируются оба шарда |
| Партиций в плане | **2** из 2 |

### 4.3 Простой запрос на конкретный шард

**Запрос к shard1 (`id = 2`):**

```sql
EXPLAIN ANALYZE SELECT * FROM track WHERE id = 2;
```

```
 Foreign Scan on track_shard1 track  (cost=100.00..112.36 rows=1 width=414) (actual time=0.920..0.922 rows=1 loops=1)
 Planning Time: 1.500 ms
 Execution Time: 7.654 ms
```

**Запрос к shard2 (`id = 700`):**

```sql
EXPLAIN ANALYZE SELECT * FROM track WHERE id = 700;
```

```
 Foreign Scan on track_shard2 track  (cost=100.00..112.36 rows=1 width=414) (actual time=0.751..0.752 rows=1 loops=1)
 Planning Time: 1.119 ms
 Execution Time: 7.576 ms
```

В обоих случаях partition pruning отсёк ненужный шард — запрос ушёл только на один `Foreign Scan`. Router по значению `id` определил, в какой диапазон попадает ключ, и отправил запрос только на нужный шард.

| Вопрос | `id = 2` | `id = 700` |
|---|---|---|
| Partition pruning | **Да** | **Да** |
| Куда ушёл запрос | `track_shard1` (shard1) | `track_shard2` (shard2) |
| Партиций в плане | **1** из 2 | **1** из 2 |

### 4.4 Вставка через router

```sql
INSERT INTO track VALUES (50, 'New Track', 240, 1, 1, 'rock', 0, 'calm');
INSERT INTO track VALUES (600, 'Another Track', 180, 2, 2, 'pop', 0, 'happy');
```

Проверка на шардах напрямую показала, что router автоматически маршрутизировал INSERT:

- `id = 50` → попал на **shard1** (диапазон 1..500)
- `id = 600` → попал на **shard2** (диапазон 501..1000)

---