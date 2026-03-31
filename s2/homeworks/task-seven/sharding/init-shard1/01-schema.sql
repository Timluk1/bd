-- Shard 1: хранит треки с id 1..500
CREATE TABLE track (
    id               INT PRIMARY KEY,
    title            VARCHAR(100) NOT NULL,
    duration_seconds INT NOT NULL,
    artist_id        INT,
    album_id         INT,
    genre            VARCHAR(50),
    play_count       INT NOT NULL DEFAULT 0,
    mood             VARCHAR(20)
);

INSERT INTO track (id, title, duration_seconds, artist_id, album_id, genre, play_count, mood) VALUES
    (1,   'Bohemian Rhapsody',       354, 1, 1, 'rock',    1500000, 'epic'),
    (2,   'Yesterday',               125, 2, 2, 'pop',      900000, 'sad'),
    (100, 'Lose Yourself',           326, 3, 3, 'hip-hop', 2000000, 'energetic'),
    (300, 'Smells Like Teen Spirit', 301, 5, 5, 'rock',    1800000, 'energetic');
