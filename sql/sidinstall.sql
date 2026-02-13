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


DROP PROCEDURE IF EXISTS InitSearch//
CREATE PROCEDURE InitSearch(IN pdbtable VARCHAR(500), IN plibrary VARCHAR(20) DEFAULT 'HEALP', IN piorder INT DEFAULT NULL)
  NOT DETERMINISTIC
  BEGIN
  IF plibrary NOT IN ('HTM', 'HEALP') THEN
    SIGNAL SQLSTATE 'HY000' SET MESSAGE_TEXT = 'Supported libraries are "HTM" and "HEALP"';
  END IF;

  DROP TABLE IF EXISTS SID.regions_full;
  CREATE TEMPORARY TABLE SID.regions_full (SID_region BIGINT, SID_pixid BIGINT NOT NULL);
  DROP TABLE IF EXISTS SID.regions_cone;
  CREATE TEMPORARY TABLE SID.regions_cone (SID_region BIGINT, SID_pixid BIGINT NOT NULL, RAd DOUBLE NOT NULL, DEd DOUBLE NOT NULL, radius_arcmin DOUBLE NOT NULL);
  DROP TABLE IF EXISTS SID.regions_rect;
  CREATE TEMPORARY TABLE SID.regions_rect (SID_region BIGINT, SID_pixid BIGINT NOT NULL, RAd1 DOUBLE NOT NULL, DEd1 DOUBLE NOT NULL, RAd2 DOUBLE NOT NULL, DEd2 DOUBLE NOT NULL);

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
      INSERT INTO SID.regions_full VALUES (region, SIDGetID(p, i, 1));
      SET i = i + 1;
    END WHILE;
  END//


DROP PROCEDURE IF EXISTS AddCone//
CREATE PROCEDURE AddCone(IN region BIGINT, IN ra DOUBLE, IN de DOUBLE, IN radius_arcmin DOUBLE)
  NOT DETERMINISTIC
  BEGIN
    DECLARE p CHAR(16);
    DECLARE i, cc INTEGER;
    IF @SID_library = 'HTM' THEN
        SET p = SIDCircleHTM(     @SID_iorder, ra, de, radius_arcmin);
    ELSE
        SET p = SIDCircleHEALP(1, @SID_iorder, ra, de, radius_arcmin); -- 1 means NESTED
    END IF;
    CALL _AddFullPixels(region, p);
    SET cc = SIDCount(p, 0);
    SET i = 0;
    WHILE i < cc DO
      INSERT INTO SID.regions_cone VALUES (region, SIDGetID(p, i, 0), ra, de, radius_arcmin);
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
      INSERT INTO SID.regions_rect VALUES (region, SIDGetID(p, i, 0), ra1, de1, ra2, de2);
      SET i = i + 1;
    END WHILE;
    SET p = SIDClear(p);
  END//


DROP FUNCTION IF EXISTS get_query//
CREATE FUNCTION get_query()
  RETURNS LONGTEXT
  NOT DETERMINISTIC
  BEGIN
    DECLARE soutput VARCHAR(1000) DEFAULT "";
    DECLARE tmp BIGINT;

    SET tmp = NULL;
    SELECT sid_pixid INTO tmp FROM SID.regions_full LIMIT 1;
    IF tmp IS NOT NULL THEN
        SET soutput = CONCAT(         'SELECT ', @SID_dbtable, '.*, SID.regions_full.SID_region FROM ', @SID_dbtable);
        SET soutput = CONCAT(soutput, '  INNER JOIN SID.regions_full ON ', @SID_dbtable, '.', @SID_pixid_field, '=SID.regions_full.sid_pixid\n');
    END IF;

    SET tmp = NULL;
    SELECT sid_pixid INTO tmp FROM SID.regions_cone LIMIT 1;
    IF tmp IS NOT NULL THEN
      IF LENGTH(soutput) > 0 THEN
          SET soutput = CONCAT(soutput, 'UNION\n');
      END IF;
      SET soutput = CONCAT(soutput, 'SELECT ', @SID_dbtable, '.*, SID.regions_cone.SID_region FROM ', @SID_dbtable);
      SET soutput = CONCAT(soutput, '  INNER JOIN SID.regions_cone ON ', @SID_dbtable, '.', @SID_pixid_field, '=SID.regions_cone.sid_pixid AND\n');
      SET soutput = CONCAT(soutput, ' (Sphedist(', @SID_RAd_field, ', ', @SID_DEd_field, ', SID.regions_cone.RAd, SID.regions_cone.DEd) <= SID.regions_cone.radius_arcmin)\n');
    END IF;

    SET tmp = NULL;
    SELECT sid_pixid INTO tmp FROM SID.regions_rect LIMIT 1;
    IF tmp IS NOT NULL THEN
      IF LENGTH(soutput) > 0 THEN
          SET soutput = CONCAT(soutput, 'UNION\n');
      END IF;
      SET soutput = CONCAT(soutput, 'SELECT ', @SID_dbtable, '.*, SID.regions_rect.SID_region FROM ', @SID_dbtable);
      SET soutput = CONCAT(soutput, '  INNER JOIN SID.regions_rect ON ', @SID_dbtable, '.', @SID_pixid_field, '=SID.regions_rect.sid_pixid AND\n');
      SET soutput = CONCAT(soutput, '  ((', @SID_RAd_field, ' BETWEEN SID.regions_rect.RAd1 AND SID.regions_rect.RAd2) AND ');
      SET soutput = CONCAT(soutput, '   (', @SID_DEd_field, ' BETWEEN SID.regions_rect.DEd1 AND SID.regions_rect.DEd2))');
    END IF;

    IF LENGTH(soutput) = 0 THEN
        SET soutput = CONCAT('SELECT ', @SID_dbtable, '.*, NULL AS SID_region FROM ', @SID_dbtable, ' LIMIT 0');
    END IF;

    RETURN soutput;
  END//

