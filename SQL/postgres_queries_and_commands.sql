-- show running queries (pre 9.2)
SELECT procpid, age(clock_timestamp(), query_start), usename, current_query
FROM pg_stat_activity
WHERE current_query != '<IDLE>' AND current_query NOT ILIKE '%pg_stat_activity%'
ORDER BY query_start desc;

-- show running queries (9.2)
SELECT pid, age(clock_timestamp(), query_start), usename, query
FROM pg_stat_activity
WHERE query != '<IDLE>' AND query NOT ILIKE '%pg_stat_activity%'
ORDER BY query_start desc;

-- kill running query
SELECT pg_cancel_backend(procpid);

-- kill idle query
SELECT pg_terminate_backend(procpid);

-- vacuum command
VACUUM (VERBOSE, ANALYZE);

-- all database users
select * from pg_stat_activity where current_query not like '<%';

-- all databases and their sizes
select * from pg_user;

-- all tables and their size, with/without indexes
select datname, pg_size_pretty(pg_database_size(datname))
from pg_database
order by pg_database_size(datname) desc;

-- cache hit rates (should not be less than 0.99)
SELECT sum(heap_blks_read) as heap_read, sum(heap_blks_hit)  as heap_hit, (sum(heap_blks_hit) - sum(heap_blks_read)) / sum(heap_blks_hit) as ratio
FROM pg_statio_user_tables;

-- table index usage rates (should not be less than 0.99)
SELECT relname, 100 * idx_scan / (seq_scan + idx_scan) percent_of_times_index_used, n_live_tup rows_in_table
FROM pg_stat_user_tables
ORDER BY n_live_tup DESC;

-- how many indexes are in cache
SELECT sum(idx_blks_read) as idx_read, sum(idx_blks_hit)  as idx_hit, (sum(idx_blks_hit) - sum(idx_blks_read)) / sum(idx_blks_hit) as ratio
FROM pg_statio_user_indexes;

-- Dump database on remote host to file
$ pg_dump -U username -h hostname databasename > dump.sql

-- Import dump into existing database
$ psql -d newdb -f dump.sql


-- Check the size  (as in disk space) of all databases
SELECT d.datname AS Name, pg_catalog.pg_get_userbyid(d.datdba) AS Owner,
  CASE WHEN pg_catalog.has_database_privilege(d.datname, 'CONNECT')
    THEN pg_catalog.pg_size_pretty(pg_catalog.pg_database_size(d.datname))
    ELSE 'No Access'
  END AS SIZE
FROM pg_catalog.pg_database d
ORDER BY
  CASE WHEN pg_catalog.has_database_privilege(d.datname, 'CONNECT')
    THEN pg_catalog.pg_database_size(d.datname)
    ELSE NULL
  END;

-- Check the size (as in disk space) of each table
SELECT nspname || '.' || relname AS "relation",
   pg_size_pretty(pg_total_relation_size(C.oid)) AS "total_size"
 FROM pg_class C
 LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace)
 WHERE nspname NOT IN ('pg_catalog', 'information_schema')
   AND C.relkind <> 'i'
   AND nspname !~ '^pg_toast'
 ORDER BY pg_total_relation_size(C.oid) DESC;

-- See all locks
SELECT t.relname, l.locktype, page, virtualtransaction, pid, mode, granted
FROM pg_locks l, pg_stat_all_tables t
WHERE l.relation = t.relid ORDER BY relation asc;

-- Get all table sizes
SELECT
  schema_name,
  relname,
  pg_size_pretty(table_size) AS size,
  table_size

FROM (
       SELECT
         pg_catalog.pg_namespace.nspname           AS schema_name,
         relname,
         pg_relation_size(pg_catalog.pg_class.oid) AS table_size

       FROM pg_catalog.pg_class
         JOIN pg_catalog.pg_namespace ON relnamespace = pg_catalog.pg_namespace.oid
     ) t
WHERE schema_name NOT LIKE 'pg_%'
ORDER BY table_size DESC;

-- Get schema s sizes
FROM (
       SELECT
         pg_catalog.pg_namespace.nspname                AS schema_name,
         sum(pg_relation_size(pg_catalog.pg_class.oid)) AS schema_size
       FROM pg_catalog.pg_class
         JOIN pg_catalog.pg_namespace ON relnamespace = pg_catalog.pg_namespace.oid
       group by 1
     ) t
WHERE schema_name NOT LIKE 'pg_%'
ORDER BY schema_size DESC;

-- Show unused indexes
SELECT relname AS table_name, indexrelname AS index_name, idx_scan, idx_tup_read, idx_tup_fetch, pg_size_pretty(pg_relation_size(indexrelname::regclass))
FROM pg_stat_all_indexes
WHERE schemaname = 'public'
AND idx_scan = 0
AND idx_tup_read = 0
AND idx_tup_fetch = 0
ORDER BY pg_relation_size(indexrelname::regclass) DESC;

-- Kill all running connections of a current database
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE datname = current_database()
  AND pid <> pg_backend_pid();

-- Check cardinality of index
SELECT relname, relkind, reltuples as cardinality, relpages
FROM pg_class
WHERE relname LIKE 'tableprefix%';

-- Connection type and count
SELECT count(*),
       state
FROM pg_stat_activity
GROUP BY 2;