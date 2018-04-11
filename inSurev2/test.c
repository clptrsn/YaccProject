#include<stdio.h>
typedef struct testDef {
	int x;
} yams;

enum X {
	MONDAY = 0,
	TUESDAY = 1
};

#ifndef OMITBAD
int main()
{

#ifndef OMITGOOD

yams A;
MONDAY;

#endif
printf("test");
}
#endif
