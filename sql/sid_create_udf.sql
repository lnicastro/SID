USE SID;

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

CREATE OR REPLACE PROCEDURE InitSearch(IN pdbname VARCHAR(100), IN ptablename VARCHAR(100), IN plibrary VARCHAR(20) DEFAULT 'HEALP', IN piorder INT DEFAULT NULL)
  NOT DETERMINISTIC
  BEGIN
  DECLARE tmp VARCHAR(500);

  IF plibrary NOT IN ('HTM', 'HEALP') THEN
    SIGNAL SQLSTATE 'HY000' SET MESSAGE_TEXT = 'Supported libraries are "HTM" and "HEALP"';
  END IF;

  DROP TABLE IF EXISTS SID.regions_full;
  CREATE TEMPORARY TABLE SID.regions_full (SID_region BIGINT, SID_pixid BIGINT NOT NULL);
  DROP TABLE IF EXISTS SID.regions_cone;
  CREATE TEMPORARY TABLE SID.regions_cone (SID_region BIGINT, SID_pixid BIGINT NOT NULL, RAd DOUBLE NOT NULL, DEd DOUBLE NOT NULL, radius_arcmin DOUBLE NOT NULL);
  DROP TABLE IF EXISTS SID.regions_rect;
  CREATE TEMPORARY TABLE SID.regions_rect (SID_region BIGINT, SID_pixid BIGINT NOT NULL, RAd1 DOUBLE NOT NULL, DEd1 DOUBLE NOT NULL, RAd2 DOUBLE NOT NULL, DEd2 DOUBLE NOT NULL);

  SET @SID_library     = plibrary;
  SET @SID_dbname      = pdbname;
  SET @SID_tablename   = ptablename;
  SET @SID_RAd_expr    = NULL;
  SET @SID_DEd_expr    = NULL;
  SET @SID_iorder      = piorder;
  SET @SID_pixid_field = NULL;

  IF piorder IS NULL THEN
    IF plibrary = 'HTM' THEN
        SELECT dbname, tablename, RAd_expr, DEd_expr, iorder, pixid_field INTO @SID_dbname, @SID_tablename, @SID_RAd_expr, @SID_DEd_expr, @SID_iorder, @SID_pixid_field FROM SID.tables_htm   WHERE dbname = @SID_dbname AND tablename=@SID_tablename ORDER BY iorder DESC LIMIT 1;
    ELSE
        SELECT dbname, tablename, RAd_expr, DEd_expr, iorder, pixid_field INTO @SID_dbname, @SID_tablename, @SID_RAd_expr, @SID_DEd_expr, @SID_iorder, @SID_pixid_field FROM SID.tables_healp WHERE dbname = @SID_dbname AND tablename=@SID_tablename ORDER BY iorder DESC LIMIT 1;
    END IF;
  ELSE
    IF plibrary = 'HTM' THEN
        SELECT dbname, tablename, RAd_expr, DEd_expr,         pixid_field INTO @SID_dbname, @SID_tablename, @SID_RAd_expr, @SID_DEd_expr,              @SID_pixid_field FROM SID.tables_htm   WHERE dbname = @SID_dbname AND tablename=@SID_tablename AND iorder = @SID_iorder LIMIT 1;
    ELSE
        SELECT dbname, tablename, RAd_expr, DEd_expr,         pixid_field INTO @SID_dbname, @SID_tablename, @SID_RAd_expr, @SID_DEd_expr,              @SID_pixid_field FROM SID.tables_healp WHERE dbname = @SID_dbname AND tablename=@SID_tablename AND iorder = @SID_iorder LIMIT 1;
    END IF;
  END IF;

  IF (@SID_RAd_expr IS NULL) OR (@SID_DEd_expr IS NULL) THEN
    IF piorder IS NULL THEN
        SET @errmsg = CONCAT('Table ', pdbname, '.', ptablename, ' is not a ', plibrary, ' registered table');
    ELSE
        SET @errmsg = CONCAT('Table ', pdbname, '.', ptablename, ' does not have a registered ', plibrary, ' index with order ', piorder);
    END IF;
    SIGNAL SQLSTATE 'HY000' SET MESSAGE_TEXT = @errmsg;
  END IF;

  SET tmp = CONCAT('SHOW INDEX FROM ', @SID_dbname, '.', @SID_tablename, ' WHERE Key_name = "', @SID_pixid_field, '"');
  EXECUTE IMMEDIATE tmp;

  SET tmp = CONCAT('SELECT * FROM SID.tables_', LOWER(@SID_library), ' WHERE dbname="', @SID_dbname, '" AND tablename="', @SID_tablename, '" AND pixid_field="', @SID_pixid_field, '"');
  EXECUTE IMMEDIATE tmp;
