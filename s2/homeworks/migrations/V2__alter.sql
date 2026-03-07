-- V2__alter.sql: оригинальные ALTER + новые поля для задания

-- ===== Оригинальные ALTER =====

ALTER TABLE "user"
ADD COLUMN phone_number VARCHAR(20);

ALTER TABLE playlist
ADD COLUMN created_at TIMESTAMP DEFAULT NOW();

ALTER TABLE track
ALTER COLUMN duration_seconds SET NOT NULL;

-- ===== Новые поля для задания (JSONB, массивы, range, геометрия, полнотекст) =====

-- subscription: JSONB
ALTER TABLE subscription
ADD COLUMN features JSONB;

-- user: JSONB, массив, range-тип
ALTER TABLE "user"
ADD COLUMN preferences JSONB,
ADD COLUMN favorite_genres INTEGER[],
ADD COLUMN subscription_period DATERANGE;

-- artist: массив, JSONB
ALTER TABLE artist
ADD COLUMN tags TEXT[],
ADD COLUMN social_links JSONB;

-- track: JSONB, массив, tsvector, дополнительные поля
ALTER TABLE track
ADD COLUMN mood VARCHAR(20),
ADD COLUMN play_count INTEGER NOT NULL DEFAULT 0,
ADD COLUMN lyrics TEXT,
ADD COLUMN tags TEXT[],
ADD COLUMN metadata JSONB,
ADD COLUMN search_vector TSVECTOR;

-- listening_history: геометрия, range, JSONB, дополнительные поля
ALTER TABLE listening_history
ADD COLUMN platform VARCHAR(20),
ADD COLUMN completed BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN skip_position INTEGER,
ADD COLUMN location POINT,
ADD COLUMN listen_duration INT4RANGE,
ADD COLUMN context JSONB,
ADD COLUMN quality VARCHAR(10) NOT NULL DEFAULT 'normal';

-- comment: JSONB, массив, tsvector, дополнительные поля
ALTER TABLE comment
ADD COLUMN edited_at TIMESTAMP,
ADD COLUMN parent_id INTEGER REFERENCES comment(id),
ADD COLUMN rating SMALLINT CHECK (rating BETWEEN 1 AND 5),
ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'visible',
ADD COLUMN reactions JSONB,
ADD COLUMN mentioned_users INTEGER[],
ADD COLUMN search_vector TSVECTOR;
