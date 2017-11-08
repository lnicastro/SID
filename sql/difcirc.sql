-- SQL Demo procedure for dif2
--
-- Circle query example usage assuming HTM pix., RA and Dec stored in mas (column names = RAmas, DECmas)
-- Note: objects in fully covered pixels are always returned no matter what't the radius requested.
--
-- Example: 
--   call DIF2.difcircpixelsHTM(6, 100.8, -20.5, 20);
--   call difcirc('TYCHO2', 100.8, -20.5, 20);
--   call difcirc('TYCHO2', 100.8, -20.5, 20, 'ORDER BY VTmm');
--   call difcirc('UCAC', 100.8, -20.5, 20, 'LIMIT 10');
--
-- Last changed: 01/07/2017

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
    SET dbcat = CONCAT(db, '.', cat);

    IF (r < 0) THEN
      LEAVE this_proc;
    END IF;

    SELECT param FROM dif_temp limit 1 into idval;
    SET htmname = CONCAT('%htm%', idval, '%');
    SELECT column_name FROM information_schema.columns WHERE TABLE_SCHEMA=db AND TABLE_NAME=cat and column_name like htmname limit 1 into idname;

    IF (r = 0) THEN
      SET l_sql = CONCAT('SELECT *, Sphedist(t1.ramas/3.6e6, t1.decmas/3.6e6,', ra, ',', de, ') as Sep FROM ', dbcat,
                         ' AS t1 JOIN dif_temp AS t2 ON ( t1.', idname, '=t2.id )');
    ELSE
      SET l_sql = CONCAT('SELECT *, Sphedist(t1.ramas/3.6e6, t1.decmas/3.6e6,', ra, ',', de, ') as Sep FROM ', dbcat,
                         ' AS t1 JOIN dif_temp AS t2 ON ( (t1.', idname, '=t2.id) AND (t2.full=1 OR sphedist(t1.ramas/3.6e6, t1.decmas/3.6e6,',
                       ra, ',', de, ') < ', r, ') )');
    END IF;

 select l_sql;

    IF (extra_clause != '') THEN
      SET l_sql = CONCAT(l_sql,' ',extra_clause);
    END IF;
    SET @sql = l_sql;

-- select @sql;
    PREPARE s1 FROM @sql;
    EXECUTE s1;
    DEALLOCATE PREPARE s1;

  END//

delimiter ;
