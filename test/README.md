## SID use cases

The catalogue `ascc25_initial` is available [here](https://ross2.oas.inaf.it/test-data/ascc25_initial.sql.gz).
Download, unzip and source the file from a MySQL DB of your choice. You must have run `source sid-demo.sql` too.
```sql
mysql> select sphedist(0.0, 0.0, RAmas/3.6e6, DECmas/3.6e6) as sep_arcmin from ascc25_initial limit 3;
  127.60125208174289 
   82.41573882094784
  202.7321211712147

mysql> CALL SID.CreateCircle_HTM(6, 10, 20, 100);
mysql> SELECT * FROM SID.sid;
mysql> CALL SID.CreateCircle_HEALP(10, 10, 20, 10);
mysql> SELECT * FROM SID.sid;
```

Use the ASCC 2.5 catalogue:
```sql
mysql> select * from ascc25_initial limit 3;
+-------+-----------+----------+----------+-----------+-------+-------+---------+------------+---------------+
| RAmas | DECmas    | EP00000c | RAPMdmas | DECPMdmas | Bmm   | Vmm   | FLAGvar | MASTERhpx6 | runningnumber |
+-------+-----------+----------+----------+-----------+-------+-------+---------+------------+---------------+
| 40130 |  -7655970 |  9125000 |       -4 |        65 | 12500 | 12240 |       0 |      17404 |             1 |
| 56640 |  -4944620 |  9125000 |     1305 |       332 | 12810 | 13130 |       0 |      17404 |             2 |
| 89280 | -12163600 |  9125000 |      174 |       -19 | 11420 | 10370 |       0 |      17395 |             1 |
+-------+-----------+----------+----------+-----------+-------+-------+---------+------------+---------------+

mysql> select healplookup(1,6, RAmas/3.6e6, DECmas/3.6e6) as hpx6, htmlookup(6, RAmas/3.6e6, DECmas/3.6e6) as htm6
       from ascc25_initial limit 3;
+-------+-------+
| hpx6  | htm6  |
+-------+-------+
| 17404 | 32769 |
| 17404 | 32768 |
| 17395 | 32774 |
+-------+-------+
```

Let's create a new `ascc25` table and use it (the `mysql>` prompt is omitted):
```sql
CREATE TABLE ascc25 SELECT RAmas, DECmas, RAPMdmas, DECPMdmas, Bmm, Vmm, FLAGvar FROM ascc25_initial;
ALTER TABLE ascc25 ADD COLUMN htm6 SMALLINT UNSIGNED NOT NULL, ENGINE=MyISAM;

SELECT COUNT(*) FROM ascc25;
  2501313

UPDATE ascc25 SET htm6 = HTMLookup(6, RAmas/3.6e6, DECmas/3.6e6);
ALTER TABLE ascc25 ADD COLUMN healp10 INT UNSIGNED NOT NULL;
UPDATE ascc25 SET healp10 = HEALPLookup(1, 10, RAmas/3.6e6, DECmas/3.6e6);
ALTER TABLE ascc25 ADD KEY (htm6), ADD KEY (healp10);
SHOW INDEX FROM ascc25;
```

Of course the two indices could be added simultaneously.
Note the `Cardinality` column values. It reports an "estimate" of the number of distinct `htm6` and `healp10` values in the table.

Now let's use the predefined demo procedures (in `sid-demo.sql`) to perform some queries on the catalogue. We assume the catalogue is in the database `Catalogs`.

```sql
CALL SID.SelectCircleHTM  ('', '*', 'Catalogs.ascc25', 'htm6'   ,  6, 'RAmas/3.6e6', 'DECmas/3.6e6', 188, -3, 10, 'LIMIT 10');

CALL SID.SelectCircleHEALP('', '*', 'Catalogs.ascc25', 'healp10', 10, 'RAmas/3.6e6', 'DECmas/3.6e6', 188, -3, 10, 'LIMIT 10');

CALL SID.SelectCircleHEALP('myregion_circ', '*', 'Catalogs.ascc25', 'healp10', 10, 'RAmas/3.6e6', 'DECmas/3.6e6', 188, -3, 10, '');
SELECT * FROM SID.myregion_circ;

CALL SID.SelectRectHEALP('myregion_rect', '*', 'Catalogs.ascc25', 'healp10', 10, 'RAmas/3.6e6', 'DECmas/3.6e6', 188, -3, 25, 38, '');
SELECT * FROM SID.myregion_rect;

CALL SID.SelectRectHEALP('myregion_rect', 'RAmas/3.6e6, DECmas/3.6e6, Vmm/1000', 'Catalogs.ascc25', 'healp10', 10, 'RAmas/3.6e6', 'DECmas/3.6e6', 188, -3, 25, 38, 'WHERE Vmm<12000');
SELECT * FROM SID.myregion_rect;

CALL SID.SelectRectvHTM('', 'RAmas/3.6e6, DECmas/3.6e6, Vmm/1000', 'Catalogs.ascc25', 'htm6', 6, 'RAmas/3.6e6', 'DECmas/3.6e6', 188, -3, 189, -2, 'WHERE Vmm<12000');

CALL SID.SelectRectvHEALP('myregion_rect', 'RAmas/3.6e6, DECmas/3.6e6, Vmm/1000', 'Catalogs.ascc25', 'healp10', 10, 'RAmas/3.6e6', 'DECmas/3.6e6', 188, -3, 189, -2, 'WHERE Vmm<12000');
SELECT * FROM SID.myregion_rect;
```

Procedure parameters are:
```
1.  (string)  Output table name. It will be located in the database SID and it is TEMPORARY
              (i.e. will removed when the DB connection is closed). Empty string means display.
2.  (string)  Fields to select.
3.  (string)  The 'DB_name.Table_name' to query.
4.  (string)  Field name of the HTM / HEALPix indexed ID.
5.  (integer) The depth / order of the index.
6.  (string)  The RA field name or its equivalent to get units in degrees.
7.  (string)  The Dec field name or its equivalent to get units in degrees.
8.  (float)   Region center RA in degrees.
9.  (float)   Region center Dec in degrees.
10. (float)   Region radius in arcmin.
    For SelectRectHTM/HEALP pass the rectangle sides length along RA and Dec.
    In the example above 25 and 38 arcmin.
    For SelectRectvHTM/HEALP pass the the RA and Dec of two opposite corners.
11. (string)  Any additional query clause (WHERE, ORDER BY, LIMIT, etc.).
```


Here we use the Tycho-2 catalogue available [here](https://ross2.iasfbo.inaf.it/test-data/tycho2.sql.gz) (the `mysql>` prompt is omitted).
```sql
ALTER TABLE tycho2 ADD COLUMN htmID_6 SMALLINT UNSIGNED NOT NULL;
UPDATE tycho2 SET htmID_6 = HTMLookup(6, RAmas/3.6e6, DECmas/3.6e6);
ALTER TABLE tycho2 ADD KEY (htmID_6);

CALL SID.SelectCircleHTM('', '*', 'Catalogs.tycho2', 'htmID_6',  6, 'RAmas/3.6e6', 'DECmas/3.6e6', 188, -3, 10, 'LIMIT 10');

CALL SID.SelectCircleHTM('myregion', 'RAmas, DECmas, VTmm', 'Catalogs.tycho2', 'htmID_6',  6, 'RAmas/3.6e6', 'DECmas/3.6e6', 188, -3, 30, '');
SELECT * FROM SID.myregion;

CALL SID.SelectRectHTM('myregion', 'RAmas, DECmas, VTmm', 'Catalogs.tycho2', 'htmID_6',  6, 'RAmas/3.6e6', 'DECmas/3.6e6', 188, -3, 30, 20, '');
SELECT * FROM SID.myregion;
```
