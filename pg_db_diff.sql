CREATE SCHEMA IF NOT EXISTS _diag_;

DROP SEQUENCE IF EXISTS _diag_.info_id_seq;
CREATE SEQUENCE _diag_.info_id_seq;

drop table if exists _diag_.info; 
CREATE TABLE IF NOT EXISTS _diag_.info (
    id integer NOT NULL DEFAULT nextval('_diag_.info_id_seq'::regclass),
	last_count_date text not null,
    server_info text not null,
	usr text not null,
	hostname text
)

	
CREATE OR REPLACE FUNCTION _diag_.get_count(table_name text)
RETURNS integer
AS $$
DECLARE
  nrows integer;
BEGIN
  EXECUTE 'SELECT COUNT(*) FROM ' || table_name
  INTO nrows;

  RETURN nrows;
END $$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION _diag_.get_all_tb_count()
RETURNS table (tbname text, nrows integer)
AS $$ BEGIN return query 
	with tables  as (
		SELECT table_schema ||  '."'|| table_name || '"'  as tname	
		FROM information_schema.tables
		WHERE table_schema NOT IN ('pg_catalog', 'pg_temp', 'information_schema', '_diag_')  and table_type ilike '%table%' 
		ORDER by 1
	)	
	select tables.tname::text as tbname, _diag_.get_count(tname) as nrows from tables;
END $$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION _diag_.get_snap()
RETURNS text
AS $$ 
	DECLARE id integer; create_tb_count text;
	BEGIN
	drop table if exists temp_host;
	CREATE TEMP TABLE temp_host(name text);
	copy temp_host (name) from '/etc/hostname';
	insert into _diag_.info	(last_count_date, server_info, usr, hostname)
	values(	to_char(now(), 'YYYY-MM-DD HH24:MI'), (SELECT setting FROM pg_settings where name='server_version'), current_user, (select name from temp_host)
		) returning _diag_.info.id	 into id;	
		
	create_tb_count=format('set search_path=_diag_;create table "tb_count_%s" as select * from _diag_.get_all_tb_count();', id);	
	execute create_tb_count;
	
	RETURN 'Created snap #' || id::text;
END $$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION _diag_.snap_diff(_s1 integer, _s2 integer)
RETURNS table (tname text, n1 integer, n2 integer)
AS $$ 
	declare sname1 text; sname2 text; qry text ;
	BEGIN 	
		sname1=format('_diag_.tb_count_%s', _s1);
		sname2=format('_diag_.tb_count_%s', _s2);
		qry=format('select t1.tbname, t1.nrows, t2.nrows from %s t1 full outer join %s t2 on t1.tbname=t2.tbname where t1.nrows != t2.nrows;', sname1, sname2);

		return  query execute qry;
	END 
$$ LANGUAGE plpgsql;