delimiter //

DROP PROCEDURE IF EXISTS difcirc//
CREATE PROCEDURE difcirc(IN cat VARCHAR(50), IN ra FLOAT, IN de FLOAT, IN r FLOAT, IN extra_clause VARCHAR(512))
  DETERMINISTIC
  this_proc:BEGIN
    DECLARE l_sql VARCHAR(1024);
    DECLARE idname,idval,htmname VARCHAR(16);
    DECLARE db VARCHAR(64);
    DECLARE dbtemp, dbcat VARCHAR(128);
    SET db = database();
    SET dbtemp = 'DIF2.dif_temp';
    SET dbcat = CONCAT(db, '.', cat);
 select dbtemp,dbcat;
    SELECT param FROM DIF2.dif_temp limit 1 into idval;
    SET htmname = CONCAT('%htm%', idval, '%');
    SELECT column_name FROM information_schema.columns WHERE TABLE_SCHEMA=db and TABLE_NAME=cat and column_name like htmname limit 1 into idname;

 select idname;
--      SET l_sql = CONCAT('SELECT *, Sphedist(t1.ramas/3.6e6, t1.decmas/3.6e6,', ra, ',', de, ') as Sep FROM ', cat, ' AS t1 JOIN ', dbtemp, ' AS t2 ON ( (t1.', idname, '=t2.id) AND (t2.full=1 OR sphedist(t1.ramas/3.6e6, t1.decmas/3.6e6,', ra, ',', de, ') < ', r, ') )');
-- select l_sql;
--    SET @sql = l_sql;
-- select @sql;
--    PREPARE s1 FROM @sql;
--    EXECUTE s1;
--    DEALLOCATE PREPARE s1;

  END//

delimiter ;
