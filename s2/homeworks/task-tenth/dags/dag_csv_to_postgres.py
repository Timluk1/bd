import csv
import json
import os

import pendulum
import psycopg2
from airflow import DAG
from airflow.decorators import task
from psycopg2.extras import execute_values


POSTGRES_DSN = os.getenv("POSTGRES_DSN")
DATA_DIR = "/opt/airflow/data/seed"
LOAD_LOCK_KEY = "csv_to_postgres"

TABLES_IN_DELETE_ORDER = [
    "comment",
    "follow",
    '"like"',
    "listening_history",
    "playlist",
    "track",
    "album",
    '"user"',
    "artist",
    "genre",
    "subscription",
]

PARTITION_REFRESH_STATEMENTS = [
    """
    TRUNCATE listening_history_part RESTART IDENTITY;
    INSERT INTO listening_history_part (
        user_id, track_id, listened_at, device, platform, completed, quality
    )
    SELECT user_id, track_id, listened_at, device, platform, completed, quality
    FROM listening_history
    WHERE listened_at IS NOT NULL
      AND listened_at >= '2023-01-01'
      AND listened_at < '2026-01-01';
    """,
    """
    TRUNCATE track_part RESTART IDENTITY;
    INSERT INTO track_part (
        title, duration_seconds, artist_id, album_id, genre_name, play_count, mood
    )
    SELECT t.title, t.duration_seconds, t.artist_id, t.album_id,
           COALESCE(g.name, 'Other'), t.play_count, t.mood
    FROM track t
    LEFT JOIN genre g ON g.id = t.genre_id;
    """,
    """
    TRUNCATE like_part RESTART IDENTITY;
    INSERT INTO like_part (user_id, track_id, created_at)
    SELECT user_id, track_id, COALESCE(created_at, now())
    FROM "like";
    """,
]


def _staging_table_name(table_name: str) -> str:
    return f"staging_{table_name.strip('\"')}"


def _reset_id_sequence(cur, table_name: str) -> None:
    cur.execute(
        f"""
        SELECT setval(
            pg_get_serial_sequence('{table_name}', 'id'),
            COALESCE((SELECT MAX(id) FROM {table_name}), 1),
            true
        )
        """
    )


def _upsert_staging_rows(cur, table_name: str, staging_table: str, columns: list[str]) -> None:
    columns_sql = ", ".join(columns)
    update_columns = [column for column in columns if column != "id"]

    if update_columns:
        update_sql = ", ".join(
            f"{column} = EXCLUDED.{column}" for column in update_columns
        )
        cur.execute(
            f"""
            INSERT INTO {table_name} ({columns_sql})
            SELECT {columns_sql} FROM {staging_table}
            ON CONFLICT (id) DO UPDATE SET {update_sql}
            """
        )
    else:
        cur.execute(
            f"""
            INSERT INTO {table_name} ({columns_sql})
            SELECT {columns_sql} FROM {staging_table}
            ON CONFLICT (id) DO NOTHING
            """
        )


def upsert_json_to_table(table_name: str, json_file_name: str) -> None:
    json_path = f"{DATA_DIR}/{json_file_name}"

    with open(json_path, "r", encoding="utf-8") as json_file:
        records = json.load(json_file)

    if not records:
        return

    columns = list(records[0].keys())
    columns_sql = ", ".join(columns)
    values = [[record[column] for column in columns] for record in records]
    staging_table = _staging_table_name(table_name)

    with psycopg2.connect(POSTGRES_DSN) as conn:
        with conn.cursor() as cur:
            cur.execute(
                f"CREATE TEMP TABLE {staging_table} "
                f"(LIKE {table_name} INCLUDING DEFAULTS) ON COMMIT DROP"
            )
            execute_values(
                cur,
                f"INSERT INTO {staging_table} ({columns_sql}) VALUES %s",
                values,
            )
            _upsert_staging_rows(cur, table_name, staging_table, columns)
            _reset_id_sequence(cur, table_name)


