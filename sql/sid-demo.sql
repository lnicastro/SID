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

    SET p = SIDClear(p);
  END//


DROP PROCEDURE IF EXISTS CreateRect_HTM//
CREATE PROCEDURE CreateRect_HTM(IN ord INTEGER, IN ra FLOAT, IN de FLOAT, IN side_ra FLOAT, IN side_de FLOAT)
  NOT DETERMINISTIC
  BEGIN
    DECLARE p CHAR(16);
    SET p = SIDRectHTM(ord, ra, de, side_ra, side_de);
    CALL CreateRegion(p, ord);  
  END//


DROP PROCEDURE IF EXISTS CreateCircle_HTM//
CREATE PROCEDURE CreateCircle_HTM(IN ord INTEGER, IN ra FLOAT, IN de FLOAT, IN rad FLOAT)
  NOT DETERMINISTIC
  BEGIN
    DECLARE p CHAR(16);
    SET p = SIDCircleHTM(ord, ra, de, rad);
    CALL CreateRegion(p, ord);  
  END//


DROP PROCEDURE IF EXISTS CreateRect_HEALP//
CREATE PROCEDURE CreateRect_HEALP(IN ord INTEGER, IN ra FLOAT, IN de FLOAT, IN side_ra FLOAT, IN side_de FLOAT)
  NOT DETERMINISTIC
  BEGIN
    DECLARE p CHAR(16);
    SET p = SIDRectHEALP(1, ord, ra, de, side_ra, side_de);
    CALL CreateRegion(p, ord);  
  END//


DROP PROCEDURE IF EXISTS CreateCircle_HEALP//
CREATE PROCEDURE CreateCircle_HEALP(IN ord INTEGER, IN ra FLOAT, IN de FLOAT, IN rad FLOAT)
  NOT DETERMINISTIC
  BEGIN
    DECLARE p CHAR(16);
    SET p = SIDCircleHEALP(1, ord, ra, de, rad);
    CALL CreateRegion(p, ord);
  END//

delimiter ;


# call CreateCircle_HTM(6, 10, 20, 100);
# select * from sid_temp;
