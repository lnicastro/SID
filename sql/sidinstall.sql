-- Create functions
DROP FUNCTION IF EXISTS HTMLookup;
DROP FUNCTION IF EXISTS HTMidByName;
DROP FUNCTION IF EXISTS HTMnameById;
DROP FUNCTION IF EXISTS HTMBary;
DROP FUNCTION IF EXISTS HTMBaryC;
DROP FUNCTION IF EXISTS HTMNeighb;
DROP FUNCTION IF EXISTS HTMsNeighb;
DROP FUNCTION IF EXISTS HTMNeighbC;
DROP FUNCTION IF EXISTS HTMBaryDist;

DROP FUNCTION IF EXISTS HEALPLookup;
DROP FUNCTION IF EXISTS HEALPMaxS;
DROP FUNCTION IF EXISTS HEALPBaryDist;
DROP FUNCTION IF EXISTS HEALPBary;
DROP FUNCTION IF EXISTS HEALPBaryC;
DROP FUNCTION IF EXISTS HEALPNeighb;
DROP FUNCTION IF EXISTS HEALPNeighbC;
DROP FUNCTION IF EXISTS HEALPBound;
DROP FUNCTION IF EXISTS HEALPBoundC;

DROP FUNCTION IF EXISTS SIDCount;
DROP FUNCTION IF EXISTS SIDGetID;
DROP FUNCTION IF EXISTS SIDClear;
DROP FUNCTION IF EXISTS SIDCircleHTM;
DROP FUNCTION IF EXISTS SIDRectHTM;
DROP FUNCTION IF EXISTS SIDRectvHTM;
DROP FUNCTION IF EXISTS SIDCircleHEALP;
DROP FUNCTION IF EXISTS SIDRectHEALP;
DROP FUNCTION IF EXISTS SIDRectvHEALP;

DROP FUNCTION IF EXISTS Sphedist;

CREATE FUNCTION HTMLookup returns INT soname 'libudf_sid.so';
CREATE FUNCTION HTMidByName returns INT soname 'libudf_sid.so';
CREATE FUNCTION HTMnameById returns STRING soname 'libudf_sid.so';
CREATE FUNCTION HTMBary returns STRING soname 'libudf_sid.so';
CREATE FUNCTION HTMBaryC returns STRING soname 'libudf_sid.so';
CREATE FUNCTION HTMNeighb returns STRING soname 'libudf_sid.so';
CREATE FUNCTION HTMsNeighb returns STRING soname 'libudf_sid.so';
CREATE FUNCTION HTMNeighbC returns STRING soname 'libudf_sid.so';
CREATE FUNCTION HTMBaryDist returns REAL soname 'libudf_sid.so';

CREATE FUNCTION HEALPLookup returns INT soname 'libudf_sid.so';
CREATE FUNCTION HEALPMaxS returns REAL soname 'libudf_sid.so';
CREATE FUNCTION HEALPBaryDist returns REAL soname 'libudf_sid.so';
CREATE FUNCTION HEALPBary returns STRING soname 'libudf_sid.so';
CREATE FUNCTION HEALPBaryC returns STRING soname 'libudf_sid.so';
CREATE FUNCTION HEALPNeighb returns STRING soname 'libudf_sid.so';
CREATE FUNCTION HEALPNeighbC returns STRING soname 'libudf_sid.so';
CREATE FUNCTION HEALPBound returns STRING soname 'libudf_sid.so';
CREATE FUNCTION HEALPBoundC returns STRING soname 'libudf_sid.so';

CREATE FUNCTION SIDCount returns INT soname 'libudf_sid.so';
CREATE FUNCTION SIDGetID returns INT soname 'libudf_sid.so';
CREATE FUNCTION SIDClear returns INT soname 'libudf_sid.so';
CREATE FUNCTION SIDCircleHTM returns STRING soname 'libudf_sid.so';
CREATE FUNCTION SIDRectHTM returns STRING soname 'libudf_sid.so';
CREATE FUNCTION SIDRectvHTM returns STRING soname 'libudf_sid.so';
CREATE FUNCTION SIDCircleHEALP returns STRING soname 'libudf_sid.so';
CREATE FUNCTION SIDRectHEALP returns STRING soname 'libudf_sid.so';
CREATE FUNCTION SIDRectvHEALP returns STRING soname 'libudf_sid.so';

CREATE FUNCTION Sphedist returns REAL soname 'libudf_sid.so';


-- Create database and tables
DROP DATABASE IF EXISTS SID;
CREATE DATABASE SID;
USE SID;

CREATE TABLE SID.tables_htm (
  dbtable      VARCHAR(500) NOT NULL,
  RAd_field    VARCHAR(500) NOT NULL,
  DEd_field    VARCHAR(500) NOT NULL,
  iorder       INT NOT NULL,
  pixid_field  VARCHAR(500) NOT NULL);
