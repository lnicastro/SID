/*
   LN 8/9/2018: MySQL 8 changes. Note: added -std=c++11 in CMAKE_CXX_FLAGS

  Last change: 17/11/2018
*/

#include <math.h>
#include <cstring>
#include <iostream>
#include <regex>
#include <string>

#include "udf.hh"

//#include <my_global.h>
#include <mysql.h>

#if MYSQL_VERSION_ID >= 80000
typedef bool   my_bool;
#endif
typedef long long   longlong;
typedef unsigned long long      uint64;


#include "udf_utils.hh"

// In the Calpont InfiniDB this is not set
#ifndef NOT_FIXED_DEC
#define NOT_FIXED_DEC                   31
#endif


//Implement UDFs

//C_MODE_START;
extern "C" {

// HTM functions
  DEFINE_FUNCTION(longlong, HTMLookup);
  DEFINE_FUNCTION(longlong, HTMidByName);
  DEFINE_FUNCTION_CHAR(char*, HTMnameById);
  DEFINE_FUNCTION_CHAR(char*, HTMBary);
  DEFINE_FUNCTION_CHAR(char*, HTMBaryC);
  DEFINE_FUNCTION_CHAR(char*, HTMNeighb);
  DEFINE_FUNCTION_CHAR(char*, HTMsNeighb);
  DEFINE_FUNCTION_CHAR(char*, HTMNeighbC);
  DEFINE_FUNCTION(double, HTMBaryDist);

  DEFINE_FUNCTION_CHAR(char*, SIDCircleHTM);
  DEFINE_FUNCTION_CHAR(char*, SIDRectHTM);
  DEFINE_FUNCTION_CHAR(char*, SIDRectvHTM);


// HEALPix functions
  DEFINE_FUNCTION(longlong, HEALPLookup);
  DEFINE_FUNCTION(double, HEALPMaxS);
  DEFINE_FUNCTION(double, HEALPBaryDist);
  DEFINE_FUNCTION_CHAR(char*, HEALPBary);
  DEFINE_FUNCTION_CHAR(char*, HEALPBaryC);
  DEFINE_FUNCTION_CHAR(char*, HEALPNeighb);
  DEFINE_FUNCTION_CHAR(char*, HEALPNeighbC);
  DEFINE_FUNCTION_CHAR(char*, HEALPBound);
  DEFINE_FUNCTION_CHAR(char*, HEALPBoundC);

  DEFINE_FUNCTION_CHAR(char*, SIDCircleHEALP);
  DEFINE_FUNCTION_CHAR(char*, SIDRectHEALP);
  DEFINE_FUNCTION_CHAR(char*, SIDRectvHEALP);


// Generic functions
  DEFINE_FUNCTION(longlong, SIDGetID);
  DEFINE_FUNCTION(longlong, SIDCount);
  DEFINE_FUNCTION(longlong, SIDClear);
  DEFINE_FUNCTION(double, Sphedist);

}
//C_MODE_END;


struct myD
{
  int count;
  vector<uint64> *flist;
  vector<uint64> *plist;
};


//--------------------------------------------------------------------
//  Below HTM functions
//--------------------------------------------------------------------


my_bool HTMLookup_init(UDF_INIT* init, UDF_ARGS *args, char *message)
{
  const char* argerr = "HTMLookup(Depth INT, Ra_deg DOUBLE, Dec_deg DOUBLE)";

  CHECK_ARG_NUM(3);
  CHECK_ARG_TYPE(    0, INT_RESULT);
  CHECK_ARG_NOT_TYPE(1, STRING_RESULT);
  CHECK_ARG_NOT_TYPE(2, STRING_RESULT);

  init->ptr = NULL;

  return 0;
}


longlong HTMLookup(UDF_INIT *init, UDF_ARGS *args,
                   char *is_null, char* error)
{
  int depth  = IARGS(0);
  double raa = DARGS(1);
  double dec = DARGS(2);
  unsigned long long int id;

  if ( getHTMid(init->ptr, depth, raa, dec, &id) )
    *error = 1;

  return id;
}


void HTMLookup_deinit(UDF_INIT *init)
{ cleanHTMUval(init->ptr); }


//--------------------------------------------------------------------

my_bool HTMidByName_init(UDF_INIT* init, UDF_ARGS *args, char *message)
{
  const char* argerr = "HTMidByName(IdName STRING)";

  CHECK_ARG_NUM(1);
  CHECK_ARG_TYPE(0, STRING_RESULT);

  init->ptr = NULL;

  return 0;
}


longlong HTMidByName(UDF_INIT *init, UDF_ARGS *args,
                     char *is_null, char* error)
{
  const char *myValue = CARGS(0);
  unsigned long long int id;

  size_t argLength = args->lengths[0];
  if (argLength > 32) {
    *error = 1;
    return 0;
  }

  char *idname = (char *)malloc(argLength+1);
  memcpy(idname, myValue, argLength);
  idname[argLength] = '\0';

  if ( getHTMidByName(init->ptr, idname, &id) )
    *error = 1;

  return id;
}

void HTMidByName_deinit(UDF_INIT *init)
{ cleanHTMUval(init->ptr); }


//--------------------------------------------------------------------

my_bool HTMnameById_init(UDF_INIT* init, UDF_ARGS *args, char *message)
{
  const char* argerr = "HTMnameById(Id INT)";

  CHECK_ARG_NUM(1);
  CHECK_ARG_TYPE(0, INT_RESULT);

  init->maybe_null = 0;
  init->max_length = 255;
  init->const_item = 0;

  return 0;
}


char* HTMnameById(UDF_INIT *init, UDF_ARGS *args,
                  char *idname, unsigned long *length,
                  char *is_null, char *error)
{
  unsigned long long int id = IARGS(0);

  if ( getHTMnameById1(id, idname) ) {
    *error = 1;
    *is_null = 1;
    return NULL;
  } else {
    *length = (unsigned long) strlen(idname);
  }

  init->ptr = idname;
  return idname;
}


void HTMnameById_deinit(UDF_INIT *init)
{}


//--------------------------------------------------------------------

