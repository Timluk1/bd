import os
import urllib.error
import urllib.parse
import urllib.request
from datetime import date, datetime
from decimal import Decimal

import pendulum
import psycopg2
from airflow import DAG
from airflow.decorators import task
from psycopg2.extras import RealDictCursor


POSTGRES_DSN = os.getenv("POSTGRES_DSN")
CLICKHOUSE_DSN = os.getenv("CLICKHOUSE_DSN", "http://clickhouse:8123")
CLICKHOUSE_USER = os.getenv("CLICKHOUSE_USER", "default")
CLICKHOUSE_PASSWORD = os.getenv("CLICKHOUSE_PASSWORD", "password")
CLICKHOUSE_DATABASE = os.getenv("CLICKHOUSE_DATABASE", "music_mart")
INSERT_BATCH_SIZE = 10_000

MART_TABLES = [
    "fact_listening",
    "dim_user",
    "dim_track",
    "dim_genre",
    "dim_date",
]

CREATE_SCHEMA_SQL = [
    f"CREATE DATABASE IF NOT EXISTS {CLICKHOUSE_DATABASE}",
    f"""
    CREATE TABLE IF NOT EXISTS {CLICKHOUSE_DATABASE}.dim_date (
        date_key UInt32,
        full_date Date,
        day_of_week UInt8,
        day_name String,
        week_of_year UInt8,
        month_number UInt8,
        month_name String,
        quarter_number UInt8,
        year_number UInt16,
        is_weekend UInt8
    ) ENGINE = MergeTree()
    ORDER BY date_key
    """,
    f"""
    CREATE TABLE IF NOT EXISTS {CLICKHOUSE_DATABASE}.dim_user (
        user_id UInt32,
        username String,
        country Nullable(String),
        subscription_name Nullable(String),
        date_joined Nullable(Date)
    ) ENGINE = MergeTree()
    ORDER BY user_id
    """,
    f"""
    CREATE TABLE IF NOT EXISTS {CLICKHOUSE_DATABASE}.dim_track (
        track_id UInt32,
        title String,
        artist_name Nullable(String),
        album_title Nullable(String),
        duration_seconds UInt32,
        genre_id UInt32,
        mood Nullable(String)
    ) ENGINE = MergeTree()
    ORDER BY track_id
    """,
    f"""
    CREATE TABLE IF NOT EXISTS {CLICKHOUSE_DATABASE}.dim_genre (
        genre_id UInt32,
        genre_name String
    ) ENGINE = MergeTree()
    ORDER BY genre_id
    """,
    f"""
    CREATE TABLE IF NOT EXISTS {CLICKHOUSE_DATABASE}.fact_listening (
        listening_id UInt32,
        date_key UInt32,
        user_id UInt32,
        track_id UInt32,
        genre_id UInt32,
        listened_at DateTime,
        device Nullable(String),
        platform Nullable(String),
        quality LowCardinality(String),
        completed UInt8,
        listen_count UInt8,
        completed_count UInt8
    ) ENGINE = MergeTree()
    PARTITION BY toYYYYMM(listened_at)
    ORDER BY (date_key, genre_id, user_id, listening_id)
    """,
]

EXTRACT_DIM_DATE_SQL = """
SELECT DISTINCT
    TO_CHAR(d::date, 'YYYYMMDD')::INTEGER AS date_key,
    d::date AS full_date,
    EXTRACT(ISODOW FROM d)::SMALLINT AS day_of_week,
    TRIM(TO_CHAR(d, 'TMDay')) AS day_name,
    EXTRACT(WEEK FROM d)::SMALLINT AS week_of_year,
    EXTRACT(MONTH FROM d)::SMALLINT AS month_number,
    TRIM(TO_CHAR(d, 'TMMonth')) AS month_name,
    EXTRACT(QUARTER FROM d)::SMALLINT AS quarter_number,
    EXTRACT(YEAR FROM d)::SMALLINT AS year_number,
    CASE WHEN EXTRACT(ISODOW FROM d) IN (6, 7) THEN 1 ELSE 0 END AS is_weekend
FROM (
    SELECT listened_at::date AS d FROM listening_history
    UNION
    SELECT date_joined FROM "user" WHERE date_joined IS NOT NULL
) AS dates
ORDER BY date_key
"""

