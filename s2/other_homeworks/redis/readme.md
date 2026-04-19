# ДЗ — Redis

## Шаг 0. Поднять Redis и подключиться

Стенд описан в соседнем `docker-compose.yml` (Redis 7-alpine, порт `6380:6379`, `appendonly yes`, healthcheck по `PING`). Поднимаем и заходим в `redis-cli`:

```bash
docker compose up -d
```

Внутри `redis-cli` проверяем, что сервер отвечает, и сразу чистим БД, чтобы прогон был идемпотентным:

```redis
PING
INFO server
FLUSHDB
DBSIZE
```

#### Результат

```
PONG
---
redis_version:7.4.8
os:Linux 5.15.167.4-microsoft-standard-WSL2 x86_64
arch_bits:64
---
OK
0
```

#### Пояснение

Пункт 1 ДЗ. Сервер ответил `PONG` — значит подключение есть; Redis 7.4.8 на Linux x86_64. `FLUSHDB → OK` и `DBSIZE → 0` подтверждают, что стартуем с пустой БД, поэтому дальше в результатах увидим ровно те ключи, которые сами создадим в шагах 1–5.

---

## Шаг 1. Hash со студентами (пункт 2 ДЗ)

### 1.1 Записать 3 студентов

```redis
HSET student:1 name "Alex"  group "BD-101" gpa 4.7
HSET student:2 name "Maria" group "BD-101" gpa 4.9
HSET student:3 name "John"  group "BD-102" gpa 4.2
```

#### Результат

```
3
3
3
```

#### Пояснение

Пункт 2 ДЗ — каждый студент хранится как отдельный Hash `student:{id}` с полями `name`, `group`, `gpa`. Каждая команда `HSET` создала ровно 3 новых поля и вернула `3`, что подтверждает: до этого ключи были пустыми (за это отвечал `FLUSHDB` из шага 0.3). Такая модель «ключ = таблица + PK, поля = колонки» — идиоматичная для Redis замена строки в реляционной таблице.

### 1.2 Прочитать данные обратно

```redis
HGETALL student:1
HGETALL student:2
HGETALL student:3
HMGET student:2 name group gpa
```

#### Результат

```
HGETALL student:1
name
Alex
group
BD-101
gpa
4.7
---
HGETALL student:2
name
Maria
group
BD-101
gpa
4.9
---
HGETALL student:3
name
John
group
BD-102
gpa
4.2
---
HMGET student:2 name group gpa
Maria
BD-101
4.9
```

#### Пояснение

Пункт 2 ДЗ. `HGETALL` возвращает плоский список `field, value, field, value, …`, и для всех трёх студентов мы видим ровно три записанные пары — данные сохранились без потерь. `HMGET student:2 name group gpa` отдаёт только запрошенные поля в том же порядке, что и аргументы — это паттерн «частичного чтения» хеша, когда не нужно тащить весь объект.

### 1.3 Сводка

```redis
KEYS student:*
```

#### Результат

```
student:1
student:3
student:2
```

#### Пояснение

`KEYS student:*` вернул ровно 3 ключа — `student:1`, `student:2`, `student:3` — что подтверждает: пункт 2 ДЗ закрыт, в БД лежат именно три студенческих хеша и ничего лишнего. Порядок не отсортирован, потому что `KEYS` возвращает ключи в порядке хеш-таблицы Redis. В продовых системах вместо блокирующего `KEYS` используют итеративный `SCAN`, но для учебного объёма из трёх ключей `KEYS` допустим.

---

## Шаг 2. Лидерборд по GPA (пункт 3 ДЗ)

### 2.1 Заполнить Sorted Set

```redis
ZADD leaderboard:gpa 4.7 "Alex" 4.9 "Maria" 4.2 "John"
```

#### Результат

```
3
```

#### Пояснение

Пункт 3 ДЗ. `ZADD` создал новый Sorted Set `leaderboard:gpa` и добавил в него 3 элемента (Alex, Maria, John); ответ `3` — это количество добавленных member'ов. Score = средний балл, сам Sorted Set физически хранит элементы упорядоченно по score, поэтому топ-N достаётся за `O(log N + N)`.

### 2.2 Вывести топ-3 по убыванию GPA

```redis
ZREVRANGE leaderboard:gpa 0 2 WITHSCORES
```

#### Результат

```
Maria
4.9
Alex
4.7
John
4.2
```

#### Пояснение

Пункт 3 ДЗ — это и есть топ-3 студентов по GPA. `ZREVRANGE 0 2 WITHSCORES` вернул элементы в порядке убывания score, чередуя `member`, `score`: Maria (4.9) → Alex (4.7) → John (4.2). Порядок ровно соответствует тому, что мы записали в Hash на шаге 1, значит лидерборд согласован с источником.