END//


CREATE OR REPLACE PROCEDURE _AddFullPixels(IN region BIGINT, IN p CHAR(16))
  NOT DETERMINISTIC
  BEGIN
    DECLARE i, cc INTEGER;
    SET cc = SIDCount(p, 1);
    SET i = 0;
    WHILE i < cc DO
      INSERT INTO SID.regions_full VALUES (region, SIDGetID(p, i, 1));
      SET i = i + 1;
    END WHILE;
  END//


CREATE OR REPLACE PROCEDURE AddCone(IN region BIGINT, IN ra DOUBLE, IN de DOUBLE, IN radius_arcmin DOUBLE)
  NOT DETERMINISTIC
  BEGIN
    DECLARE p CHAR(16);
    DECLARE i, cc INTEGER;
    IF @SID_library = 'HTM' THEN
        SET p = SIDCircleHTM(     @SID_iorder, ra, de, radius_arcmin);
    ELSE
        SET p = SIDCircleHEALP(1, @SID_iorder, ra, de, radius_arcmin); -- 1 means NESTED
    END IF;
    CALL SID._AddFullPixels(region, p);
    SET cc = SIDCount(p, 0);
    SET i = 0;
    WHILE i < cc DO
      INSERT INTO SID.regions_cone VALUES (region, SIDGetID(p, i, 0), ra, de, radius_arcmin);
      SET i = i + 1;
    END WHILE;
    SET p = SIDClear(p);
  END//


CREATE OR REPLACE PROCEDURE AddRect(IN region BIGINT, IN ra1 DOUBLE, IN de1 DOUBLE, IN ra2 DOUBLE, IN de2 DOUBLE)
  NOT DETERMINISTIC
  BEGIN
    DECLARE p CHAR(16);
    DECLARE i, cc INTEGER;
    IF @SID_library = 'HTM' THEN
        SET p = SIDRectvHTM(     @SID_iorder, ra1, de1, ra2, de2);
    ELSE
        SET p = SIDRectvHEALP(1, @SID_iorder, ra1, de1, ra2, de2); -- 1 means NESTED
    END IF;
    CALL SID._AddFullPixels(region, p);
    SET cc = SIDCount(p, 0);
    SET i = 0;
    WHILE i < cc DO
      INSERT INTO SID.regions_rect VALUES (region, SIDGetID(p, i, 0), ra1, de1, ra2, de2);
      SET i = i + 1;
    END WHILE;
    SET p = SIDClear(p);
  END//


