-- Example queries on TYCHO2 HTM 6 indexed. Coords are in mas.
--
-- fisrt position
set @depth= 6;
set @ra= 10;
set @de= 20;
set @r= 30;

-- Circle
call DIF2.difcircpixelsHTM(@depth, @ra, @de, @r);

select * from MyCats.TYCHO2 as t1 join DIF2.dif_temp as t2 on
 (t1.htmID_6=t2.id) AND (t2.full=1 OR sphedist(t1.ramas/3.6e6, t1.decmas/3.6e6, @ra, @de) < @r);

-- order by distance
select *, sphedist(t1.ramas/3.6e6, t1.decmas/3.6e6, @ra, @de) as d from
 MyCats.TYCHO2 as t1 join DIF2.dif_temp as t2 on
 (
  (t1.htmID_6=t2.id) AND
  (t2.full=1 OR sphedist(t1.ramas/3.6e6, t1.decmas/3.6e6, @ra, @de) < @r)
 ) order by d;


-- Rectangle. Give sides in same units ar RA and Dec (i.e. mas) .
set @dra= 0.2*3.6e6;
set @dde= 0.1*3.6e6;

call DIF2.difrectpixelsHTM(@depth, @ra, @de, @dra, @dde);

select * from MyCats.TYCHO2 as t1 join DIF2.dif_temp as t2 on
  (t1.htmID_6=t2.id) AND
  (t2.full=1 OR (t1.ramas > (@ra - @dra) AND t1.ramas < (@ra + @dra) AND (@de - @dde) > t1.decmas AND t1.decmas < (@de + @dde));

-- Let's see the pixels IDs
select * from DIF2.dif_temp;


-- another position
set @ra= 20;
set @de= 30;
set @r= 10;

call DIF2.difcircpixelsHTM(@depth, @ra, @de, @r);

select *, sphedist(t1.ramas/3.6e6, t1.decmas/3.6e6, @ra, @de) as d from
 MyCats.TYCHO2 as t1 join DIF2.dif_temp as t2 on
 (
  (t1.htmID_6=t2.id) AND
  (t2.full=1 OR sphedist(t1.ramas/3.6e6, t1.decmas/3.6e6, @ra, @de) < @r)
 ) order by d;


-- second position