my_bool HTMBary_init(UDF_INIT *init, UDF_ARGS *args, char *message)
{
 const char* argerr = "HTMBary(depth INT, id INT)";

  CHECK_ARG_NUM(2);
  CHECK_ARG_TYPE(0, INT_RESULT);
  CHECK_ARG_TYPE(1, INT_RESULT);

  init->maybe_null = 0;
  init->max_length = 255;
  init->const_item = 0;

  return 0;
}


char* HTMBary(UDF_INIT *init, UDF_ARGS *args,
              char *result, unsigned long *length,
              char *is_null, char *error)
{
  int depth  = IARGS(0);
  unsigned long long int id = IARGS(1);

  double bc_ra, bc_dec;

  if ( getHTMBary1(depth, id, &bc_ra, &bc_dec) ) {
    *error = 1;
    *is_null = 1;
    return NULL;
  } else {
    sprintf(result,"%.16g, %.16g",bc_ra, bc_dec);
    *length = (unsigned long) strlen(result);
  }

  init->ptr = result;
  return result;
}


void HTMBary_deinit(UDF_INIT* init)
{
}


//--------------------------------------------------------------------

my_bool HTMBaryC_init(UDF_INIT *init, UDF_ARGS *args, char *message)
{
 const char* argerr = "HTMBaryC(depth INT, ra DOUBLE, dec DOUBLE)";

  CHECK_ARG_NUM(3);
  CHECK_ARG_TYPE(0, INT_RESULT);
  CHECK_ARG_NOT_TYPE(1, STRING_RESULT);
  CHECK_ARG_NOT_TYPE(2, STRING_RESULT);

  init->maybe_null = 0;
  init->max_length = 255;
  init->const_item = 0;

  return 0;
}


char* HTMBaryC(UDF_INIT *init, UDF_ARGS *args,
               char *result, unsigned long *length,
               char *is_null, char *error)
{
  int depth  = IARGS(0);
  double ra  = DARGS(1);
  double dec = DARGS(2);

  double bc_ra, bc_dec;

  if ( getHTMBaryC1(depth, ra, dec, &bc_ra, &bc_dec) ) {
    *error = 1;
    *is_null = 1;
    return NULL;
  } else {
    sprintf(result,"%.16g, %.16g",bc_ra, bc_dec);
    *length = (unsigned long) strlen(result);
  }

  init->ptr = result;
  return result;
}


void HTMBaryC_deinit(UDF_INIT* init)
{
}


//--------------------------------------------------------------------

my_bool HTMNeighb_init(UDF_INIT *init, UDF_ARGS *args, char *message)
{
 const char* argerr = "HTMNeighb(depth INT, id INT)";

  CHECK_ARG_NUM(2);
  CHECK_ARG_TYPE(0, INT_RESULT);
  CHECK_ARG_TYPE(1, INT_RESULT);

  init->maybe_null = 0;
  init->max_length = 255;
  init->const_item = 0;

  return 0;
}



char* HTMNeighb(UDF_INIT *init, UDF_ARGS *args,
                char *result, unsigned long *length,
                char *is_null, char *error)
{
  int depth = IARGS(0);
  unsigned long long int id = IARGS(1);

  vector<unsigned long long int> idn;
  char temp[20];

  if ( getHTMNeighb1(depth, id, idn) ) {
    *error = 1;
    *is_null = 1;
    return NULL;
  } else {
    sprintf(result,"%lld",idn[0]);
    for (unsigned int i=1; i<idn.size(); i++) {
      sprintf(temp,", %lld",idn[i]);
      strcat(result,temp);
    }
    *length = (unsigned long) strlen(result);
  }

  init->ptr = result;
  return result;
}


void HTMNeighb_deinit(UDF_INIT* init)
{
}


//--------------------------------------------------------------------

my_bool HTMsNeighb_init(UDF_INIT *init, UDF_ARGS *args, char *message)
{
 const char* argerr = "HTMsNeighb(depth INT, id INT, out_depth INT)";

  CHECK_ARG_NUM(3);
  CHECK_ARG_TYPE(0, INT_RESULT);
  CHECK_ARG_TYPE(1, INT_RESULT);
  CHECK_ARG_TYPE(2, INT_RESULT);

  init->maybe_null = 1;
  init->const_item = 0;

// Initial buffer size is 2048 chars
  init->ptr = NULL;
  if ( !(init->ptr =
        (char *) malloc( sizeof(char) * 2048 ) ) ) {
        strcpy(message, "Couldn't allocate memory!");
        return 1;
   }
   memset( init->ptr, 0, sizeof(char) * 2048 );

  return 0;
}


char* HTMsNeighb(UDF_INIT *init, UDF_ARGS *args,
                 char *result, unsigned long *length,
                 char *is_null, char *error)
{
  int depth = IARGS(0);
  unsigned long long int id = IARGS(1);
  int odepth = IARGS(2);

  vector<unsigned long long int> idn;
  unsigned long nc=0;
  char temp[20];
  char *ss = init->ptr;

  if ( getHTMsNeighb1(depth, id, odepth, idn) ) {
    *error = 1;
    *is_null = 1;
    return NULL;
  } else {
    sprintf(ss,"%lld",idn[0]);
    nc = strlen(ss);
    for (unsigned int i=1; i<idn.size(); i++) {
      sprintf(temp,", %lld",idn[i]);
      nc += strlen(temp);
      if (nc > 2047) {
        char *p = (char *) realloc(ss, sizeof(char) * (nc+1));
        if (!p) {
          *error = 1;
          return 0;
        }
       ss = p;
      }
      strcat(ss,temp);
    }
    *length = (unsigned long) strlen(ss);
  }

  init->ptr = ss;
  return ss;
}


void HTMsNeighb_deinit(UDF_INIT* init)
{
  if (init->ptr)
    free(init->ptr);
}


//--------------------------------------------------------------------

my_bool HTMNeighbC_init(UDF_INIT *init, UDF_ARGS *args, char *message)
{
 const char* argerr = "HTMNeighbC(depth INT, Ra_deg DOUBLE, Dec_deg DOUBLE)";

  CHECK_ARG_NUM(3);
  CHECK_ARG_TYPE(    0, INT_RESULT);
  CHECK_ARG_NOT_TYPE(1, STRING_RESULT);
  CHECK_ARG_NOT_TYPE(2, STRING_RESULT);

  init->maybe_null = 0;
  init->max_length = 255;
  init->const_item = 0;

  return 0;
}


