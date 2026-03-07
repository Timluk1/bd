-- V1__init.sql: оригинальная схема

CREATE TABLE subscription (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    price DECIMAL(5,2),
    duration_months INTEGER
);

CREATE TABLE "user" (
    id SERIAL PRIMARY KEY,
    email VARCHAR(100) UNIQUE,
    username VARCHAR(50) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    country VARCHAR(50),
    date_joined DATE,
    subscription_id INTEGER REFERENCES subscription(id)
);

CREATE TABLE playlist (
    id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    is_public BOOLEAN,
    user_id INTEGER REFERENCES "user"(id)
);

CREATE TABLE artist (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    country VARCHAR(50),
    description TEXT,
    user_id INTEGER REFERENCES "user"(id),
    start_year INTEGER
);

CREATE TABLE genre (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);

CREATE TABLE album (
    id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    release_date DATE,
    artist_id INTEGER REFERENCES artist(id),
    genre_id INTEGER REFERENCES genre(id)
);

CREATE TABLE track (
    id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    duration_seconds INTEGER,
    album_id INTEGER REFERENCES album(id),
    artist_id INTEGER REFERENCES artist(id),
    genre_id INTEGER REFERENCES genre(id)
);

CREATE TABLE listening_history (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES "user"(id),
    track_id INTEGER REFERENCES track(id),
    listened_at TIMESTAMP,
    device VARCHAR(50)
);

CREATE TABLE "like" (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES "user"(id),
    track_id INTEGER REFERENCES track(id),
    created_at TIMESTAMP
);

CREATE TABLE comment (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES "user"(id),
    track_id INTEGER REFERENCES track(id),
    content TEXT,
    created_at TIMESTAMP
);

CREATE TABLE follow (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES "user"(id),
    artist_id INTEGER REFERENCES artist(id),
    created_at TIMESTAMP
);
