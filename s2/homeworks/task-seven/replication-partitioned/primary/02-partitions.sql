-- Секционированная таблица listening_history на primary
CREATE TABLE listening_history (
    id              SERIAL,
    user_id         INT NOT NULL,
    track_id        INT NOT NULL,
    listened_at     TIMESTAMP NOT NULL,
    device          VARCHAR(50),
    platform        VARCHAR(20),
    completed       BOOLEAN NOT NULL DEFAULT true,
    quality         VARCHAR(10) NOT NULL DEFAULT 'normal'
) PARTITION BY RANGE (listened_at);

CREATE TABLE listening_history_2024 PARTITION OF listening_history
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
CREATE TABLE listening_history_2025 PARTITION OF listening_history
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE INDEX idx_lh_listened_at ON listening_history (listened_at);

INSERT INTO listening_history (user_id, track_id, listened_at, device, platform) VALUES
    (1, 10, '2024-05-01 12:00:00', 'iPhone 14', 'mobile'),
    (2, 20, '2025-03-15 18:30:00', 'Chrome',    'web');
