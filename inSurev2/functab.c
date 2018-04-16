#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define USER_DEFINED 0
#define SYSTEM_DEFINED 1
#define BANNED_DEFINED 2

struct funcTableData {
	int type;
	char name[64];
	struct funcTableData* next;
};

struct funcTable {
	struct funcTableData* head;
	int len;
};

struct funcTable* FUNC_SYMBOL_TABLE;

char *bannedFunctionNames[] = {"strcpy", "strcpyA", "strcpyW", "wcscpy", "_tcscpy", "_mbscpy", "StrCpy", "StrCpyA", "StrCpyW", "lstrcpy", "lstrcpyA", "lstrcpyW", "_tccpy", "_mbccpy", "_ftcscpy", "strncpy", "wcsncpy", "_tcsncpy", "_mbsncpy", "_mbsnbcpy", "StrCpyN", "StrCpyNA", "StrCpyNW", "StrNCpy", "strcpynA", "StrNCpyA", "StrNCpyW", "lstrcpyn", "lstrcpynA", "lstrcpynW", "strcat", "strcatA", "strcatW", "wcscat", "_tcscat", "_mbscat", "StrCat", "StrCatA", "StrCatW", "lstrcat", "lstrcatA", "lstrcatW", "StrCatBuff", "StrCatBuffA", "StrCatBuffW", "StrCatChainW", "_tccat", "_mbccat", "_ftcscat", "strncat", "wcsncat", "_tcsncat", "_mbsncat", "_mbsnbcat", "StrCatN", "StrCatNA", "StrCatNW", "StrNCat", "StrNCatA", "StrNCatW", "lstrncat", "lstrcatnA", "lstrcatnW", "lstrcatn", "sprintfW", "sprintfA", "wsprintf", "wsprintfW", "wsprintfA", "sprintf", "swprintf", "_stprintf", "wvsprintf", "wvsprintfA", "wvsprintfW", "vsprintf", "_vstprintf", "vswprintf", "wnsprintf", "wnsprintfA", "wnsprintfW", "_snwprintf", "snprintf", "sntprintf", "_vsnprintf", "vsnprintf", "_vsnwprintf", "_vsntprintf", "wvnsprintf", "wvnsprintfA", "wvnsprintfW", "_snwprintf", "_snprintf", "_sntprintf", "nsprintf", "wvsprintf", "wvsprintfA", "wvsprintfW", "vsprintf", "_vstprintf", "vswprintf", "_vsnprintf", "_vsnwprintf", "_vsntprintf", "wvnsprintf", "wvnsprintfA", "wvnsprintfW", "strncpy", "wcsncpy", "_tcsncpy", "_mbsncpy", "_mbsnbcpy", "StrCpyN", "StrCpyNA", "StrCpyNW", "StrNCpy", "strcpynA", "StrNCpyA", "StrNCpyW", "lstrcpyn", "lstrcpynA", "lstrcpynW", "_fstrncpy", "strncat", "wcsncat", "_tcsncat", "_mbsncat", "_mbsnbcat", "StrCatN", "StrCatNA", "StrCatNW", "StrNCat", "StrNCatA", "StrNCatW", "lstrncat", "lstrcatnA", "lstrcatnW", "lstrcatn", "_fstrncat", "strtok", "_tcstok", "wcstok", "_mbstok", "makepath", "_tmakepath", "_makepath", "_wmakepath", "_splitpath", "_tsplitpath", "_wsplitpath", "scanf", "wscanf", "_tscanf", "sscanf", "swscanf", "_stscanf", "snscanf", "snwscanf", "_sntscanf", "_itoa", "_itow", "_i64toa", "_i64tow", "_ui64toa", "_ui64tot", "_ui64tow", "_ultoa", "_ultot", "_ultow", "gets", "_getts", "_gettws", "IsBadWritePtr", "IsBadHugeWritePtr", "IsBadReadPtr", "IsBadHugeReadPtr", "IsBadCodePtr", "IsBadStringPtr", "CharToOem", "CharToOemA", "CharToOemW", "OemToChar", "OemToCharA", "OemToCharW", "CharToOemBuffA", "CharToOemBuffW", "strlen", "wcslen", "_mbslen", "_mbstrlen", "StrLen", "lstrlen", "memcpy", "RtlCopyMemory", "CopyMemory", "wmemcpy", "ChangeWindowMessageFilter" };

void init_functable()
{
	FUNC_SYMBOL_TABLE = malloc(sizeof(struct funcTable));
	FUNC_SYMBOL_TABLE->head = NULL;
	FUNC_SYMBOL_TABLE->len = 0;
}

int in_functable(char* id)
{
	struct funcTableData* walk = FUNC_SYMBOL_TABLE->head;
	while(walk != NULL)
	{
		if(strcmp(id, walk->name) == 0)
			return 1;

		walk = walk->next;
	}

	return 0;
}

void add_functable(char* id)
{
	struct funcTableData* node = malloc(sizeof(struct funcTableData));
	node->next = FUNC_SYMBOL_TABLE->head;
	strcpy(node->name, id);
	FUNC_SYMBOL_TABLE->head = node;
}

void add_functype(char* id, int type)
{
	struct funcTableData* walk = FUNC_SYMBOL_TABLE->head;
	while(walk != NULL)
	{
		if(strcmp(id, walk->name) == 0)
		{
			if(type == SYSTEM_DEFINED)
			{
				int i;
				for(int i = 0; i < sizeof(bannedFunctionNames)/sizeof(char*); i++)
				{
					if(strcmp(bannedFunctionNames[i], id) == 0)
					{
						type = BANNED_DEFINED;
					}
				}
			}
			printf("%s is %d: banned 3\n", id, type);
			walk->type = type;
			return;
		}

		walk = walk->next;
	}

	add_functable(id);
	add_functype(id, type);
}

int get_functype(char* id)
{
	struct funcTableData* walk = FUNC_SYMBOL_TABLE->head;
	while(walk != NULL)
	{
		if(strcmp(id, walk->name) == 0)
		{
			return walk->type;
		}

		walk = walk->next;
	}
	return -1;
}
