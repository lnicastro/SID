USE SID;

delimiter //

DROP PROCEDURE IF EXISTS CreateRegion//
CREATE PROCEDURE CreateRegion(IN p CHAR(16), IN ord INTEGER)
  NOT DETERMINISTIC
  BEGIN
    DECLARE i, countp, countf INTEGER;

    SET countf = SIDCount(p, 1);
    SET countp = SIDCount(p, 0);

    IF (countf != 0 OR countp != 0) THEN
      DROP TABLE IF EXISTS SID.sid;
      CREATE TEMPORARY TABLE SID.sid (sid_param INT not null, sid_id BIGINT not null, sid_full TINYINT not null);
    END IF;

    SET i = 0;
    WHILE i < countf DO
      INSERT INTO SID.sid VALUES (ord, SIDGetID(p, i, 1), 1);
      SET i = i + 1;
    END WHILE;

    SET i = 0;
    WHILE i < countp DO
      INSERT INTO SID.sid VALUES (ord, SIDGetID(p, i, 0), 0);
      SET i = i + 1;
    END WHILE;

    SET p = SIDClear(p);
  END//


DROP PROCEDURE IF EXISTS CreateRect_HTM//
CREATE PROCEDURE CreateRect_HTM(IN ord INTEGER, IN ra FLOAT, IN de FLOAT, IN side_ra FLOAT, IN side_de FLOAT)
  NOT DETERMINISTIC
  BEGIN
    DECLARE p CHAR(16);
    SET p = SIDRectHTM(ord, ra, de, side_ra, side_de);
    CALL SID.CreateRegion(p, ord);  
  END//


DROP PROCEDURE IF EXISTS CreateRectv_HTM//
CREATE PROCEDURE CreateRectv_HTM(IN ord INTEGER, IN ra1 FLOAT, IN de1 FLOAT, IN ra2 FLOAT, IN de2 FLOAT)
  NOT DETERMINISTIC
  BEGIN
    DECLARE p CHAR(16);
    SET p = SIDRectvHTM(ord, ra1, de1, ra2, de2);
    CALL SID.CreateRegion(p, ord);  
  END//


DROP PROCEDURE IF EXISTS CreateCircle_HTM//
CREATE PROCEDURE CreateCircle_HTM(IN ord INTEGER, IN ra FLOAT, IN de FLOAT, IN rad FLOAT)
  NOT DETERMINISTIC
  BEGIN
    DECLARE p CHAR(16);
    SET p = SIDCircleHTM(ord, ra, de, rad);
    CALL SID.CreateRegion(p, ord);  
  END//


DROP PROCEDURE IF EXISTS CreateRect_HEALP//
CREATE PROCEDURE CreateRect_HEALP(IN ord INTEGER, IN ra FLOAT, IN de FLOAT, IN side_ra FLOAT, IN side_de FLOAT)
  NOT DETERMINISTIC
  BEGIN
    DECLARE p CHAR(16);
    SET p = SIDRectHEALP(1, ord, ra, de, side_ra, side_de);
    CALL SID.CreateRegion(p, ord);  
  END//


DROP PROCEDURE IF EXISTS CreateRectv_HEALP//
CREATE PROCEDURE CreateRectv_HEALP(IN ord INTEGER, IN ra1 FLOAT, IN de1 FLOAT, IN ra2 FLOAT, IN de2 FLOAT)
  NOT DETERMINISTIC
  BEGIN
    DECLARE p CHAR(16);
    SET p = SIDRectvHEALP(1, ord, ra1, de1, ra2, de2);
    CALL SID.CreateRegion(p, ord);  
  END//


DROP PROCEDURE IF EXISTS CreateCircle_HEALP//
CREATE PROCEDURE CreateCircle_HEALP(IN ord INTEGER, IN ra FLOAT, IN de FLOAT, IN rad FLOAT)
  NOT DETERMINISTIC
  BEGIN
    DECLARE p CHAR(16);
    SET p = SIDCircleHEALP(1, ord, ra, de, rad);
    CALL SID.CreateRegion(p, ord);
  END//

