-- SQL Demo procedure for dif2
--
-- Rectangular query example usage (center + sides) assuming HTM pix., RA and Dec stored in mas (column names = RAmas, DECmas)
-- Note: objects in fully covered pixels are always returned no matter what are the sides requested.
--
-- Example: 
--   call DIF2.difcircpixelsHTM(6, 100.8, -20.5, 20);
--   call difrect('TYCHO2', 100.8, -20.5, 40, 40);
--   call difrect('TYCHO2', 100.8, -20.5, 40, 40, 'ORDER BY VTmm');
--   call difrect('UCAC', 100.8, -20.5, 40, 30, 'LIMIT 10');
--
-- Last changed: 01/07/2017

delimiter //

DROP PROCEDURE IF EXISTS difrect//
CREATE PROCEDURE difrect(IN cat VARCHAR(50), IN ra FLOAT, IN de FLOAT, IN side_ra FLOAT, IN side_de FLOAT, IN extra_clause VARCHAR(512))
  DETERMINISTIC
  this_proc:BEGIN
    DECLARE l_sql VARCHAR(1024);
    DECLARE ra1, ra2, de1, de2 FLOAT;
    DECLARE idname,idval,htmname VARCHAR(16);

    SELECT param FROM dif_temp limit 1 into idval;
    SET htmname = CONCAT('%htm%', idval, '%');
    SELECT column_name FROM information_schema.columns WHERE TABLE_NAME=cat and column_name like htmname limit 1 into idname;

    IF (side_ra < 0 OR side_de < 0) THEN
      LEAVE this_proc;
    END IF;

    SET ra1 = ra - side_ra/120;
    SET ra2 = ra + side_ra/120;
    SET de1 = de - side_de/120;
    SET de2 = de + side_de/120;

    IF (side_ra = 0 AND side_de = 0) THEN
      SET l_sql = CONCAT('SELECT *, Sphedist(t1.ramas/3.6e6, t1.decmas/3.6e6,', ra, ',', de, ') as Sep FROM ', cat,
                         ' AS t1 JOIN dif_temp AS t2 ON ( t1.', idname, '=t2.id )');
    ELSEIF (side_ra > 0 AND side_de = 0) THEN
      SET l_sql = CONCAT('SELECT *, Sphedist(t1.ramas/3.6e6, t1.decmas/3.6e6,', ra, ',', de, ') as Sep FROM ', cat,
                         ' AS t1 JOIN dif_temp AS t2 ON ( (t1.', idname, '=t2.id) AND (t2.full=1 OR (t1.ramas/3.6e6 >= ', ra1,
                         ' AND t1.ramas/3.6e6 <= ', ra2, ') ) )');
    ELSEIF (side_ra = 0 AND side_de > 0) THEN
      SET l_sql = CONCAT('SELECT *, Sphedist(t1.ramas/3.6e6, t1.decmas/3.6e6,', ra, ',', de, ') as Sep FROM ', cat,
                         ' AS t1 JOIN dif_temp AS t2 ON ( (t1.', idname, '=t2.id) AND (t2.full=1 OR (t1.decmas/3.6e6 >= ', de1,
                         ' AND t1.decmas/3.6e6 <= ', de2, ') ) )');

    ELSE

      SET l_sql = CONCAT('SELECT *, Sphedist(t1.ramas/3.6e6, t1.decmas/3.6e6,', ra, ',', de, ') as Sep FROM ', cat,
                         ' AS t1 JOIN dif_temp AS t2 ON ( (t1.', idname, '=t2.id) AND (t2.full=1 OR (t1.ramas/3.6e6 >= ', ra1,
                         ' AND t1.ramas/3.6e6 <= ', ra2, ') AND (t1.decmas/3.6e6 >= ', de1, ' AND t1.decmas/3.6e6 <= ', de2, ') ) )');
   END IF;

-- select l_sql;

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
