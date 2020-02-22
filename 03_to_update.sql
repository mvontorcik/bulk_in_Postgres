CREATE TABLE bulk_test.tab_items_to_update
(
  id_item bigint NOT NULL,
  date_item timestamp without time zone NOT NULL,
  new_value numeric NOT NULL,
  is_updated integer NOT NULL DEFAULT 0
);

SELECT setseed(0);

INSERT INTO bulk_test.tab_items_to_update(id_item, date_item, new_value)
SELECT id_item, date_item, random()
  FROM bulk_test.tab_items
 WHERE random() < 0.333;

CREATE UNIQUE INDEX ON bulk_test.tab_items_to_update(id_item);

DROP TYPE IF EXISTS bulk_test.type_item_to_update CASCADE;

CREATE TYPE bulk_test.type_item_to_update AS (id_item bigint, date_item timestamp, new_value numeric);

CREATE OR REPLACE FUNCTION bulk_test.get_items_to_update_bulk(IN _max_array_size integer)
  RETURNS TABLE(r bigint, arr_text text) AS
$BODY$
DECLARE
BEGIN
    RETURN QUERY WITH d AS (
        SELECT id_item, date_item, new_value
          FROM bulk_test.tab_items_to_update
         WHERE is_updated = 0
        ),
        dr AS 
        (
        SELECT d.*, rank() OVER (ORDER BY d.date_item) AS r
          FROM d
        ORDER BY d.date_item
        )
        SELECT dr.r / _max_array_size AS r,
               array_to_string(array_agg(CAST(ROW(id_item, date_item, new_value) AS bulk_test.type_item_to_update)), ';') AS arr_text
          FROM dr
        GROUP BY dr.r / _max_array_size
        ORDER BY dr.r / _max_array_size;

    RETURN;
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER;


CREATE OR REPLACE FUNCTION bulk_test.update_items_bulk(_arr_text text)
  RETURNS void AS
$BODY$
DECLARE
    _arr bulk_test.type_item_to_update ARRAY;
BEGIN
    _arr = string_to_array(_arr_text, ';');
    WITH t AS (
    SELECT CAST(n AS bulk_test.type_item_to_update) AS r
      FROM unnest(_arr) n
    ) 
    UPDATE bulk_test.tab_items o
       SET data_value = (r).new_value 
      FROM t
     WHERE o.id_item = (r).id_item
       AND o.date_item = (r).date_item;
    
    UPDATE bulk_test.tab_items_to_update u
       SET is_updated = 1
     WHERE u.id_item IN (SELECT n.id_item FROM unnest(_arr) n);
    
    RETURN;
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER;


-- VACUUM ANALYZE bulk_test.tab_items_to_update;

