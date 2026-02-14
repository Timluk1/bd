```sql
-- ===== SUBSCRIPTIONS =====
INSERT INTO subscription (name, price, duration_months)
VALUES 
('Free', 0.00, 0),
('Premium', 9.99, 1),
('Family', 14.99, 1),
('Student', 4.99, 1);

-- ===== USERS =====
INSERT INTO "user" (email, username, password_hash, country, date_joined, subscription_id)
VALUES
('alice@mail.com', 'alice', 'hash1', 'Germany', '2023-06-01', 2),
('bob@mail.com', 'bob', 'hash2', 'France', '2023-07-15', 1),
('charlie@mail.com', 'charlie', 'hash3', 'USA', '2023-09-10', 3),
('diana@mail.com', 'diana', 'hash4', 'UK', '2023-10-22', 2),
('ed@mail.com', 'ed', 'hash5', 'Germany', '2024-01-05', 4),
('fiona@mail.com', 'fiona', 'hash6', 'Spain', '2024-02-10', 2),
('george@mail.com', 'george', 'hash7', 'Italy', '2024-03-18', 1),
('hannah@mail.com', 'hannah', 'hash8', 'Canada', '2024-04-25', 3),
('ivan@mail.com', 'ivan', 'hash9', 'Russia', '2024-05-03', 2),
('julia@mail.com', 'julia', 'hash10', 'Germany', '2024-05-10', 1),
('kevin@mail.com', 'kevin', 'hash11', 'USA', '2024-06-01', 3),
('laura@mail.com', 'laura', 'hash12', 'UK', '2024-06-20', 2),
('mark@mail.com', 'mark', 'hash13', 'France', '2024-07-11', 4),
('nina@mail.com', 'nina', 'hash14', 'Spain', '2024-07-21', 1),
('oscar@mail.com', 'oscar', 'hash15', 'Italy', '2024-08-05', 2),
('paul@mail.com', 'paul', 'hash16', 'Germany', '2024-08-15', 3),
('quinn@mail.com', 'quinn', 'hash17', 'USA', '2024-09-01', 4),
('rachel@mail.com', 'rachel', 'hash18', 'Canada', '2024-09-10', 2),
('sam@mail.com', 'sam', 'hash19', 'France', '2024-09-25', 3),
('tina@mail.com', 'tina', 'hash20', 'Germany', '2024-10-05', 2);

-- ===== GENRES =====
INSERT INTO genre (name)
VALUES
('Pop'), ('Rock'), ('Hip-Hop'), ('Jazz'), ('Classical'), ('Electronic'),
('Folk'), ('Indie'), ('Metal'), ('R&B');

-- ===== ARTISTS =====
INSERT INTO artist (name, country, description, user_id, start_year)
VALUES
('The Harmonics', 'UK', 'Indie rock band', 1, 2010),
('DJ Pulse', 'Germany', 'Electronic producer', 2, 2015),
('Luna Vibe', 'France', 'Pop artist', 3, 2018),
('SmoothCats', 'USA', 'Jazz group', 4, 2005),
('Orchestra Nova', 'Italy', 'Classical orchestra', 5, 1998),
('FireStream', 'USA', 'Hard rock band', 6, 2012),
('Urban Flow', 'Canada', 'Hip-hop collective', 7, 2016),
('Melody Lane', 'Spain', 'Pop duo', 8, 2019),
('Metal Storm', 'Germany', 'Heavy metal band', 9, 2008),
('DreamLights', 'France', 'Synthwave project', 10, 2020),
('Blue Horizon', 'UK', 'Indie folk band', 11, 2014),
('JazzMakers', 'USA', 'Contemporary jazz', 12, 2002),
('Electric Souls', 'Germany', 'Electropop trio', 13, 2019),
('The Classics', 'Italy', 'Classical ensemble', 14, 1995),
('BeatKings', 'USA', 'Hip-Hop legends', 15, 2010);

-- ===== ALBUMS =====
INSERT INTO album (title, release_date, artist_id, genre_id)
VALUES
('Waves of Sound', '2021-03-15', 1, 2),
('Electric Dreams', '2022-06-10', 2, 6),
('Midnight Stories', '2020-11-05', 3, 1),
('Cat Groove', '2019-08-22', 4, 4),
('Symphony of Stars', '2018-01-01', 5, 5),
('Rock Inferno', '2022-09-10', 6, 2),
('Street Beats', '2023-01-15', 7, 3),
('Summer Lights', '2021-07-25', 8, 1),
('Metal Fury', '2020-12-05', 9, 9),
('Retro Vision', '2023-03-01', 10, 6),
('Folk Tales', '2022-05-12', 11, 7),
('Smooth Ride 2', '2023-06-18', 12, 4),
('Neon Beats', '2023-08-10', 13, 6),
('Baroque Revival', '2021-11-11', 14, 5),
('Urban Empire', '2023-09-01', 15, 3);

-- ===== TRACKS =====
INSERT INTO track (title, duration_seconds, album_id, artist_id, genre_id)
VALUES
('Echoes', 210, 1, 1, 2), ('Lost in Sound', 195, 1, 1, 2),
('Dream Machine', 230, 2, 2, 6), ('Pulse Drive', 250, 2, 2, 6),
('Night Sky', 200, 3, 3, 1), ('Falling Lights', 185, 3, 3, 1),
('Smooth Ride', 300, 4, 4, 4), ('Jazz Flow', 275, 4, 4, 4),
('Celestial Overture', 420, 5, 5, 5), ('Starfall Finale', 390, 5, 5, 5),
('Firestorm', 260, 6, 6, 2), ('Infernal Drive', 245, 6, 6, 2),
('City Lights', 210, 7, 7, 3), ('Street Anthem', 225, 7, 7, 3),
('Sunset Waves', 215, 8, 8, 1), ('Bright Days', 205, 8, 8, 1),
('Iron Will', 310, 9, 9, 9), ('Thunder March', 295, 9, 9, 9),
('Neon Skies', 240, 10, 10, 6), ('Digital Dreams', 250, 10, 10, 6),
('Wandering Road', 275, 11, 11, 7), ('Folk Spirit', 290, 11, 11, 7),
('Sax Nights', 320, 12, 12, 4), ('Cool Jazz', 280, 12, 12, 4),
('Electric Hearts', 230, 13, 13, 6), ('Neon Pulse', 240, 13, 13, 6),
('Baroque Symphony', 480, 14, 14, 5), ('Classic Flow', 460, 14, 14, 5),
('Urban Legend', 230, 15, 15, 3), ('Empire Rise', 245, 15, 15, 3);

-- ===== PLAYLISTS =====
INSERT INTO playlist (title, description, is_public, user_id)
VALUES
('Morning Vibes', 'Soft pop and chill', TRUE, 1),
('Workout Mix', 'Rock & EDM', TRUE, 2),
('Jazz Night', 'Smooth jazz', FALSE, 4),
('Focus Mode', 'Calm tunes', TRUE, 5),
('Hip-Hop Heat', 'Best rap tracks', TRUE, 7),
('Metal Madness', 'Heavy riffs only', TRUE, 9),
('Study Chill', 'Lo-fi and acoustic', TRUE, 10),
('Symphony', 'Classical pieces', FALSE, 14),
('Summer Vibes', 'Hot pop hits', TRUE, 8),
('Underground', 'Indie discoveries', TRUE, 11);

-- ===== LISTENING HISTORY =====
INSERT INTO listening_history (user_id, track_id, listened_at, device)
VALUES
(1, 1, '2024-10-20 08:00', 'iPhone'),
(2, 11, '2024-10-21 09:00', 'Android'),
(3, 15, '2024-10-21 10:00', 'PC'),
(4, 7, '2024-10-21 11:00', 'SmartTV'),
(5, 9, '2024-10-22 12:00', 'Laptop'),
(6, 17, '2024-10-22 13:00', 'Android'),
(7, 13, '2024-10-22 14:00', 'iPhone'),
(8, 21, '2024-10-22 15:00', 'iPad'),
(9, 19, '2024-10-23 16:00', 'PC'),
(10, 25, '2024-10-23 17:00', 'Laptop'),
(11, 28, '2024-10-23 18:00', 'PC'),
(12, 4, '2024-10-23 19:00', 'iPhone'),
(13, 23, '2024-10-23 20:00', 'Android'),
(14, 29, '2024-10-24 21:00', 'SmartTV'),
(15, 30, '2024-10-24 22:00', 'PC'),
(16, 2, '2024-10-25 08:00', 'Laptop'),
(17, 6, '2024-10-25 09:00', 'Android'),
(18, 8, '2024-10-25 10:00', 'iPhone'),
(19, 10, '2024-10-25 11:00', 'iPad'),
(20, 12, '2024-10-25 12:00', 'PC');

-- ===== LIKES =====
INSERT INTO "like" (user_id, track_id, created_at)
VALUES
(1, 3, '2024-10-21 09:00'), (2, 4, '2024-10-21 09:05'),
(3, 5, '2024-10-21 10:00'), (4, 7, '2024-10-21 11:00'),
(5, 9, '2024-10-22 12:00'), (6, 11, '2024-10-22 13:00'),
(7, 13, '2024-10-22 14:00'), (8, 15, '2024-10-22 15:00'),
(9, 17, '2024-10-22 16:00'), (10, 19, '2024-10-23 17:00'),
(11, 21, '2024-10-23 18:00'), (12, 23, '2024-10-23 19:00'),
(13, 25, '2024-10-23 20:00'), (14, 27, '2024-10-24 21:00'),
(15, 29, '2024-10-24 22:00');

-- ===== COMMENTS =====
INSERT INTO comment (user_id, track_id, content, created_at)
VALUES
(1, 1, 'Amazing vocals!', '2024-10-21 09:10'),
(2, 4, 'Fire track!', '2024-10-21 09:20'),
(3, 5, 'So smooth.', '2024-10-21 10:10'),
(4, 7, 'Jazz perfection.', '2024-10-21 11:20'),
(5, 9, 'Beautiful symphony.', '2024-10-22 12:10'),
(6, 11, 'Rock on!', '2024-10-22 13:10'),
(7, 13, 'Love the beat!', '2024-10-22 14:10'),
(8, 15, 'Perfect summer track.', '2024-10-22 15:10'),
(9, 17, 'Heavy and powerful.', '2024-10-22 16:10'),
(10, 19, 'Synth heaven.', '2024-10-23 17:10');

-- ===== FOLLOWS =====
INSERT INTO follow (user_id, artist_id, created_at)
VALUES
(1, 1, '2024-10-21'), (2, 2, '2024-10-21'),
(3, 3, '2024-10-22'), (4, 4, '2024-10-22'),
(5, 5, '2024-10-22'), (6, 6, '2024-10-23'),
(7, 7, '2024-10-23'), (8, 8, '2024-10-23'),
(9, 9, '2024-10-24'), (10, 10, '2024-10-24'),
(11, 11, '2024-10-24'), (12, 12, '2024-10-24'),
(13, 13, '2024-10-25'), (14, 14, '2024-10-25'),
(15, 15, '2024-10-25');
```