CREATE OR REPLACE FUNCTION GetQuery(IN pfields VARCHAR(500) DEFAULT NULL, IN where_clause LONGTEXT DEFAULT "")
  RETURNS LONGTEXT
  NOT DETERMINISTIC
  BEGIN
    DECLARE soutput VARCHAR(1000) DEFAULT "";
    DECLARE tmp BIGINT;

    IF pfields IS NULL THEN
       SET pfields = CONCAT(@SID_dbname, '.', @SID_tablename, '.*');
    END IF;

    SET tmp = NULL;
    SELECT sid_pixid INTO tmp FROM SID.regions_full LIMIT 1;
    IF tmp IS NOT NULL THEN
        SET soutput = CONCAT(soutput, 'SELECT ', pfields, ', SID.regions_full.SID_region FROM ', @SID_dbname, '.', @SID_tablename, '\n');
        SET soutput = CONCAT(soutput, '  INNER JOIN SID.regions_full ON ', @SID_dbname, '.', @SID_tablename, '.', @SID_pixid_field, '=SID.regions_full.sid_pixid\n');
        SET soutput = CONCAT(soutput, '  ', where_clause, '\n');
    END IF;

    SET tmp = NULL;
    SELECT sid_pixid INTO tmp FROM SID.regions_cone LIMIT 1;
    IF tmp IS NOT NULL THEN
      IF LENGTH(soutput) > 0 THEN
          SET soutput = CONCAT(soutput, 'UNION\n');
      END IF;
      SET soutput = CONCAT(soutput, 'SELECT ', pfields, ', SID.regions_cone.SID_region FROM ', @SID_dbname, '.', @SID_tablename, '\n');
      SET soutput = CONCAT(soutput, '  INNER JOIN SID.regions_cone ON ', @SID_dbname, '.', @SID_tablename, '.', @SID_pixid_field, '=SID.regions_cone.sid_pixid AND\n');
      SET soutput = CONCAT(soutput, '  (Sphedist(', @SID_RAd_expr, ', ', @SID_DEd_expr, ', SID.regions_cone.RAd, SID.regions_cone.DEd) <= SID.regions_cone.radius_arcmin)\n');
      SET soutput = CONCAT(soutput, '  ', where_clause, '\n');
    END IF;

    SET tmp = NULL;
    SELECT sid_pixid INTO tmp FROM SID.regions_rect LIMIT 1;
    IF tmp IS NOT NULL THEN
      IF LENGTH(soutput) > 0 THEN
          SET soutput = CONCAT(soutput, 'UNION\n');
      END IF;
      SET soutput = CONCAT(soutput, 'SELECT ', pfields, ', SID.regions_rect.SID_region FROM ', @SID_dbname, '.', @SID_tablename, '\n');
      SET soutput = CONCAT(soutput, '  INNER JOIN SID.regions_rect ON ', @SID_dbname, '.', @SID_tablename, '.', @SID_pixid_field, '=SID.regions_rect.sid_pixid AND\n');
      SET soutput = CONCAT(soutput, '  ((', @SID_RAd_expr, ' BETWEEN SID.regions_rect.RAd1 AND SID.regions_rect.RAd2) AND \n');
      SET soutput = CONCAT(soutput, '   (', @SID_DEd_expr, ' BETWEEN SID.regions_rect.DEd1 AND SID.regions_rect.DEd2))\n');
      SET soutput = CONCAT(soutput, '  ', where_clause, '\n');
    END IF;

    IF LENGTH(soutput) = 0 THEN
        SET soutput = CONCAT('SELECT ', pfields, ', NULL AS SID_region FROM ', @SID_dbname, '.', @SID_tablename, ' ', where_clause, ' LIMIT 0');
    ELSE
        SET soutput = CONCAT('\n', soutput);
    END IF;

    RETURN soutput;
  END//


CREATE OR REPLACE PROCEDURE RunQuery(IN pfields VARCHAR(500) DEFAULT NULL, IN where_clause LONGTEXT DEFAULT "")
  NOT DETERMINISTIC
  BEGIN
    DECLARE tmp LONGTEXT;
    SET tmp = SID.GetQuery(pfields, where_clause);
    EXECUTE IMMEDIATE tmp;
  END//