delimiter ;


CREATE TABLE SID.Messier (
	M int NOT NULL,
	Type CHAR(2) DEFAULT '**',
	Const CHAR(3) DEFAULT '***',
	Mag FLOAT,
	Ra  FLOAT,
	Decl FLOAT,
	Dist CHAR(20),
	App_size CHAR(20) DEFAULT 'unknown'
);

INSERT INTO `Messier` VALUES
(1,'BN','Tau',8.2,83.625,22.0167,'6.3 kly','6\'x4\''),
(2,'GC','Aqu',6.3,323.375,-0.816667,'36.2 kly','12.9\''),
(3,'GC','CVn',6.3,205.549,28.3833,'30.6 kly','16.2\''),
(4,'GC','Sco',6.4,245.876,-25.475,'6.8 kly','26.3\''),
(5,'GC','Ser',6.2,229.65,2.08333,'22.8 kly','17.4\''),
(6,'OC','Sco',4.2,265.099,-31.77,'2 kly','33\''),
(7,'OC','Sco',4.1,268.474,-33.2167,NULL,'80.0\''),
(8,'BN','Sag',6,271.025,-23.7,'5200 ly','90\'x40\''),
(9,'GC','Oph',7.3,259.8,-17.4833,'26.4 kly','9.3\''),
(10,'GC','Oph',6.7,254.299,-3.9,'13.4 kly','15.1\''),
(11,'OC','Scu',6.3,282.776,-5.73333,'6 kly','14.0\''),
(12,'GC','Oph',6.6,251.8,-0.0516666,'17.6 kly','14.5\''),
(13,'GC','Her',5.7,250.425,36.46,'22.2 kly','16.6\''),
(14,'GC','Oph',7.7,264.4,-2.75333,'27.4 kly','11.7\''),
(15,'GC','Peg',6,322.5,12.1667,'32.6 kly','12.3\''),
(16,'OC','Ser',6.4,274.676,-12.2,'7 kly','7.0\''),
(17,'BN','Sag',7.5,275.175,-15.8333,'5000 ly','11.0\''),
(18,'OC','Sag',7.5,274.975,-16.9,'4.9(?) kly','9.0\''),
(19,'GC','Oph',6.6,255.65,-25.7317,'27.1 kly','13.5\''),
(20,'BN','Sag',9,180.6,-21.0167,'5.2 kly','OC28.0\'/BN20\'x20\''),
(21,'OC','Sag',6.5,271.151,-21.5167,'4250 ly','13.0\''),
(22,'GC','Sag',5.9,279.101,-22.0967,'10.1 kly','24.0\''),
(23,'OC','Sag',6.9,269.224,-18.9833,'2150 ly','27.0\''),
(24,'*C','Sag',4.6,274.225,-17.5167,'10 kly','90\''),
(25,'OC','Sag',6.5,277.924,-18.7667,'2 kly','40.0\''),
(26,'OC','Scu',9.3,281.299,-8.61667,'5 kly','15.0\''),
(27,'PN','Vul',7.4,299.9,22.7217,'1250 ly','8.0\'x5.7\''),
(28,'GC','Sag',7.3,276.15,-23.13,'17.9 kly','11.2\''),
(29,'OC','Cyg',7.1,305.974,38.5333,'4 kly','7.0\''),
(30,'GC','Cap',8.4,325.099,-22.8217,'24.8 kly','11.0\''),
(31,'GX','And',4.8,10.675,41.2683,'2.2 Mly','192.4\'x62.2\''),
(32,'GX','And',8.7,10.675,40.865,'2.2 Mly','8.7\'x6.4\''),
(33,'GX','Tri',6.7,23.45,30.66,'2.3 Mly','65.6\'x38.0\''),
(34,'OC','Per',5.5,40.525,42.75,'1.4 kly','35.0\''),
(35,'OC','Gem',5.3,92.25,24.35,'2.8 kly','28.0\''),
(36,'OC','Aur',6.3,84.075,34.14,'4.1 kly','12.0\''),
(37,'OC','Aur',6.2,88.075,32.5533,'4.4 kly','24.0\''),
(38,'OC','Aur',7.4,82.1749,35.855,'4.2(?) kly','21.0\''),
(39,'OC','Cyg',5.2,323.05,48.45,'825 ly','32.0\''),
(40,'*2','UMj',9.1,185.599,58.0833,'300 ly','0.8\''),
(41,'OC','CMj',4.6,101.5,-19.245,'2.3 kly','38.0\''),
(42,'BN','Ori',4,83.75,-4.58333,'1.6 kly','85\'x60\''),
(43,'BN','Ori',9.1,83.8751,-4.725,'1.6 kly','9.1\''),
(44,'OC','Cnc',3.7,130.1,19.6667,'500 ly','95.0\''),
(45,'OC','Tau',1.6,56.875,24.105,'400 ly','110.0\''),
(46,'OC','Pup',6,115.45,-13.19,'5.4 kly','27.0\''),
(47,'OC','Pup',4.5,114.15,-13.35,'1.6 kly','30.0\''),
(48,'OC','Hyd',5.3,123.425,-4.25,'1.5 kly','54.0\''),
(49,'GX','Vir',8.5,187.451,8,'60 Mly','9.3\'x7.0\''),
(50,'OC','Mon',6.3,105.7,-7.61667,'3 kly','16.0\''),
(51,'GX','CVn',8.4,202.474,47.1967,'37 Mly','11\'x7\''),
(52,'OC','Cas',7.3,351.049,61.5833,'5.0 kly','13.0\''),
(53,'GC','Com',7.6,198.225,18.1717,'56.4 kly','12.6\''),
(54,'GC','Sag',7.6,283.775,-29.5217,'82.2 kly','9.1\''),
(55,'GC','Sag',6.3,294.949,-29.0383,'16.6 kly','19\''),
(56,'GC','Lyr',8.2,289.15,30.185,'31.6 kly','7.1\''),
(57,'PN','Lyr',9.7,283.399,33.03,'4.1 kly','86.0\"x63.0\"'),
(58,'GX','Vir',9.6,189.424,11.82,'60 Mly','5.9\'x4.7\''),
(59,'GX','Vir',9.6,190.5,11.635,'60 Mly','5.3\'x3.2\''),
(60,'GX','Vir',8.9,190.924,11.55,'60 Mly','7.4\'x6.0\''),
(61,'GX','Vir',10.1,185.475,4.47167,'60 Mly','6.5\'x5.7\''),
(62,'GC','Oph',6.6,255.3,-29.8883,'21.5 kly','14.1\''),
(63,'GX','CVn',9.5,198.949,42.035,'37 Mly','10\'x6\''),
(64,'GX','Com',8.8,194.175,21.685,'12 Mly','10.1\'x5.4\''),
(65,'GX','Leo',9.3,169.725,13.0933,'35 Mly','8\'x1.5\''),
(66,'GX','Leo',8.2,170.051,12.9917,'35 Mly','9.1\'x4.1\''),
(67,'OC','Cnc',6.9,132.85,11.8167,'2.7 kly','29.0\''),
(68,'GC','Hyd',7.3,189.875,-25.2567,'32.3 ly','11.0\''),
(69,'GC','Sag',7.7,277.849,-31.6517,'25.4 kly','10.0\''),
(70,'GC','Sag',7.8,280.8,-31.7083,'28.0 kly','8.0\''),
(71,'GC','Sgt',8.4,298.451,18.7783,'11.7 kly','7.2\''),
(72,'GC','Aqu',9.3,313.376,-11.4633,'52.8 kly','6.0\''),
(73,'**','Aqu',9,314.726,-11.365,'--','2.8\''),
(74,'GX','Psc',10.2,24.1751,15.7833,'35 kly','10.5\'x9.5\''),
(75,'GC','Sag',8.6,301.526,-20.0767,'57.7 kly','7.0\''),
(76,'PN','Per',10.1,25.575,51.575,'3.4 kly','2.7\'x1.8\''),
(77,'GX','Cet',8.9,40.675,-0.0133333,'60 Mly','7.1\'x6.0\''),
(78,'BN','Ori',10.3,86.6749,0.0583333,'1.6 kly','8\'x6\''),
(79,'GC','Lep',7.7,81.0499,-23.475,'39.8 kly','6.0\''),
(80,'GC','Sco',7.7,244.275,-21.025,'27.4 kly','8.9\''),
(81,'GX','UMj',6.8,148.9,69.0667,'11 Mly','27.1\'x14.2\''),
(82,'GX','UMj',8.4,148.975,69.6833,'11 Mly','11.3\'x4.2\''),
(83,'GX','Hyd',7.6,204.251,-28.1317,'15 Mly','12.8\'x11.4\''),
(84,'GX','Vir',9.3,186.274,12.8867,'60 Mly','6.4\'x5.5\''),
(85,'GX','Com',9.1,186.35,18.19,'60 Mly','7.1\'x5.5\''),
(86,'GX','Vir',9.7,186.55,12.9467,'60 Mly','8.9\'x5.7\''),
(87,'GX','Vir',9.2,187.699,12.39,'60 Mly','7.4\'x6.0\''),
(88,'GX','Com',10.2,188,14.4217,'60 Mly','7.0\'x3.7\''),
(89,'GX','Vir',9.5,188.925,12.5567,'60 Mly','3.5\'x3.5\''),
(90,'GX','Vir',10,189.2,13.1633,'60 Mly','9.6\'x4.3\''),
(91,'GX','Com',9.5,188.85,14.4967,'60 Mly','5.4\'x4.2\''),
(92,'GC','Her',6.5,259.275,43.1367,'26.1 kly','14.0\''),
(93,'OC','Pup',6,116.125,-22.1467,'3.6 kly','22.0\''),
(94,'GX','CVn',7.9,192.725,41.12,'14.5 Mly','14.3\'x12.1\''),
(95,'GX','Leo',10.4,160.999,11.7033,'38 Mly','7.5\'x5.0\''),
(96,'GX','Leo',9.1,161.7,11.8217,'38 Mly','7.6\'x5.2\''),
(97,'PN','UMj',9.9,168.701,55.0183,'2.6 kly','3.4\'x3.3\''),
(98,'GX','Com',11.7,183.45,14.9,'60 Mly','9.8\'x2.7\''),
(99,'GX','Com',10.1,184.7,14.4167,'60 Mly','5.4\'x4.7\''),
(100,'GX','Com',10.6,185.725,15.8233,'60 Mly','7.5\'x6.3\''),
(101,'GX','UMj',9.6,210.799,54.3483,'24 Mly','28.9\'x26.9\''),
(102,'GX','Dra',10,226.624,55.7633,'40 Mly','6.4\'x2.8\''),
(103,'OC','Cas',7.4,23.35,60.6583,'8 kly','6.0\''),
(104,'GX','Vir',8.7,190.001,-10.3767,'50 Mly','8.8\'x3.5\''),
(105,'GC','Leo',9.2,161.951,12.5817,'38 Mly','5.4\'x4.8\''),
(106,'GX','CVn',8.6,184.751,47.3283,'25 Mly','18.8\'x7.3\''),
(107,'GC','Oph',7.8,248.126,-12.9383,'19.6 kl','11.0\''),
(108,'GX','UMj',10.7,167.876,55.6717,'45 Mly','8.7\'x2.2\''),
(109,'GX','UMj',10.8,179.4,53.375,'55 Mly','7.6\'x4.6\''),
(110,'GX','And',9.4,10.1,41.6867,'2.2 Mly','21.9\'x10.9\'');
