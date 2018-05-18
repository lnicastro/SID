# SID
Spherical Indexing for Databases

SID is a set of tools aimed at implementing a powerful indexing system for astronomical catalogs and other data with spherical coordinates, stored into MySQL / MariaDB databases. SID is able to use both HTM and HEALPix pixelization schemas and it allows very fast query execution even on billion-row tables. 

Written to be used on Linux and Mac OS.

THIS IS WORK IN PROGESS !


## Requirements

1. MySQL / MariaDB development files
2. cmake

## Compile and install

To compile and install the library:
```
mkdir Build
cd Build
cmake ..
make
sudo make install
```

To compile on Mac OS (use the appropriate path for `gcc / c++`):
```
mkdir Build
cd Build
cmake -DCMAKE_C_COMPILER=/opt/local/bin/gcc -DCMAKE_CXX_COMPILER=/opt/local/bin/c++ ..
make

sudo make install
```

## UDFs installation
* Import UDFs into MySQL (in the directory `sql`)
        * shell> cd ../sql
        * shell> mysql -u root -p

        * mysql> source sidinstall.sql


## Test installation
1. Import into MySQL the pre-defined SID demo procedures (in the directory `sql`)
        * `mysql> source sid-demo.sql`

2. Download the [ASCC 2.5](http://ross2.iasfbo.inaf.it/test-data/ascc25_initial.sql.gz) star catalogue in a working directoy, say `sid_data`. Can also download the file manually:
```
shell> mkdir ~/sid_data
shell> cd ~/sid_data
shell> wget http://ross2.iasfbo.inaf.it/test-data/ascc25_initial.sql.gz
```

Uncompress and load the data into a database of your choice, e.g. `Catalogs`;
```
shell> cd ~/sid_data
shell> gunzip ascc25_initial.sql.gz

mysql> create database Catalogs;
mysql> use Catalogs;
mysql> source ~/sid_data/ascc25_initial.sql
mysql> describe ascc25_initial
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
10 rows in set (0.00 sec)

```

See use cases in the [test](https://github.com/lnicastro/SID/tree/master/test) directory.
