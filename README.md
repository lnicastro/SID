# SID
Spherical Indexing for Databases

SID is a set of tools aimed at implementing a powerful indexing system for astronomical catalogs and other data with spherical coordinates, stored into MySQL / MariaDB databases. SID is able to use both HTM and HEALPix pixelization schemas and it allows very fast query execution even on billion-row tables. 

THIS IS WORK IN PROGESS !

To compile on Mac OS (use the appropriate path for `gcc / c++`):
```
cd Build
cmake -DCMAKE_C_COMPILER=/opt/local/bin/gcc -DCMAKE_CXX_COMPILER=/opt/local/bin/c++ ..
make

sudo make install
```
