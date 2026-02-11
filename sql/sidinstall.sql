-- Create database and tables
DROP DATABASE IF EXISTS SID;
CREATE DATABASE SID;
USE SID;

CREATE TABLE SID.tables_htm (
  dbtable    VARCHAR(500) NOT NULL,
  RAd_field  VARCHAR(500) NOT NULL,
  DECd_field VARCHAR(500) NOT NULL,
  iorder     INT NOT NULL);
CREATE INDEX dbtable ON SID.tables_htm (dbtable);

CREATE TABLE SID.tables_healpix (
  dbtable    VARCHAR(500) NOT NULL,
  RAd_field  VARCHAR(500) NOT NULL,
  DECd_field VARCHAR(500) NOT NULL,
  iorder     INT NOT NULL);
CREATE INDEX dbtable ON SID.tables_healpix (dbtable);

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


-- Create stored procedures
delimiter //

DROP PROCEDURE IF EXISTS AddHealpixIndex//
CREATE PROCEDURE AddHealpixIndex(IN dbtable VARCHAR(500), IN RAd_field VARCHAR(500), IN DECd_field VARCHAR(500), IN iorder INT)
  NOT DETERMINISTIC
  BEGIN
     DECLARE sqlStatement VARCHAR(1024);
     SET sqlStatement = CONCAT('ALTER TABLE ', dbtable, ' ADD COLUMN healpix', iorder, ' BIGINT NOT NULL');
     SET @sql = sqlStatement; PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
     SET sqlStatement = CONCAT('UPDATE ', dbtable, ' SET healpix', iorder, ' = HEALPLookup(1, ', iorder, ', ', RAd_field, ', ', DECd_field, ')'); -- 1 means NESTED
     SET @sql = sqlStatement; PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
     SET sqlStatement = CONCAT('CREATE INDEX healpix', iorder, ' ON ', dbtable, ' (healpix', iorder, ')');
     SET @sql = sqlStatement; PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
     SET sqlStatement = CONCAT('INSERT INTO SID.tables_healpix VALUES ("', dbtable, '", "', RAd_field, '", "', DECd_field, '", ', iorder, ')');
     SET @sql = sqlStatement; PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
  END//


DROP PROCEDURE IF EXISTS AddHTMIndex//
CREATE PROCEDURE AddHTMIndex(IN dbtable VARCHAR(500), IN RAd_field VARCHAR(500), IN DECd_field VARCHAR(500), IN iorder INT)
  NOT DETERMINISTIC
  BEGIN
     DECLARE sqlStatement VARCHAR(1024);
     SET sqlStatement = CONCAT('ALTER TABLE ', dbtable, ' ADD COLUMN htm', iorder, ' BIGINT NOT NULL');
     SET @sql = sqlStatement; PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
     SET sqlStatement = CONCAT('UPDATE ', dbtable, ' SET htm', iorder, ' = HTMLookup(', iorder, ', ', RAd_field, ', ', DECd_field, ')');
     SET @sql = sqlStatement; PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
     SET sqlStatement = CONCAT('CREATE INDEX htm', iorder, ' ON ', dbtable, ' (htm', iorder, ')');
     SET @sql = sqlStatement; PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
     SET sqlStatement = CONCAT('INSERT INTO SID.tables_htm VALUES ("', dbtable, '", "', RAd_field, '", "', DECd_field, '", ', iorder, ')');
     SET @sql = sqlStatement; PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
  END//


DROP PROCEDURE IF EXISTS ResetRegion//
CREATE PROCEDURE ResetRegion()
  NOT DETERMINISTIC
  BEGIN
  DROP TABLE IF EXISTS SID.sid;
  CREATE TEMPORARY TABLE SID.sid (SID_pixid BIGINT not null, SID_isfull TINYINT not null, SID_region INT NOT NULL);
  END//


DROP PROCEDURE IF EXISTS SelectRegion//
CREATE PROCEDURE SelectRegion(IN p CHAR(16))
  NOT DETERMINISTIC
  BEGIN
    DECLARE i, countp, countf, region INTEGER;

    SET countf = SIDCount(p, 1);
    SET countp = SIDCount(p, 0);
    SET region = (SELECT IFNULL(MAX(SID_region), 0)+1 FROM SID.sid);

    SET i = 0;
    WHILE i < countf DO
      INSERT INTO SID.sid VALUES (SIDGetID(p, i, 1), 1, region);
      SET i = i + 1;
    END WHILE;

    SET i = 0;
    WHILE i < countp DO
      INSERT INTO SID.sid VALUES (SIDGetID(p, i, 0), 0, region);
      SET i = i + 1;
    END WHILE;

    SET p = SIDClear(p);
  END//


