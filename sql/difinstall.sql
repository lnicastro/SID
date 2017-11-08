-- Install in DIF2 db

create database if not exists DIF2;

USE DIF2;

DROP FUNCTION IF EXISTS HTMLookup;
DROP FUNCTION IF EXISTS HTMidByName;
DROP FUNCTION IF EXISTS HTMnameById;
DROP FUNCTION IF EXISTS HTMBary;
DROP FUNCTION IF EXISTS HTMBaryC;
DROP FUNCTION IF EXISTS HTMNeighb;
DROP FUNCTION IF EXISTS HTMsNeighb;
DROP FUNCTION IF EXISTS HTMNeighbC;
DROP FUNCTION IF EXISTS HTMBaryDist;

DROP FUNCTION IF EXISTS DIFCircleHTM;
DROP FUNCTION IF EXISTS DIFRectHTM;
DROP FUNCTION IF EXISTS DIFRectvHTM;

DROP FUNCTION IF EXISTS HEALPLookup;
DROP FUNCTION IF EXISTS HEALPMaxS;
DROP FUNCTION IF EXISTS HEALPBaryDist;
DROP FUNCTION IF EXISTS HEALPBary;
DROP FUNCTION IF EXISTS HEALPBaryC;
DROP FUNCTION IF EXISTS HEALPNeighb;
DROP FUNCTION IF EXISTS HEALPNeighbC;
DROP FUNCTION IF EXISTS HEALPBound;
DROP FUNCTION IF EXISTS HEALPBoundC;

DROP FUNCTION IF EXISTS DIFCircleHEALP;
DROP FUNCTION IF EXISTS DIFRectHEALP;
DROP FUNCTION IF EXISTS DIFRectvHEALP;

DROP FUNCTION IF EXISTS DIFCount;
DROP FUNCTION IF EXISTS DIFGetID;
DROP FUNCTION IF EXISTS DIFClear;
DROP FUNCTION IF EXISTS Sphedist;

create function HTMLookup returns INT soname 'udf_dif.so';
create function HTMidByName returns INT soname 'udf_dif.so';
create function HTMnameById returns STRING soname 'udf_dif.so';
create function HTMBary returns STRING soname 'udf_dif.so';
create function HTMBaryC returns STRING soname 'udf_dif.so';
create function HTMNeighb returns STRING soname 'udf_dif.so';
create function HTMsNeighb returns STRING soname 'udf_dif.so';
create function HTMNeighbC returns STRING soname 'udf_dif.so';
create function HTMBaryDist returns REAL soname 'udf_dif.so';

create function DIFCircleHTM returns STRING soname 'udf_dif.so';
create function DIFRectHTM returns STRING soname 'udf_dif.so';
create function DIFRectvHTM returns STRING soname 'udf_dif.so';

create function HEALPLookup returns INT soname 'udf_dif.so';
create function HEALPMaxS returns REAL soname 'udf_dif.so';
create function HEALPBaryDist returns REAL soname 'udf_dif.so';
create function HEALPBary returns STRING soname 'udf_dif.so';
create function HEALPBaryC returns STRING soname 'udf_dif.so';
create function HEALPNeighb returns STRING soname 'udf_dif.so';
create function HEALPNeighbC returns STRING soname 'udf_dif.so';
create function HEALPBound returns STRING soname 'udf_dif.so';
create function HEALPBoundC returns STRING soname 'udf_dif.so';

create function DIFCircleHEALP returns STRING soname 'udf_dif.so';
create function DIFRectHEALP returns STRING soname 'udf_dif.so';
create function DIFRectvHEALP returns STRING soname 'udf_dif.so';

create function DIFCount returns INT soname 'udf_dif.so';
create function DIFGetID returns INT soname 'udf_dif.so';
create function DIFClear returns INT soname 'udf_dif.so';
create function Sphedist returns REAL soname 'udf_dif.so';

delimiter //

