/*
  Name: int myHealPRect

  Description:
   Calculates full and partial pixel intersected by a rectangle, along RA and Dec,
   in the HEALPix RING or NESTED sheme.

  Parameters:
   (i) int nested:     Scheme ID; if 0 then RING else NESTED
   (i) int k:          Resolution level of map
   (i) double cra:     Right Ascension of center (degrees)
   (i) double cde:     Declination of center (degrees)
   (i) double side_ra: Side length along RA (arcmin)
   (i) double side_de: Side length along Dec (arcmin).
                       If omitted then use side_ra (i.e. square area)

   (o) vector<int64>& flist: list of fully covered pixels
   (o) vector<int64>& plist: list of partially covered pixels

  Note:
   Npix = 12 * Nside^2
   Nside = 2^k, k = [0, ..., 29] -> order = WMAP resolution parameter
   Sky resolution: Omega=PI/(3Nside^2)
   For Nside=64 it is ~1 deg (12 * 64^2 = 49152 pixels).

   The minimum side is TBD (1 mas assumed). See Healpix_Base::query_multidisc and pix2loc.

   Returned list of partial pixels could be > real ones, that of full pixels
   could be < real ones.
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

int build_rect(double cra, double cde, double hside_ra, double hside_de, std::vector<pointing> &vertex) { 
// Compute coordinates for two opposite corners (clockwise coords)
  double ra1 = cra - hside_ra;
  double ra2 = cra + hside_ra;
  double de1 = cde - hside_de;
  double de2 = cde + hside_de;

  vertex.clear();

  pointing ptg;

  ptg.theta = (90. - de1)*DEG2RAD;
  ptg.phi   = ra1*DEG2RAD;
  vertex.push_back(ptg);

  ptg.theta = (90. - de2)*DEG2RAD;
  ptg.phi   = ra1*DEG2RAD;
  vertex.push_back(ptg);

  ptg.theta = (90. - de2)*DEG2RAD;
  ptg.phi   = ra2*DEG2RAD;
  vertex.push_back(ptg);

  ptg.theta = (90. - de1)*DEG2RAD;
  ptg.phi   = ra2*DEG2RAD;
  vertex.push_back(ptg);

#ifdef DEBUG_PRINT
for (unsigned short i=0; i<4; i++)
cout<<"theta="<<vertex[i].theta<<"  phi="<<vertex[i].phi <<endl;
#endif
  return 0;
}

int myHealPRect(int nested, int k, double cra, double cde, double side_ra, double side_de,
                vector<unsigned long long int>& flist,
                vector<unsigned long long int>& plist)
{
  int64 my_nside;
  vector<int64> tmp_list;
  vector<unsigned long long int> all;
  //vector<uint64> all;
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

  double hside_ra = side_ra/120.;
  if (hside_ra < MIN_HSIDE_DEG) hside_ra = MIN_HSIDE_DEG;
  double hside_de = hside_ra;

  if (side_de > 0.)
    hside_de = side_de/120.;
  if (hside_de < MIN_HSIDE_DEG) hside_de = MIN_HSIDE_DEG;

#ifdef DEBUG_PRINT
  if (hside_ra == MIN_HSIDE_DEG || hside_de == MIN_HSIDE_DEG)
    cout <<"*** Side reset to "<< MIN_HSIDE_DEG <<" degrees ("<< MIN_HSIDE_DEG * 3.6e6 <<" mas) ***\n";
#endif

// Check parameters
  while (cra < 0.) cra += 360.;

  if ( (! (  0. <= cra      &&  cra       <  360.))  ||
       (! (-90. <= cde      &&  cde       <=  90.))  ||
       (! (  0. < hside_ra  &&  hside_ra  <= 180.))  ||
       (! (  0. < hside_de  &&  hside_de  <=  90.)) )
    return -1;

  try {

  hside_ra /= cos(cde*DEG2RAD);
  if (hside_ra > 180.)
    hside_ra = 180.;
//cout<<"hside_ra "<<hside_ra<<"  hside_de "<<hside_de<<endl;

  std::vector<pointing> vertex;
  rangeset<int64> pixset;

  if (build_rect(cra, cde, hside_ra, hside_de, vertex)) {
#ifdef DEBUG_PRINT
    cout <<"Error computing rectangle corners\n";
#endif
    return 1;
  }

// All interested pixels!
  base->query_polygon_inclusive(vertex, pixset, 2);

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

  hside_ra -= (mpr / cos(cde*DEG2RAD));
  hside_de -= mpr;

#ifdef DEBUG_PRINT
cout <<"mpr, mpr_ra: "<<mpr*DEG2RAD<<", "<<mpr/cos(cde*DEG2RAD)*DEG2RAD<<endl;
#endif

  if (hside_ra > 0 && hside_de > 0) {
    if (build_rect(cra, cde, hside_ra, hside_de, vertex)) {
#ifdef DEBUG_PRINT
    cout <<"Error computing rectangle corners\n";
#endif
      return 1;
    }

    base->query_polygon_inclusive(vertex, pixset, 4);

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
    cout <<"Error executing myHealPRect. std::exception: "<< e.what() << std::endl;
    return -3;
  }

}
