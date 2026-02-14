# 1. SELECT (3 шт.)
## 1. Получить названия треков, длительность которых больше средней
![img.png](screenshots/sub_queries_results/1.png)

## 2. Получить имена пользователей, подписка которых дороже средней стоимости
![img.png](screenshots/sub_queries_results/2.png)

## 3. Получить жанры, для которых существует хоть один трек
![img.png](screenshots/sub_queries_results/3.png)

# 2. FROM (3 шт.)

## 4. Показать пользователей и количество их лайков (через подзапрос как источник FROM)
![img.png](screenshots/sub_queries_results/4.png)

## 5. Альбомы и количество песен в них
![img.png](screenshots/sub_queries_results/5.png)

## 6. Артисты и количество их подписчиков
![img.png](screenshots/sub_queries_results/6.png)

# 3. WHERE (3 шт.)

## 7. Треки с длительностью больше максимума у жанра "Rock"
![img.png](screenshots/sub_queries_results/7.png)

## 8. Артисты из стран, где зарегистрировано более 3 пользователей
![img.png](screenshots/sub_queries_results/8.png)

## 9. Пользователи, у которых страна совпадает со страной артиста "BeatKings"
![img.png](screenshots/sub_queries_results/9.png)

# 4. HAVING (3 шт.)

## 10. Жанры с количеством треков больше среднего
![img.png](screenshots/sub_queries_results/10.png)

## 11. Артисты с количеством альбомов больше среднего
![img.png](screenshots/sub_queries_results/11.png)

## 12. Пользователи с количеством лайков больше либо равным среднему
![img.png](screenshots/sub_queries_results/12.png)

# 5. ALL (3 шт.)

## 13. Треки, длиннее всех треков жанра Pop
![img.png](screenshots/sub_queries_results/13.png)

## 14. Альбомы, выпущенные позже любого альбома артиста "The Harmonics"
![img.png](screenshots/sub_queries_results/14.png)

## 15. Комментарии позже всех лайков пользователя
![img.png](screenshots/sub_queries_results/15.png)

# 6. IN (3 шт.)
![img.png](screenshots/sub_queries_results/delete.png)
``sql
DELETE FROM public.follow WHERE id = 15
``

## 16. Треки только тех артистов, на которых кто-то подписан
![img.png](screenshots/sub_queries_results/16.png)

## 17. Плейлисты только пользователей с подпиской
![img.png](screenshots/sub_queries_results/17.png)

## 18. Пользователи, лайкнувшие треки в альбоме c album_id = 2
![img.png](screenshots/sub_queries_results/18.png)

# 7. ANY (3 шт.)

## 19. Треки с длительностью больше хотя бы одного трека артиста DJ Pulse
![img.png](screenshots/sub_queries_results/19.png)

## 20. Артисты, начавшие карьеру раньше хотя бы одного из России
![img.png](screenshots/sub_queries_results/20.png)

## 21. Альбомы, выпущенные раньше хотя бы одного релиза жанра Rock
![img.png](screenshots/sub_queries_results/21.png)

# 8. EXISTS (3 шт.)

## 22. Артисты, у которых есть альбомы с более чем 5 треками
```sql
INSERT INTO public.track (id, title, duration_seconds, album_id, artist_id, genre_id) VALUES (31, 'Empire Rise DELUX', 300, 15, 15, 3)
```
![img.png](screenshots/sub_queries_results/22.png)

## 23. Пользователи, лайкнувшие хотя бы один трек
```sql
DELETE FROM public."like" WHERE id = 15
```
![img.png](screenshots/sub_queries_results/23.png)

## 24. Жанры, в которых существуют треки
![img.png](screenshots/sub_queries_results/24.png)

# 9. Сравнение по нескольким столбцам (3 шт.)

## 25. Треки, у которых такой же (artist_id,genre_id), как у трека id = 1 (исключая сам трек id = 1)
![img.png](screenshots/sub_queries_results/25.png)

## 26. Артисты из той же страны и стартового года, что и артист The Harmonics (включая самого артиста The Harmonics)
```sql
UPDATE public.artist SET start_year = 2010 WHERE id = 11
```
![img.png](screenshots/sub_queries_results/26.png)

## 27. Альбомы такого же жанра и артиста, как альбом id = 2 (включая сам альбом id = 2)
```sql
SELECT title
FROM album
WHERE (artist_id, genre_id) = (
  SELECT artist_id, genre_id FROM album WHERE id = 2
);
```
![img.png](screenshots/sub_queries_results/27.png)

# Коррелированные подзапросы (5 шт.)

## 3. Получить жанры, для которых существует хоть один трек
![img.png](screenshots/sub_queries_results/3.png)

## 5. Альбомы и количество песен в них
![img.png](screenshots/sub_queries_results/5.png)

## 6. Артисты и количество их подписчиков
![img.png](screenshots/sub_queries_results/6.png)

## 15. Комментарии позже всех лайков пользователя
![img.png](screenshots/sub_queries_results/15.png)

## 22. Артисты, у которых есть альбомы с более чем 5 треками
```sql
INSERT INTO public.track (id, title, duration_seconds, album_id, artist_id, genre_id) VALUES (31, 'Empire Rise DELUX', 300, 15, 15, 3)
```
![img.png](screenshots/sub_queries_results/22.png)