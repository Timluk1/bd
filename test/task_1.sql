-- Практическая контрольная работа.
-- Подготовка окружения.

-- Очистка окружения
DROP TABLE IF EXISTS exam_measurements CASCADE;
DROP TABLE IF EXISTS exam_measurements_src CASCADE;
DROP TABLE IF EXISTS exam_lock_items CASCADE;
DROP TABLE IF EXISTS exam_mvcc_items CASCADE;
DROP TABLE IF EXISTS exam_orders CASCADE;
DROP TABLE IF EXISTS exam_users CASCADE;
DROP TABLE IF EXISTS exam_events CASCADE;

-- ----------------------------
-- Блок 1
-- ----------------------------
CREATE TABLE exam_events (
    id BIGSERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    status TEXT NOT NULL,
    amount NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMP NOT NULL,
    payload TEXT
);

INSERT INTO exam_events (user_id, status, amount, created_at, payload)
SELECT
    ((g * 37) % 5000) + 1,
    CASE
        WHEN g % 10 = 0 THEN 'cancelled'
        WHEN g % 3 = 0 THEN 'paid'
        ELSE 'new'
    END,
    ((g * 19) % 100000) / 100.0,
    TIMESTAMP '2025-01-01 00:00:00'
        + ((g % 90) || ' days')::interval
        + (((g * 17) % 86400) || ' seconds')::interval,
    'event-' || g
FROM generate_series(1, 60000) AS g;

INSERT INTO exam_events (user_id, status, amount, created_at, payload) VALUES
(4242, 'paid', 199.90, '2025-03-10 08:15:00', 'target-1'),
(4242, 'paid', 299.50, '2025-03-10 12:40:00', 'target-2'),
(4242, 'new',  89.00, '2025-03-10 18:05:00', 'target-3'),
(4242, 'paid', 120.00, '2025-03-15 09:00:00', 'outside-range');

CREATE INDEX idx_exam_events_status ON exam_events (status);
CREATE INDEX idx_exam_events_amount_hash ON exam_events USING hash (amount);

-- ----------------------------
-- Блок 2
-- ----------------------------
CREATE TABLE exam_users (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    country TEXT NOT NULL,
    segment TEXT NOT NULL
);

CREATE TABLE exam_orders (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    amount NUMERIC(10,2) NOT NULL,
    status TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL
);

INSERT INTO exam_users (name, country, segment)
SELECT
    'User ' || g,
    CASE
        WHEN g % 20 = 0 THEN 'JP'
        WHEN g % 7 = 0 THEN 'DE'
        WHEN g % 5 = 0 THEN 'US'
        ELSE 'NL'
    END,
    CASE
        WHEN g % 10 = 0 THEN 'enterprise'
        WHEN g % 3 = 0 THEN 'pro'
        ELSE 'basic'
    END
FROM generate_series(1, 20000) AS g;

INSERT INTO exam_orders (user_id, amount, status, created_at)
SELECT
    ((g * 13) % 20000) + 1,
    ((g * 29) % 200000) / 100.0,
    CASE
        WHEN g % 9 = 0 THEN 'cancelled'
        WHEN g % 4 = 0 THEN 'paid'
        ELSE 'new'
    END,
    TIMESTAMP '2025-01-01 00:00:00'
        + ((g % 120) || ' days')::interval
        + (((g * 31) % 86400) || ' seconds')::interval
FROM generate_series(1, 120000) AS g;

CREATE INDEX idx_exam_orders_created_at ON exam_orders (created_at);
CREATE INDEX idx_exam_users_name ON exam_users (name);

-- ----------------------------
-- Блок 3
-- ----------------------------
CREATE TABLE exam_mvcc_items (
    id BIGSERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    qty INTEGER NOT NULL
);

INSERT INTO exam_mvcc_items (title, qty) VALUES
('Keyboard', 10),
('Mouse', 20),
('Monitor', 5);

-- ----------------------------
-- Блок 3b
-- ----------------------------
CREATE TABLE exam_lock_items (
    id BIGSERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    qty INTEGER NOT NULL
);

INSERT INTO exam_lock_items (title, qty) VALUES
('SSD', 7),
('RAM', 15);

-- ----------------------------
-- Блок 4
-- ----------------------------
CREATE TABLE exam_measurements_src (
    city_id INTEGER NOT NULL,
    log_date DATE NOT NULL,
    peaktemp INTEGER,
    unitsales INTEGER
);

INSERT INTO exam_measurements_src (city_id, log_date, peaktemp, unitsales)
SELECT
    (g % 50) + 1,
    DATE '2025-01-01' + (g % 31),
    (g % 25) - 5,
    50 + (g % 300)
FROM generate_series(1, 1200) AS g;

INSERT INTO exam_measurements_src (city_id, log_date, peaktemp, unitsales)
SELECT
    (g % 50) + 1,
    DATE '2025-02-01' + (g % 28),
    (g % 25),
    70 + (g % 320)
FROM generate_series(1, 1200) AS g;

INSERT INTO exam_measurements_src (city_id, log_date, peaktemp, unitsales)
SELECT
    (g % 50) + 1,
    DATE '2025-03-01' + (g % 31),
    5 + (g % 20),
    90 + (g % 350)
FROM generate_series(1, 1200) AS g;

INSERT INTO exam_measurements_src (city_id, log_date, peaktemp, unitsales)
SELECT
    (g % 50) + 1,
    DATE '2025-04-01' + (g % 10),
    10 + (g % 15),
    100 + (g % 200)
FROM generate_series(1, 100) AS g;

ANALYZE;

SELECT 'exam_events' AS table_name, count(*) AS rows_count FROM exam_events
UNION ALL
SELECT 'exam_users', count(*) FROM exam_users
UNION ALL
SELECT 'exam_orders', count(*) FROM exam_orders
UNION ALL
SELECT 'exam_mvcc_items', count(*) FROM exam_mvcc_items
UNION ALL
SELECT 'exam_lock_items', count(*) FROM exam_lock_items
UNION ALL
SELECT 'exam_measurements_src', count(*) FROM exam_measurements_src
ORDER BY table_name;
