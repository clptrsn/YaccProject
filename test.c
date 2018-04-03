#include<stdio.h>

int three()
{

return 3;
}

int main()
{
	#ifndef OMITBAD
		three();
	#endif
	#ifndef OMITGOOD
		return 7;
	#endif
}
