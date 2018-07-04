/*
  Name:  htmRectRegion

  Purpose:

   Intersect a rectangular domain with the HTM grid returning the IDs
   of full and partial nodes. MCS - DIF custom version.
   For circular domains see 'htmCircleRegion'.

  Parameters:
   (i) int depth:     Pixelization depth
   (i) double ra[4]:  Corners Right Ascension (degrees)
   (i) double de[4]:  Corners Declination (degrees)
   (o) vector<uint64> flist: list of intersected full nodes
   (o) vector<uint64> plist: list of intersected partial nodes

  Return 0 on success.


  LN@IASF-INAF, January 2003                   ( Last change: 30/10/2008 )
*/

#include "SpatialInterface.h"

//static const int MY_DEPTH_DEF = 6;

using namespace std;

#include <vector>

int htmRectRegion(int depth, double ra[4], double dec[4],
                  vector<uint64>& flist2,
                  vector<uint64>& plist2)
{
//  int savedepth=2;              // stored depth
  ValVec<uint64> plist, flist;  // List results
  uint64 i;


  flist2.clear();
  plist2.clear();

// If out of range depth return here
//  if ((depth < 0)  ||  (depth > 25))  depth = MY_DEPTH_DEF;
  if ((depth < 0) || (depth > 25)) return -1;

  try {
    // construct index with given depth (and savedeptha?)
    //htmInterface htm(depth);  // generate htm interface
    //const SpatialIndex &index = htm.index();
    const SpatialIndex index(depth);

    SpatialDomain domain;    // initialize empty domain

    SpatialVector v1(ra[0], dec[0]);
    SpatialVector v2(ra[1], dec[1]);
    SpatialVector v3(ra[2], dec[2]);
    SpatialVector v4(ra[3], dec[3]);
    SpatialConvex cvx(&v1,&v2,&v3,&v4);

    domain.add(cvx);
    domain.intersect(&index,plist,flist);     // intersect with list

    for (i = 0; i < flist.length(); i++) {    // just loop full nodes list
      flist2.push_back(flist(i));
    }
    for (i = 0; i < plist.length(); i++) {    // just loop partial nodes list
      plist2.push_back(plist(i));
    }
  }
  catch (SpatialException &x) {
    return -1;
  }

  return 0;
}