char* HTMNeighbC(UDF_INIT *init, UDF_ARGS *args,
                 char *result, unsigned long *length,
                 char *is_null, char *error)
{
  int depth  = IARGS(0);
  double raa = DARGS(1);
  double dec = DARGS(2);

  vector<unsigned long long int> idn;
  char temp[20];

  if ( getHTMNeighbC1(depth, raa, dec, idn) ) {
    *error = 1;
    *is_null = 1;
    return NULL;
  } else {
    sprintf(result,"%lld",idn[0]);
    for (unsigned int i=1; i<idn.size(); i++) {
      sprintf(temp,", %lld",idn[i]);
      strcat(result,temp);
    }
    *length = (unsigned long) strlen(result);
  }

  init->ptr = result;
  return result;
}


void HTMNeighbC_deinit(UDF_INIT* init)
{
}


//--------------------------------------------------------------------

my_bool HTMBaryDist_init(UDF_INIT *init, UDF_ARGS *args, char *message)
{
 const char* argerr = "HTMBaryDist(depth INT, id INT, ra DOUBLE, dec DOUBLE)";

  CHECK_ARG_NUM(4);
  CHECK_ARG_TYPE(0, INT_RESULT);
  CHECK_ARG_TYPE(1, INT_RESULT);
  CHECK_ARG_NOT_TYPE(2, STRING_RESULT);
  CHECK_ARG_NOT_TYPE(3, STRING_RESULT);
  init->decimals = NOT_FIXED_DEC;

  return 0;
}


double HTMBaryDist(UDF_INIT *init, UDF_ARGS *args,
                   char *is_null, char *error)
{
  int order  = IARGS(0);
  unsigned long long int id = IARGS(1);
  double ra  = DARGS(2);
  double dec = DARGS(3);
  return getHTMBaryDist1(order, id, ra, dec);
}


void HTMBaryDist_deinit(UDF_INIT* init)
{
}


//--------------------------------------------------------------------


//--------------------------------------------------------------------


//--------------------------------------------------------------------

my_bool SIDCircleHTM_init(UDF_INIT* init, UDF_ARGS *args, char *message)
{
  const char* argerr = "SIDCircleHTM(depth INT, Ra_deg DOUBLE, Dec_deg DOUBLE, Rad_arcmin DOUBLE)";

  CHECK_ARG_NUM(4);
  CHECK_ARG_NOT_TYPE(0, STRING_RESULT);
  CHECK_ARG_NOT_TYPE(1, STRING_RESULT);
  CHECK_ARG_NOT_TYPE(2, STRING_RESULT);
  CHECK_ARG_NOT_TYPE(3, STRING_RESULT);

  init->maybe_null = 0;
  init->max_length = 255;
  init->const_item = 0;

  init->ptr = (char *)malloc(sizeof (myD));

  ((struct myD*)init->ptr)->flist = new vector<uint64>; 
  ((struct myD*)init->ptr)->plist = new vector<uint64>; 
  ((struct myD*)init->ptr)->count = 0;

  return 0;
}


char* SIDCircleHTM(UDF_INIT *init, UDF_ARGS *args,
                   char *result, unsigned long *length,
                   char *is_null, char *error)
{
  int depth  = IARGS(0);
  double rac = DARGS(1);
  double dec = DARGS(2);
  double rad = DARGS(3);


  struct myD* m = (struct myD*) init->ptr;

  if (htmCircleRegion(depth, rac, dec, rad, *(m->flist),*(m->plist))) {
    *error = 1;
    *is_null = 1;
    return NULL;
  }
 
//fprintf(stderr, "FULL: %ld  PARTIAL: %ld\n", m->flist->size(), m->plist->size()); 

  char buff[32];
  sprintf(buff, "%p", m);


  *length = strlen(buff);
  strcpy(result, buff);
  return result;

}


void SIDCircleHTM_deinit(UDF_INIT *init)
{
}


//--------------------------------------------------------------------

my_bool SIDRectHTM_init(UDF_INIT* init, UDF_ARGS *args, char *message)
{
//This function requires the coordinate of the center of the rectangular region and one or two sides.
const char* argerr = "SIDRectHTM(Depth INT, Ra_deg DOUBLE, Dec_deg DOUBLE, side_ra_arcmin DOUBLE [, side_dec_arcmin DOUBLE])";

  switch (args->arg_count) {
  case 5:
    CHECK_ARG_NOT_TYPE(4, STRING_RESULT);
  case 4:
    CHECK_ARG_NOT_TYPE(0, STRING_RESULT);
    CHECK_ARG_NOT_TYPE(1, STRING_RESULT);
    CHECK_ARG_NOT_TYPE(2, STRING_RESULT);
    CHECK_ARG_NOT_TYPE(3, STRING_RESULT);
    break;
  default:
    CHECK_ARG_NUM(5);  //Raise an error.
  }


  init->maybe_null = 0;
  init->max_length = 255;
  init->const_item = 0;

  init->ptr = (char *)malloc(sizeof (myD));

  ((struct myD*)init->ptr)->flist = new vector<uint64>;
  ((struct myD*)init->ptr)->plist = new vector<uint64>;
  ((struct myD*)init->ptr)->count = 0;

  return 0;
}


