#!/bin/sh
psql "postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}" --command="select * from ${TABLE_NAME};"