CREATE INDEX dbtable ON SID.tables_htm (dbtable);

CREATE TABLE SID.tables_healp (
  dbtable      VARCHAR(500) NOT NULL,
  RAd_field    VARCHAR(500) NOT NULL,
  DEd_field    VARCHAR(500) NOT NULL,
  iorder       INT NOT NULL,
  pixid_field  VARCHAR(500) NOT NULL);
CREATE INDEX dbtable ON SID.tables_healp (dbtable);


-- Create stored procedures
delimiter //

DROP FUNCTION IF EXISTS ensureDB//
CREATE FUNCTION ensureDB(IN s VARCHAR(500))
  RETURNS LONGTEXT
  NOT DETERMINISTIC
  BEGIN
  IF LOCATE('.', s) = 0 THEN
    SET s = CONCAT(DATABASE(), '.', s);
  END IF;
  RETURN s;
  END//


DROP PROCEDURE IF EXISTS AddHEALPIndex//
CREATE PROCEDURE AddHEALPIndex(IN dbtable VARCHAR(500), IN RAd_field VARCHAR(500), IN DEd_field VARCHAR(500), IN iorder INT)
  NOT DETERMINISTIC
  BEGIN
     DECLARE ss VARCHAR(1024);
     SET dbtable = ensureDB(dbtable);
     IF LOCATE('.', RAd_field) = 0 THEN
         SET RAd_field = CONCAT(dbtable, '.', RAd_field);
     END IF;
     IF LOCATE('.', DEd_field) = 0 THEN
         SET DEd_field = CONCAT(dbtable, '.', DEd_field);
     END IF;
     SET ss = CONCAT('ALTER TABLE ', dbtable, ' ADD COLUMN healp', iorder, ' BIGINT NOT NULL');
     PREPARE stmt FROM ss; EXECUTE stmt; DEALLOCATE PREPARE stmt;
     SET ss = CONCAT('UPDATE ', dbtable, ' SET healp', iorder, ' = HEALPLookup(1, ', iorder, ', ', RAd_field, ', ', DEd_field, ')'); -- 1 means NESTED
     PREPARE stmt FROM ss; EXECUTE stmt; DEALLOCATE PREPARE stmt;
     SET ss = CONCAT('CREATE INDEX healp', iorder, ' ON ', dbtable, ' (healp', iorder, ')');
     PREPARE stmt FROM ss; EXECUTE stmt; DEALLOCATE PREPARE stmt;
     SET ss = CONCAT('INSERT INTO SID.tables_healp VALUES ("', dbtable, '", "', RAd_field, '", "', DEd_field, '", ', iorder, ', "healp', iorder, '")');
     PREPARE stmt FROM ss; EXECUTE stmt; DEALLOCATE PREPARE stmt;
  END//


DROP PROCEDURE IF EXISTS AddHTMIndex//
CREATE PROCEDURE AddHTMIndex(IN dbtable VARCHAR(500), IN RAd_field VARCHAR(500), IN DEd_field VARCHAR(500), IN iorder INT)
  NOT DETERMINISTIC
  BEGIN
     DECLARE ss VARCHAR(1024);
     SET dbtable = ensureDB(dbtable);
     IF LOCATE('.', RAd_field) = 0 THEN
        SET RAd_field = CONCAT(dbtable, '.', RAd_field);
     END IF;
     IF LOCATE('.', DEd_field) = 0 THEN
        SET DEd_field = CONCAT(dbtable, '.', DEd_field);
     END IF;
     SET ss = CONCAT('ALTER TABLE ', dbtable, ' ADD COLUMN htm', iorder, ' BIGINT NOT NULL');
     PREPARE stmt FROM ss; EXECUTE stmt; DEALLOCATE PREPARE stmt;
     SET ss = CONCAT('UPDATE ', dbtable, ' SET htm', iorder, ' = HTMLookup(', iorder, ', ', RAd_field, ', ', DEd_field, ')');
     PREPARE stmt FROM ss; EXECUTE stmt; DEALLOCATE PREPARE stmt;
     SET ss = CONCAT('CREATE INDEX htm', iorder, ' ON ', dbtable, ' (htm', iorder, ')');
     PREPARE stmt FROM ss; EXECUTE stmt; DEALLOCATE PREPARE stmt;
     SET ss = CONCAT('INSERT INTO SID.tables_htm VALUES ("', dbtable, '", "', RAd_field, '", "', DEd_field, '", ', iorder, ', "htm', iorder, '")');
     PREPARE stmt FROM ss; EXECUTE stmt; DEALLOCATE PREPARE stmt;
  END//