char* SIDRectHTM(UDF_INIT *init, UDF_ARGS *args,
                 char *result, unsigned long *length,
                 char *is_null, char *error)
{
  int depth  = DARGS(0);
  double cra = DARGS(1);
  double cde = DARGS(2);
  double hside_ra = DARGS(3)/120.;
  double hside_de = (args->arg_count == 5  ?  DARGS(4)/120.  :  hside_ra);

// Some parameter checks
  if (cra < 0.) cra += 360.;

  if ( (! (  0. <= cra      &&  cra       <  360.))  ||
       (! (-90. <= cde      &&  cde       <=  90.))  ||
       (! (  0. < hside_ra  &&  hside_ra  <= 180.))  ||
       (! (  0. < hside_de  &&  hside_de  <=  90.)) ) {
    *error = 1;
    *is_null = 1;
    return NULL;
  }

  hside_ra /= cos(cde*DEG2RAD);

  if (hside_ra > 180.) hside_ra = 180.;

  double ra[4], de[4];

  ra[0] = cra - hside_ra;
  de[0] = cde - hside_de;
  ra[2] = cra + hside_ra;
  de[1] = cde + hside_de;
  ra[1] = ra[0];
  de[2] = de[1];
  ra[3] = ra[2];
  de[3] = de[0];

  struct myD* m = (struct myD*) init->ptr;

  if (htmRectRegion(depth, ra, de, *(m->flist),*(m->plist))) {
    *error = 1;
    *is_null = 1;
    return NULL;
  }

//fprintf(stderr, "FULL: %ld  PARTIAL: %ld\n", m->flist->size(), m->plist->size()); 

  char buff[32];
  sprintf(buff, "%p", m);


  *length = strlen(buff);
  strcpy(result, buff);

  return result;
}


void SIDRectHTM_deinit(UDF_INIT *init)
{
}


//--------------------------------------------------------------------

my_bool SIDRectvHTM_init(UDF_INIT* init, UDF_ARGS *args, char *message)
{
//This function requires the coordinates of the 2 opposite (or 4) corners of the rectangular region.
const char* argerr = "SIDRectvHTM(Depth INT, Ra1_deg DOUBLE, Dec1_deg DOUBLE, Ra2_deg DOUBLE, Dec2_deg DOUBLE [, x 2])";


  switch (args->arg_count) {
  case 9:
    CHECK_ARG_NOT_TYPE(5, STRING_RESULT);
    CHECK_ARG_NOT_TYPE(6, STRING_RESULT);
    CHECK_ARG_NOT_TYPE(7, STRING_RESULT);
    CHECK_ARG_NOT_TYPE(8, STRING_RESULT);
  case 5:
    CHECK_ARG_NOT_TYPE(0, STRING_RESULT);
    CHECK_ARG_NOT_TYPE(1, STRING_RESULT);
    CHECK_ARG_NOT_TYPE(2, STRING_RESULT);
    CHECK_ARG_NOT_TYPE(3, STRING_RESULT);
    CHECK_ARG_NOT_TYPE(4, STRING_RESULT);
    break;
  default:
    CHECK_ARG_NUM(5); //Raise an error
  }

  init->maybe_null = 0;
  init->max_length = 255;
  init->const_item = 0;

  init->ptr = (char *)malloc(sizeof (myD));

  ((struct myD*)init->ptr)->flist = new vector<uint64>;
  ((struct myD*)init->ptr)->plist = new vector<uint64>;
  ((struct myD*)init->ptr)->count = 0;

  return 0;
}


char * SIDRectvHTM(UDF_INIT *init, UDF_ARGS *args,
               char *result, unsigned long *length,
               char *is_null, char *error)
{
  int depth = IARGS(0);

  double ra[4], de[4];

  if (args->arg_count == 5) {
    ra[0] = DARGS(1);
    de[0] = DARGS(2);
    ra[1] = DARGS(3);
    de[1] = DARGS(4);

// Order ranges (clockwise)
    if (ra[0] < ra[1]) {
      ra[0] = ra[0];
      ra[2] = ra[1];
    } else {
      ra[0] = ra[1];
      ra[2] = ra[0];
    }
    ra[1] = ra[0];
    ra[3] = ra[2];

    if (de[0] < de[1]) {
      de[0] = de[0];
      de[1] = de[1];
    } else {
      de[0] = de[1];
      de[1] = de[0];
    }
    de[2] = de[1];
    de[3] = de[0];

  }
  else {
    for (unsigned short i=1; i<args->arg_count; i+=2) {
      ra[i] = DARGS(i);
      de[i] = DARGS(i+1);
    }
  }


  struct myD* m = (struct myD*) init->ptr;

  if (htmRectRegion(depth, ra, de, *(m->flist),*(m->plist))) {
    *error = 1;
    *is_null = 1;
    return NULL;
  }

  char buff[32];
  sprintf(buff, "%p", m);


  *length = strlen(buff);
  strcpy(result, buff);

  return result;
}


void SIDRectvHTM_deinit(UDF_INIT *init)
{
}


//--------------------------------------------------------------------
//  Below HEALPix functions
//--------------------------------------------------------------------


my_bool HEALPLookup_init(UDF_INIT* init, UDF_ARGS *args, char *message)
{
  const char* argerr = "HEALPLookup(nested INT, order INT, Ra_deg DOUBLE, Dec_deg DOUBLE)";

  CHECK_ARG_NUM(4);
  CHECK_ARG_TYPE(    0, INT_RESULT);
  CHECK_ARG_TYPE(    1, INT_RESULT);
  CHECK_ARG_NOT_TYPE(2, STRING_RESULT);
  CHECK_ARG_NOT_TYPE(3, STRING_RESULT);

  init->ptr = NULL;

  return 0;
}


longlong HEALPLookup(UDF_INIT *init, UDF_ARGS *args,
                     char *is_null, char* error)
{
  int nested = IARGS(0);
  int order  = IARGS(1);
  double raa = DARGS(2);
  double dec = DARGS(3);
  long long int id;

  if ( getHealPid(init->ptr, nested, order, raa, dec, &id) )
    *error = 1;

  return id;
}


void HEALPLookup_deinit(UDF_INIT *init)
{ cleanHealPUval(init->ptr); }


//--------------------------------------------------------------------

my_bool HEALPMaxS_init(UDF_INIT *init, UDF_ARGS *args, char *message)
{
 const char* argerr = "HEALPMaxS(order INT)";

  CHECK_ARG_NUM(1);
  CHECK_ARG_TYPE(0, INT_RESULT);

  init->decimals = NOT_FIXED_DEC;

  return 0;
}


double HEALPMaxS(UDF_INIT *init, UDF_ARGS *args,
                 char *is_null, char *error)
{
  int order  = IARGS(0);
  return getHealPMaxS1(order);
}


void HEALPMaxS_deinit(UDF_INIT* init)
{
}


//--------------------------------------------------------------------

