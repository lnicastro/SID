/*
  Name: int myHealPRect4v

  Description:
   Calculates full and partial pixel intersected by a rectangle identified by
   its 4 vertices in the HEALPix RING or NESTED sheme.

  Parameters:
   (i) int nested:     Scheme ID; if 0 then RING else NESTED
   (i) int k:          Resolution level of map
   (i) double ra[4]:   Right Ascension of the 4 vertices (degrees)
   (i) double de[4]:   Declination of the 4 vertices (degrees)

   (o) vector<int64>& flist: list of fully covered pixels
   (o) vector<int64>& plist: list of partially covered pixels

  Note:
   Npix = 12 * Nside^2
   Nside = 2^k, k = [0, ..., 29] -> order = WMAP resolution parameter
   Sky resolution: Omega=PI/(3Nside^2)
   For Nside=64 it is ~1 deg (12 * 64^2 = 49152 pixels).

   The minimum side is TBD (1 mas assumed). See Healpix_Base::query_multidisc and pix2loc.

   Returned list of partial pixels could be > real ones, that of full pixels too!

   The vertices must be given in clock or counter-clockwise order!
   
   If k is not in the allowed range then return empty lists
   (and not 0 code).

  Return 0 on success.

  05/07/2016: Use Healpix_Base version 3. First version.


  LN@IASF-INAF, May 2016                        Last change: 21/03/2017
*/

#include <algorithm>

/* degrees to radians */
static const double DEG2RAD = 1.74532925199432957692369E-2;

/* Minimum side (rad): ~ 1 mas - this is function of K and "fact" in "query_multidisc" - TBC */
//static const double MIN_CONE_RAD = 5e-9;
static const double MIN_HSIDE_DEG = 2.865e-7;  // half side

#include "arr.h"
#include "geom_utils.h"
#include "healpix_base.h"

using namespace std;


extern void difflist_ui(vector<unsigned long long int>& v1,
                       vector<unsigned long long int>& v2,
                       vector<unsigned long long int>& vdiff);

int build_rect4v(const double ra[4], const double de[4], std::vector<pointing> &vertex) { 

  vertex.clear();
  pointing ptg;

  for (unsigned short i = 0; i < 4; i++) {
    ptg.theta = (90. - de[i])*DEG2RAD;
    ptg.phi   = ra[i]*DEG2RAD;
    vertex.push_back(ptg);

#ifdef DEBUG_PRINT
cout<<"theta="<<vertex[i].theta<<"  phi="<<vertex[i].phi <<endl;
#endif
  }
  return 0;
}

int myHealPRect4v(int nested, int k, const double ra[4], const double de[4],
                vector<unsigned long long int>& flist,
                vector<unsigned long long int>& plist)
{
  int64 my_nside;
  vector<int64> tmp_list;
  //vector<uint64> all;
  vector<unsigned long long int> all;
  unsigned long long int j;


  flist.clear();
  plist.clear();

  if ((k < 0) || (k > 29))
    return -1;

  my_nside = 1 << k;

  T_Healpix_Base<int64>* base;

  if (nested)
    base = new T_Healpix_Base<int64>(my_nside, NEST, SET_NSIDE);
  else
    base = new T_Healpix_Base<int64>(my_nside, RING, SET_NSIDE);

#ifdef DEBUG_PRINT
//  int order = base.nside2order(my_nside);
  cout <<"Nside of map: "<< my_nside << endl;
#endif

  try {

  std::vector<pointing> vertex;
  rangeset<int64> pixset;

  if (build_rect4v(ra, de, vertex)) {
#ifdef DEBUG_PRINT
    cout <<"Error computing rectangle corners\n";
#endif
    return 1;
  }

// All interested pixels!
  base->query_polygon_inclusive(vertex, pixset, 4);

// If nothing found then there is an error
  if (pixset.size() == 0) {
#ifdef DEBUG_PRINT
    cout <<"Error in query_polygon_inclusive\n";
#endif
    return 1;
  }

  pixset.toVector(tmp_list);
// If just 1 then stop here
  if (pixset.size() == 1 && pixset.ivlen(0) == 1) {
    //unit64 not supported// pixset.toVector(plist);
    plist.push_back(tmp_list[0]);
#ifdef DEBUG_PRINT
  cout <<"Partial node:\n"
       <<"0: "<< plist[0] << endl;
#endif
    return 0;
  }

  //unit64 not supported// pixset.toVector(all);

  for (j=0; j<tmp_list.size(); j++)
    all.push_back( tmp_list[j] );

  tmp_list.clear();

// Sort array - already sorted by toVector method
  //sort(all.begin(),all.end());

#ifdef DEBUG_PRINT
  cout <<"ALL nodes:\n";
  for (j=0; j<all.size(); j++)
    cout << j << ": " << all[j] << endl;
#endif

// maximum angular distance between any pixel center and its corners, in deg
  double mpr = base->max_pixrad() / DEG2RAD;

// Decrease by the max pix. radius. This would give all pixel (approx ?!)
// fully covered by the rectangle.

  double hside_ra = (mpr / cos(de[0]*DEG2RAD));
  double hside_de = mpr;

#ifdef DEBUG_PRINT
cout <<"mpr, mpr_ra: "<<mpr*DEG2RAD<<", "<<mpr/cos(de[0]*DEG2RAD)*DEG2RAD<<endl;
#endif

  if (hside_ra > 0 && hside_de > 0) {
    //if (build_rect(cra, cde, hside_ra, hside_de, vertex)) {
//#ifdef DEBUG_PRINT
    //cout <<"Error computing rectangle corners\n";
//#endif
      //return 1;
    //}

    base->query_polygon(vertex, pixset);

    if (pixset.size() > 0) {

      //unit64 not supported// pixset.toVector(flist);
      pixset.toVector(tmp_list);
      for (j=0; j<tmp_list.size(); j++)
        flist.push_back( tmp_list[j] );

      tmp_list.clear();

// Sort array - already sorted by toVector method
      sort(flist.begin(),flist.end());
#ifdef DEBUG_PRINT
      cout <<"Full nodes:\n";
      for (j=0; j<flist.size(); j++)
        cout << j << ": " << flist[j] << endl;
#endif
    }
  }

// Difference -> partial nodes
  difflist_ui(all,flist,plist);

#ifdef DEBUG_PRINT
  cout <<"Partial nodes:\n";
  for (j=0; j<plist.size(); j++)
    cout << j << ": " << plist[j] << endl;

  double m_area = M_PI / (3.*base->Nside()*base->Nside()) /
         DEG2RAD / DEG2RAD * 3600;
  //double mpr_m = mpr / DEG2RAD * 60;
  double mpr_s = mpr * 3600;
  cout << endl
       <<"Total Nr of nodes: "<< all.size() <<"  Full: "<< flist.size()
       <<"  Partial: "<< plist.size() << endl << endl
       <<"Nside: "<< base->Nside() <<"  Npix: " << base->Npix() << endl
       <<"Pixel area: "<< m_area <<" arcmin^2 ("<< m_area * 3600 <<" arcsec^2)\n"
       <<"Ang. res (SQRT(P_area)): "<< sqrt(m_area) <<" arcmin ("<< sqrt(m_area)*60 <<" arcsec)\n"
       <<"max_pixrad= "<< mpr*60 <<" arcmin ("<< mpr_s <<" arcsec)\n";
#endif
 
  all.clear();
  return 0;

  }
  catch (std::exception &e) {
    cout <<"Error executing myHealPRect4V. std::exception: "<< e.what() << std::endl;
    return -3;
  }

}
