#!/bin/bash

DB_SRC_HOST_IP=localhost
DB_SRC_HOST_PORT=5432
DB_SRC_NAME=postgres
DB_SRC_USER=postgres


DB_DST_HOST_IP=localhost
DB_DST_HOST_PORT=5432
DB_DST_NAME=postgres
DB_DST_USER=postgres

MAX_ARRAY_SIZE=$1

now="$(date +'%m/%d/%Y %H:%M:%S')"
echo "Start updating by ${MAX_ARRAY_SIZE} records at $now"

psql -h ${DB_SRC_HOST_IP} -p ${DB_SRC_HOST_PORT} -U ${DB_SRC_USER} ${DB_SRC_NAME} --quiet \
-c "\copy (SELECT format('DO \$\$ \
BEGIN \
    PERFORM bulk_test.update_items_bulk(%L);  \
END \
\$\$;', \
t.arr_text) \
FROM bulk_test.get_items_to_update_bulk(${MAX_ARRAY_SIZE}) t ) TO STDOUT" \
| psql -h ${DB_DST_HOST_IP} -p ${DB_DST_HOST_PORT} -U ${DB_DST_USER} ${DB_DST_NAME} --quiet

now="$(date +'%m/%d/%Y %H:%M:%S')"
echo "End   updating by ${MAX_ARRAY_SIZE} records at $now"

