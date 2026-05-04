CREATE TABLE IF NOT EXISTS customers (
    id          INTEGER PRIMARY KEY,
    first_name  VARCHAR(50)  NOT NULL,
    last_name   VARCHAR(50)  NOT NULL,
    email       VARCHAR(100) NOT NULL UNIQUE,
    country     VARCHAR(50),
    signup_date DATE         NOT NULL,
    tier        VARCHAR(20)  NOT NULL
);

INSERT INTO customers VALUES
    (1, 'Alice', 'Smith',  'alice@example.com',  'US', '2024-01-15', 'gold'),
    (2, 'Bob',   'Jones',  'bob@example.com',    'UK', '2024-03-22', 'silver'),
    (3, 'Carol', 'White',  'carol@example.com',  'DE', '2024-05-10', 'bronze');