-- Create HTM-specific stored procedures
DROP PROCEDURE IF EXISTS SelectRect_HTM//
CREATE PROCEDURE SelectRect_HTM(IN ord INTEGER, IN ra DOUBLE, IN de DOUBLE, IN side_ra DOUBLE, IN side_de DOUBLE)
  NOT DETERMINISTIC
  BEGIN
    DECLARE p CHAR(16);
    SET p = SIDRectHTM(ord, ra, de, side_ra, side_de);
    CALL SID.SelectRegion(p);
  END//


DROP PROCEDURE IF EXISTS SelectRectv_HTM//
CREATE PROCEDURE SelectRectv_HTM(IN ord INTEGER, IN ra1 DOUBLE, IN de1 DOUBLE, IN ra2 DOUBLE, IN de2 DOUBLE)
  NOT DETERMINISTIC
  BEGIN
    DECLARE p CHAR(16);
    SET p = SIDRectvHTM(ord, ra1, de1, ra2, de2);
    CALL SID.SelectRegion(p);
  END//


DROP PROCEDURE IF EXISTS SelectCircle_HTM//
CREATE PROCEDURE SelectCircle_HTM(IN ord INTEGER, IN ra DOUBLE, IN de DOUBLE, IN rad DOUBLE)
  NOT DETERMINISTIC
  BEGIN
    DECLARE p CHAR(16);
    SET p = SIDCircleHTM(ord, ra, de, rad);
    CALL SID.SelectRegion(p);
  END//


-- Create Healpix-specific stored procedures
DROP PROCEDURE IF EXISTS SelectRect_HEALPix//
CREATE PROCEDURE SelectRect_HEALPix(IN ord INTEGER, IN ra DOUBLE, IN de DOUBLE, IN side_ra DOUBLE, IN side_de DOUBLE)
  NOT DETERMINISTIC
  BEGIN
    DECLARE p CHAR(16);
    SET p = SIDRectHEALP(1, ord, ra, de, side_ra, side_de);
    CALL SID.SelectRegion(p);
  END//


DROP PROCEDURE IF EXISTS SelectRectv_HEALPix//
CREATE PROCEDURE SelectRectv_HEALPix(IN ord INTEGER, IN ra1 DOUBLE, IN de1 DOUBLE, IN ra2 DOUBLE, IN de2 DOUBLE)
  NOT DETERMINISTIC
  BEGIN
    DECLARE p CHAR(16);
    SET p = SIDRectvHEALP(1, ord, ra1, de1, ra2, de2);
    CALL SID.SelectRegion(p);
  END//


DROP PROCEDURE IF EXISTS SelectCircle_HEALPix//
CREATE PROCEDURE SelectCircle_HEALPix(IN ord INTEGER, IN ra DOUBLE, IN de DOUBLE, IN rad DOUBLE)
  NOT DETERMINISTIC
  BEGIN
    DECLARE p CHAR(16);
    SET p = SIDCircleHEALP(1, ord, ra, de, rad);
    CALL SID.SelectRegion(p);
  END//


