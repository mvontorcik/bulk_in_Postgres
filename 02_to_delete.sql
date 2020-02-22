DROP TABLE IF EXISTS bulk_test.tab_items_to_delete CASCADE;

CREATE TABLE bulk_test.tab_items_to_delete
(
  id_item bigint NOT NULL,
  date_item timestamp without time zone NOT NULL,
  is_deleted smallint DEFAULT 0,
  CONSTRAINT pk_tabitemstodelete_iditem PRIMARY KEY (id_item) 
);

SELECT setseed(0);

INSERT INTO bulk_test.tab_items_to_delete
SELECT id_item, date_item
  FROM bulk_test.tab_items
 WHERE random() < 0.333;

DROP TYPE IF EXISTS bulk_test.type_item_to_delete CASCADE;

CREATE TYPE bulk_test.type_item_to_delete AS (id_item bigint, date_item timestamp);

CREATE OR REPLACE FUNCTION bulk_test.get_items_to_delete_bulk(IN _max_array_size integer)
  RETURNS TABLE(r bigint, arr_text text) AS
$BODY$
DECLARE
BEGIN
    RETURN QUERY WITH d AS (
        SELECT id_item, date_item
          FROM bulk_test.tab_items_to_delete
         WHERE is_deleted = 0
        ),
        dr AS 
        (
        SELECT d.*, rank() OVER (ORDER BY d.date_item) AS r
          FROM d
        ORDER BY d.date_item
        )
        SELECT dr.r / _max_array_size AS r,
               array_to_string(array_agg(CAST(ROW(id_item, date_item) AS bulk_test.type_item_to_delete)), ';') AS arr_text
          FROM dr
        GROUP BY dr.r / _max_array_size
        ORDER BY dr.r / _max_array_size;

    RETURN;
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION bulk_test.delete_items_bulk(_arr_text text)
  RETURNS void AS
$BODY$
DECLARE
    _arr bulk_test.type_item_to_delete ARRAY;
BEGIN
    _arr = string_to_array(_arr_text, ';');
    
    DELETE FROM bulk_test.tab_items
     WHERE (id_item, date_item) IN (SELECT id_item, date_item FROM unnest(_arr));

    UPDATE bulk_test.tab_items_to_delete
       SET is_deleted = 1
     WHERE id_item IN (SELECT id_item FROM unnest(_arr));
    
    RETURN;
END
$BODY$
  LANGUAGE plpgsql VOLATILE SECURITY DEFINER;
  
--VACUUM ANALYZE bulk_test.tab_items_to_delete;