DROP PROCEDURE IF EXISTS InitRegion//
CREATE PROCEDURE InitRegion(IN pdbtable VARCHAR(500), IN plibrary VARCHAR(20) DEFAULT 'HEALP', IN piorder INT DEFAULT NULL)
  NOT DETERMINISTIC
  BEGIN
  IF plibrary NOT IN ('HTM', 'HEALP') THEN
    SIGNAL SQLSTATE 'HY000' SET MESSAGE_TEXT = 'Supported libraries are "HTM" and "HEALP"';
  END IF;

  DROP TABLE IF EXISTS SID.sid_full;
  CREATE TEMPORARY TABLE SID.sid_full (SID_region BIGINT, SID_pixid BIGINT NOT NULL);
  DROP TABLE IF EXISTS SID.sid_cone;
  CREATE TEMPORARY TABLE SID.sid_cone (SID_region BIGINT, SID_pixid BIGINT NOT NULL, RAd DOUBLE NOT NULL, DEd DOUBLE NOT NULL, radius DOUBLE NOT NULL);
  DROP TABLE IF EXISTS SID.sid_rect;
  CREATE TEMPORARY TABLE SID.sid_rect (SID_region BIGINT, SID_pixid BIGINT NOT NULL, RAd1 DOUBLE NOT NULL, DEd1 DOUBLE NOT NULL, RAd2 DOUBLE NOT NULL, DEd2 DOUBLE NOT NULL);

  SET pdbtable = ensureDB(pdbtable);
  SET @SID_library     = plibrary;
  SET @SID_dbtable     = pdbtable;
  SET @SID_RAd_field   = NULL;
  SET @SID_DEd_field   = NULL;
  SET @SID_iorder      = piorder;
  SET @SID_pixid_field = NULL;

  IF piorder IS NULL THEN
    IF plibrary = 'HTM' THEN
        SELECT dbtable, RAd_field, DEd_field, iorder, pixid_field INTO @SID_dbtable, @SID_RAd_field, @SID_DEd_field, @SID_iorder, @SID_pixid_field FROM SID.tables_htm WHERE dbtable = @SID_dbtable ORDER BY iorder DESC LIMIT 1;
    ELSE
        SELECT dbtable, RAd_field, DEd_field, iorder, pixid_field INTO @SID_dbtable, @SID_RAd_field, @SID_DEd_field, @SID_iorder, @SID_pixid_field FROM SID.tables_healp WHERE dbtable = @SID_dbtable ORDER BY iorder DESC LIMIT 1;
    END IF;
  ELSE
    IF plibrary = 'HTM' THEN
        SELECT dbtable, RAd_field, DEd_field, pixid_field INTO @SID_dbtable, @SID_RAd_field, @SID_DEd_field, @SID_pixid_field FROM SID.tables_htm WHERE dbtable = @SID_dbtable AND iorder = @SID_iorder LIMIT 1;
    ELSE
        SELECT dbtable, RAd_field, DEd_field, pixid_field INTO @SID_dbtable, @SID_RAd_field, @SID_DEd_field, @SID_pixid_field FROM SID.tables_healp WHERE dbtable = @SID_dbtable AND iorder = @SID_iorder LIMIT 1;
    END IF;
  END IF;

  IF (@SID_RAd_field IS NULL) OR (@SID_DEd_field IS NULL) THEN
    IF piorder IS NULL THEN
        SET @errmsg = CONCAT('Table ', pdbtable, ' is not a ', plibrary, ' registered table');
    ELSE
        SET @errmsg = CONCAT('Table ', pdbtable, ' does not have a registered ', plibrary, ' index with order ', piorder);
    END IF;
    SIGNAL SQLSTATE 'HY000' SET MESSAGE_TEXT = @errmsg;
  END IF;
END//


DROP PROCEDURE IF EXISTS _AddFullPixels//
CREATE PROCEDURE _AddFullPixels(IN region BIGINT, IN p CHAR(16))
  NOT DETERMINISTIC
  BEGIN
    DECLARE i, cc INTEGER;
    SET cc = SIDCount(p, 1);
    SET i = 0;
    WHILE i < cc DO
      INSERT INTO SID.sid_full VALUES (region, SIDGetID(p, i, 1));
      SET i = i + 1;
    END WHILE;
  END//