my_bool HEALPBaryDist_init(UDF_INIT *init, UDF_ARGS *args, char *message)
{
 const char* argerr = "HEALPBaryDist(nested INT, order INT, id INT, ra DOUBLE, dec DOUBLE)";

  CHECK_ARG_NUM(5);
  CHECK_ARG_TYPE(0, INT_RESULT);
  CHECK_ARG_TYPE(1, INT_RESULT);
  CHECK_ARG_TYPE(2, INT_RESULT);
  CHECK_ARG_NOT_TYPE(3, STRING_RESULT);
  CHECK_ARG_NOT_TYPE(4, STRING_RESULT);
  init->decimals = NOT_FIXED_DEC;

  return 0;
}


double HEALPBaryDist(UDF_INIT *init, UDF_ARGS *args,
                     char *is_null, char *error)
{
  int nested = IARGS(0);
  int order  = IARGS(1);
  long long int id = IARGS(2);
  double ra  = DARGS(3);
  double dec = DARGS(4);
  return getHealPBaryDist1(nested, order, id, ra, dec);
}


void HEALPBaryDist_deinit(UDF_INIT* init)
{
}


//--------------------------------------------------------------------

my_bool HEALPBary_init(UDF_INIT *init, UDF_ARGS *args, char *message)
{
 const char* argerr = "HEALPBary(nested INT, order INT, id INT)";

  CHECK_ARG_NUM(3);
  CHECK_ARG_TYPE(0, INT_RESULT);
  CHECK_ARG_TYPE(1, INT_RESULT);
  CHECK_ARG_TYPE(2, INT_RESULT);

  init->maybe_null = 0;
  init->max_length = 255;
  init->const_item = 0;

  return 0;
}


char * HEALPBary(UDF_INIT *init, UDF_ARGS *args,
                 char *result, unsigned long *length,
                 char *is_null, char *error)
{
  int nested = IARGS(0);
  int order  = IARGS(1);
  unsigned long long int id = IARGS(2);

  double bc_ra, bc_dec;

  if ( getHealPBary1(nested, order, id, &bc_ra, &bc_dec) ) {
    *error = 1;
    *is_null = 1;
    return NULL;
  } else {
    sprintf(result,"%.16g, %.16g",bc_ra, bc_dec);
    *length = (unsigned long) strlen(result);
  }

  init->ptr = result;
  return result;
}


void HEALPBary_deinit(UDF_INIT* init)
{
}


//--------------------------------------------------------------------

my_bool HEALPBaryC_init(UDF_INIT *init, UDF_ARGS *args, char *message)
{
 const char* argerr = "HEALPBaryC(nested INT, order INT, ra DOUBLE, dec DOUBLE)";

  CHECK_ARG_NUM(4);
  CHECK_ARG_TYPE(0, INT_RESULT);
  CHECK_ARG_TYPE(1, INT_RESULT);
  CHECK_ARG_NOT_TYPE(2, STRING_RESULT);
  CHECK_ARG_NOT_TYPE(3, STRING_RESULT);

  init->maybe_null = 0;
  init->max_length = 255;
  init->const_item = 0;

  return 0;
}


char * HEALPBaryC(UDF_INIT *init, UDF_ARGS *args,
                  char *result, unsigned long *length,
                  char *is_null, char *error)
{
  int nested = IARGS(0);
  int order  = IARGS(1);
  double ra  = DARGS(2);
  double dec = DARGS(3);

  double bc_ra, bc_dec;

  if ( getHealPBaryC1(nested, order, ra, dec, &bc_ra, &bc_dec) ) {
    *error = 1;
    *is_null = 1;
    return NULL;
  } else {
    sprintf(result,"%.16g, %.16g",bc_ra, bc_dec);
    *length = (unsigned long) strlen(result);
  }

  init->ptr = result;
  return result;
}


void HEALPBaryC_deinit(UDF_INIT* init)
{
}


//--------------------------------------------------------------------

my_bool HEALPNeighb_init(UDF_INIT *init, UDF_ARGS *args, char *message)
{
 const char* argerr = "HEALPNeighb(nested INT, order INT, id INT)";

  CHECK_ARG_NUM(3);
  CHECK_ARG_TYPE(0, INT_RESULT);
  CHECK_ARG_TYPE(1, INT_RESULT);
  CHECK_ARG_TYPE(2, INT_RESULT);

  init->maybe_null = 0;
  init->max_length = 255;
  init->const_item = 0;
  return 0;
}


char * HEALPNeighb(UDF_INIT *init, UDF_ARGS *args,
                   char *result, unsigned long *length,
                   char *is_null, char *error)
{
  int nested = IARGS(0);
  int order  = IARGS(1);
  long long int id = IARGS(2);

  vector<long long int> idn;
  char temp[20];
  if ( getHealPNeighb1(nested, order, id, idn) ) {
    *error = 1;
    *is_null = 1;
    return NULL;
  } else {
    sprintf(result,"%lld",idn[0]);
    for (unsigned int i=1; i<idn.size(); i++) {
      sprintf(temp,", %lld",idn[i]);
      strcat(result,temp);
    }
    *length = (unsigned long) strlen(result);
  }

  init->ptr = result;
  return result;
}


void HEALPNeighb_deinit(UDF_INIT* init)
{
}


//--------------------------------------------------------------------

my_bool HEALPNeighbC_init(UDF_INIT *init, UDF_ARGS *args, char *message)
{
 const char* argerr = "HEALPNeighbC(nested INT, order INT, Ra_deg DOUBLE, Dec_deg DOUBLE)";

  CHECK_ARG_NUM(4);
  CHECK_ARG_TYPE(    0, INT_RESULT);
  CHECK_ARG_TYPE(    1, INT_RESULT);
  CHECK_ARG_NOT_TYPE(2, STRING_RESULT);
  CHECK_ARG_NOT_TYPE(3, STRING_RESULT);

  init->maybe_null = 0;
  init->max_length = 255;
  init->const_item = 0;

  return 0;
}


