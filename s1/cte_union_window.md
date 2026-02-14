# CTE 5 запросов 
1. Пользователи, которые чаще всего слушают музыку
![](screenshots/cte_union_window/1.png)
2.Самые популярные треки (по количеству лайков и прослушиваний)
```sql
WITH likes_count as
         (select t.id, count(l.id) as like_count
          from track t
                   inner join "like" l on t.id = l.track_id
          group by t.id),
     listened_count as
         (select t.id, count(l.id) as listen_count
          from track t
                   inner join listening_history l on l.track_id = t.id
          group by t.id)

select t.id, t.title, like_count, listen_count
from track t
         join likes_count l1 on l1.id = t.id
         join listened_count l2 on l2.id = t.id
order by listen_count, like_count desc;
```
![](screenshots/cte_union_window/2.png)
3. Артисты, у которых средняя продолжительность треков выше средней по всем
![](screenshots/cte_union_window/3.png)
4. Самые активные комментаторы за последний месяц
![](screenshots/cte_union_window/4.png)
5. Средняя стоимость подписки по странам пользователей
![](screenshots/cte_union_window/5.png)

# UNION 3 запроса
1. 
![](screenshots/cte_union_window/6.png)
2. Вывести все месяцы после регистрации пользователя до текущего
![](screenshots/cte_union_window/7.png)
3. Вывести всех пользователей, которые слушали или лайкали данный трек
![](screenshots/cte_union_window/8.png)

# INTERSECT 3 запроса
1. Вывести пользователей и треки, которые они слушали и лайкали
![](screenshots/cte_union_window/9.png)
2. Вывести пользователей и треки, которые они слушали и комментировали
![](screenshots/cte_union_window/10.png)
3. Артисты, которых пользователь и слушает, и комментирует
![](screenshots/cte_union_window/11.png)

# EXCEPT 3 запроса
1. Пользователи, которые слушали треки, но ни разу не лайкали
![](screenshots/cte_union_window/12.png)
2. Выбрать треки из альбома, которые пользователь еще не слушал
![](screenshots/cte_union_window/13.png)
3. Выбрать треки, которые никто не слушал
![](screenshots/cte_union_window/14.png)

# PARTITION BY 2 запроса
1. Выбрать треки с количеством треков в альбоме
![](screenshots/cte_union_window/15.png)
2. Вывести комментарии с количеством комментариев к данному треку
![](screenshots/cte_union_window/16.png)
# PARTITION BY + ORDER BY
1. Список прослушиваний пользователей с увеличивающимся счетчиком прослушенных треков
![](screenshots/cte_union_window/17.png)
2. Вывести треки альбома сортированные по продолжительности с увеличивающимся счетчиком
![](screenshots/cte_union_window/18.png)

# ROWS, RANGE по 2 запроса
1. Скользящая сумма длительности трека по последним двум строкам
![](screenshots/cte_union_window/19.png)
2. Разница между текущей и предыдущей длительностью трека
![](screenshots/cte_union_window/20.png)
3. Отобразить в истории прослушиваний среднюю длительность прослушивания в отрезке между предыдущим и следующим днем
![](screenshots/cte_union_window/21.png)
4. Вывести дни с количеством прослушиваний за последние 7 дней
```sql
WITH daily_listens AS (
    SELECT 
        date_trunc('day', listened_at)::date AS day,
        COUNT(*) AS listens
    FROM listening_history
    GROUP BY 1
)
SELECT
    day,
    listens,
    SUM(listens) OVER (
        ORDER BY day 
        RANGE BETWEEN INTERVAL '7 days' PRECEDING AND CURRENT ROW
    ) AS listens_last_2_days
FROM daily_listens
ORDER BY day;
```
![](screenshots/cte_union_window/22.png)
# Ранджирующие

1. Трек и его номер в порядке длительности
![](screenshots/cte_union_window/23.png)
2. Треки и их ранг по количеству лайков
![](screenshots/cte_union_window/24.png)
3. Треки по длительности с помощью DENSE_RANK
![](screenshots/cte_union_window/25.png)

# Функции смещения
1. Следующий трек по длительности
![](screenshots/cte_union_window/26.png)
2. Первый альбом исполнителя
![](screenshots/cte_union_window/27.png)
3. Дата прослушивания и последнее прослушивание пользователя
![](screenshots/cte_union_window/28.png)