CREATE OR REPLACE PROCEDURE PixelizationStats(IN dbname VARCHAR(100), IN tablename VARCHAR(100), IN plibrary VARCHAR(20) DEFAULT 'HEALP', IN iorder INT DEFAULT NULL)
  NOT DETERMINISTIC
  BEGIN
    DECLARE tmp LONGTEXT;
    DECLARE nrows BIGINT;
    DECLARE ndistinct BIGINT;
    DECLARE npixels BIGINT;
    DECLARE pixelarea DOUBLE;
    DECLARE footprint DOUBLE;
    DECLARE skycoverage DOUBLE;

    CALL SID.InitSearch(dbname, tablename, plibrary, iorder);
    SELECT TABLE_ROWS INTO nrows FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA=dbname AND TABLE_NAME=tablename;

    SET tmp = CONCAT('SELECT COUNT(DISTINCT ', @SID_pixid_field, ') INTO @SID_tmp FROM ', dbname, '.', tablename);
    EXECUTE IMMEDIATE tmp;
    SET ndistinct = @SID_tmp;

    IF @SID_library='HEALP' THEN
        SET npixels = 12 * POW(POW(2, @SID_iorder), 2);
    ELSE
        SET npixels = 8 * POW(4, @SID_iorder);
    END IF;
    SET pixelarea = 4 * PI() * POW(180 / PI(), 2) / npixels;
    SET footprint = ndistinct * pixelarea;
    SET skycoverage = ndistinct / npixels;
    SET tmp = CONCAT('SELECT ', ndistinct, ' AS NPixels, ', SQRT(pixelarea) * 3600., ' AS PixelTypicalSize_arcsec, ', pixelarea, ' AS PixelArea_sqdeg, ', footprint, ' AS FootPrint_sqdeg, ', skycoverage, ' AS SkyFraction');
    EXECUTE IMMEDIATE tmp;

    SET tmp = CONCAT('SELECT ', @SID_pixid_field, ', COUNT(*) AS C FROM ', @SID_dbname, '.', @SID_tablename, ' GROUP BY ', @SID_pixid_field);
    set tmp = CONCAT('SELECT T.C AS SourcesInAPixel, COUNT(*) AS Multiplicity FROM (', tmp, ') AS T GROUP BY T.C ORDER BY SourcesInAPixel');
    SET tmp = CONCAT('SELECT M.*, M.SourcesInAPixel * M.Multiplicity / ', nrows, ' AS Fraction, SUM(M.SourcesInAPixel * M.Multiplicity) OVER(ORDER BY M.SourcesInAPixel) / ', nrows, ' AS CumulativeFraction FROM (', tmp, ') AS M');
    EXECUTE IMMEDIATE tmp;
  END//


CREATE OR REPLACE PROCEDURE AddHEALPIndex(IN dbname VARCHAR(100), IN tablename VARCHAR(100), IN RAd_expr VARCHAR(500), IN DEd_expr VARCHAR(500), IN iorder INT)
  NOT DETERMINISTIC
  BEGIN
     DECLARE tmp VARCHAR(1024);
     IF LOCATE('.', RAd_expr) = 0 THEN
         SET RAd_expr = CONCAT(dbname, '.', tablename, '.', RAd_expr);
     END IF;
     IF LOCATE('.', DEd_expr) = 0 THEN
         SET DEd_expr = CONCAT(dbname, '.', tablename, '.', DEd_expr);
     END IF;
     SET tmp = CONCAT('ALTER TABLE ', dbname, '.', tablename, ' ADD COLUMN healp', iorder, ' BIGINT NOT NULL');
     EXECUTE IMMEDIATE tmp;
     SET tmp = CONCAT('UPDATE ', dbname, '.', tablename, ' SET healp', iorder, ' = HEALPLookup(1, ', iorder, ', ', RAd_expr, ', ', DEd_expr, ')'); -- 1 means NESTED
     EXECUTE IMMEDIATE tmp;
     SET tmp = CONCAT('CREATE INDEX healp', iorder, ' ON ', dbname, '.', tablename, ' (healp', iorder, ')');
     EXECUTE IMMEDIATE tmp;
     SET tmp = CONCAT('INSERT INTO SID.tables_healp VALUES ("', dbname, '", "', tablename, '", "', RAd_expr, '", "', DEd_expr, '", ', iorder, ', "healp', iorder, '")');
     EXECUTE IMMEDIATE tmp;
     CALL SID.PixelizationStats(dbname, tablename, 'HEALP', iorder);
  END//


