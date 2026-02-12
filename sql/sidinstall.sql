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
  dbtable    VARCHAR(500) NOT NULL,
  RAd_field  VARCHAR(500) NOT NULL,
  DEd_field  VARCHAR(500) NOT NULL,
  iorder     INT NOT NULL);
CREATE INDEX dbtable ON SID.tables_htm (dbtable);

CREATE TABLE SID.tables_healp (
  dbtable    VARCHAR(500) NOT NULL,
  RAd_field  VARCHAR(500) NOT NULL,
  DEd_field  VARCHAR(500) NOT NULL,
  iorder     INT NOT NULL);
CREATE INDEX dbtable ON SID.tables_healp (dbtable);


-- Create stored procedures
delimiter //

DROP PROCEDURE IF EXISTS AddHEALPIndex//
CREATE PROCEDURE AddHEALPIndex(IN dbtable VARCHAR(500), IN RAd_field VARCHAR(500), IN DEd_field VARCHAR(500), IN iorder INT)
  NOT DETERMINISTIC
  BEGIN
     DECLARE sqlStatement VARCHAR(1024);
     SET sqlStatement = CONCAT('ALTER TABLE ', dbtable, ' ADD COLUMN healp', iorder, ' BIGINT NOT NULL');
     PREPARE stmt FROM sqlStatement; EXECUTE stmt; DEALLOCATE PREPARE stmt;
     SET sqlStatement = CONCAT('UPDATE ', dbtable, ' SET healp', iorder, ' = HEALPLookup(1, ', iorder, ', ', RAd_field, ', ', DEd_field, ')'); -- 1 means NESTED
     PREPARE stmt FROM sqlStatement; EXECUTE stmt; DEALLOCATE PREPARE stmt;
     SET sqlStatement = CONCAT('CREATE INDEX healp', iorder, ' ON ', dbtable, ' (healp', iorder, ')');
     PREPARE stmt FROM sqlStatement; EXECUTE stmt; DEALLOCATE PREPARE stmt;
     SET sqlStatement = CONCAT('INSERT INTO SID.tables_healp VALUES ("', dbtable, '", "', RAd_field, '", "', DEd_field, '", ', iorder, ')');
     PREPARE stmt FROM sqlStatement; EXECUTE stmt; DEALLOCATE PREPARE stmt;
  END//


DROP PROCEDURE IF EXISTS AddHTMIndex//
CREATE PROCEDURE AddHTMIndex(IN dbtable VARCHAR(500), IN RAd_field VARCHAR(500), IN DEd_field VARCHAR(500), IN iorder INT)
  NOT DETERMINISTIC
  BEGIN
     DECLARE sqlStatement VARCHAR(1024);
     SET sqlStatement = CONCAT('ALTER TABLE ', dbtable, ' ADD COLUMN htm', iorder, ' BIGINT NOT NULL');
     PREPARE stmt FROM sqlStatement; EXECUTE stmt; DEALLOCATE PREPARE stmt;
     SET sqlStatement = CONCAT('UPDATE ', dbtable, ' SET htm', iorder, ' = HTMLookup(', iorder, ', ', RAd_field, ', ', DEd_field, ')');
     PREPARE stmt FROM sqlStatement; EXECUTE stmt; DEALLOCATE PREPARE stmt;
     SET sqlStatement = CONCAT('CREATE INDEX htm', iorder, ' ON ', dbtable, ' (htm', iorder, ')');
     PREPARE stmt FROM sqlStatement; EXECUTE stmt; DEALLOCATE PREPARE stmt;
     SET sqlStatement = CONCAT('INSERT INTO SID.tables_htm VALUES ("', dbtable, '", "', RAd_field, '", "', DEd_field, '", ', iorder, ')');
     PREPARE stmt FROM sqlStatement; EXECUTE stmt; DEALLOCATE PREPARE stmt;
  END//


DROP PROCEDURE IF EXISTS InitRegion//
CREATE PROCEDURE InitRegion(IN plibrary VARCHAR(20), IN pdbtable VARCHAR(500), IN piorder INT DEFAULT NULL)
  NOT DETERMINISTIC
  BEGIN

  IF plibrary NOT IN ('HTM', 'HEALP') THEN
    SIGNAL SQLSTATE 'HY000' SET MESSAGE_TEXT = 'Supported libraries are "HTM" and "HEALP"';
  END IF;

  DROP TABLE IF EXISTS SID.sid_full;
  CREATE TEMPORARY TABLE SID.sid_full (SID_region BIGINT, SID_pixid BIGINT NOT NULL);
  DROP TABLE IF EXISTS SID.sid_part;
  CREATE TEMPORARY TABLE SID.sid_part (SID_region BIGINT, SID_pixid BIGINT NOT NULL, p1 DOUBLE NOT NULL, p2 DOUBLE NOT NULL, p3 DOUBLE NOT NULL, p4 DOUBLE NOT NULL);

  SET @SID_library   = plibrary;
  SET @SID_dbtable   = pdbtable;
  SET @SID_RAd_field = NULL;
  SET @SID_DEd_field = NULL;
  SET @SID_iorder    = piorder;

  IF piorder IS NULL THEN
    IF plibrary = 'HTM' THEN
        SELECT dbtable, RAd_field, DEd_field, iorder INTO @SID_dbtable, @SID_RAd_field, @SID_DEd_field, @SID_iorder FROM SID.tables_htm WHERE dbtable = @SID_dbtable ORDER BY iorder DESC LIMIT 1;
    ELSE
        SELECT dbtable, RAd_field, DEd_field, iorder INTO @SID_dbtable, @SID_RAd_field, @SID_DEd_field, @SID_iorder FROM SID.tables_healp WHERE dbtable = @SID_dbtable ORDER BY iorder DESC LIMIT 1;
    END IF;
  ELSE
    IF plibrary = 'HTM' THEN
        SELECT dbtable, RAd_field, DEd_field INTO @SID_dbtable, @SID_RAd_field, @SID_DEd_field FROM SID.tables_htm WHERE dbtable = @SID_dbtable AND iorder = @SID_iorder LIMIT 1;
    ELSE
        SELECT dbtable, RAd_field, DEd_field INTO @SID_dbtable, @SID_RAd_field, @SID_DEd_field FROM SID.tables_healp WHERE dbtable = @SID_dbtable AND iorder = @SID_iorder LIMIT 1;
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