DROP PROCEDURE IF EXISTS AddCone//
CREATE PROCEDURE AddCone(IN region BIGINT, IN ra DOUBLE, IN de DOUBLE, IN rad DOUBLE)
  NOT DETERMINISTIC
  BEGIN
    DECLARE p CHAR(16);
    DECLARE i, cc INTEGER;
    IF @SID_library = 'HTM' THEN
        SET p = SIDCircleHTM(     @SID_iorder, ra, de, rad);
    ELSE
        SET p = SIDCircleHEALP(1, @SID_iorder, ra, de, rad); -- 1 means NESTED
    END IF;
    CALL _AddFullPixels(region, p);
    SET cc = SIDCount(p, 0);
    SET i = 0;
    WHILE i < cc DO
      INSERT INTO SID.sid_cone VALUES (region, SIDGetID(p, i, 0), ra, de, rad);
      SET i = i + 1;
    END WHILE;
    SET p = SIDClear(p);
  END//


DROP PROCEDURE IF EXISTS AddRect//
CREATE PROCEDURE AddRect(IN region BIGINT, IN ra1 DOUBLE, IN de1 DOUBLE, IN ra2 DOUBLE, IN de2 DOUBLE)
  NOT DETERMINISTIC
  BEGIN
    DECLARE p CHAR(16);
    DECLARE i, cc INTEGER;
    IF @SID_library = 'HTM' THEN
        SET p = SIDRectvHTM(     @SID_iorder, ra1, de1, ra2, de2);
    ELSE
        SET p = SIDRectvHEALP(1, @SID_iorder, ra1, de1, ra2, de2); -- 1 means NESTED
    END IF;
    CALL _AddFullPixels(region, p);
    SET cc = SIDCount(p, 0);
    SET i = 0;
    WHILE i < cc DO
      INSERT INTO SID.sid_rect VALUES (region, SIDGetID(p, i, 0), ra1, de1, ra2, de2);
      SET i = i + 1;
    END WHILE;
    SET p = SIDClear(p);
  END//


DROP FUNCTION IF EXISTS select_query//
CREATE FUNCTION select_query()
  RETURNS LONGTEXT
  NOT DETERMINISTIC
  BEGIN
    DECLARE soutput VARCHAR(1000) DEFAULT "";
    DECLARE tmp BIGINT;

    SET tmp = NULL;
    SELECT sid_pixid INTO tmp FROM SID.sid_full LIMIT 1;
    IF tmp IS NOT NULL THEN
        SET soutput = CONCAT(         'SELECT ', @SID_dbtable, '.*, SID.sid_full.SID_region FROM ', @SID_dbtable);
        SET soutput = CONCAT(soutput, '  INNER JOIN SID.sid_full ON ', @SID_dbtable, '.', @SID_pixid_field, '=SID.sid_full.sid_pixid\n');
    END IF;

    SET tmp = NULL;
    SELECT sid_pixid INTO tmp FROM SID.sid_cone LIMIT 1;
    IF tmp IS NOT NULL THEN
      IF LENGTH(soutput) > 0 THEN
          SET soutput = CONCAT(soutput, 'UNION\n');
      END IF;
      SET soutput = CONCAT(soutput, 'SELECT ', @SID_dbtable, '.*, SID.sid_cone.SID_region FROM ', @SID_dbtable);
      SET soutput = CONCAT(soutput, '  INNER JOIN SID.sid_cone ON ', @SID_dbtable, '.', @SID_pixid_field, '=SID.sid_cone.sid_pixid AND\n');
      SET soutput = CONCAT(soutput, ' (Sphedist(', @SID_RAd_field, ', ', @SID_DEd_field, ', SID.sid_cone.RAd, SID.sid_cone.DEd) <= SID.sid_cone.radius)\n');
    END IF;

    SET tmp = NULL;
    SELECT sid_pixid INTO tmp FROM SID.sid_rect LIMIT 1;
    IF tmp IS NOT NULL THEN
      IF LENGTH(soutput) > 0 THEN
          SET soutput = CONCAT(soutput, 'UNION\n');
      END IF;
      SET soutput = CONCAT(soutput, 'SELECT ', @SID_dbtable, '.*, SID.sid_rect.SID_region FROM ', @SID_dbtable);
      SET soutput = CONCAT(soutput, '  INNER JOIN SID.sid_rect ON ', @SID_dbtable, '.', @SID_pixid_field, '=SID.sid_rect.sid_pixid AND\n');
      SET soutput = CONCAT(soutput, '  ((', @SID_RAd_field, ' BETWEEN SID.sid_rect.RAd1 AND SID.sid_rect.RAd2) AND ');
      SET soutput = CONCAT(soutput, '   (', @SID_DEd_field, ' BETWEEN SID.sid_rect.DEd1 AND SID.sid_rect.DEd2))');
    END IF;

    IF LENGTH(soutput) = 0 THEN
        SET soutput = CONCAT('SELECT ', @SID_dbtable, '.*, NULL AS SID_region FROM ', @SID_dbtable, ' LIMIT 0');
    END IF;

    RETURN soutput;
  END//

delimiter ;
