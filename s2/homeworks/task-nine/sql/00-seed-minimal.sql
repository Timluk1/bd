-- Минимальные тестовые данные для OLAP (основная БД music)

INSERT INTO subscription (name, price, duration_months) VALUES
    ('free',    0.00, NULL),
    ('basic',   4.99, 1),
    ('premium', 9.99, 1),
    ('family', 14.99, 1);

INSERT INTO genre (name) VALUES
    ('Rock'), ('Pop'), ('Hip-Hop'), ('Electronic'), ('Jazz');

INSERT INTO artist (name, country) VALUES
    ('Arctic Monkeys', 'UK'),
    ('Daft Punk',      'FR'),
    ('Kendrick Lamar', 'US'),
    ('Radiohead',      'UK'),
    ('Billie Eilish',  'US');

INSERT INTO album (title, release_date, artist_id, genre_id) VALUES
    ('AM',             '2013-09-09', 1, 1),
    ('Random Access',    '2013-05-17', 2, 4),
    ('DAMN.',            '2017-04-14', 3, 3),
    ('OK Computer',      '1997-06-16', 4, 1),
    ('When We All Fall', '2019-03-29', 5, 2);

INSERT INTO track (title, duration_seconds, album_id, artist_id, genre_id) VALUES
    ('Do I Wanna Know?', 272, 1, 1, 1),
    ('R U Mine?',        201, 1, 1, 1),
    ('Get Lucky',        248, 2, 2, 4),
    ('Instant Crush',    337, 2, 2, 4),
    ('HUMBLE.',          177, 3, 3, 3),
    ('DNA.',             185, 3, 3, 3),
    ('Paranoid Android', 383, 4, 4, 1),
    ('Karma Police',     261, 4, 4, 1),
    ('bad guy',          194, 5, 5, 2),
    ('bury a friend',    193, 5, 5, 2);

INSERT INTO "user" (email, username, password_hash, country, date_joined, subscription_id) VALUES
    ('alice@mail.ru',  'alice', 'hash1', 'RU', '2023-01-15', 3),
    ('bob@mail.ru',    'bob',   'hash2', 'RU', '2023-03-20', 1),
    ('carol@mail.com', 'carol', 'hash3', 'US', '2023-06-01', 2),
    ('dave@mail.de',   'dave',  'hash4', 'DE', '2024-01-10', 4),
    ('eve@mail.co.uk', 'eve',   'hash5', 'UK', '2024-02-28', 3);

INSERT INTO listening_history (user_id, track_id, listened_at, device, platform, completed, quality) VALUES
    (1, 1, '2024-05-01 08:15:00', 'mobile',  'android', true,  'high'),
    (1, 3, '2024-05-01 09:30:00', 'mobile',  'android', true,  'high'),
    (2, 5, '2024-05-01 12:00:00', 'desktop', 'web',     true,  'normal'),
    (3, 9, '2024-05-01 18:45:00', 'mobile',  'ios',     false, 'normal'),
    (1, 2, '2024-05-02 07:20:00', 'mobile',  'android', true,  'high'),
    (4, 7, '2024-05-02 14:10:00', 'desktop', 'web',     true,  'lossless'),
    (5, 3, '2024-05-02 20:00:00', 'tablet',  'ios',     true,  'high'),
    (2, 5, '2024-05-03 10:00:00', 'mobile',  'android', true,  'normal'),
    (2, 6, '2024-05-03 10:05:00', 'mobile',  'android', false, 'normal'),
    (3, 9, '2024-05-03 11:30:00', 'mobile',  'ios',     true,  'normal'),
    (3, 10,'2024-05-03 11:35:00', 'mobile',  'ios',     true,  'normal'),
    (1, 1, '2024-05-04 09:00:00', 'mobile',  'android', true,  'high'),
    (1, 3, '2024-05-04 09:15:00', 'mobile',  'android', true,  'high'),
    (1, 5, '2024-05-04 09:30:00', 'mobile',  'android', true,  'high'),
    (4, 4, '2024-05-04 16:00:00', 'desktop', 'web',     true,  'lossless'),
    (5, 8, '2024-05-05 08:00:00', 'mobile',  'ios',     true,  'high'),
    (5, 7, '2024-05-05 08:30:00', 'mobile',  'ios',     false, 'high'),
    (2, 1, '2024-05-05 19:00:00', 'desktop', 'web',     true,  'normal'),
    (3, 3, '2024-05-06 13:00:00', 'mobile',  'ios',     true,  'normal'),
    (4, 5, '2024-05-06 15:00:00', 'desktop', 'web',     true,  'lossless'),
    (1, 9, '2024-05-07 10:00:00', 'mobile',  'android', true,  'high'),
    (2, 3, '2024-05-07 11:00:00', 'mobile',  'android', true,  'normal'),
    (5, 3, '2024-05-07 12:00:00', 'tablet',  'ios',     true,  'high'),
    (3, 5, '2024-05-08 09:00:00', 'mobile',  'ios',     true,  'normal'),
    (1, 1, '2024-05-08 17:00:00', 'mobile',  'android', true,  'high'),
    (4, 7, '2024-05-09 14:00:00', 'desktop', 'web',     true,  'lossless'),
    (2, 5, '2024-05-09 20:00:00', 'mobile',  'android', true,  'normal'),
    (5, 9, '2024-05-10 07:30:00', 'mobile',  'ios',     true,  'high'),
    (3, 9, '2024-05-10 08:00:00', 'mobile',  'ios',     false, 'normal'),
    (1, 3, '2024-05-10 18:00:00', 'mobile',  'android', true,  'high');
