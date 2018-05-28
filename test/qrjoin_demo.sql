-- Use the SID created temporary index table SID.sid to perform joins with
-- an indexed (HTM or HEALPix) catalogue.
--
-- Example queries on tycho2 HTM 6 indexed (column name = htmID_6). Coords are in mas.
-- Must be in the database where the catalogue is stored.
--

-- First position. Pos in degs, radius in arcmin.

set @depth= 6;
set @ra= 10;
set @de= 20;
set @r= 30;

-- Circle
call SID.CreateCircle_HTM(@depth, @ra, @de, @r);

select * from tycho2 as t1 join SID.sid as t2 on
 (t1.htmID_6=t2.sid_id) AND (t2.sid_full=1 OR sphedist(t1.ramas/3.6e6, t1.decmas/3.6e6, @ra, @de) < @r);

-- Order by distance
select *, sphedist(t1.ramas/3.6e6, t1.decmas/3.6e6, @ra, @de) as d from
 tycho2 as t1 join SID.sid as t2 on
 (
  (t1.htmID_6=t2.sid_id) AND
  (t2.sid_full=1 OR sphedist(t1.ramas/3.6e6, t1.decmas/3.6e6, @ra, @de) < @r)
 ) order by d;


-- Rectangle. Sides in arcmin.
set @dra= 25;
set @dde= 15;

call SID.CreateRect_HTM(@depth, @ra, @de, @dra, @dde);

select * from tycho2 as t1 join SID.sid as t2 on
  (t1.htmID_6=t2.sid_id) AND
  (t2.sid_full=1 OR (t1.ramas/3.6e6 > (@ra - @dra/60) AND t1.ramas/3.6e6 < (@ra + @dra/60) AND (@de - @dde/60) > t1.decmas/3.6e6 AND t1.decmas/3.6e6 < (@de + @dde/60)));

-- Let's see the pixels IDs
select * from SID.sid;


-- Another position
set @ra= 20;
set @de= 30;
set @r= 10;

call SID.CreateCircle_HTM(@depth, @ra, @de, @r);

select *, sphedist(t1.ramas/3.6e6, t1.decmas/3.6e6, @ra, @de) as d from
 tycho2 as t1 join SID.sid as t2 on
 (
  (t1.htmID_6=t2.sid_id) AND
  (t2.sid_full=1 OR sphedist(t1.ramas/3.6e6, t1.decmas/3.6e6, @ra, @de) < @r)
 ) order by d;