DROP PROCEDURE IF EXISTS RunSelect//
CREATE PROCEDURE RunSelect(IN destTable VARCHAR(64),
                           IN fieldList VARCHAR(1024), IN mainTable VARCHAR(64),
                           IN Region VARCHAR(50), IN Library VARCHAR(50), IN indexField VARCHAR(50), IN indexDepth INTEGER,
                           IN raField VARCHAR(50), IN deField VARCHAR(50),
                           IN ra FLOAT, IN de FLOAT, IN r1 FLOAT, IN r2 FLOAT, IN extra_clause VARCHAR(1024))
  DETERMINISTIC
  BEGIN
    DECLARE sqlStatement VARCHAR(1024);
    DECLARE dbTable VARCHAR(96) DEFAULT '';

    IF (Region != 'Circle'  AND  
        Region != 'Rectv'   AND
        Region != 'Rect') THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Unrecognized region';
    END IF;

    IF (Library != 'HTM'  AND  
        Library != 'HEALP') THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Unrecognized library';
    END IF;

   IF ( LOCATE('.', mainTable, 1) ) THEN
     SET dbTable = mainTable;
   ELSE
     SET dbTable = CONCAT(database(), '.', mainTable);
   END IF;

    IF (Region = 'Circle') THEN
      SET sqlStatement = CONCAT('CALL SID.Create', Region, '_', Library, '(', indexDepth, ', ', ra, ', ', de, ', ', r1, ');');
    ELSE
      IF (Region = 'Rect' OR Region = 'Rectv') THEN
        SET sqlStatement = CONCAT('CALL SID.Create', Region, '_', Library, '(', indexDepth, ', ', ra, ', ', de, ', ', r1, ', ', r2, ');');
      END IF;
    END IF;
    SELECT sqlStatement;
    SET @sql = sqlStatement;
    PREPARE s1 FROM @sql;
    EXECUTE s1;
    DEALLOCATE PREPARE s1;

    SET sqlStatement = '';
    IF (destTable != '') THEN
       SET sqlStatement = CONCAT('DROP TABLE IF EXISTS ', destTable);
       SET @sql = sqlStatement;
       PREPARE s1 FROM @sql;
       EXECUTE s1;
       DEALLOCATE PREPARE s1;
       SET sqlStatement = CONCAT('CREATE TEMPORARY TABLE ', destTable, ' ');
    END IF;
    
	SET sqlStatement = CONCAT(sqlStatement, 'SELECT ', fieldList, ' FROM ', dbTable,
                       ' AS t1 JOIN SID.sid AS t2 ON ( (t1.', indexField, '=t2.sid_id)');
    IF (Region = 'Circle'  AND  r1 > 0) THEN
 	  SET sqlStatement = CONCAT(sqlStatement, ' AND (t2.sid_full=1 OR Sphedist(', raField, ', ', deField, ', ', ra, ', ', de, ') <= ', r1, ') )');
    ELSE
 	  SET sqlStatement = CONCAT(sqlStatement, ')');
    END IF;
    IF (extra_clause != '') THEN
      SET sqlStatement = CONCAT(sqlStatement, ' ', extra_clause);
    END IF;
    SET sqlStatement = CONCAT(sqlStatement, ';');

    SELECT sqlStatement;
    SET @sql = sqlStatement;
    PREPARE s1 FROM @sql;
    EXECUTE s1;
    DEALLOCATE PREPARE s1;
  END//


DROP PROCEDURE IF EXISTS SelectCircleHTM//
CREATE PROCEDURE SelectCircleHTM(IN dest VARCHAR(64), IN fieldList VARCHAR(1024), IN mainTable VARCHAR(64),
                                 IN indexField VARCHAR(50), IN indexDepth INTEGER,
                                 IN raField VARCHAR(50), IN deField VARCHAR(50),
                                 IN ra FLOAT, IN de FLOAT, IN radius FLOAT, IN extra_clause VARCHAR(1024))
  DETERMINISTIC
  BEGIN
    CALL SID.RunSelect(dest, fieldList, mainTable, 'Circle', 'HTM', indexField, indexDepth, raField, deField, ra, de, radius, 0, extra_clause);
  END//

DROP PROCEDURE IF EXISTS SelectRectHTM//
CREATE PROCEDURE SelectRectHTM(IN dest VARCHAR(64), IN fieldList VARCHAR(1024), IN mainTable VARCHAR(64),
                               IN indexField VARCHAR(50), IN indexDepth INTEGER,
                               IN raField VARCHAR(50), IN deField VARCHAR(50),
                               IN ra FLOAT, IN de FLOAT, IN r1 FLOAT, IN r2 FLOAT, IN extra_clause VARCHAR(1024))
  DETERMINISTIC
  BEGIN
    CALL SID.RunSelect(dest, fieldList, mainTable, 'Rect', 'HTM', indexField, indexDepth, raField, deField, ra, de, r1, r2, extra_clause);
  END//

DROP PROCEDURE IF EXISTS SelectRectvHTM//
CREATE PROCEDURE SelectRectvHTM(IN dest VARCHAR(64), IN fieldList VARCHAR(1024), IN mainTable VARCHAR(64),
                               IN indexField VARCHAR(50), IN indexDepth INTEGER,
                               IN raField VARCHAR(50), IN deField VARCHAR(50),
                               IN ra1 FLOAT, IN de1 FLOAT, IN ra2 FLOAT, IN de2 FLOAT, IN extra_clause VARCHAR(1024))
  DETERMINISTIC
  BEGIN
    CALL SID.RunSelect(dest, fieldList, mainTable, 'Rectv', 'HTM', indexField, indexDepth, raField, deField, ra1, de1, ra2, de2, extra_clause);
  END//