char * HEALPNeighbC(UDF_INIT *init, UDF_ARGS *args,
                    char *result, unsigned long *length,
                    char *is_null, char *error)
{
  int nested = IARGS(0);
  int order  = IARGS(1);
  double raa = DARGS(2);
  double dec = DARGS(3);

  vector<long long int> idn;
  char temp[20];

  if ( getHealPNeighbC1(nested, order, raa, dec, idn) ) {
    *error = 1;
    *is_null = 1;
    return NULL;
  } else {
    sprintf(result,"%lld",idn[0]);
    for (unsigned int i=1; i<idn.size(); i++) {
      sprintf(temp,", %lld",idn[i]);
      strcat(result,temp);
    }
    *length = (unsigned long) strlen(result);
  }

  init->ptr = result;
  return result;  //return init->ptr
}


void HEALPNeighbC_deinit(UDF_INIT* init)
{
}


//--------------------------------------------------------------------

my_bool HEALPBound_init(UDF_INIT *init, UDF_ARGS *args, char *message)
{
  const char* argerr = "HEALPBound(nested INT, order INT, id INT [, step INT])";

  switch (args->arg_count) {
  case 4:
    CHECK_ARG_TYPE(3, INT_RESULT);
  case 3:
    CHECK_ARG_TYPE(0, INT_RESULT);
    CHECK_ARG_TYPE(1, INT_RESULT);
    CHECK_ARG_TYPE(2, INT_RESULT);
    break;
  default:
    CHECK_ARG_NUM(4);  //Raise an error
  }


  init->maybe_null = 0;
  //init->max_length = 255;
  init->const_item = 0;

// Initial buffer size is 2048 chars 
  init->ptr = NULL;
  if ( !(init->ptr = (char *) malloc(sizeof(char) * 2048)) ) {
        strcpy(message, "Couldn't allocate memory!");
        return 1;
   }
   memset( init->ptr, 0, sizeof(char) * 2048 );

  return 0;
}


char * HEALPBound(UDF_INIT *init, UDF_ARGS *args,
                   char *result, unsigned long *length,
                   char *is_null, char *error)
{
  int nested = IARGS(0);
  int order  = IARGS(1);
  long long int id = IARGS(2);
  unsigned int step = 1;
  if (args->arg_count == 4)
    step = IARGS(3);

  vector<double> b_ra, b_dec;
  unsigned long nc=0;
  char temp[40];
  char *ss = init->ptr;

  if ( getHealPBound1(nested, order, id, step, b_ra, b_dec) ) {
    *error = 1;
    *is_null = 1;
    return NULL;
  } else {
    sprintf(ss,"%.16g, %.16g", b_ra[0], b_dec[0]);
    nc = strlen(ss);
    for (unsigned int i=1; i<b_ra.size(); i++) {
      sprintf(temp,", %.16g, %.16g", b_ra[i], b_dec[i]);
      nc += strlen(temp);
      if (nc > 2047) {
        char *p = (char *) realloc(ss, sizeof(char) * (nc+1));
        if (!p) {
          *error = 1;
          return 0;
        }
       ss = p;
      }
      strcat(ss,temp);
    }
    *length = (unsigned long) strlen(ss);
  }

  init->ptr = ss;
  return ss;
}


void HEALPBound_deinit(UDF_INIT* init)
{}



//--------------------------------------------------------------------

my_bool HEALPBoundC_init(UDF_INIT *init, UDF_ARGS *args, char *message)
{
  const char* argerr = "HEALPBoundC(nested INT, order INT, RA_deg DOUBLE, Dec_deg DOUBLE [, step INT])";

  switch (args->arg_count) {
  case 5:
    CHECK_ARG_TYPE(4, INT_RESULT);
  case 4:
    CHECK_ARG_TYPE(0, INT_RESULT);
    CHECK_ARG_TYPE(1, INT_RESULT);
    CHECK_ARG_NOT_TYPE(2, STRING_RESULT);
    CHECK_ARG_NOT_TYPE(3, STRING_RESULT);
    break;
  default:
    CHECK_ARG_NUM(5);  //Raise an error
  }

  init->maybe_null = 0;
  //init->max_length = 255;
  init->const_item = 0;

// Initial buffer size is 2048 chars
  init->ptr = NULL;
  if ( !(init->ptr = (char *) malloc(sizeof(char) * 2048)) ) {
        strcpy(message, "Couldn't allocate memory!");
        return 1;
   }
   memset( init->ptr, 0, sizeof(char) * 2048 );

  return 0;
}


char * HEALPBoundC(UDF_INIT *init, UDF_ARGS *args,
                   char *result, unsigned long *length,
                   char *is_null, char *error)
{
  int nested = IARGS(0);
  int order  = IARGS(1);
  double ra = DARGS(2);
  double de = DARGS(3);
  unsigned int step = 1;
  if (args->arg_count == 5)
    step = IARGS(4);

  vector<double> b_ra, b_dec;
  unsigned long nc=0;
  char temp[51];
  char *ss = init->ptr;

  if ( getHealPBoundC1(nested, order, ra, de, step, b_ra, b_dec) ) {
    *error = 1;
    *is_null = 1;
    return NULL;
  } else {
    sprintf(ss,"%.16g, %.16g", b_ra[0], b_dec[0]);
    nc = strlen(ss);
    for (unsigned int i=1; i<b_ra.size(); i++) {
      sprintf(temp,", %.16g, %.16g", b_ra[i], b_dec[i]);
      nc += strlen(temp);
      if (nc > 2047) {
        char *p = (char *) realloc(ss, sizeof(char) * (nc+1));
        if (!p) {
          *error = 1;
          return 0;
        }
       ss = p;
      }
      strcat(ss,temp);
    }
    *length = (unsigned long) strlen(ss);
  }

  init->ptr = ss;
  return ss;
}


void HEALPBoundC_deinit(UDF_INIT* init)
{}



//--------------------------------------------------------------------

