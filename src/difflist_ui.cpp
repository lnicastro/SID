/*
  Name: void difflist_ui

  Description:
   Return in vdiff the (v1 - v2).

  Input:
   vector<uint64>& v1
   vector<uint64>& v2

  Output:
   vector<uint64>& vdiff

  Note:
   Input vector lists must be sorted in "ascending" order.
   v2 should be a sub-set of v1.

  LN@IASF-INAF, Aug 2007                        Last change: 31/03/2017
*/

#include <vector>

#include "datatypes.h"

using namespace std;

void difflist_ui(vector<unsigned long long int>& v1,
                vector<unsigned long long int>& v2,
                vector<unsigned long long int>& vdiff)
{
  unsigned long long int i, j0=0, j=0, n1, n2;

  vdiff.clear();
  n1 = v1.size();
  n2 = v2.size();

  if (n1 == 0) return;

  for (i=0; i<n2; i++) {

    for (j=j0; j<n1; j++) {
      if (v1[j] < v2[i]) {  //
        vdiff.push_back(v1[j]);
      }
      else if (v1[j] == v2[i]) {
        j0 = j + 1;
        break;
      }
      else
      if (v1[j] > v2[i]) { // should never happen
        j0 = j;
        break;
      }
    }

  }

// Assign remaining elements
  if ( j < n1 )
    for (j=j0; j<n1; j++) vdiff.push_back(v1[j]);

}
