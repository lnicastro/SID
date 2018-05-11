delimiter //

DROP PROCEDURE IF EXISTS rectpixelsHTM//
CREATE PROCEDURE  rectpixelsHTM(IN depth INTEGER, IN ra FLOAT, IN de FLOAT, IN side_ra FLOAT, IN side_de FLOAT)
  DETERMINISTIC
  BEGIN
    DECLARE i, countp, countf INTEGER;
    DECLARE p CHAR(16);

    SET p = SIDRectHTM(depth, ra, de, side_ra, side_de);
    SET countf = SIDCount(p, 1);
    SET countp = SIDCount(p, 0);

    IF (countf != 0 OR countp != 0) THEN
      DROP TABLE IF EXISTS sid_temp;
      CREATE TEMPORARY TABLE sid_temp (param INT not null, id BIGINT not null, full TINYINT not null);
    END IF;

    SET i = 0;
    WHILE i < countf DO
      INSERT INTO sid_temp VALUES (depth, SIDGetID(p, i, 1), 1);
      SET i = i + 1;
    END WHILE;

    SET i = 0;
    WHILE i < countp DO
      INSERT INTO sid_temp VALUES (depth, SIDGetID(p, i, 0), 0);
      SET i = i + 1;
    END WHILE;

  set p = SIDClear(p);
  
  END//


DROP PROCEDURE IF EXISTS sidcircpixelsHTM//
CREATE PROCEDURE  sidcircpixelsHTM(IN depth INTEGER, IN ra FLOAT, IN de FLOAT, IN rad FLOAT)
  DETERMINISTIC
  BEGIN
    DECLARE i, countp, countf INTEGER;
    DECLARE p CHAR(16);
    DECLARE db VARCHAR(64);

    SET p = SIDCircleHTM(depth, ra, de, rad);
    SET countf = SIDCount(p, 1);
    SET countp = SIDCount(p, 0);

    IF (countf != 0 OR countp != 0) THEN
      DROP TABLE IF EXISTS sid_temp;
      CREATE TEMPORARY TABLE sid_temp (param INT not null, id BIGINT not null, full TINYINT not null);
    END IF;

    SET i = 0;
    WHILE i < countf DO
      INSERT INTO sid_temp VALUES (depth, SIDGetID(p, i, 1), 1);
      SET i = i + 1;
    END WHILE;

    SET i = 0;
    WHILE i < countp DO
      INSERT INTO sid_temp VALUES (depth, SIDGetID(p, i, 0), 0);
      SET i = i + 1;
    END WHILE;

  set p = SIDClear(p);
  END//


DROP PROCEDURE IF EXISTS sidrectpixelsHEALP//
CREATE PROCEDURE  sidrectpixelsHEALP(IN nested INTEGER, IN ord INTEGER, IN ra FLOAT, IN de FLOAT, IN side_ra FLOAT, IN side_de FLOAT)
  DETERMINISTIC
  BEGIN
    DECLARE i, countp, countf INTEGER;
    DECLARE p CHAR(16);

    SET p = SIDRectHEALP(nested, ord, ra, de, side_ra, side_de);
    SET countf = SIDCount(p, 1);
    SET countp = SIDCount(p, 0);

    IF (countf != 0 OR countp != 0) THEN
      DROP TABLE IF EXISTS sid_temp;
      CREATE TEMPORARY TABLE sid_temp (param INT not null, id BIGINT not null, full TINYINT not null);
    END IF;

    SET i = 0;
    WHILE i < countf DO
      INSERT INTO sid_temp VALUES (ord, SIDGetID(p, i, 1), 1);
      SET i = i + 1;
    END WHILE;

    SET i = 0;
    WHILE i < countp DO
      INSERT INTO sid_temp VALUES (ord, SIDGetID(p, i, 0), 0);
      SET i = i + 1;
    END WHILE;

  set p = SIDClear(p);
  
  END//


DROP PROCEDURE IF EXISTS sidcircpixelsHEALP//
CREATE PROCEDURE  sidcircpixelsHEALP(IN nested INTEGER, IN ord INTEGER, IN ra FLOAT, IN de FLOAT, IN rad FLOAT)
  DETERMINISTIC
  BEGIN
    DECLARE i, countp, countf INTEGER;
    DECLARE p CHAR(16);

    SET p = SIDCircleHEALP(nested, ord, ra, de, rad);
    SET countf = SIDCount(p, 1);
    SET countp = SIDCount(p, 0);

    IF (countf != 0 OR countp != 0) THEN
      DROP TABLE IF EXISTS sid_temp;
      CREATE TEMPORARY TABLE sid_temp (param INT not null, id BIGINT not null, full TINYINT not null);
    END IF;

    SET i = 0;
    WHILE i < countf DO
      INSERT INTO sid_temp VALUES (ord, SIDGetID(p, i, 1), 1);
      SET i = i + 1;
    END WHILE;

    SET i = 0;
    WHILE i < countp DO
      INSERT INTO sid_temp VALUES (ord, SIDGetID(p, i, 0), 0);
      SET i = i + 1;
    END WHILE;

  set p = SIDClear(p);
  
  END//

delimiter ;