### 2.3 Доп. проверка: ранг конкретного студента

```redis
ZREVRANK leaderboard:gpa "Alex"
ZSCORE leaderboard:gpa "Maria"
ZCARD leaderboard:gpa
```

#### Результат

```
1
4.9
3
```

#### Пояснение

`ZREVRANK leaderboard:gpa "Alex"` = `1` означает, что Alex занимает 2-е место в рейтинге (ранги нумеруются с нуля, 0-й — Maria). `ZSCORE` для Maria вернул её балл 4.9, `ZCARD` — общее число участников (3). Это показывает, что Sorted Set хорош не только для «топ-N», но и для точечных запросов «какая позиция/балл у конкретного игрока» за `O(log N)`.

---

## Шаг 3. Очередь задач на List (пункт 4 ДЗ)

> Договорённость: производитель кладёт задачи в **левый** конец (`LPUSH`), потребитель забирает с **правого** (`RPOP`) — классический FIFO-паттерн.

### 3.1 Положить 5 задач

```redis
LPUSH queue:tasks "task-1" "task-2" "task-3" "task-4" "task-5"
LLEN queue:tasks
LRANGE queue:tasks 0 -1
```

#### Результат

```
5
5
--- LRANGE ---
task-5
task-4
task-3
task-2
task-1
```

#### Пояснение

Пункт 4 ДЗ — очередь из 5 задач. `LPUSH` ответил `5` (новая длина списка), `LLEN` это подтвердил. Порядок в `LRANGE 0 -1` — слева направо `task-5, task-4, …, task-1`: вариативный `LPUSH a b c d e` вставляет элементы по одному слева, поэтому первый аргумент (`task-1`) оказывается в самом хвосте (правый конец = «голова» нашей FIFO-очереди), а последний (`task-5`) — слева. Дальше потребитель будет забирать задачи именно с правого конца через `RPOP`.

### 3.2 Забрать 3 задачи

```redis
RPOP queue:tasks
RPOP queue:tasks
RPOP queue:tasks
LLEN queue:tasks
LRANGE queue:tasks 0 -1
```

#### Результат

```
task-1
task-2
task-3
2
--- LRANGE ---
task-5
task-4
```

#### Пояснение

Пункт 4 ДЗ — забрали 3 задачи и видим честный FIFO: первой пришла `task-1`, она же первой ушла, затем `task-2`, `task-3`. `LLEN` упал с 5 до 2, а `LRANGE 0 -1` показывает ровно те две задачи, которые мы клали последними и которые ещё не успели обработать (`task-5`, `task-4`). Очередь работает как и ожидалось: `LPUSH` слева, `RPOP` справа = классический producer/consumer.

---

## Шаг 4. TTL и автоудаление ключа (пункт 5 ДЗ)

### 4.1 Создать ключ и поставить ему TTL

```redis
SET session:demo "active"
EXPIRE session:demo 5
TTL session:demo
GET session:demo
```

#### Результат

```
OK
1
5
active
```

#### Пояснение

Пункт 5 ДЗ. `SET` создал ключ (`OK`), `EXPIRE session:demo 5` навесил TTL и вернул `1` — это означает «таймер успешно установлен на существующий ключ» (вернул бы `0`, если бы ключа не было). `TTL = 5` — ровно тот таймер, который мы запросили; `GET = "active"` — пока TTL не истёк, ключ виден и читается как обычный.

### 4.2 Подождать 7 секунд и убедиться, что ключ исчез

```redis
TTL session:demo
GET session:demo
EXISTS session:demo
```

#### Результат

```
TTL session:demo
-2
GET session:demo
(nil)
EXISTS session:demo
0
```

> В сыром выводе `redis-cli` пустая строка между `-2` и `0` — это и есть `(nil)` от `GET`: при печати в stdout без TTY клиент пишет пустую строку вместо текстового маркера.

#### Пояснение

Пункт 5 ДЗ — после паузы в 7 секунд (то есть гарантированно дольше TTL=5) Redis сам удалил ключ. Это видно по трём независимым признакам сразу: `TTL = -2` (ключа нет), `GET = (nil)` (читать нечего) и `EXISTS = 0` (ключа физически нет в БД). Никто не вызывал `DEL` — это именно автоматическая чистка по таймеру.

---

## Шаг 5. Транзакция MULTI/EXEC: перевод «баллов» (пункт 6 ДЗ)

> Сценарий: переводим 0.2 балла со счёта Джона (`student:3`) на счёт Алекса (`student:1`) и одновременно обновляем их позиции в лидерборде. Всё в одной транзакции, чтобы не было «полу-перевода».

### 5.1 Состояние ДО

