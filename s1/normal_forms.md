```sql
-- 1. Удаляем старые поля device и country
ALTER TABLE "user"
DROP COLUMN IF EXISTS device,
DROP COLUMN IF EXISTS country;

-- 2. Добавляем новое поле country_id
ALTER TABLE "user"
ADD COLUMN country_id INTEGER;

-- 3. Добавляем внешний ключ на таблицу countries
ALTER TABLE "user"
ADD CONSTRAINT fk_user_country
FOREIGN KEY (country_id) REFERENCES countries(id)
ON DELETE SET NULL;
```