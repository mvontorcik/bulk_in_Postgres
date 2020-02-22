# bulk_in_Postgres
Something like Oracle's bulk operations in PostreSQL

I've 20+ years experience with Oracle database. Last year I started to work with PostgreSQL v10.5 database. I was assigned to the task to delete tens of millions records in database according to some criteria. I has been told that in Postgres we want avoid huge transactions. Recommended pattern is to create the query generating DELETE statements, execute the query by psql No.1, send generated DELETE statements via pipe to psql No.2 for execution. In this way we will have many small transactions. If query will create DO blocks with DELETE statement and additional UPDATE statement that the record was deleted, then in case of error during deleting, the delete can continue from point of interruption.
Oracle has BULK COLLECT clause and FORALL statement. I search through Postgres documentation for something similar but Postgres has no such feature. So I thinked how to combine Postgres features to create something like Oracle's bulk operations. I found one way how do it. It is described below.
In Postgres rows can be aggregated into arrays, arrays can be sent as input parameters, and arrays can be accessed like tables. It is enough to implement something like Oracle's bulk operations.

Illustrative example
Let's say we have table bulk_test.tab_items with id_item as PK, partitioned by date_item, and filled by some test data. 
We want to delete rows with matching id_item and date_item in table bulk_test.tab_items_to_delete. Table bulk_test.tab_items_to_delete has ca. 1/3 of rows from bulk_test.tab_items.
Instead of Oracle's BULK COLLECT clause we aggregate data into arrays in little tricky way:
    WITH d AS (
    -- gather data to be deleted
    SELECT id_item, date_item
      FROM bulk_test.tab_items_to_delete
     WHERE is_deleted = 0
    ),
    dr AS 
    (
    -- rank and order rows by partition key
    SELECT d.*, rank() OVER (ORDER BY d.date_item) AS r
      FROM d
    ORDER BY d.date_item
    )
    -- aggregate rows - pack them into arrays with max size limited to input parameter _max_array_size
    SELECT dr.r / _max_array_size AS r,
           array_to_string(array_agg(CAST(ROW(id_item, date_item) AS bulk_test.type_item)), ';') AS arr_text
      FROM dr
    GROUP BY dr.r / _max_array_size
    ORDER BY dr.r / _max_array_size;

Query above returns recordset consisting of rows with small arrays with data needed to identify rows to delete in bulk_test.tab_items.


Instead of Oracle's FORALL statement we access the array like a table:
    DELETE FROM bulk_test.tab_items
     WHERE (id_item, date_item) IN (SELECT id_item, date_item FROM unnest(_arr));

    UPDATE bulk_test.tab_items_to_delete
       SET is_deleted = 1
     WHERE id_item IN (SELECT id_item FROM unnest(_arr));

Performance comparision for DELETE
I created test_bulk schema in my Postgres database to test above mentioned ideas. Table tab_items is in file 01_data.sql. Table tab_items_to_delete and functions get_items_to_delete_bulk and delete_items_bulk are in file 02_to_delete.sql. Table tab_items is filled with ca. 15M records. Table tab_items_to_delete is filled with ca. 5M records. 
Bash file delete_bulk.sh runs bulk implementation with parameter MAX_ARRAY_SIZE. Bash file delete_solo.sh runs traditional approach - deleting by one record.
Table below lists execution times for bulk deleting variations and deleting by one record:
 command            |  execution time
delete_bulk.sh 1000 |      4 min 20 s
delete_bulk.sh 100  |     10 min 04 s
delete_bulk.sh 10   | 1 h 04 min 03 s
delete_solo.sh      | 8 h 57 min 10 s

As expected arrays with more items are significantly faster then arrays with fewer items. 
Bulk variations are significantly faster then deleting by one record.

Performance comparision for UPDATE
Again in test_bulk schema in my Postgres database. Table tab_items is in file 01_data.sql. Table tab_items_to_update and functions get_items_to_update_bulk and update_items_bulk are in file 03_to_update.sql. Table tab_items is filled with ca. 15M records. Table tab_items_to_update is filled with ca. 5M records. 
Bash file update_bulk.sh runs bulk implementation with parameter MAX_ARRAY_SIZE. Bash file update_solo.sh runs traditional approach - updating by one record.
Table below lists execution times for bulk updating variations and updating by one record.
 command            |  execution time
update_bulk.sh 1000 |      5 min 05 s
update_bulk.sh 100  |     10 min 56 s
update_bulk.sh 10   | 1 h 03 min 59 s
update_solo.sh      | 8 h 45 min 23 s

As expected arrays with more items are significantly faster then arrays with fewer items. 
Bulk variations are significantly faster then updating by one record.
