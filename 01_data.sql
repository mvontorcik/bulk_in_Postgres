CREATE SCHEMA IF NOT EXISTS bulk_test AUTHORIZATION betsys;

DROP TABLE IF EXISTS bulk_test.tab_items CASCADE;

CREATE TABLE bulk_test.tab_items
(
  id_item bigint NOT NULL,
  date_item timestamp without time zone NOT NULL,
  data_value integer DEFAULT 0,
  other_data text
) PARTITION BY RANGE (date_item);

CREATE TABLE bulk_test.tab_items_y2019m01 PARTITION OF bulk_test.tab_items
    FOR VALUES FROM ('2019-01-01') TO ('2019-02-01');

CREATE TABLE bulk_test.tab_items_y2019m02 PARTITION OF bulk_test.tab_items
    FOR VALUES FROM ('2019-02-01') TO ('2019-03-01');

CREATE TABLE bulk_test.tab_items_y2019m03 PARTITION OF bulk_test.tab_items
    FOR VALUES FROM ('2019-03-01') TO ('2019-04-01');

CREATE TABLE bulk_test.tab_items_y2019m04 PARTITION OF bulk_test.tab_items
    FOR VALUES FROM ('2019-04-01') TO ('2019-05-01');

CREATE TABLE bulk_test.tab_items_y2019m05 PARTITION OF bulk_test.tab_items
    FOR VALUES FROM ('2019-05-01') TO ('2019-06-01');

CREATE TABLE bulk_test.tab_items_y2019m06 PARTITION OF bulk_test.tab_items
    FOR VALUES FROM ('2019-06-01') TO ('2019-07-01');

CREATE TABLE bulk_test.tab_items_y2019m07 PARTITION OF bulk_test.tab_items
    FOR VALUES FROM ('2019-07-01') TO ('2019-08-01');

CREATE TABLE bulk_test.tab_items_y2019m08 PARTITION OF bulk_test.tab_items
    FOR VALUES FROM ('2019-08-01') TO ('2019-09-01');

CREATE TABLE bulk_test.tab_items_y2019m09 PARTITION OF bulk_test.tab_items
    FOR VALUES FROM ('2019-09-01') TO ('2019-10-01');

CREATE TABLE bulk_test.tab_items_y2019m10 PARTITION OF bulk_test.tab_items
    FOR VALUES FROM ('2019-10-01') TO ('2019-11-01');

CREATE TABLE bulk_test.tab_items_y2019m11 PARTITION OF bulk_test.tab_items
    FOR VALUES FROM ('2019-11-01') TO ('2019-12-01');

CREATE TABLE bulk_test.tab_items_y2019m12 PARTITION OF bulk_test.tab_items
    FOR VALUES FROM ('2019-12-01') TO ('2020-01-01');


INSERT INTO bulk_test.tab_items(id_item, date_item, other_data)
SELECT row_number() OVER(), ts, to_char(ts, '"some text data: "DAY DD MONTH YYYY HH24:MI:SS.US TZ, "week number of ISO 8601:" IW, " Julian Day: " J')
  FROM generate_series('2019-01-01 00:00'::timestamp,  '2019-12-31 12:00'::timestamp, '2 seconds') ts;
-- 02:18 minutes execution time


CREATE INDEX ON bulk_test.tab_items_y2019m01 (date_item);
CREATE INDEX ON bulk_test.tab_items_y2019m02 (date_item);
CREATE INDEX ON bulk_test.tab_items_y2019m03 (date_item);
CREATE INDEX ON bulk_test.tab_items_y2019m04 (date_item);
CREATE INDEX ON bulk_test.tab_items_y2019m05 (date_item);
CREATE INDEX ON bulk_test.tab_items_y2019m06 (date_item);
CREATE INDEX ON bulk_test.tab_items_y2019m07 (date_item);
CREATE INDEX ON bulk_test.tab_items_y2019m08 (date_item);
CREATE INDEX ON bulk_test.tab_items_y2019m09 (date_item);
CREATE INDEX ON bulk_test.tab_items_y2019m10 (date_item);
CREATE INDEX ON bulk_test.tab_items_y2019m11 (date_item);
CREATE INDEX ON bulk_test.tab_items_y2019m12 (date_item);


CREATE UNIQUE INDEX ON bulk_test.tab_items_y2019m01 (id_item);
CREATE UNIQUE INDEX ON bulk_test.tab_items_y2019m02 (id_item);
CREATE UNIQUE INDEX ON bulk_test.tab_items_y2019m03 (id_item);
CREATE UNIQUE INDEX ON bulk_test.tab_items_y2019m04 (id_item);
CREATE UNIQUE INDEX ON bulk_test.tab_items_y2019m05 (id_item);
CREATE UNIQUE INDEX ON bulk_test.tab_items_y2019m06 (id_item);
CREATE UNIQUE INDEX ON bulk_test.tab_items_y2019m07 (id_item);
CREATE UNIQUE INDEX ON bulk_test.tab_items_y2019m08 (id_item);
CREATE UNIQUE INDEX ON bulk_test.tab_items_y2019m09 (id_item);
CREATE UNIQUE INDEX ON bulk_test.tab_items_y2019m10 (id_item);
CREATE UNIQUE INDEX ON bulk_test.tab_items_y2019m11 (id_item);
CREATE UNIQUE INDEX ON bulk_test.tab_items_y2019m12 (id_item);

-- VACUUM ANALYZE bulk_test.tab_items;

-- UPDATE bulk_test.tab_items_to_delete SET is_deleted = 0
-- VACUUM ANALYZE bulk_test.tab_items_to_delete;