EXTRACT_DIM_USER_SQL = """
SELECT
    u.id AS user_id,
    u.username,
    u.country,
    s.name AS subscription_name,
    u.date_joined
FROM "user" u
LEFT JOIN subscription s ON s.id = u.subscription_id
ORDER BY u.id
"""

EXTRACT_DIM_TRACK_SQL = """
SELECT
    t.id AS track_id,
    t.title,
    a.name AS artist_name,
    al.title AS album_title,
    t.duration_seconds,
    t.genre_id,
    t.mood
FROM track t
LEFT JOIN artist a ON a.id = t.artist_id
LEFT JOIN album al ON al.id = t.album_id
ORDER BY t.id
"""

EXTRACT_DIM_GENRE_SQL = """
SELECT id AS genre_id, name AS genre_name
FROM genre
ORDER BY id
"""

EXTRACT_FACT_LISTENING_SQL = """
SELECT
    lh.id AS listening_id,
    TO_CHAR(lh.listened_at::date, 'YYYYMMDD')::INTEGER AS date_key,
    lh.user_id,
    lh.track_id,
    t.genre_id,
    lh.listened_at,
    lh.device,
    lh.platform,
    COALESCE(lh.quality, 'normal') AS quality,
    CASE WHEN COALESCE(lh.completed, true) THEN 1 ELSE 0 END AS completed,
    1 AS listen_count,
    CASE WHEN COALESCE(lh.completed, true) THEN 1 ELSE 0 END AS completed_count
FROM listening_history lh
JOIN track t ON t.id = lh.track_id
WHERE lh.listened_at IS NOT NULL
ORDER BY lh.id
"""


def _format_ch_value(value) -> str:
    if value is None:
        return "\\N"
    if isinstance(value, bool):
        return "1" if value else "0"
    if isinstance(value, datetime):
        return value.strftime("%Y-%m-%d %H:%M:%S")
    if isinstance(value, date):
        return value.isoformat()
    if isinstance(value, Decimal):
        return format(value, "f")
    text = str(value)
    return (
        text.replace("\\", "\\\\")
        .replace("\t", "\\t")
        .replace("\n", "\\n")
        .replace("\r", "\\r")
    )


def ch_execute(sql: str, body: bytes | None = None, database: str | None = None) -> None:
    params = {
        "user": CLICKHOUSE_USER,
        "password": CLICKHOUSE_PASSWORD,
    }
    if database is not None:
        params["database"] = database

    payload = body if body is not None else sql.encode("utf-8")
    if body is not None:
        params["query"] = sql

    url = f"{CLICKHOUSE_DSN.rstrip('/')}/?{urllib.parse.urlencode(params)}"
    request = urllib.request.Request(url, data=payload, method="POST")

    try:
        with urllib.request.urlopen(request) as response:
            response.read()
    except urllib.error.HTTPError as exc:
        raise RuntimeError(exc.read().decode("utf-8", errors="replace")) from exc


def ch_insert_rows(table: str, columns: list[str], rows: list[dict]) -> None:
    if not rows:
        return

    qualified_table = f"{CLICKHOUSE_DATABASE}.{table}"
    insert_sql = (
        f"INSERT INTO {qualified_table} ({', '.join(columns)}) FORMAT TabSeparated"
    )
    lines = [
        "\t".join(_format_ch_value(row[column]) for column in columns)
        for row in rows
    ]
    ch_execute(insert_sql, body=("\n".join(lines) + "\n").encode("utf-8"))


def ch_truncate_tables(tables: list[str]) -> None:
    for table in tables:
        ch_execute(
            f"TRUNCATE TABLE {CLICKHOUSE_DATABASE}.{table}",
            database=CLICKHOUSE_DATABASE,
        )


def fetch_postgres_rows(query: str) -> list[dict]:
    with psycopg2.connect(POSTGRES_DSN) as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query)
            return [dict(row) for row in cur.fetchall()]


def load_query_to_clickhouse(
    table: str,
    columns: list[str],
    query: str,
) -> int:
    rows = fetch_postgres_rows(query)
    for offset in range(0, len(rows), INSERT_BATCH_SIZE):
        ch_insert_rows(table, columns, rows[offset : offset + INSERT_BATCH_SIZE])
    return len(rows)


