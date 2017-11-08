#include "stdio.h"
int main() {

  int a = 13;

  int *p = &a;

  char buff [100] = {'\0'};


  sprintf(buff, "%p", p);

  printf("%p\n", p);


  int *q;

  sscanf(buff, "%p", &q);

  printf("%p\n", q);

  printf("%d\n", *q);

return 0;
}