CREATE OR REPLACE PROCEDURE AddHTMIndex(IN dbname VARCHAR(100), IN tablename VARCHAR(100), IN RAd_expr VARCHAR(500), IN DEd_expr VARCHAR(500), IN iorder INT)
  NOT DETERMINISTIC
  BEGIN
     DECLARE tmp VARCHAR(1024);
     IF LOCATE('.', RAd_expr) = 0 THEN
        SET RAd_expr = CONCAT(dbname, '.', tablename, '.', RAd_expr);
     END IF;
     IF LOCATE('.', DEd_expr) = 0 THEN
        SET DEd_expr = CONCAT(dbname, '.', tablename, '.', DEd_expr);
     END IF;
     SET tmp = CONCAT('ALTER TABLE ', dbname, '.', tablename, ' ADD COLUMN htm', iorder, ' BIGINT NOT NULL');
     EXECUTE IMMEDIATE tmp;
     SET tmp = CONCAT('UPDATE ', dbname, '.', tablename, ' SET htm', iorder, ' = HTMLookup(', iorder, ', ', RAd_expr, ', ', DEd_expr, ')');
     EXECUTE IMMEDIATE tmp;
     SET tmp = CONCAT('CREATE INDEX htm', iorder, ' ON ', dbname, '.', tablename, ' (htm', iorder, ')');
     EXECUTE IMMEDIATE tmp;
     SET tmp = CONCAT('INSERT INTO SID.tables_htm VALUES ("', dbname, '", "', tablename, '", "', RAd_expr, '", "', DEd_expr, '", ', iorder, ', "htm', iorder, '")');
     EXECUTE IMMEDIATE tmp;
     CALL SID.PixelizationStats(dbname, tablename, 'HTM', iorder);
  END//


CREATE OR REPLACE PROCEDURE DropHEALPIndex(IN pdbname VARCHAR(100), IN ptablename VARCHAR(100), IN piorder INT DEFAULT NULL)
  NOT DETERMINISTIC
  BEGIN
     DECLARE tmp VARCHAR(1024);
     CALL SID.InitSearch(pdbname, ptablename, 'HEALP', piorder);
     SET tmp = CONCAT('ALTER TABLE ', @SID_dbname, '.', @SID_tablename, ' DROP COLUMN ', @SID_pixid_field);
     EXECUTE IMMEDIATE tmp;
     SET tmp = CONCAT('DELETE FROM SID.tables_healp WHERE dbname="', @SID_dbname, '" AND tablename="', @SID_tablename, '" AND pixid_field="', @SID_pixid_field, '"');
     EXECUTE IMMEDIATE tmp;
  END//


CREATE OR REPLACE PROCEDURE DropHTMIndex(IN pdbname VARCHAR(100), IN ptablename VARCHAR(100), IN piorder INT DEFAULT NULL)
  NOT DETERMINISTIC
  BEGIN
     DECLARE tmp VARCHAR(1024);
     CALL SID.InitSearch(pdbname, ptablename, 'HTM', piorder);
     SET tmp = CONCAT('ALTER TABLE ', @SID_dbname, '.', @SID_tablename, ' DROP COLUMN ', @SID_pixid_field);
     EXECUTE IMMEDIATE tmp;
     SET tmp = CONCAT('DELETE FROM SID.tables_htm WHERE dbname="', @SID_dbname, '" AND tablename="', @SID_tablename, '" AND pixid_field="', @SID_pixid_field, '"');
     EXECUTE IMMEDIATE tmp;
  END//

delimiter ;
