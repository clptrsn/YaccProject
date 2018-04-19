#include <stdio.h>
#include <string.h>
#include <stdlib.h>

struct symTableData {
	int type;
	char name[64];
	struct symTableData* next;
};

struct symTable {
	struct symTableData* head;
	int len;
};

struct symTable* SYMBOL_TABLE;

void print_symtable() {
	struct symTableData* walk = SYMBOL_TABLE->head;
	while(walk != NULL)
	{
		printf("%s %d\n", walk->name, walk->type);
		walk = walk->next;
	}
}

void init_symtable()
{
	SYMBOL_TABLE = malloc(sizeof(struct symTable));
	SYMBOL_TABLE->head = NULL;
	SYMBOL_TABLE->len = 0;
}

int in_table(char* id)
{
	struct symTableData* walk = SYMBOL_TABLE->head;
	while(walk != NULL)
	{
		if(strcmp(id, walk->name) == 0)
			return 1;

		walk = walk->next;
	}

	return 0;
}

void add_table(char* id)
{
	struct symTableData* node = malloc(sizeof(struct symTableData));
	node->next = SYMBOL_TABLE->head;
	strcpy(node->name, id);
	SYMBOL_TABLE->head = node;
}

void add_type(char* id, int type)
{
	struct symTableData* walk = SYMBOL_TABLE->head;
	while(walk != NULL)
	{
		if(strcmp(id, walk->name) == 0)
		{
			walk->type = type;
			return;
		}

		walk = walk->next;
	}

	add_table(id);
	add_type(id, type);
}

int get_type(char* id)
{
	struct symTableData* walk = SYMBOL_TABLE->head;
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

