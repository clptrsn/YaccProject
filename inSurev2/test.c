#include<stdio.h>
typedef struct testDef {
	int x;
} s;

enum X {
	MONDAY = 0,
	TUESDAY = 1
}

int main()
{
#ifdef TEST
s A;
MONDAY;
printf("test");
#endif
}
