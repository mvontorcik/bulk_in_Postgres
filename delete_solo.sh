#!/bin/bash

DB_SRC_HOST_IP=localhost
DB_SRC_HOST_PORT=5432
DB_SRC_NAME=postgres
DB_SRC_USER=postgres

DB_DST_HOST_IP=localhost
DB_DST_HOST_PORT=5432
DB_DST_NAME=postgres
DB_DST_USER=postgres

now="$(date +'%m/%d/%Y %H:%M:%S')"
echo "Start deleting by 1 record at $now"

psql -h ${DB_SRC_HOST_IP} -p ${DB_SRC_HOST_PORT} -U ${DB_SRC_USER} ${DB_SRC_NAME} --quiet \
-c "\copy (SELECT format('DELETE FROM bulk_test.tab_items WHERE id_item = %s AND date_item = %L;', \
t.id_item, t.date_item) \
FROM bulk_test.tab_items_to_delete t ) TO STDOUT" \
| psql -h ${DB_DST_HOST_IP} -p ${DB_DST_HOST_PORT} -U ${DB_DST_USER} ${DB_DST_NAME} --quiet

now="$(date +'%m/%d/%Y %H:%M:%S')"
echo "End   deleting by 1 record at $now"

