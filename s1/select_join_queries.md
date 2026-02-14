1. Получить пользователей с видом подписки

```sql
SELECT 
    u.id,
    u.username,
    CASE 
        WHEN s.price > 0 THEN 'Платная подписка'
        ELSE 'Бесплатная подписка'
    END AS subscription_status
FROM user u
JOIN subscription s ON u.subscription_id = s.id;
```

2. Получить треки с категориями по длительности

```sql
SELECT 
    t.name AS track_name,
    CASE 
        WHEN t.duration_seconds < 180 THEN 'Короткий'
        WHEN t.duration_seconds BETWEEN 180 AND 300 THEN 'Средний'
        ELSE 'Длинный'
    END AS length_category
FROM track t;
```

3. Получить ассоциативную таблицу с именами пользователей и названиями понравившихся треков
```sql
SELECT username, t.title as track_name from user u join like l on l.user_id = user.id join t on l.track_id = track.id
```
4. Получить имена пользователей и их страну
```sql
select username, c.name as country from user u join country c on u.country_id = c.id;
```
5. Получить пользователей и их устройств
```sql
SELECT 
    u.username,
    d.name AS device_name
FROM user u
INNER JOIN device d ON u.id = d.user_id;
```
6. Треки и их альбомы
```sql 
SELECT 
    t.name AS track_name,
    a.name AS album_name
FROM track t
INNER JOIN album a ON t.album_id = a.id;
```
7. Пользователи и их подписки
```sql
SELECT 
    u.username, 
    s.name AS subscription_name
FROM user u
LEFT JOIN subscription s ON u.subscription_id = s.id;
```
8. Исполнители и их альбомы
```sql
SELECT 
    ar.name AS artist_name,
    al.name AS album_name
FROM artist ar
LEFT JOIN album al ON ar.id = al.artist_id;
```
9. Треки и артисты
```sql
SELECT 
    t.name AS track_name,
    a.name AS artist_name
FROM track t
RIGHT JOIN artist a ON t.artist_id = a.id;
```
10. Комментарий и пользователь
```sql
SELECT 
    c.content, 
    u.username
FROM comment c
RIGHT JOIN user u ON c.user_id = u.id;
```
11. Все треки и комментарии
```sql
SELECT 
    t.name AS track_name,
    c.content AS comment_text,
    c.created_at
FROM track t
FULL OUTER JOIN comment c ON t.id = c.track_id;
```
12. Альбомы и треки
```sql
SELECT a.name as album_name, t.name as track_name FROM album a FULL OUTER JOIN track t ON a.id = t.album_id;
```
13. Все возможные комбинации жанров и подписок
```sql
SELECT 
    g.name AS genre_name, 
    s.name AS subscription_name
FROM genre g
CROSS JOIN subscription s;
```
14. Все возможные комбинации стран и подписок
```sql
SELECT 
    c.name AS country, 
    s.name AS subscription_name
FROM countries c
CROSS JOIN subscription s;
```