DROP PROCEDURE IF EXISTS SelectCircleHEALP//
CREATE PROCEDURE SelectCircleHEALP(IN dest VARCHAR(64), IN fieldList VARCHAR(1024), IN mainTable VARCHAR(64),
                                   IN indexField VARCHAR(50), IN indexDepth INTEGER,
                                   IN raField VARCHAR(50), IN deField VARCHAR(50),
                                   IN ra FLOAT, IN de FLOAT, IN radius FLOAT, IN extra_clause VARCHAR(1024))
  DETERMINISTIC
  BEGIN
    CALL SID.RunSelect(dest, fieldList, mainTable, 'Circle', 'HEALP', indexField, indexDepth, raField, deField, ra, de, radius, 0, extra_clause);
  END//

DROP PROCEDURE IF EXISTS SelectRectHEALP//
CREATE PROCEDURE SelectRectHEALP(IN dest VARCHAR(64), IN fieldList VARCHAR(1024), IN mainTable VARCHAR(64),
                                 IN indexField VARCHAR(50), IN indexDepth INTEGER,
                                 IN raField VARCHAR(50), IN deField VARCHAR(50),
                                 IN ra FLOAT, IN de FLOAT, IN r1 FLOAT, IN r2 FLOAT, IN extra_clause VARCHAR(1024))
  DETERMINISTIC
  BEGIN
    CALL SID.RunSelect(dest, fieldList, mainTable, 'Rect', 'HEALP', indexField, indexDepth, raField, deField, ra, de, r1, r2, extra_clause);
  END//

DROP PROCEDURE IF EXISTS SelectRectvHEALP//
CREATE PROCEDURE SelectRectvHEALP(IN dest VARCHAR(64), IN fieldList VARCHAR(1024), IN mainTable VARCHAR(64),
                                 IN indexField VARCHAR(50), IN indexDepth INTEGER,
                                 IN raField VARCHAR(50), IN deField VARCHAR(50),
                                 IN ra1 FLOAT, IN de1 FLOAT, IN ra2 FLOAT, IN de2 FLOAT, IN extra_clause VARCHAR(1024))
  DETERMINISTIC
  BEGIN
    CALL SID.RunSelect(dest, fieldList, mainTable, 'Rectv', 'HEALP', indexField, indexDepth, raField, deField, ra1, de1, ra2, de2, extra_clause);
  END//

delimiter ;


-- CALL CreateCircle_HTM(6, 10, 20, 100);   SELECT * FROM SID.sid;
-- CALL CreateCircle_HEALP(10, 10, 20, 10); SELECT * FROM SID.sid;

-- Use the ASCC 2.5 catalogue
--
-- ALTER TABLE ascc25_initial DROP COLUMN hpxid;
-- ALTER TABLE ascc25_initial ADD COLUMN htm6 INT UNSIGNED NOT NULL, ADD KEY (htm6);
-- UPDATE ascc25_initial SET htm6 = HTMLookup(6, RAmas/3.6e6, DECmas/3.6e6);
-- ALTER TABLE ascc25_initial ADD COLUMN healp10 INT UNSIGNED NOT NULL, ADD KEY (healp10);
-- UPDATE ascc25_initial SET healp10 = HEALPLookup(1, 10, RAmas/3.6e6, DECmas/3.6e6);

-- CALL SID.SelectCircleHTM  ('', '*', 'Catalogs.ascc25_initial', 'htm6'   ,  6, 'RAmas/3.6e6', 'DECmas/3.6e6', 188, -3, 10, 'LIMIT 10');
-- CALL SID.SelectCircleHEALP('', '*', 'Catalogs.ascc25_initial', 'healp10', 10, 'RAmas/3.6e6', 'DECmas/3.6e6', 188, -3, 10, 'LIMIT 10');


-- Use the Tycho-2 catalogue
--
-- CALL SID.SelectCircleHTM  ('', '*', 'Catalogs.tycho2', 'htmID_6',  6, 'RAmas/3.6e6', 'DECmas/3.6e6', 188, -3, 10, 'LIMIT 10');
-- CALL SID.SelectCircleHTM  ('myregion', 'RAmas', 'Catalogs.tycho2', 'htmID_6',  6, 'RAmas/3.6e6', 'DECmas/3.6e6', 188, -3, 10, 'LIMIT 10');
