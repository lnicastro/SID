## SID use cases

**Test generic SID functions**: HEALPlookup, HTMlookup, sphedist, ...
```
mysql> select sphedist(0.0, 0.0, RAmas/3.6e6, DECmas/3.6e6) as sep_arcmin from ascc25_initial limit 3;
+--------------------+
| sep_arcmin         |
+--------------------+
| 127.60125208174289 |
|  82.41573882094784 |
|  202.7321211712147 |
+--------------------+

mysql> CALL CreateCircle_HTM(6, 10, 20, 100);   SELECT * FROM SID.sid;
mysql> CALL CreateCircle_HEALP(10, 10, 20, 10); SELECT * FROM SID.sid;
```

Use the ASCC 2.5 catalogue

```
mysql> select * from ascc25_initial limit 3;
+-------+-----------+----------+----------+-----------+-------+-------+---------+------------+---------------+
| RAmas | DECmas    | EP00000c | RAPMdmas | DECPMdmas | Bmm   | Vmm   | FLAGvar | MASTERhpx6 | runningnumber |
+-------+-----------+----------+----------+-----------+-------+-------+---------+------------+---------------+
| 40130 |  -7655970 |  9125000 |       -4 |        65 | 12500 | 12240 |       0 |      17404 |             1 |
| 56640 |  -4944620 |  9125000 |     1305 |       332 | 12810 | 13130 |       0 |      17404 |             2 |
| 89280 | -12163600 |  9125000 |      174 |       -19 | 11420 | 10370 |       0 |      17395 |             1 |
+-------+-----------+----------+----------+-----------+-------+-------+---------+------------+---------------+

mysql> select healplookup(1,6, RAmas/3.6e6, DECmas/3.6e6) as hpx6, htmlookup(6, RAmas/3.6e6, DECmas/3.6e6) as htm6 from ascc25_initial limit 3;
+-------+-------+
| hpx6  | htm6  |
+-------+-------+
| 17404 | 32769 |
| 17404 | 32768 |
| 17395 | 32774 |
+-------+-------+
```

Let's create a new table and use it.
```
mysql> CREATE TABLE ascc25 SELECT RAmas, DECmas, RAPMdmas, DECPMdmas, Bmm, Vmm, FLAGvar FROM ascc25_initial;
mysql> ALTER TABLE ascc25 ADD COLUMN htm6 SMALLINT UNSIGNED NOT NULL;
mysql> UPDATE ascc25 SET htm6 = HTMLookup(6, RAmas/3.6e6, DECmas/3.6e6);
mysql> ALTER TABLE ascc25 ADD KEY (htm6);
mysql> ALTER TABLE ascc25 ADD COLUMN healp10 INT UNSIGNED NOT NULL;
mysql> UPDATE ascc25 SET healp10 = HEALPLookup(1, 10, RAmas/3.6e6, DECmas/3.6e6);
mysql> ALTER TABLE ascc25 ADD KEY (healp10);
```

Of course the two indexes could be added simultaneously.
Now let's use the predefined demo procedures to perform some queries on the catalogue. 

```
mysql> CALL SID.SelectCircleHTM  ('', '*', 'Catalogs.ascc25', 'htm6'   ,  6, 'RAmas/3.6e6', 'DECmas/3.6e6', 188, -3, 10, 'LIMIT 10');
mysql> CALL SID.SelectCircleHEALP('', '*', 'Catalogs.ascc25', 'healp10', 10, 'RAmas/3.6e6', 'DECmas/3.6e6', 188, -3, 10, 'LIMIT 10');
```


Use the Tycho-2 catalogue
```
mysql> CALL SID.SelectCircleHTM  ('', '*', 'Catalogs.tycho2', 'htmID_6',  6, 'RAmas/3.6e6', 'DECmas/3.6e6', 188, -3, 10, 'LIMIT 10');
mysql> CALL SID.SelectCircleHTM  ('myregion', 'RAmas', 'Catalogs.tycho2', 'htmID_6',  6, 'RAmas/3.6e6', 'DECmas/3.6e6', 188, -3, 10, 'LIMIT 10');
```
