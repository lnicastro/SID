/*
  Name: int myHealPCone

  Description:
   Calculates full and partial pixel intersected by a cone in the HEALPix 
   RING or NESTED sheme.

  Parameters:
   (i) int nested:    Scheme ID; if 0 then RING else NESTED
   (i) int k:         Resolution level of map
   (i) double ra:     Cone center Right Ascension (degrees)
   (i) double dec:    Cone center Declination (degrees)
   (i) double radius: Cone radius (arcmin)

   (o) vector<long long int> flist: list of fully covered pixels
   (o) vector<long long int> plist: list of partially covered pixels

  Note:
   Npix = 12 * Nside^2
   Nside = 2^k, k = [0, ..., 29] -> order = WMAP resolution parameter
   Sky resolution: Omega=PI/(3Nside^2)
   For Nside=64 it is ~1 deg (12 * 64^2 = 49152 pixels).

   The minimum radius is TBD (1 mas assumed). See Healpix_Base::query_disc and pix2loc.

   Returned list of partial pixels could be > real ones, that of full pixels
   could be < real ones.
   If k is not in the allowed range then return empty lists
   (and not 0 code).

  Return 0 on success.

  25/09/2008: Use Healpix_Base2 and set minimun circle radius
  16/05/2016: Use Healpix_Base version 3


  LN@IASF-INAF, July 2007                        Last change: 21/03/2017
*/

#include <algorithm>

//static const int MY_NSIDE_DEF = 64;

/* degrees to radians */
static const double DEG2RAD = 1.74532925199432957692369E-2;

/* Minimum cone radius (rad): ~ 1 mas - this is function of K and "fact" in "query_disc_inclusive" - TBC */
static const double MIN_CONE_RAD = 5e-9;

#include "arr.h"
#include "geom_utils.h"
#include "healpix_base.h"

using namespace std;


extern void difflist_ui(vector<unsigned long long int>& v1,
                       vector<unsigned long long int>& v2,
                       vector<unsigned long long int>& vdiff);


int myHealPCone(int nested, int k, double ra, double dec, double radius,
                vector<unsigned long long int>& flist,
                vector<unsigned long long int>& plist)
{
  int64 my_nside;
  vector<int64> tmp_list;
  vector<unsigned long long int> all;
  //vector<uint64> all;
  unsigned long long int j;

  pointing ptg;

  flist.clear();
  plist.clear();

//  if ((k < 0)  ||  (k > 29))  my_nside = MY_NSIDE_DEF;
//  else                        my_nside = 1 << k;
  if ((k < 0) || (k > 29))
    return -1;

  my_nside = 1 << k;

  T_Healpix_Base<int64>* base;

  if (nested)
//    Healpix_Base2 base (my_nside, NEST, SET_NSIDE);
    base = new T_Healpix_Base<int64>(my_nside, NEST, SET_NSIDE);
  else
//    Healpix_Base2 base (my_nside, RING, SET_NSIDE);
    base = new T_Healpix_Base<int64>(my_nside, RING, SET_NSIDE);

#ifdef DEBUG_PRINT
//  int order = base.nside2order(my_nside);
  cout <<"Nside of map: "<< my_nside << endl;
#endif

  ptg.theta = (90. - dec)*DEG2RAD;
  ptg.phi   = ra*DEG2RAD;
  double rad = radius/60.*DEG2RAD;
#ifdef DEBUG_PRINT
cout<<"rad="<<rad<<endl;
#endif

  if (rad < MIN_CONE_RAD)
    rad = MIN_CONE_RAD;

#ifdef DEBUG_PRINT
  if (rad == MIN_CONE_RAD)
    cout <<"*** Cone radius reset to "<< MIN_CONE_RAD <<" radians ("<< MIN_CONE_RAD/DEG2RAD * 3.6e6 <<" mas) ***\n";
#endif

  try {

// maximum angular distance between any pixel center and its corners
  double mpr = base->max_pixrad();

// All interested pixels!
  //base->query_disc(ptg, rad+mpr, tmp_list);
  base->query_disc_inclusive(ptg, rad, tmp_list, 2);

// If nothing found then there is an error
  if (tmp_list.size() == 0) {
#ifdef DEBUG_PRINT
    cout <<"Error in query_polygon_inclusive\n";
#endif
    return 1;
  }

// If just 1 then stop here
  if (tmp_list.size() == 1) {
    plist.push_back(tmp_list[0]);
#ifdef DEBUG_PRINT
  cout <<"Partial node:\n"
       <<"0: "<< plist[0] << endl;
#endif
    return 0;
  }

  for (j=0; j<tmp_list.size(); j++)
    all.push_back( tmp_list[j] );

  tmp_list.clear();

// Sort array - already sorted by toVector method in query_disc_inclusive
  //sort(all.begin(),all.end());

#ifdef DEBUG_PRINT
  cout <<"ALL nodes:\n";
  for (j=0; j<all.size(); j++)
    cout << j <<": "<< all[j] << endl;
#endif

// If just 1 then stop here
  if (all.size() == 0) {
#ifdef DEBUG_PRINT
    cout<<"Error in query_disc_inclusive\n";
#endif
    return 1;
  }

// Decrease by the max pix. radius. This would give all pixel (approx ?!)
// fully covered by the disc.
//--  base.query_disc(ptg, rad-1.362*M_PI/(4*my_nside), tmp_list);
  //base->query_disc(ptg, rad-mpr, tmp_list);

  if (rad-mpr > 0) {
    base->query_disc(ptg, rad-mpr, tmp_list);

    if (tmp_list.size() > 0) {

      for (j=0; j<tmp_list.size(); j++)
        flist.push_back( tmp_list[j] );

      tmp_list.clear();

// Sort array - already sorted by toVector method in query_disc
      //sort(flist.begin(),flist.end());
#ifdef DEBUG_PRINT
      cout <<"Full nodes:\n";
      for (j=0; j<flist.size(); j++)
        cout << j <<": "<< flist[j] << endl;
#endif
    }
  }

// Difference -> partial nodes
  difflist_ui(all,flist,plist);

#ifdef DEBUG_PRINT
  cout <<"Partial nodes:\n";
  for (j=0; j<plist.size(); j++)
    cout << j <<": "<< plist[j] << endl;

  double m_area = M_PI / (3.*base->Nside()*base->Nside()) /
         DEG2RAD / DEG2RAD * 3600;
  double mpr_m = mpr / DEG2RAD * 60;
  double mpr_s = mpr_m * 60;
  cout <<endl
       <<"Total Nr of nodes: "<< all.size() <<"  Full: "<< flist.size()
       <<"  Partial: "<< plist.size() << endl << endl
       <<"Nside: "<< base->Nside() <<"  Npix: "<< base->Npix() << endl
       <<"Pixel area: "<< m_area << " arcmin^2 ("<< m_area * 3600 <<" arcsec^2)\n"
       <<"Ang. res (SQRT(P_area)): "<< sqrt(m_area) <<" arcmin ("<< sqrt(m_area)*60 <<" arcsec)\n"
       <<"max_pixrad= "<< mpr_m <<" arcmin ("<< mpr_s << " arcsec)\n";
#endif
 
  all.clear();
  return 0;

  }
  catch (std::exception &e) {
    cout <<"Error executing myHealPCone. std::exception: "<< e.what() << std::endl;
    return -3;
  }

}