my_bool SIDCircleHEALP_init(UDF_INIT* init, UDF_ARGS *args, char *message)
{
  const char* argerr = "SIDCircleHEALP(nested INT, order INT, Ra_deg DOUBLE, Dec_deg DOUBLE, Rad_arcmin DOUBLE)";

// Assume nested by default if fisrt parameter is missing (4 params passed)
  switch (args->arg_count) {
  case 5:
    CHECK_ARG_TYPE(0, INT_RESULT);
  case 4:
    CHECK_ARG_TYPE(0, INT_RESULT);
    CHECK_ARG_NOT_TYPE(1, STRING_RESULT);
    CHECK_ARG_NOT_TYPE(2, STRING_RESULT);
    CHECK_ARG_NOT_TYPE(3, STRING_RESULT);
    break;
  default:
    CHECK_ARG_NUM(5);  //Raise an error
  }

  init->maybe_null = 0;
  init->max_length = 255;
  init->const_item = 0;

  init->ptr = (char *)malloc(sizeof (myD));

  ((struct myD*)init->ptr)->flist = new vector<uint64>; 
  ((struct myD*)init->ptr)->plist = new vector<uint64>; 
  ((struct myD*)init->ptr)->count = 0;

  return 0;
}


char* SIDCircleHEALP(UDF_INIT *init, UDF_ARGS *args,
                   char *result, unsigned long *length,
                   char *is_null, char *error)
{
  int nested=1, order;
  double rac, dec, rad;
  if (args->arg_count == 5) {
    nested = IARGS(0);
    order  = IARGS(1);
    rac = DARGS(2);
    dec = DARGS(3);
    rad = DARGS(4);
  } else {
    order  = IARGS(0);
    rac = DARGS(1);
    dec = DARGS(2);
    rad = DARGS(3);
  }

  struct myD* m = (struct myD*) init->ptr;

  if (myHealPCone(nested, order, rac, dec, rad, *(m->flist),*(m->plist))) {
    *error = 1;
    *is_null = 1;
    return NULL;
  }
 
//fprintf(stderr, "FULL: %ld  PARTIAL: %ld\n", m->flist->size(), m->plist->size()); 

  char buff[32];
  sprintf(buff, "%p", m);


  *length = strlen(buff);
  strcpy(result, buff);
  return result;

}


void SIDCircleHEALP_deinit(UDF_INIT *init)
{
}


//--------------------------------------------------------------------

my_bool SIDRectHEALP_init(UDF_INIT* init, UDF_ARGS *args, char *message)
{
//This function requires the coordinate of the center of the rectangular region and one or two sides.
const char* argerr = "SIDRectHEALP(Nested INT, Order INT, Ra_deg DOUBLE, Dec_deg DOUBLE, side_ra_arcmin DOUBLE [, side_dec_arcmin DOUBLE])";

  switch (args->arg_count) {
  case 6:
    CHECK_ARG_NOT_TYPE(5, STRING_RESULT);
  case 5:
    CHECK_ARG_NOT_TYPE(0, STRING_RESULT);
    CHECK_ARG_NOT_TYPE(1, STRING_RESULT);
    CHECK_ARG_NOT_TYPE(2, STRING_RESULT);
    CHECK_ARG_NOT_TYPE(3, STRING_RESULT);
    CHECK_ARG_NOT_TYPE(4, STRING_RESULT);
    break;
  default:
    CHECK_ARG_NUM(6);  //Raise an error.
  }


  init->maybe_null = 0;
  init->max_length = 255;
  init->const_item = 0;

  init->ptr = (char *)malloc(sizeof (myD));

  ((struct myD*)init->ptr)->flist = new vector<uint64>;
  ((struct myD*)init->ptr)->plist = new vector<uint64>;
  ((struct myD*)init->ptr)->count = 0;

  return 0;
}


char* SIDRectHEALP(UDF_INIT *init, UDF_ARGS *args,
                 char *result, unsigned long *length,
                 char *is_null, char *error)
{
  int nested = IARGS(0);
  int order  = IARGS(1);
  double cra = DARGS(2);
  double cde = DARGS(3);
  double hside_ra = DARGS(4)/120.;
  double hside_de = (args->arg_count == 6  ?  DARGS(5)/120.  :  hside_ra);

// Some parameter checks
  if (cra < 0.) cra += 360.;

  if ( (! (  0. <= cra      &&  cra       <  360.))  ||
       (! (-90. <= cde      &&  cde       <=  90.))  ||
       (! (  0. < hside_ra  &&  hside_ra  <= 180.))  ||
       (! (  0. < hside_de  &&  hside_de  <=  90.)) ) {
    *error = 1;
    *is_null = 1;
    return NULL;
  }

  hside_ra /= cos(cde*DEG2RAD);

  if (hside_ra > 180.) hside_ra = 180.;

  double ra[4], de[4];

  ra[0] = cra - hside_ra;
  de[0] = cde - hside_de;
  ra[2] = cra + hside_ra;
  de[1] = cde + hside_de;
  ra[1] = ra[0];
  de[2] = de[1];
  ra[3] = ra[2];
  de[3] = de[0];

  struct myD* m = (struct myD*) init->ptr;

  if (myHealPRect4v(nested, order, ra, de, *(m->flist),*(m->plist))) {
    *error = 1;
    *is_null = 1;
    return NULL;
  }

//fprintf(stderr, "FULL: %ld  PARTIAL: %ld\n", m->flist->size(), m->plist->size()); 

  char buff[32];
  sprintf(buff, "%p", m);


  *length = strlen(buff);
  strcpy(result, buff);

  return result;
}


void SIDRectHEALP_deinit(UDF_INIT *init)
{
}


//--------------------------------------------------------------------

my_bool SIDRectvHEALP_init(UDF_INIT* init, UDF_ARGS *args, char *message)
{
//This function requires the coordinates of the 2 opposite (or 4) corners of the rectangular region.
const char* argerr = "SIDRectvHEALP(Nested INT, Order INT, Ra1_deg DOUBLE, Dec1_deg DOUBLE, Ra2_deg DOUBLE, Dec2_deg DOUBLE [, x 2])";


  switch (args->arg_count) {
  case 10:
    CHECK_ARG_NOT_TYPE(6, STRING_RESULT);
    CHECK_ARG_NOT_TYPE(7, STRING_RESULT);
    CHECK_ARG_NOT_TYPE(8, STRING_RESULT);
    CHECK_ARG_NOT_TYPE(9, STRING_RESULT);
  case 6:
    CHECK_ARG_NOT_TYPE(0, STRING_RESULT);
    CHECK_ARG_NOT_TYPE(1, STRING_RESULT);
    CHECK_ARG_NOT_TYPE(2, STRING_RESULT);
    CHECK_ARG_NOT_TYPE(3, STRING_RESULT);
    CHECK_ARG_NOT_TYPE(4, STRING_RESULT);
    CHECK_ARG_NOT_TYPE(5, STRING_RESULT);
    break;
  default:
    CHECK_ARG_NUM(6); //Raise an error
  }

  init->maybe_null = 0;
  init->max_length = 255;
  init->const_item = 0;

  init->ptr = (char *)malloc(sizeof (myD));

  ((struct myD*)init->ptr)->flist = new vector<uint64>;
  ((struct myD*)init->ptr)->plist = new vector<uint64>;
  ((struct myD*)init->ptr)->count = 0;

  return 0;
}


