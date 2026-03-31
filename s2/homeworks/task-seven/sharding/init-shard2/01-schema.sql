-- Shard 2: хранит треки с id 501..1000
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
    (501, 'Shape of You',    234, 6,  6,  'pop',     3000000, 'happy'),
    (502, 'Take Five',       324, 4,  4,  'jazz',     400000, 'calm'),
    (700, 'Blinding Lights', 200, 7,  7,  'pop',     2500000, 'energetic'),
    (999, 'Stairway to Heaven', 482, 8, 8, 'rock',   1200000, 'epic');
