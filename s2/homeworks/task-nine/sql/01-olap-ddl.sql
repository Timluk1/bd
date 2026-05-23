-- OLAP DDL (для запуска на основной БД проекта, порт 5433)

CREATE SCHEMA IF NOT EXISTS olap;

CREATE TABLE olap.dim_date (
    date_key        INTEGER PRIMARY KEY,
    full_date       DATE NOT NULL UNIQUE,
    day_of_week     SMALLINT NOT NULL,
    day_name        VARCHAR(10) NOT NULL,
    week_of_year    SMALLINT NOT NULL,
    month_number    SMALLINT NOT NULL,
    month_name      VARCHAR(10) NOT NULL,
    quarter_number  SMALLINT NOT NULL,
    year_number     SMALLINT NOT NULL,
    is_weekend      BOOLEAN NOT NULL
);

CREATE TABLE olap.dim_user (
    user_key            SERIAL PRIMARY KEY,
    user_id             INTEGER NOT NULL UNIQUE,
    username            VARCHAR(50) NOT NULL,
    country             VARCHAR(50),
    subscription_name   VARCHAR(50),
    date_joined         DATE
);

CREATE TABLE olap.dim_track (
    track_key           SERIAL PRIMARY KEY,
    track_id            INTEGER NOT NULL UNIQUE,
    title               VARCHAR(100) NOT NULL,
    artist_name         VARCHAR(100),
    album_title         VARCHAR(100),
    duration_seconds    INTEGER NOT NULL
);

CREATE TABLE olap.dim_genre (
    genre_key       SERIAL PRIMARY KEY,
    genre_id        INTEGER NOT NULL UNIQUE,
    genre_name      VARCHAR(50) NOT NULL
);

CREATE TABLE olap.fact_listening (
    listening_id        INTEGER PRIMARY KEY,
    date_key            INTEGER NOT NULL REFERENCES olap.dim_date(date_key),
    user_key            INTEGER NOT NULL REFERENCES olap.dim_user(user_key),
    track_key           INTEGER NOT NULL REFERENCES olap.dim_track(track_key),
    genre_key           INTEGER NOT NULL REFERENCES olap.dim_genre(genre_key),
    device              VARCHAR(50),
    platform            VARCHAR(20),
    quality             VARCHAR(10),
    completed           BOOLEAN NOT NULL DEFAULT true,
    listen_count        INTEGER NOT NULL DEFAULT 1,
    completed_count     INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_fact_listening_date   ON olap.fact_listening(date_key);
CREATE INDEX idx_fact_listening_user   ON olap.fact_listening(user_key);
CREATE INDEX idx_fact_listening_track  ON olap.fact_listening(track_key);
CREATE INDEX idx_fact_listening_genre  ON olap.fact_listening(genre_key);