-- Search_query functions
DROP FUNCTION IF EXISTS ConeSearch_query//
CREATE FUNCTION ConeSearch_query(IN pdbtable VARCHAR(500), IN ra DOUBLE, IN de DOUBLE, IN rad_arcsec DOUBLE)
  RETURNS VARCHAR(500)
  NOT DETERMINISTIC
  BEGIN
    DECLARE _output     VARCHAR(500) DEFAULT NULL;
    DECLARE _dbtable    VARCHAR(500) DEFAULT NULL;
    DECLARE _RAd_field  VARCHAR(500) DEFAULT NULL;
    DECLARE _DECd_field VARCHAR(500) DEFAULT NULL;
    DECLARE _iorder     INT;

    SET _dbtable = NULL;
    SELECT dbtable, RAd_field, DECd_field, iorder INTO _dbtable, _RAd_field, _DECd_field, _iorder FROM SID.tables_htm WHERE dbtable = pdbtable ORDER BY iorder DESC LIMIT 1;
    IF (_dbtable IS NOT NULL) THEN
       SET _output = CONCAT('CALL SID.ResetRegion();\n');
       SET _output = CONCAT(_output, 'CALL SID.SelectCircle_HTM(', _iorder, ', ', ra, ', ', de, ', ', rad_arcsec / 3600., ');\n');
       SET _output = CONCAT(_output, 'SELECT ', _dbtable, '.* FROM ', _dbtable);
       SET _output = CONCAT(_output, ' INNER JOIN SID.sid\n ON ', _dbtable, '.htm', _iorder, '=SID.sid.sid_pixid  AND  (SID.sid.sid_isfull=1 OR\n');
    END IF;

    SET _dbtable = NULL;
    SELECT dbtable, RAd_field, DECd_field, iorder INTO _dbtable, _RAd_field, _DECd_field, _iorder FROM SID.tables_healpix WHERE dbtable = pdbtable ORDER BY iorder DESC LIMIT 1;
    IF (_dbtable IS NOT NULL) THEN
       SET _output = CONCAT('CALL SID.ResetRegion();\n');
       SET _output = CONCAT(_output, 'CALL SID.SelectCircle_HEALPix(', _iorder, ', ', ra, ', ', de, ', ', rad_arcsec / 3600., ');\n');
       SET _output = CONCAT(_output, 'SELECT ', _dbtable, '.* FROM ', _dbtable);
       SET _output = CONCAT(_output, ' INNER JOIN SID.sid\n ON ', _dbtable, '.healpix', _iorder, '=SID.sid.sid_pixid  AND  (SID.sid.sid_isfull=1 OR\n');
    END IF;

    IF (_output IS NOT NULL) THEN
       SET _output = CONCAT(_output, ' (Sphedist(', _dbtable, '.', _RAd_field, ', ', _dbtable, '.', _DECd_field, ', ', ra, ', ', de, ') <= ', rad_arcsec/3600., '));');
    END IF;
    RETURN _output;
  END//


DROP FUNCTION IF EXISTS RectSearch_query//
CREATE FUNCTION RectSearch_query(IN pdbtable VARCHAR(500), IN ra DOUBLE, IN de DOUBLE, IN side_ra_arcsec DOUBLE, IN side_de_arcsec DOUBLE)
  RETURNS VARCHAR(500)
  NOT DETERMINISTIC
  BEGIN
    DECLARE _output     VARCHAR(500) DEFAULT NULL;
    DECLARE _dbtable    VARCHAR(500) DEFAULT NULL;
    DECLARE _RAd_field  VARCHAR(500) DEFAULT NULL;
    DECLARE _DECd_field VARCHAR(500) DEFAULT NULL;
    DECLARE _iorder     INT;

    SET _dbtable = NULL;
    SELECT dbtable, RAd_field, DECd_field, iorder INTO _dbtable, _RAd_field, _DECd_field, _iorder FROM SID.tables_htm WHERE dbtable = pdbtable ORDER BY iorder DESC LIMIT 1;
    IF (_dbtable IS NOT NULL) THEN
       SET _output = CONCAT('CALL SID.ResetRegion();\n');
       SET _output = CONCAT(_output, 'CALL SID.SelectRect_HTM(', _iorder, ', ', ra, ', ', de, ', ', side_ra_arcsec / 3600., ', ', side_de_arcsec / 3600., ');\n');
       SET _output = CONCAT(_output, 'SELECT ', _dbtable, '.* FROM ', _dbtable);
       SET _output = CONCAT(_output, ' INNER JOIN SID.sid\n ON ', _dbtable, '.htm', _iorder, '=SID.sid.sid_pixid  AND  (SID.sid.sid_isfull=1 OR\n');
    END IF;

    SET _dbtable = NULL;
    SELECT dbtable, RAd_field, DECd_field, iorder INTO _dbtable, _RAd_field, _DECd_field, _iorder FROM SID.tables_healpix WHERE dbtable = pdbtable ORDER BY iorder DESC LIMIT 1;
    IF (_dbtable IS NOT NULL) THEN
       SET _output = CONCAT('CALL SID.ResetRegion();\n');
       SET _output = CONCAT(_output, 'CALL SID.SelectRect_HEALPix(', _iorder, ', ', ra, ', ', de, ', ', side_ra_arcsec / 3600., ', ', side_de_arcsec / 3600., ');\n');
       SET _output = CONCAT(_output, 'SELECT ', _dbtable, '.* FROM ', _dbtable);
       SET _output = CONCAT(_output, ' INNER JOIN SID.sid\n ON ', _dbtable, '.healpix', _iorder, '=SID.sid.sid_pixid  AND  (SID.sid.sid_isfull=1 OR\n');
    END IF;

    IF (_output IS NOT NULL) THEN
       SET _output = CONCAT(_output, ' ((', _dbtable, '.', _RAd_field, ' BETWEEN ', ra - side_ra_arcsec / 3600. / 2., ' AND ', ra + side_ra_arcsec / 3600. / 2., ') AND ');
       SET _output = CONCAT(_output, '  (', _dbtable, '.', _DECd_field,' BETWEEN ', de - side_de_arcsec / 3600. / 2., ' AND ', de + side_de_arcsec / 3600. / 2., ')));');
    END IF;

    RETURN _output;
  END//


