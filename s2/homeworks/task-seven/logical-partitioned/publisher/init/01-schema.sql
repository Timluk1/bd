-- Секционированная таблица listening_history на publisher
CREATE TABLE listening_history (
    id              SERIAL,
    user_id         INT NOT NULL,
    track_id        INT NOT NULL,
    listened_at     TIMESTAMP NOT NULL,
    device          VARCHAR(50),
    platform        VARCHAR(20),
    completed       BOOLEAN NOT NULL DEFAULT true,
    quality         VARCHAR(10) NOT NULL DEFAULT 'normal',
    PRIMARY KEY (id, listened_at)
) PARTITION BY RANGE (listened_at);

CREATE TABLE listening_history_2024 PARTITION OF listening_history
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
CREATE TABLE listening_history_2025 PARTITION OF listening_history
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

-- Публикация с publish_via_partition_root = true
-- Данные публикуются от имени родительской таблицы listening_history
CREATE PUBLICATION pub_root FOR TABLE listening_history
    WITH (publish_via_partition_root = true);

-- Публикация с publish_via_partition_root = false (по умолчанию)
-- Данные публикуются от имени конкретной партиции
CREATE PUBLICATION pub_leaf FOR TABLE listening_history
    WITH (publish_via_partition_root = false);

INSERT INTO listening_history (user_id, track_id, listened_at, device, platform, quality) VALUES
    (1, 10, '2024-06-01 14:00:00', 'iPhone 14', 'mobile',  'high'),
    (2, 20, '2025-02-15 20:30:00', 'Chrome',    'web',     'normal');
