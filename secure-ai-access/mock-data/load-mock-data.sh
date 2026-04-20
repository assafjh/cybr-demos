#!/bin/bash

sudo -u postgres psql -d demo -f customers.sql
sudo -u postgres psql -d demo -f orders.sql
sudo -u postgres psql -d demo -f support_tickets.sql

sudo -u postgres psql -d demo -c "SELECT COUNT(*) FROM customers;"   # 200
sudo -u postgres psql -d demo -c "SELECT COUNT(*) FROM orders;"      # 500
sudo -u postgres psql -d demo -c "SELECT COUNT(*) FROM support_tickets;"  # 100

sudo -u postgres psql -d demo -c "
SELECT c.tier, COUNT(o.id) AS orders, SUM(o.amount_usd) AS revenue
FROM customers c
JOIN orders o ON o.customer_id = c.id
GROUP BY c.tier;
"