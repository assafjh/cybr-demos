CREATE TABLE customers (
    id            INTEGER PRIMARY KEY,
    first_name    VARCHAR(50)  NOT NULL,
    last_name     VARCHAR(50)  NOT NULL,
    email         VARCHAR(100) NOT NULL UNIQUE,
    country       VARCHAR(50),
    signup_date   DATE         NOT NULL,
    tier          VARCHAR(20)  NOT NULL
);

CREATE TABLE orders (
    id            INTEGER PRIMARY KEY,
    customer_id   INTEGER       NOT NULL REFERENCES customers(id),
    order_date    DATE          NOT NULL,
    amount_usd    DECIMAL(10,2) NOT NULL,
    status        VARCHAR(20)   NOT NULL,
    product_sku   VARCHAR(50)   NOT NULL
);

CREATE TABLE support_tickets (
    id            INTEGER PRIMARY KEY,
    customer_id   INTEGER     NOT NULL REFERENCES customers(id),
    opened_date   DATE        NOT NULL,
    severity      VARCHAR(20) NOT NULL,
    status        VARCHAR(20) NOT NULL,
    subject       TEXT        NOT NULL
);

CREATE INDEX idx_orders_customer          ON orders(customer_id);
CREATE INDEX idx_orders_date              ON orders(order_date);
CREATE INDEX idx_support_tickets_customer ON support_tickets(customer_id);
CREATE INDEX idx_support_tickets_severity ON support_tickets(severity);