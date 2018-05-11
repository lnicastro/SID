using namespace std;

#include <vector>

//General external functions

double skysep_h(double phi1, double theta1, double phi2, double theta2, short radians);
void difflist_ui(vector<unsigned long long int>& v1, vector<unsigned long long int>& v2, vector<unsigned long long int>& vdiff);


//HTM-related functions

int getHTMnameById(char*& saved, unsigned long long int id, char *idname);
int getHTMnameById1(unsigned long long int id, char *idname);
int getHTMidByName(char*& saved, const char *idname, unsigned long long int* id);
int getHTMid(char*& saved, int depth, double ra, double dec, unsigned long long int* id);

void cleanHTMUval(char*& saved);
void cleanHTMsUval(char*& saved, char*& osaved);

int getHTMNeighb(char*& saved, int depth, unsigned long long int id,
                 vector<unsigned long long int>& idn);

int getHTMNeighb1(int depth, unsigned long long int id,
                  vector<unsigned long long int>& idn);

int getHTMsNeighb(char*& saved, char*& osaved, int depth, unsigned long long int id, int odepth,
                 vector<unsigned long long int>& idn);

int getHTMsNeighb1(int depth, unsigned long long int id, int odepth,
                 vector<unsigned long long int>& idn);

int getHTMNeighbC(char*& saved, int depth, double ra, double dec,
                  vector<unsigned long long int>& idn);

int getHTMNeighbC1(int depth, double ra, double dec,
                   vector<unsigned long long int>& idn);

int getHTMBary(char*& saved, int depth, unsigned long long int id,
               double *bc_ra, double *bc_dec);

int getHTMBary1(int depth, unsigned long long int id,
                double *bc_ra, double *bc_dec);

int getHTMBaryC(char*& saved, int depth, double ra, double dec,
                double *bc_ra, double *bc_dec);

int getHTMBaryC1(int depth, double ra, double dec,
                 double *bc_ra, double *bc_dec);

double getHTMBaryDist(char*& saved, int depth, unsigned long long int id,
                      double ra, double dec);

double getHTMBaryDist1(int depth, unsigned long long int id,
                       double ra, double dec);



int htmCircleRegion(int depth, double ra, double dec, double radius,
                    vector<unsigned long long int>& flist2,
                    vector<unsigned long long int>& plist2);

int htmRectRegion(int depth, double ra[4], double dec[4],
                  vector<unsigned long long int>& flist2,
                  vector<unsigned long long int>& plist2);


//HEALPix-related functions

int getHealPid(char*& saved, int nested, int order, double ra, double dec, long long int *id);
void cleanHealPUval(char*& saved);

int myHealPCone(int nested, int order, double ra, double dec, double radius,
                vector<long long int>& flist,
                vector<long long int>& plist);

int getHealPNeighb(char*& saved, int nested, int order, long long int id,
                   vector<long long int>& idn);

int getHealPNeighb1(int nested, int order, long long int id,
                   vector<long long int>& idn);

int getHealPNeighbC(char*& saved, int nested, int order, double ra, double dec,
                    vector<long long int>& idn);

int getHealPNeighbC1(int nested, int order, double ra, double dec,
                     vector<long long int>& idn);


int getHealPBary(char*& saved, int nested, int order, long long int id,
                 double *bc_ra, double *bc_dec);

int getHealPBary1(int nested, int order, long long int id,
                  double *bc_ra, double *bc_dec);

int getHealPBaryC(char*& saved, int nested, int order, double ra, double dec,
                  double *bc_ra, double *bc_dec);

int getHealPBaryC1(int nested, int order, double ra, double dec,
                   double *bc_ra, double *bc_dec);

double getHealPBaryDist(char*& saved, int nested, int order, long long int id,
                        double ra, double dec);

double getHealPBaryDist1(int nested, int order, long long int id,
                         double ra, double dec);

double getHealPMaxS(char*& saved, int order);

double getHealPMaxS1(int order);

int getHealPBound(char*& saved, int nested, int k, long long int id, unsigned int step,
                 vector<double> &b_ra, vector<double> &b_dec);

int getHealPBound1(int nested, int k, long long int id, unsigned int step,
                  vector<double> &b_ra, vector<double> &b_dec);

int getHealPBoundC(char*& saved, int nested, int k, double ra, double dec, unsigned int step,
                 vector<double> &b_ra, vector<double> &b_dec);

int getHealPBoundC1(int nested, int k, double ra, double dec, unsigned int step,
                  vector<double> &b_ra, vector<double> &b_dec);

int myHealPCone(int nested, int k, double ra, double dec, double radius,
                vector<unsigned long long int>& flist, vector<unsigned long long int>& plist);

int myHealPRect4v(int nested, int k, const double ra[4], const double de[4],
                vector<unsigned long long int>& flist,
                vector<unsigned long long int>& plist);
