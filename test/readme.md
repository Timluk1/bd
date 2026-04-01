## Задание 1

## 1. Построить план запроса

![](/test/images/1.png)


## 1.3 Какой тип сканирования использован
seq scan

## 1.4 Какие из уже созданных индексов не помогают этому запросу

Были созданы для таблички exam_events 2 индекса, но в запросе поля для индексов не используются

```SQL
CREATE INDEX idx_exam_events_status ON exam_events (status);
CREATE INDEX idx_exam_events_amount_hash ON exam_events USING hash (amount);
```

В нашем запросе используются user_id, created_at - на них индексы не были созданы


## 1.5 Почему планировщик выбирает именно такой план.

Он выбрал такой план, потому что мы не создали индексов для полей используемых в запросе и используется seq scan, который последовательно с диска считывает все страницы

## 1.6 Создайте индекс, который лучше подходит под этот запрос.

BTree индекс на оба поля

``` SQL
CREATE INDEX idx_exam_events_user_id_created_at ON exam_events (user_id, created_at);
```

## 1.7 Повторно постройте план выполнения.

![](/test/images/2.png)

## 1.8 Кратко объясните, что изменилось в плане и почему.

Теперь используются тип сканировния index scan так как мы создали необходимые индексы для запроса

## 1.9 Ответьте, нужно ли после создания индекса выполнять ANALYZE, и зачем.

Нужно так как планировщик должен обновить статистику по таблицам

# Задание 2

## 2.1. Постройте план выполнения запроса до изменений.
![](/test/images/3.png)
## 2.2. Определите, какой тип JOIN использован.
Hash join
## 2.3. Объясните, почему планировщик выбрал именно этот тип JOIN.
Потому что у нас есть индекс на PRIMARY KEY для exam users, а размер exam_users среднего размера 12к строк
## 2.4. Укажите, какие существующие индексы полезны слабо или не полезны для этого запроса.
exam_users (PRIMARY KEY id) - полезен


```SQL
CREATE INDEX idx_exam_users_name_1775025026565_index ON 
    exam_users USING KEY ("name");
```
 - бесполезен

## 2.5. Предложите и создайте одно улучшение, которое может ускорить запрос.
Создадим новый индекс
```SQL
CREATE INDEX idx_user_country ON exam_users (country);
```
## 2.6. Повторно постройте план выполнения.
![](/test/images/4.png)

## 2.7. Кратко поясните, улучшился ли план и за счет чего.
cost явно уменьшится
хотя execution time увеличился

## 2.8. Отдельно укажите, что означает преобладание shared hit или read в BUFFERS.

shared hit - это чтение из кэша
read - прямое чтение с диска

# Задание 3

## 3.1
Для записи с id = 1 застился xmax, который удалил старую запись
и добавилась новую запись в транзакции 842. SELECT запрос не выводит данные где есть xmax

![](/test/images/5.png)
![](/test/images/6.png)

## 3.2 Объясните, почему в модели MVCC UPDATE не является простым "перезаписыванием" строки.
Потому что нужно хранить разные версии строк и нельзя просто обновить данные в строке, сначала засетиться xmax и создастся новая запись в новой транзакции с новой версией строки

## 3.3 Объясните, что произошло после DELETE и почему строка исчезла из обычного SELECT.
У нас для записи с id = 2 засетился xmax то есть строка теперь удалена и по умолчанию она пропала из SELECT запроса
![](/test/images/7.png)

## 3.4 Кратко сравните:
   - VACUUM;
   - autovacuum;
   - VACUUM FULL.

VACUUM - делает более глубокую очистку
autovacuum - самая быстрая и легковесная очистка
VACUUM FULL - полностью блокирует таблицу и полностью перестраивает индекс

## 3.5 Отдельно укажите, какой из этих механизмов может полностью блокировать табли

VACUUM FULL.

# Задание 5

```SQL
CREATE TABLE exam_measurements (
    id              SERIAL,
    city_id         INT NOT NULL,
    log_date        DATE NOT NULL,
    peaktemp        INTEGER,
    unitsales       INTEGER
) PARTITION BY RANGE (log_date);

CREATE TABLE exam_measurements_2024 PARTITION OF exam_measurements
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
CREATE TABLE exam_measurements_2025 PARTITION OF exam_measurements
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE INDEX idx_exam_measurements_log_date ON exam_measurements (log_date);

INSERT INTO exam_measurements (city_id, log_date, peaktemp, unitsales) VALUES
    (1, '2024-01-01', 10, 100),
    (2, '2025-01-01', 20, 200);
```

## Задание 5.1

## Задание 5.2
## Задание 5.3