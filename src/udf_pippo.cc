#include <my_global.h>
#include <my_sys.h>

#include <new>
#include <vector>
#include <algorithm>

#if defined(MYSQL_SERVER)
#include <m_string.h>           /* To get strmov() */
#else
/* when compiled as standalone */
#include <string.h>
#define strmov(a,b) stpcpy(a,b)
#endif

#include <mysql.h>
#include <ctype.h>


#define CARGS(A) ((char*) args->args[A])

C_MODE_START;

my_bool pippo_init(UDF_INIT *initid, UDF_ARGS *args, char *message);
void pippo_deinit(UDF_INIT *initid);
char *pippo(UDF_INIT *initid, UDF_ARGS *args, char *result,
               unsigned long *length, char *is_null, char *error);

my_bool pluto_init(UDF_INIT *initid, UDF_ARGS *args, char *message);
void pluto_deinit(UDF_INIT *initid);
char *pluto(UDF_INIT *initid, UDF_ARGS *args, char *result,
               unsigned long *length, char *is_null, char *error);

C_MODE_END;


typedef struct myData
{
    char firstTime;
    char is_null;
    char error;
    char flag;
    long long val;
    long long tmp;
};


my_bool pippo_init(UDF_INIT *init, UDF_ARGS *args, char *message)
{
 const char* argerr = "";


  init->maybe_null = 1;
//  init->max_length = 255;
  init->const_item = 0;

  return 0;
}

char * pippo(UDF_INIT *init, UDF_ARGS *args,
                 char *result, unsigned long *length,
                 char *is_null, char *error)
{

    struct myData *m = (struct myData*) malloc(sizeof (myData));

    m->firstTime = 65;
    m->is_null = 66;
    m->error = 67;
    m->flag = 64;
    m->val = 13;
    m->tmp = 14;

  *length = sizeof(m);
  result = (char*)m;
  return (char *)m;
}


void pippo_deinit(UDF_INIT* init)
{
}




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

  struct myData *m = (struct myData*)p;
  *length = 1;
  result = &(m->firstTime);
  return &(m->firstTime);
}


void pluto_deinit(UDF_INIT* init)
{
}