with DAG(
    dag_id="postgres_to_clickhouse",
    description="Build music analytics mart in ClickHouse from PostgreSQL",
    start_date=pendulum.datetime(2026, 5, 24, tz="UTC"),
    schedule="@once",
    catchup=False,
    max_active_runs=1,
) as dag:
    @task
    def prepare_clickhouse_schema():
        ch_execute(CREATE_SCHEMA_SQL[0], database="default")
        for statement in CREATE_SCHEMA_SQL[1:]:
            ch_execute(statement, database=CLICKHOUSE_DATABASE)

        ch_truncate_tables(MART_TABLES)

    @task
    def load_dim_date() -> int:
        return load_query_to_clickhouse(
            "dim_date",
            [
                "date_key",
                "full_date",
                "day_of_week",
                "day_name",
                "week_of_year",
                "month_number",
                "month_name",
                "quarter_number",
                "year_number",
                "is_weekend",
            ],
            EXTRACT_DIM_DATE_SQL,
        )

    @task
    def load_dim_user() -> int:
        return load_query_to_clickhouse(
            "dim_user",
            [
                "user_id",
                "username",
                "country",
                "subscription_name",
                "date_joined",
            ],
            EXTRACT_DIM_USER_SQL,
        )

    @task
    def load_dim_track() -> int:
        return load_query_to_clickhouse(
            "dim_track",
            [
                "track_id",
                "title",
                "artist_name",
                "album_title",
                "duration_seconds",
                "genre_id",
                "mood",
            ],
            EXTRACT_DIM_TRACK_SQL,
        )

    @task
    def load_dim_genre() -> int:
        return load_query_to_clickhouse(
            "dim_genre",
            ["genre_id", "genre_name"],
            EXTRACT_DIM_GENRE_SQL,
        )

    @task
    def load_fact_listening() -> int:
        return load_query_to_clickhouse(
            "fact_listening",
            [
                "listening_id",
                "date_key",
                "user_id",
                "track_id",
                "genre_id",
                "listened_at",
                "device",
                "platform",
                "quality",
                "completed",
                "listen_count",
                "completed_count",
            ],
            EXTRACT_FACT_LISTENING_SQL,
        )

    @task
    def build_daily_summary():
        ch_execute(
            f"""
            CREATE TABLE IF NOT EXISTS {CLICKHOUSE_DATABASE}.mart_daily_listens (
                full_date Date,
                day_name String,
                is_weekend UInt8,
                total_listens UInt64,
                unique_users UInt64,
                completion_pct Float64
            ) ENGINE = MergeTree()
            ORDER BY full_date
            """,
            database=CLICKHOUSE_DATABASE,
        )
        ch_execute(
            f"TRUNCATE TABLE {CLICKHOUSE_DATABASE}.mart_daily_listens",
            database=CLICKHOUSE_DATABASE,
        )
        ch_execute(
            f"""
            INSERT INTO {CLICKHOUSE_DATABASE}.mart_daily_listens
            SELECT
                d.full_date,
                d.day_name,
                d.is_weekend,
                sum(f.listen_count) AS total_listens,
                uniqExact(f.user_id) AS unique_users,
                round(
                    100.0 * sum(f.completed_count) / nullIf(sum(f.listen_count), 0),
                    1
                ) AS completion_pct
            FROM {CLICKHOUSE_DATABASE}.fact_listening f
            INNER JOIN {CLICKHOUSE_DATABASE}.dim_date d
                ON d.date_key = f.date_key
            GROUP BY
                d.full_date,
                d.day_name,
                d.is_weekend
            ORDER BY d.full_date
            """,
            database=CLICKHOUSE_DATABASE,
        )

    prepare = prepare_clickhouse_schema()
    dim_date = load_dim_date()
    dim_user = load_dim_user()
    dim_track = load_dim_track()
    dim_genre = load_dim_genre()
    fact_listening = load_fact_listening()
    daily_summary = build_daily_summary()

    prepare >> [dim_date, dim_user, dim_track, dim_genre]
    [dim_date, dim_user, dim_track, dim_genre] >> fact_listening
    fact_listening >> daily_summary
