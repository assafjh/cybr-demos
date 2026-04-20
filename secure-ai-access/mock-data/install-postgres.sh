#!/bin/bash

sudo dnf update -y
sudo dnf install -y postgresql15-server postgresql15

sudo postgresql-setup --initdb

sed -i "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/" /var/lib/pgsql/data/postgresql.conf

cat >> /var/lib/pgsql/data/pg_hba.conf <<HBA
host    all    all    10.0.0.0/8    md5
host    all    all    172.16.0.0/12 md5
host    all    all    192.168.0.0/16 md5
host    all    all    0.0.0.0/0     md5
HBA

systemctl enable postgresql
systemctl start postgresql