DROP FUNCTION IF EXISTS RectvSearch_query//
CREATE FUNCTION RectvSearch_query(IN pdbtable VARCHAR(500), IN ra1 DOUBLE, IN de1 DOUBLE, IN ra2 DOUBLE, IN de2 DOUBLE)
  RETURNS VARCHAR(500)
  NOT DETERMINISTIC
  BEGIN
    DECLARE _output     VARCHAR(500) DEFAULT NULL;
    DECLARE _dbtable    VARCHAR(500) DEFAULT NULL;
    DECLARE _RAd_field  VARCHAR(500) DEFAULT NULL;
    DECLARE _DECd_field VARCHAR(500) DEFAULT NULL;
    DECLARE _iorder     INT;

    SET _dbtable = NULL;
    SELECT dbtable, RAd_field, DECd_field, iorder INTO _dbtable, _RAd_field, _DECd_field, _iorder FROM SID.tables_htm WHERE dbtable = pdbtable ORDER BY iorder DESC LIMIT 1;
    IF (_dbtable IS NOT NULL) THEN
       SET _output = CONCAT('CALL SID.ResetRegion();\n');
       SET _output = CONCAT(_output, 'CALL SID.SelectRectv_HTM(', _iorder, ', ', ra1, ', ', de1, ', ', ra2, ', ', de2, ');\n');
       SET _output = CONCAT(_output, 'SELECT ', _dbtable, '.* FROM ', _dbtable);
       SET _output = CONCAT(_output, ' INNER JOIN SID.sid\n ON ', _dbtable, '.htm', _iorder, '=SID.sid.sid_pixid  AND  (SID.sid.sid_isfull=1 OR\n');
    END IF;

    SET _dbtable = NULL;
    SELECT dbtable, RAd_field, DECd_field, iorder INTO _dbtable, _RAd_field, _DECd_field, _iorder FROM SID.tables_healpix WHERE dbtable = pdbtable ORDER BY iorder DESC LIMIT 1;
    IF (_dbtable IS NOT NULL) THEN
       SET _output = CONCAT('CALL SID.ResetRegion();\n');
       SET _output = CONCAT(_output, 'CALL SID.SelectRectv_HEALPix(', _iorder, ', ', ra1, ', ', de1, ', ', ra2, ', ', de2, ');\n');
       SET _output = CONCAT(_output, 'SELECT ', _dbtable, '.* FROM ', _dbtable);
       SET _output = CONCAT(_output, ' INNER JOIN SID.sid\n ON ', _dbtable, '.healpix', _iorder, '=SID.sid.sid_pixid  AND  (SID.sid.sid_isfull=1 OR\n');
    END IF;

    IF (_output IS NOT NULL) THEN
       SET _output = CONCAT(_output, ' ((', _dbtable, '.', _RAd_field, ' BETWEEN ', ra1, ' AND ', ra2, ') AND ');
       SET _output = CONCAT(_output, '  (', _dbtable, '.', _DECd_field,' BETWEEN ', de1, ' AND ', de2, ')));');
    END IF;

    RETURN _output;
  END//


delimiter ;
