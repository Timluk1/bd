CREATE TABLE IF NOT EXISTS test_pk (
    id INT PRIMARY KEY,
    name TEXT
);

CREATE TABLE IF NOT EXISTS test_nopk (
    id INT,
    name TEXT
);

CREATE PUBLICATION pub_demo FOR TABLE test_pk, test_nopk;
