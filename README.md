# pg_migration
*script to check difference in tables rows count between a DB and its copy* 

the pg_db_diff.sql script creates a schema _diag_ and some fucntions to support the verify phase of DB migration.

The step are:

1. execute pg_db_diff.sql on source server;
2. on same server, just before execute backup run: select * from  _diag_.get_snap() and get result: this is id1;
3. execute backup and restore on destination server;
4. run: select * from  _diag_.get_snap() on destination server and get result: this is id2;
5. run: select * from  _diag_.snap_diff(id1, id2)

the last function called returns any differences in the number of rows between the tables of the source DB and destination DB.

More exstensive desription on:

https://medium.com/@dante.vitale/postgresql-database-in-cloud-migration-part-1-2-c69381c8a949