DROP PROCEDURE IF EXISTS _AddRegion//
CREATE PROCEDURE _AddRegion(IN region BIGINT, IN p CHAR(16), IN p1 DOUBLE, IN p2 DOUBLE, IN p3 DOUBLE, IN p4 DOUBLE)
  NOT DETERMINISTIC
  BEGIN
    DECLARE i, countp, countf INTEGER;

    SET countf = SIDCount(p, 1);
    SET countp = SIDCount(p, 0);

    SET i = 0;
    WHILE i < countf DO
      INSERT INTO SID.sid_full VALUES (region, SIDGetID(p, i, 1));
      SET i = i + 1;
    END WHILE;

    SET i = 0;
    WHILE i < countp DO
      INSERT INTO SID.sid_part VALUES (region, SIDGetID(p, i, 0), p1, p2, p3, p4);
      SET i = i + 1;
    END WHILE;

    SET p = SIDClear(p);
  END//


DROP PROCEDURE IF EXISTS AddCone//
CREATE PROCEDURE AddCone(IN region BIGINT, IN ra DOUBLE, IN de DOUBLE, IN rad DOUBLE)
  NOT DETERMINISTIC
  BEGIN
    DECLARE p CHAR(16);
    SET @SID_regiontype = 1; -- Cone search
    IF @SID_library = 'HTM' THEN
        SET p = SIDCircleHTM(     @SID_iorder, ra, de, rad);
    ELSE
        SET p = SIDCircleHEALP(1, @SID_iorder, ra, de, rad);
    END IF;
    CALL SID._AddRegion(region, p, ra, de, rad, 0.);
  END//


DROP PROCEDURE IF EXISTS AddRectV//
CREATE PROCEDURE AddRectV(IN region BIGINT, IN ra1 DOUBLE, IN de1 DOUBLE, IN ra2 DOUBLE, IN de2 DOUBLE)
  NOT DETERMINISTIC
  BEGIN
    DECLARE p CHAR(16);
    SET @SID_regiontype = 2; -- Rectangle search
    IF @SID_library = 'HTM' THEN
        SET p = SIDRectvHTM(     @SID_iorder, ra1, de1, ra2, de2);
    ELSE
        SET p = SIDRectvHEALP(1, @SID_iorder, ra1, de1, ra2, de2);
    END IF;
    CALL SID._AddRegion(region, p, ra1, de1, ra2, de2);
  END//


DROP FUNCTION IF EXISTS select_query//
CREATE FUNCTION select_query()
  RETURNS LONGTEXT
  NOT DETERMINISTIC
  BEGIN
    DECLARE soutput VARCHAR(1000) DEFAULT NULL;
    SET soutput = CONCAT(         'SELECT ', @SID_dbtable, '.*, SID.sid_full.SID_region FROM ', @SID_dbtable);
    SET soutput = CONCAT(soutput, '  INNER JOIN SID.sid_full ON ', @SID_dbtable, '.', LOWER(@SID_library), @SID_iorder, '=SID.sid_full.sid_pixid\n');
    SET soutput = CONCAT(soutput, 'UNION\n');
    SET soutput = CONCAT(soutput, 'SELECT ', @SID_dbtable, '.*, SID.sid_part.SID_region FROM ', @SID_dbtable);
    SET soutput = CONCAT(soutput, '  INNER JOIN SID.sid_part ON ', @SID_dbtable, '.', LOWER(@SID_library), @SID_iorder, '=SID.sid_part.sid_pixid AND\n');
    IF @SID_regiontype = 1 THEN
        SET soutput = CONCAT(soutput, ' (Sphedist(', @SID_dbtable, '.', @SID_RAd_field, ', ', @SID_dbtable, '.', @SID_DEd_field, ', SID.sid_part.p1, SID.sid_part.p2) <= SID.sid_part.p3);');
    ELSE
        SET soutput = CONCAT(soutput, '  ((', @SID_dbtable, '.', @SID_RAd_field, ' BETWEEN SID.sid_part.p1 AND SID.sid_part.p3) AND ');
        SET soutput = CONCAT(soutput, '   (', @SID_dbtable, '.', @SID_DEd_field, ' BETWEEN SID.sid_part.p2 AND SID.sid_part.p4));');
    END IF;
    RETURN soutput;
  END//

delimiter ;