def upsert_csv_to_table(table_name: str, csv_file_name: str) -> None:
    csv_path = f"{DATA_DIR}/{csv_file_name}"

    with open(csv_path, "r", encoding="utf-8", newline="") as csv_file:
        columns = next(csv.reader(csv_file))

    columns_sql = ", ".join(columns)
    staging_table = _staging_table_name(table_name)

    with psycopg2.connect(POSTGRES_DSN) as conn:
        with conn.cursor() as cur:
            cur.execute(
                f"CREATE TEMP TABLE {staging_table} "
                f"(LIKE {table_name} INCLUDING DEFAULTS) ON COMMIT DROP"
            )

            copy_sql = (
                f"COPY {staging_table} ({columns_sql}) "
                f"FROM STDIN WITH (FORMAT CSV, HEADER TRUE)"
            )
            with open(csv_path, "r", encoding="utf-8", newline="") as csv_file:
                cur.copy_expert(copy_sql, csv_file)

            _upsert_staging_rows(cur, table_name, staging_table, columns)
            _reset_id_sequence(cur, table_name)


def _table_exists(cur, table_name: str) -> bool:
    bare_name = table_name.strip('"')
    cur.execute("SELECT to_regclass(%s) IS NOT NULL", (f"public.{bare_name}",))
    return cur.fetchone()[0]


with DAG(
    dag_id="csv_to_postgres",
    description="CSV and JSON seed files to Postgres",
    start_date=pendulum.datetime(2026, 5, 24, tz="UTC"),
    schedule="@once",
    catchup=False,
    max_active_runs=1,
) as dag:
    @task
    def prepare_database():
        with psycopg2.connect(POSTGRES_DSN) as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT pg_advisory_xact_lock(hashtext(%s))",
                    (LOAD_LOCK_KEY,),
                )
                cur.execute(
                    f"TRUNCATE {', '.join(TABLES_IN_DELETE_ORDER)} "
                    "RESTART IDENTITY CASCADE"
                )

    @task
    def load_subscriptions():
        upsert_csv_to_table("subscription", "subscription.csv")

    @task
    def load_genres():
        upsert_json_to_table("genre", "genre.json")

    @task
    def load_users():
        upsert_csv_to_table('"user"', "user.csv")

    @task
    def load_artists():
        upsert_csv_to_table("artist", "artist.csv")

    @task
    def load_albums():
        upsert_csv_to_table("album", "album.csv")

    @task
    def load_tracks():
        upsert_csv_to_table("track", "track.csv")

    @task
    def load_listening_history():
        upsert_csv_to_table("listening_history", "listening_history.csv")

    @task
    def load_likes():
        upsert_csv_to_table('"like"', "like.csv")

    @task
    def load_follows():
        upsert_csv_to_table("follow", "follow.csv")

    @task
    def load_comments():
        upsert_csv_to_table("comment", "comment.csv")

    @task
    def refresh_partitioned_tables():
        with psycopg2.connect(POSTGRES_DSN) as conn:
            with conn.cursor() as cur:
                for statement in PARTITION_REFRESH_STATEMENTS:
                    table_name = statement.split()[1]
                    if _table_exists(cur, table_name):
                        cur.execute(statement)

    prepare = prepare_database()

    subscriptions = load_subscriptions()
    genres = load_genres()
    artists = load_artists()
    albums = load_albums()
    users = load_users()
    tracks = load_tracks()
    listening_history = load_listening_history()
    likes = load_likes()
    follows = load_follows()
    comments = load_comments()
    refresh_partitions = refresh_partitioned_tables()

    prepare >> [subscriptions, genres, artists]
    [artists, genres] >> albums
    subscriptions >> users
    [albums, artists, genres] >> tracks
    users >> [listening_history, likes, comments]
    tracks >> [listening_history, likes, comments]
    [users, artists] >> follows
    [listening_history, likes, tracks] >> refresh_partitions
