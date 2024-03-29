# SID

Spherical Indexing for relational Databases

SID is a set of tools aimed at implementing a powerful indexing system for astronomical
catalogues and other data with spherical coordinates, stored into MySQL / MariaDB databases.
SID is able to use both  [HTM](http://www.skyserver.org/htm/) and [HEALPix](http://healpix.jpl.nasa.gov/)
pixelization schemas and it allows very fast query execution even on billion-row tables. 
The library is mostly derived from [DIF](https://github.com/lnicastro/DIF), with the main
difference being its fully UDFs structure. This means that it is not necessary to install
a dedicated storage engine (like in DIF) and consequently it is not requested to use the MySQL
source code to compile SID. You only need to have the MySQL header files installed together with `mysql_config`. See e.g. the [MySQL documentation](https://dev.mysql.com/doc/refman/8.0/en/adding-functions.html).

Written to be used on Linux and Mac OS.

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.7628445.svg)](https://doi.org/10.5281/zenodo.7628445)

The current version is still a beta release, so please report any problem to the authors.
Package extended documentation is TODO.
However, because several functions are shared with DIF, you can have a look to the document [here](https://github.com/lnicastro/DIF/tree/master/doc).


## Requirements

1. MySQL / MariaDB development files
2. cmake
3. C/C++ compiler

## Compile and install

To compile and install the library:
```shell
mkdir Build
cd Build
cmake ..
make
sudo make install
```

On Mac OS, if you have compilation errors, try to use the appropriate path for the GNU `c++` (the default `/usr/bin/c++` is an alias for `clang++`), e.g.:
```shell
mkdir Build
cd Build
cmake -DCMAKE_CXX_COMPILER=/opt/local/bin/c++ ..
make

sudo make install
```

## UDFs installation

Import UDFs into MySQL (in the directory `sql`):
```shell
shell> cd ../sql
shell> mysql -u root -p

mysql> source sidinstall.sql
```

## List of functions

**Generic User Defined Functions**

 UDF         | Parameters
------------ | -------------
HTMLookup    | (d, RA, Dec)
HTMidByName  | (ID_Name)
HTMnameById  | (ID)
HTMBary      | (d, ID)
HTMBaryC     | (d, RA, Dec)
HTMBaryDist  | (d, ID, RA, Dec)
HTMNeighb    | (d, ID)
HTMsNeighb   | (d1, ID_d2, d2)
HTMNeighbC   | (d, RA, Dec)
HEALPLookup  | (s, k, RA, Dec)
HEALPMaxS    | (k)
HEALPBary    | (s, k, ID)
HEALPBaryC   | (s, k, RA, Dec)
HEALPBaryDist| (s, k, ID, RA, Dec)
HEALPNeighb  | (s, k, ID)
HEALPNeighbC | (s, k, RA, Dec)
HEALPBound   | (s, k, ID, *step*)
HEALPBoundC  | (s, k, RA, Dec, *step*)
Sphedist     | (RA1 ,Dec1, RA2, Dec2)

**SID specific User Defined Functions**

 UDF          | Parameters
------------- | -------------
SIDCount      | (p, full)
SIDGetID      | (p, i, full)
SIDClear      | ()
SIDCircleHTM  | (RA, Dec, r)
SIDRectHTM    | (RA, Dec, s1, *s2*)
SIDRectvHTM   | (RA1, Dec1, ...)
SIDCircleHEALP| (RA, Dec)
SIDRectHEALP  | (*var*)
SIDRectvHEALP | (RA1, Dec1, RA2, Dec2)

Note that SID specific UDFs are not meant to be used directly in SQL commands, but rather within stored procedures
like those you can find in `sid-demo.sql` (see below).

## Test installation

**Test some SID functions**: sphedist, HEALPLookup, HTMLookup, etc.
Note that several functions are shared with DIF and are documented [here](https://github.com/lnicastro/DIF/tree/master/doc).
Input sky coordinates units are degrees.  

Spherical distance of two points, e.g. at coordinates (0,0) (1,1) - output is in arcmin:
```sql
mysql> select sphedist(0.0, 0.0, 1.0, 1.0) as d_arcmin;
       84.85065965712684
```

HEALPix pixel max size (in arcmin), from center to corner at a given order:
```sql
mysql> select HealPMaxS(8);
       14.34420720055738
```

Lookup ID of a sky point (20,30) for HTM and HEALPix (nested scheme) depth / order (here depth=6 and order=8):
```sql
mysql> select HTMLookup(6, 20,30);
       64152

mysql> select HEALPLookup(1,8, 20,30);
       35178
```

HEALPix barycenter (center) coordinates for a given scheme, order and pixel ID:
```sql
mysql> select HEALPBary(1,8, 500);
       48.1640625, 6.429418462523309
```

IDs of the HEALPix pixels touching a given pixel ID (neighbors):
```sql
mysql> select HEALPNeighb(0,8, 1000) as nids_ring;
       1091, 999, 912, 829, 913, 1001, 1092, 1187

mysql> select HEALPNeighb(1,8, 1000) as nids_nest;
       957, 959, 1002, 1003, 1001, 995, 994, 951
```

IDs of the HTM trixels touching a given pixel ID (neighbors):
```sql
mysql> select HTMNeighb(6, 32768);
       32769, 32770, 32771, 47104, 47106, 47107, 49152, 63488, 63489, 63491
```

See the documentation (TODO) and the [test](test) directory for more examples.

## Demo procedures

Import into MySQL the pre-defined SID demo procedures (in the directory `sql`):
```sql
mysql> source sid-demo.sql
```

Main provided procedures are:

 Name             | Input Parameters
----------------- | ----------------
CreateCircle_HTM  | (depth, ra, de, radius)
CreateCircle_HEALP| (order, ra, de, radius)
CreateRect_HTM    | (depth, ra, de, side_ra, side_dec)
CreateRect_HEALP  | (order, ra, de, side_ra, side_dec)
SelectCircleHTM   | (dest, fieldList, mainTable, indexField, indexDepth, raField, deField, ra, de, radius, extra_clause)
SelectCircleHEALP | (dest, fieldList, mainTable, indexField, indexOrder, raField, deField, ra, de, radius, extra_clause)
SelectRectHTM     | (dest, fieldList, mainTable, indexField, indexDepth, raField, deField, ra, de, r1, r2, extra_clause)
SelectRectHEALP   | (dest, fieldList, mainTable, indexField, indexOrder, raField, deField, ra, de, r1, r2, extra_clause)
SelectRectvHTM    | (dest, fieldList, mainTable, indexField, indexDepth, raField, deField, ra1, de1, ra2, de2, extra_clause)
SelectRectvHEALP  | (dest, fieldList, mainTable, indexField, indexOrder, raField, deField, ra1, de1, ra2, de2, extra_clause)

Note that stored procedures are bounded to the database where you define them. In our case the database is `SID`.

For some use cases see the [test](test) directory.

## A test catalogue
Download the reduced version of the [ASCC 2.5](https://ross2.oas.inaf.it/test-data/ascc25_initial.sql.gz) star catalogue in a working directory, say `sid_data`. From a terminal:
```shell
shell> mkdir ~/sid_data
shell> cd ~/sid_data
shell> wget https://ross2.oas.inaf.it/test-data/ascc25_initial.sql.gz
shell> gunzip ascc25_initial.sql.gz
```

Load the data into a database of your choice, e.g. `Catalogs`:
```sql
mysql> create database Catalogs;
mysql> use Catalogs;
mysql> source ~/sid_data/ascc25_initial.sql
mysql> describe ascc25_initial;
+---------------+-----------------------+------+-----+---------+-------+
| Field         | Type                  | Null | Key | Default | Extra |
+---------------+-----------------------+------+-----+---------+-------+
| RAmas         | int(10) unsigned      | NO   |     | 0       |       |
| DECmas        | int(11)               | NO   |     | 0       |       |
| EP00000c      | mediumint(8) unsigned | NO   |     | 0       |       |
| RAPMdmas      | smallint(6)           | NO   |     | 0       |       |
| DECPMdmas     | smallint(6)           | NO   |     | 0       |       |
| Bmm           | mediumint(9)          | NO   |     | 0       |       |
| Vmm           | mediumint(9)          | NO   |     | 0       |       |
| FLAGvar       | tinyint(1)            | NO   |     | 0       |       |
| MASTERhpx6    | smallint(5) unsigned  | NO   |     | 0       |       |
| runningnumber | int(10) unsigned      | NO   |     | 0       |       |
+---------------+-----------------------+------+-----+---------+-------+
```
A reduced version of the Tycho-2 catalogue is also available [here](https://ross2.oas.inaf.it/test-data/tycho2.sql.gz), but any set of data with spherical coordinates can be used.

See use cases in the [test](test) directory.
