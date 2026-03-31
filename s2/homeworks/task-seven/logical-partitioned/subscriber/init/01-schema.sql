-- На subscriber создаём такую же секционированную таблицу
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
