#!/bin/bash

sudo -u postgres psql -c "CREATE DATABASE demo;"
sudo -u postgres psql -c "CREATE USER demouser WITH PASSWORD 'SomePass123@';"
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'SomePass123@';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE demo TO demouser;"
sudo -u postgres psql -d demo -c "GRANT ALL ON SCHEMA public TO demouser;"
sudo -u postgres psql -d demo -f create-tables.sql