## Запрос 1
**Формулировка:**  
Найти все названия треков жанра *Rock*.  

**Реляционная алгебра:**  
π_{title}(σ_{name='Rock'}(Genre ⨝ Track)

---

## Запрос 2
**Формулировка:**  
Найти имена пользователей и названия плейлистов, которые они создали.  

**Реляционная алгебра:**  
π_{User.username, Playlist.title}(User ⨝_{User.id = Playlist.user_id} Playlist)

# Домашняя работа 2

## Создание БД

```sql
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
```
## Alter запросы
```sql
-- 1. Добавим поле phone_number в таблицу User
ALTER TABLE "user"
ADD COLUMN phone_number VARCHAR(20);

-- 2. В Playlist добавим дату создания
ALTER TABLE playlist
ADD COLUMN created_at TIMESTAMP DEFAULT NOW();

-- 3. В Track сделаем поле duration_seconds обязательным
ALTER TABLE track
ALTER COLUMN duration_seconds SET NOT NULL;

```

## Insert-запросы
```sql
INSERT INTO subscription (name, price, duration_months)
VALUES
  ('Free', 0.00, 0),
  ('Premium', 9.99, 1),
  ('Family', 14.99, 1);

INSERT INTO "user" (email, username, password_hash, country, date_joined, subscription_id, phone_number)
VALUES
  ('timluk@mail.ru', 'Timur', 'hash1', 'Russia', '2024-01-10', 2, '+123456789'),
  ('sequze@mail.ru', 'Amir', 'hash2', 'Russia', '2024-02-15', 1, '+987654321');

INSERT INTO artist (name, country, description, user_id, start_year)
VALUES
  ('Timur', 'Russia', '', 1, 2000),
  ('Amir', 'Russia', '', 2, 2010);

INSERT INTO genre (name)
VALUES ('Rock'), ('Electronic'), ('Pop');
```

## UPDATE-запросы
```sql
UPDATE "user"
SET subscription_id = 2
WHERE username = 'Amir';

UPDATE artist
SET description = 'Timur Lukmanov'
WHERE name = 'Timur';

UPDATE subscription
SET price = 17.99
WHERE name = 'Family';

UPDATE "user"
SET country = 'China'
WHERE username = 'Timur'
```