```redis
HGET student:1 gpa
HGET student:3 gpa
ZSCORE leaderboard:gpa "Alex"
ZSCORE leaderboard:gpa "John"
```

#### Результат

```
HGET student:1 gpa  -> 4.7
HGET student:3 gpa  -> 4.2
ZSCORE leaderboard:gpa "Alex" -> 4.7
ZSCORE leaderboard:gpa "John" -> 4.2
```

#### Пояснение

Фиксируем «снимок ДО»: GPA Alex = 4.7, John = 4.2 — и эти же значения лежат как score в лидерборде. Сумма GPA до перевода: `4.7 + 4.2 = 8.9` — этот инвариант проверим после транзакции.

### 5.2 Выполнить транзакцию

```redis
MULTI
HINCRBYFLOAT student:1 gpa 0.2
HINCRBYFLOAT student:3 gpa -0.2
ZINCRBY leaderboard:gpa 0.2 Alex
ZINCRBY leaderboard:gpa -0.2 John
EXEC
```

#### Результат

```
OK
QUEUED
QUEUED
QUEUED
QUEUED
4.9
4
4.9
4
```

#### Пояснение

Пункт 6 ДЗ. `MULTI` открыл транзакцию (`OK`), 4 команды попали в очередь (`QUEUED ×4`), и `EXEC` атомарно их выполнил, вернув массив из 4 ответов: новый `student:1.gpa = 4.9`, новый `student:3.gpa = 4`, новый score Alex = 4.9, новый score John = 4. Между этими 4 операциями ни один другой клиент в очередь не вклинится — это и есть атомарный «перевод 0.2 балла», который не может оставить хеш и лидерборд в рассинхроне. Сумма GPA сохранилась: `4.7 + 4.2 = 8.9 == 4.9 + 4.0` — инвариант «массы баллов» выполнен (Redis показывает `4` без хвостового `.0`, но это та же `4.0`).

### 5.3 Состояние ПОСЛЕ + проверка лидерборда

```redis
HGET student:1 gpa
HGET student:3 gpa
ZREVRANGE leaderboard:gpa 0 -1 WITHSCORES
```

#### Результат

```
HGET student:1 gpa -> 4.9
HGET student:3 gpa -> 4

ZREVRANGE leaderboard:gpa 0 -1 WITHSCORES:
Maria
4.9
Alex
4.9
John
4
```

#### Пояснение

Перевод применился одинаково и в Hash, и в Sorted Set: GPA Alex стал `4.9` (как было у Maria), GPA John — `4` (т.е. `4.0`). В лидерборде на первом месте теперь два студента со score 4.9; при равных score Sorted Set Redis сортирует members лексикографически по возрастанию, поэтому `Maria` идёт раньше `Alex` (а в `ZREVRANGE` — наоборот, по убыванию score, и при равенстве — по убыванию member; здесь `Maria > Alex` лексикографически, поэтому Maria первая). Сумма GPA `4.9 + 4.0 = 8.9` совпала с предтранзакционной `4.7 + 4.2 = 8.9` — инвариант «массы баллов» сохранён.

---

## Шаг 6 (бонус). Pub/Sub

> Цель — продемонстрировать, что подписчик в одном процессе получает сообщения, опубликованные другим процессом.

### 6.1 Подписчик (терминал A)

```redis
SUBSCRIBE news:students
```

### 6.2 Издатель (терминал B)

```redis
PUBLISH news:students "Maria moved to top of leaderboard"
PUBLISH news:students "John lost 0.2 GPA"
```

Каждый `PUBLISH` возвращает число подписчиков, получивших сообщение (ожидаем `1`).

#### Результат

Часть 1 — ответы `PUBLISH` (число доставленных подписчиков):

```
PUBLISH news:students "Maria moved to top of leaderboard" -> 1
PUBLISH news:students "John lost 0.2 GPA"                 -> 1
```

Часть 2 — что увидел подписчик в терминале A (подтверждение подписки + 2 сообщения):

```
subscribe
news:students
1
message
news:students
Maria moved to top of leaderboard
message
news:students
John lost 0.2 GPA
```

#### Пояснение

Бонусный пункт ДЗ — Pub/Sub. Подписчик сначала получил служебное подтверждение (`subscribe news:students 1` — «успешно подписан на 1 канал»), а затем оба сообщения от издателя в формате `message <channel> <payload>`. Каждый `PUBLISH` вернул `1` — ровно столько подписчиков было активно на канале `news:students` в момент публикации. Это и есть ключевое свойство Redis Pub/Sub: fire-and-forget — сообщение получают только те клиенты, которые уже подписаны; в БД оно не сохраняется, и если бы подписчик запустился после `PUBLISH`, он бы ничего не увидел.