char * SIDRectvHEALP(UDF_INIT *init, UDF_ARGS *args,
               char *result, unsigned long *length,
               char *is_null, char *error)
{
  int nested = IARGS(0);
  int order = IARGS(1);

  double ra[4], de[4];

  if (args->arg_count == 6) {
    ra[0] = DARGS(2);
    de[0] = DARGS(3);
    ra[1] = DARGS(4);
    de[1] = DARGS(5);

// Order ranges (clockwise)
    if (ra[0] < ra[1]) {
      ra[0] = ra[0];
      ra[2] = ra[1];
    } else {
      ra[0] = ra[1];
      ra[2] = ra[0];
    }
    ra[1] = ra[0];
    ra[3] = ra[2];

    if (de[0] < de[1]) {
      de[0] = de[0];
      de[1] = de[1];
    } else {
      de[0] = de[1];
      de[1] = de[0];
    }
    de[2] = de[1];
    de[3] = de[0];

  }
  else {
    for (unsigned short i=2; i<args->arg_count; i+=2) {
      ra[i] = DARGS(i);
      de[i] = DARGS(i+1);
    }
  }


  struct myD* m = (struct myD*) init->ptr;

  if (myHealPRect4v(nested, order, ra, de, *(m->flist),*(m->plist))) {
    *error = 1;
    *is_null = 1;
    return NULL;
  }

  char buff[32];
  sprintf(buff, "%p", m);


  *length = strlen(buff);
  strcpy(result, buff);

  return result;
}


void SIDRectvHEALP_deinit(UDF_INIT *init)
{
}

//--------------------------------------------------------------------



//--------------------------------------------------------------------
//  Below generic functions
//--------------------------------------------------------------------

my_bool SIDCount_init(UDF_INIT* init, UDF_ARGS *args, char *message)
{

  init->maybe_null = 0;
  init->const_item = 0;

  return 0;
}


longlong SIDCount(UDF_INIT *init, UDF_ARGS *args,
                   char *is_null, char* error)
{
  char* p = CARGS(0);
  int full = IARGS(1);

  struct myD* m = (struct myD*)p;
  sscanf(p, "%p", &m);

//fprintf(stderr, "PAPPO: %p\n", m); 
//fprintf(stderr, "N_full, N_part: %ld, %ld", m->flist->size(), m->plist->size());

  if (full)
    return m->flist->size();

  return m->plist->size();
}


void SIDCount_deinit(UDF_INIT *init)
{
}


//--------------------------------------------------------------------

my_bool SIDGetID_init(UDF_INIT* init, UDF_ARGS *args, char *message)
{
  init->maybe_null = 0;
  init->const_item = 0;

  return 0;
}


longlong SIDGetID(UDF_INIT *init, UDF_ARGS *args,
                   char *is_null, char* error)
{
  char* p = CARGS(0);
  unsigned long long int pos = IARGS(1);
  int full = IARGS(2);

  struct myD* m = (struct myD*)p;
  sscanf(p, "%p", &m);

  if (full)
    return m->flist->at(pos);

  return m->plist->at(pos);
}


void SIDGetID_deinit(UDF_INIT *init)
{
}


//--------------------------------------------------------------------

my_bool SIDClear_init(UDF_INIT* init, UDF_ARGS *args, char *message)
{
  init->maybe_null = 0;
  init->const_item = 0;

  return 0;
}


longlong SIDClear(UDF_INIT *init, UDF_ARGS *args,
                   char *is_null, char* error)
{
  char* p = CARGS(0);

  struct myD* m = (struct myD*)p;
  sscanf(p, "%p", &m);

  delete m->flist;
  delete m->plist;

  free (m);

  return 0;
}


void SIDClear_deinit(UDF_INIT *init)
{
}


//--------------------------------------------------------------------

my_bool Sphedist_init(UDF_INIT* init, UDF_ARGS *args, char *message)
{
  const char* argerr = "Sphedist(Ra1_deg DOUBLE, Dec1_deg DOUBLE, Ra2_deg DOUBLE, Dec2_deg DOUBLE)";

  CHECK_ARG_NUM(4);
  CHECK_ARG_NOT_TYPE(0, STRING_RESULT);
  CHECK_ARG_NOT_TYPE(1, STRING_RESULT);
  CHECK_ARG_NOT_TYPE(2, STRING_RESULT);
  CHECK_ARG_NOT_TYPE(3, STRING_RESULT);

  init->decimals = NOT_FIXED_DEC;

  return 0;
}


double Sphedist(UDF_INIT *init, UDF_ARGS *args,
                char *is_null, char* error)
{
  return skysep_h(DARGS(0), DARGS(1), DARGS(2), DARGS(3), 0);
}


void Sphedist_deinit(UDF_INIT *init)
{
}




//--------------------------------------------------------------------


/*
my_bool pluto_init(UDF_INIT *init, UDF_ARGS *args, char *message)
{
 const char* argerr = "";


  init->maybe_null = 1;
//  init->max_length = 255;
  init->const_item = 0;

  return 0;
}

char * pluto(UDF_INIT *init, UDF_ARGS *args,
                 char *result, unsigned long *length,
                 char *is_null, char *error)
{

  char* p = CARGS(0);

  struct myD *m = (struct myD*)p;
  *length = 1;
  result = &(m->firstTime);
  return &(m->firstTime);
}


void pluto_deinit(UDF_INIT* init)
{
}
*/
