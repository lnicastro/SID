/*
  Name: htmCircleRegion

  Purpose:

   Intersect a circular domain with the HTM grid returning the IDs
   of full and partial nodes. MCS - DIF custom version.
   For rectangular domains see 'htmRectRegion'.

  Parameters:
   (i) int depth:     Pixelization depth
   (i) double ra:     Cone center Right Ascension (degrees)
   (i) double dec:    Cone center Declination (degrees)
   (i) double radius: Cone radius (arcmin)
   (o) vector<uint64> flist: list of intersected full nodes
   (o) vector<uint64> plist: list of intersected partial nodes

  Return 0 on success.


  LN@IASF-INAF, January 2003                   ( Last change: 03/10/2008 )
*/

#include <vector>
#include "SpatialInterface.h"

//static const int MY_DEPTH_DEF = 6;

using namespace std;

/* degrees to radians */
static const double DEG2RAD = 1.74532925199432957692369E-2;
 

int htmCircleRegion(int depth, double ra, double dec, double radius,
                    vector<uint64>& flist2,
                    vector<uint64>& plist2)
{
//  int savedepth=2;              // stored depth
  ValVec<uint64> plist, flist;  // List results
  uint64 i;
  double distance = cos(radius/60.*DEG2RAD);


  flist2.clear();
  plist2.clear();

// If out of range depth return here
//  if ((depth < 0)  ||  (depth > 25))  depth = MY_DEPTH_DEF;
  if ((depth < 0) || (depth > 25)) return -1;

  try {
// construct index with given depth (and savedepth?)
    //htmInterface htm(depth);  // generate htm interface
    //const SpatialIndex &index = htm.index();
    const SpatialIndex index(depth);

    SpatialDomain domain;    // initialize empty domain
    SpatialVector v(ra, dec);
    SpatialConvex cvx;
    SpatialConstraint constr(v, distance);
    cvx.add(constr);
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
    return -2;
  }

  return 0;
}
