-- Роли
CREATE ROLE app LOGIN PASSWORD 'app_pass' VALID UNTIL 'infinity'
CONNECTION LIMIT 10;


CREATE ROLE admin LOGIN PASSWORD 'app_adm' VALID UNTIL 'infinity'
CONNECTION LIMIT 2;


CREATE ROLE readonly LOGIN PASSWORD 'app_read' VALID UNTIL 'infinity'
CONNECTION LIMIT 20;


-- Даем доступ к подключению и схемам таблиц
GRANT CONNECT ON DATABASE music TO app, admin, readonly;
GRANT USAGE ON SCHEMA public TO app, admin, readonly;

-- Даем доступ к чтению и записи в зависимости от пользователя
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app; -- Доступ к вставке SERIAL
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;