DROP PROCEDURE IF EXISTS difrectpixelsHTM//
CREATE PROCEDURE  difrectpixelsHTM(IN depth INTEGER, IN ra FLOAT, IN de FLOAT, IN side_ra FLOAT, IN side_de FLOAT)
  DETERMINISTIC
  BEGIN
    DECLARE i, countp, countf INTEGER;
    DECLARE p CHAR(16);

    SET p = DIFRectHTM(depth, ra, de, side_ra, side_de);
    SET countf = DIFCount(p, 1);
    SET countp = DIFCount(p, 0);

    IF (countf != 0 OR countp != 0) THEN
      DROP TABLE IF EXISTS dif_temp;
      CREATE TEMPORARY TABLE dif_temp (param INT not null, id BIGINT not null, full TINYINT not null);
    END IF;

    SET i = 0;
    WHILE i < countf DO
      INSERT INTO dif_temp VALUES (depth, DIFGetID(p, i, 1), 1);
      SET i = i + 1;
    END WHILE;

    SET i = 0;
    WHILE i < countp DO
      INSERT INTO dif_temp VALUES (depth, DIFGetID(p, i, 0), 0);
      SET i = i + 1;
    END WHILE;

  set p = DIFClear(p);
  
  END//


DROP PROCEDURE IF EXISTS difcircpixelsHTM//
CREATE PROCEDURE  difcircpixelsHTM(IN depth INTEGER, IN ra FLOAT, IN de FLOAT, IN rad FLOAT)
  DETERMINISTIC
  BEGIN
    DECLARE i, countp, countf INTEGER;
    DECLARE p CHAR(16);
    DECLARE db VARCHAR(64);

    SET p = DIFCircleHTM(depth, ra, de, rad);
    SET countf = DIFCount(p, 1);
    SET countp = DIFCount(p, 0);

    IF (countf != 0 OR countp != 0) THEN
      DROP TABLE IF EXISTS dif_temp;
      CREATE TEMPORARY TABLE dif_temp (param INT not null, id BIGINT not null, full TINYINT not null);
    END IF;

    SET i = 0;
    WHILE i < countf DO
      INSERT INTO dif_temp VALUES (depth, DIFGetID(p, i, 1), 1);
      SET i = i + 1;
    END WHILE;

    SET i = 0;
    WHILE i < countp DO
      INSERT INTO dif_temp VALUES (depth, DIFGetID(p, i, 0), 0);
      SET i = i + 1;
    END WHILE;

  set p = DIFClear(p);
  END//


DROP PROCEDURE IF EXISTS difrectpixelsHEALP//
CREATE PROCEDURE  difrectpixelsHEALP(IN nested INTEGER, IN ord INTEGER, IN ra FLOAT, IN de FLOAT, IN side_ra FLOAT, IN side_de FLOAT)
  DETERMINISTIC
  BEGIN
    DECLARE i, countp, countf INTEGER;
    DECLARE p CHAR(16);

    SET p = DIFRectHEALP(nested, ord, ra, de, side_ra, side_de);
    SET countf = DIFCount(p, 1);
    SET countp = DIFCount(p, 0);

    IF (countf != 0 OR countp != 0) THEN
      DROP TABLE IF EXISTS dif_temp;
      CREATE TEMPORARY TABLE dif_temp (param INT not null, id BIGINT not null, full TINYINT not null);
    END IF;

    SET i = 0;
    WHILE i < countf DO
      INSERT INTO dif_temp VALUES (ord, DIFGetID(p, i, 1), 1);
      SET i = i + 1;
    END WHILE;

    SET i = 0;
    WHILE i < countp DO
      INSERT INTO dif_temp VALUES (ord, DIFGetID(p, i, 0), 0);
      SET i = i + 1;
    END WHILE;

  set p = DIFClear(p);
  
  END//


DROP PROCEDURE IF EXISTS difcircpixelsHEALP//
CREATE PROCEDURE  difcircpixelsHEALP(IN nested INTEGER, IN ord INTEGER, IN ra FLOAT, IN de FLOAT, IN rad FLOAT)
  DETERMINISTIC
  BEGIN
    DECLARE i, countp, countf INTEGER;
    DECLARE p CHAR(16);

    SET p = DIFCircleHEALP(nested, ord, ra, de, rad);
    SET countf = DIFCount(p, 1);
    SET countp = DIFCount(p, 0);

    IF (countf != 0 OR countp != 0) THEN
      DROP TABLE IF EXISTS dif_temp;
      CREATE TEMPORARY TABLE dif_temp (param INT not null, id BIGINT not null, full TINYINT not null);
    END IF;

    SET i = 0;
    WHILE i < countf DO
      INSERT INTO dif_temp VALUES (ord, DIFGetID(p, i, 1), 1);
      SET i = i + 1;
    END WHILE;

    SET i = 0;
    WHILE i < countp DO
      INSERT INTO dif_temp VALUES (ord, DIFGetID(p, i, 0), 0);
      SET i = i + 1;
    END WHILE;

  set p = DIFClear(p);
  
  END//

delimiter ;
