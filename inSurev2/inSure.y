%token	IDENTIFIER I_CONSTANT F_CONSTANT STRING_LITERAL FUNC_NAME SIZEOF
%token	PTR_OP INC_OP DEC_OP LEFT_OP RIGHT_OP LE_OP GE_OP EQ_OP NE_OP
%token	AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN
%token	SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN
%token	XOR_ASSIGN OR_ASSIGN
%token	TYPEDEF_NAME ENUMERATION_CONSTANT

%token	TYPEDEF EXTERN STATIC AUTO REGISTER INLINE
%token	CONST RESTRICT VOLATILE
%token	BOOL CHAR SHORT INT LONG SIGNED UNSIGNED FLOAT DOUBLE VOID
%token	COMPLEX IMAGINARY 
%token	STRUCT UNION ENUM ELLIPSIS

%token	CASE DEFAULT IF ELSE SWITCH WHILE DO FOR GOTO CONTINUE BREAK RETURN

%token	ALIGNAS ALIGNOF ATOMIC GENERIC NORETURN STATIC_ASSERT THREAD_LOCAL

%start translation_unit
%{
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

typedef struct {
	int ival;
	char *str;
	char id[64];
	int hasTypedef;
} tstruct;

#define YYSTYPE tstruct

int hasTypedef = 0;

extern void init_symtable();
extern void add_type(char* id, int type);
extern void add_table(char* id);
extern void in_table(char* id);
extern int get_type(char* id);

char* newStr(char const *fmt, ...);
int yylex();
void yyerror(char *s);
%}
%%

primary_expression
	: IDENTIFIER {
		$$.str = newStr("%s", $1.str);
	}
	| constant {
		$$.str = newStr("%s", $1.str);
	}
	| string {
		$$.str = newStr("%s", $1.str);
	}
	| '(' expression ')' {
		$$.str = newStr("(%s)", $2.str);
	}
	| generic_selection {
		$$.str = newStr("%s", $1.str);
	}
	;

constant
	: I_CONSTANT		/* includes character_constant */ {
		$$.str = newStr("%s", $1.str);
	}
	| F_CONSTANT {
		$$.str = newStr("%s", $1.str);
	}
	| ENUMERATION_CONSTANT	/* after it has been defined as such */ {
		$$.str = newStr("%s", $1.str);
	}
	;

enumeration_constant		/* before it has been defined as such */
	: IDENTIFIER {
		add_type($1.str, ENUMERATION_CONSTANT);

		$$.str = newStr("%s", $1.str);
	}
	;

string
	: STRING_LITERAL {
		$$.str = newStr("%s", $1.str);
	}
	| FUNC_NAME {
		$$.str = newStr("%s", $1.str);
	}
	;

generic_selection
	: GENERIC '(' assignment_expression ',' generic_assoc_list ')' {
		$$.str = newStr("%s(%s,%s)", $1.str, $3.str, $5.str);
	}
	;

generic_assoc_list
	: generic_association {
		$$.str = newStr("%s", $1.str);
	}
	| generic_assoc_list ',' generic_association {
		$$.str = newStr("%s, $s", $1.str, $3.str);
	}
	;

generic_association
	: type_name ':' assignment_expression {
		$$.str = newStr("%s: %s", $1.str, $3.str);
	}
	| DEFAULT ':' assignment_expression {
		$$.str = newStr("%s: %s", $1.str, $3.str);
	}
	;

postfix_expression
	: primary_expression {
		$$.str = newStr("%s", $1.str);
	}
	| postfix_expression '[' expression ']' {
		$$.str = newStr("%s[%s]", $1.str, $3.str);
	}
	| postfix_expression '(' ')' {
		$$.str = newStr("%s()", $1.str);
	}
	| postfix_expression '(' argument_expression_list ')' {
		$$.str = newStr("%s(%s)", $1.str, $3.str);
	}
	| postfix_expression '.' IDENTIFIER {
		$$.str = newStr("%s.%s", $1.str, $3.str);
	}
	| postfix_expression PTR_OP IDENTIFIER {
		$$.str = newStr("%s%s%s", $1.str, $2.str, $3.str);
	}
	| postfix_expression INC_OP {
		$$.str = newStr("%s%s", $1.str, $2.str);
	}
	| postfix_expression DEC_OP {
		$$.str = newStr("%s%s", $1.str, $2.str);
	}
	| '(' type_name ')' '{' initializer_list '}' {
		$$.str = newStr("(%s) { %s }", $2.str, $5.str);
	}
	| '(' type_name ')' '{' initializer_list ',' '}' {
		$$.str = newStr("(%s) { %s, }", $2.str, $5.str);
	}
	;

argument_expression_list
	: assignment_expression {
		$$.str = newStr("%s", $1.str);
	}
	| argument_expression_list ',' assignment_expression {
		$$.str = newStr("%s, %s", $1.str, $3.str);
	}
	;

unary_expression
	: postfix_expression {
		$$.str = newStr("%s", $1.str);
	}
	| INC_OP unary_expression {
		$$.str = newStr("%s%s", $1.str, $2.str);
	}
	| DEC_OP unary_expression {
		$$.str = newStr("%s%s", $1.str, $2.str);
	}
	| unary_operator cast_expression {
		$$.str = newStr("%s%s", $1.str, $2.str);
	}
	| SIZEOF unary_expression {
		$$.str = newStr("%s%s", $1.str, $2.str);
	}
	| SIZEOF '(' type_name ')' {
		$$.str = newStr("%s(%s)", $1.str, $3.str);
	}
	| ALIGNOF '(' type_name ')' {
		$$.str = newStr("%s(%s)", $1.str, $3.str);
	}
	;

unary_operator
	: '&'
	| '*'
	| '+'
	| '-'
	| '~'
	| '!'
	;

cast_expression
	: unary_expression {
		$$.str = newStr("%s", $1.str);
	}
	| '(' type_name ')' cast_expression {	
		$$.str = newStr("(%s) %s", $2.str, $4.str);
	}
	;

multiplicative_expression
	: cast_expression {
		$$.str = newStr("%s", $1.str);
	}
	| multiplicative_expression '*' cast_expression {
		$$.str = newStr("%s * %s", $1.str, $3.str);
	}
	| multiplicative_expression '/' cast_expression {
		$$.str = newStr("%s / %s", $1.str, $3.str);
	}
	| multiplicative_expression '%' cast_expression {
		$$.str = newStr("%s % %s", $1.str, $3.str);
	}
	;

additive_expression
	: multiplicative_expression {
		$$.str = newStr("%s", $1.str);
	}
	| additive_expression '+' multiplicative_expression {
		$$.str = newStr("%s + %s", $1.str, $3.str);
	}
	| additive_expression '-' multiplicative_expression {
		$$.str = newStr("%s - %s", $1.str, $3.str);
	}
	;

shift_expression
	: additive_expression {
		$$.str = newStr("%s", $1.str);
	}
	| shift_expression LEFT_OP additive_expression {
		$$.str = newStr("%s %s %s", $1.str, $2.str, $3.str);
	}
	| shift_expression RIGHT_OP additive_expression {
		$$.str = newStr("%s %s %s", $1.str, $2.str, $3.str);
	}
	;

relational_expression
	: shift_expression {
		$$.str = newStr("%s", $1.str);
	}
	| relational_expression '<' shift_expression {
		$$.str = newStr("%s < %s", $1.str, $3.str);
	}
	| relational_expression '>' shift_expression {
		$$.str = newStr("%s > %s", $1.str, $3.str);
	}
	| relational_expression LE_OP shift_expression {
		$$.str = newStr("%s %s %s", $1.str, $2.str, $3.str);
	}
	| relational_expression GE_OP shift_expression {
		$$.str = newStr("%s %s %s", $1.str, $2.str, $3.str);
	}
	;

equality_expression
	: relational_expression {
		$$.str = newStr("%s", $1.str);
	}
	| equality_expression EQ_OP relational_expression {
		$$.str = newStr("%s %s %s", $1.str, $2.str, $3.str);
	}
	| equality_expression NE_OP relational_expression {
		$$.str = newStr("%s %s %s", $1.str, $2.str, $3.str);
	}
	;

and_expression
	: equality_expression {
		$$.str = newStr("%s", $1.str);
	}
	| and_expression '&' equality_expression {
		$$.str = newStr("%s & %s", $1.str, $3.str);
	}
	;

exclusive_or_expression
	: and_expression {
		$$.str = newStr("%s", $1.str);
	}
	| exclusive_or_expression '^' and_expression {
		$$.str = newStr("%s ^ %s", $1.str, $3.str);
	}
	;

inclusive_or_expression
	: exclusive_or_expression {
		$$.str = newStr("%s", $1.str);
	}
	| inclusive_or_expression '|' exclusive_or_expression {
		$$.str = newStr("%s | %s", $1.str, $3.str);
	}
	;

logical_and_expression
	: inclusive_or_expression {
		$$.str = newStr("%s", $1.str);
	}
	| logical_and_expression AND_OP inclusive_or_expression {
		$$.str = newStr("%s %s %s", $1.str, $2.str, $3.str);
	}
	;

logical_or_expression
	: logical_and_expression {
		$$.str = newStr("%s", $1.str);
	}
	| logical_or_expression OR_OP logical_and_expression {
		$$.str = newStr("%s %s %s", $1.str, $2.str, $3.str);
	}
	;

conditional_expression
	: logical_or_expression {
		$$.str = newStr("%s", $1.str);
	}
	| logical_or_expression '?' expression ':' conditional_expression {
		$$.str = newStr("%s ? %s : %s", $1.str, $2.str, $3.str);
	}
	;

assignment_expression
	: conditional_expression {
		$$.str = newStr("%s", $1.str);
	}
	| unary_expression assignment_operator assignment_expression {
		$$.str = newStr("%s%s%s", $1.str, $2.str, $3.str);
	}
	;

assignment_operator
	: '=' {
		$$.str = newStr("=");
	}
	| MUL_ASSIGN  {
		$$.str = newStr("%s", $1.str);
	}
	| DIV_ASSIGN  {
		$$.str = newStr("%s", $1.str);
	}
	| MOD_ASSIGN  {
		$$.str = newStr("%s", $1.str);
	}
	| ADD_ASSIGN  {
		$$.str = newStr("%s", $1.str);
	}
	| SUB_ASSIGN  {
		$$.str = newStr("%s", $1.str);
	}
	| LEFT_ASSIGN  {
		$$.str = newStr("%s", $1.str);
	}
	| RIGHT_ASSIGN  {
		$$.str = newStr("%s", $1.str);
	}
	| AND_ASSIGN  {
		$$.str = newStr("%s", $1.str);
	}
	| XOR_ASSIGN  {
		$$.str = newStr("%s", $1.str);
	}
	| OR_ASSIGN  {
		$$.str = newStr("%s", $1.str);
	}
	;

expression
	: assignment_expression {
		$$.str = newStr("%s", $1.str);
	}
	| expression ',' assignment_expression {
		$$.str = newStr("%s, %s", $1.str, $3.str);
	}
	;

constant_expression
	: conditional_expression	/* with constraints */  {
		$$.str = newStr("%s", $1.str);
	}
	;

declaration
	: declaration_specifiers ';' {
		$$.str = newStr("%s;\n", $1.str);
		printf("ASDF\n");
	}
	| declaration_specifiers init_declarator_list ';' {
		$$.str = newStr("%s %s;\n", $1.str, $2.str);

		if(hasTypedef == 1)
		{
			printf("typealias");
			add_type($2.id, TYPEDEF_NAME);
		}
		hasTypedef = 0;
	}
	| static_assert_declaration {
		$$.str = newStr("%s;\n", $1.str);
	}
	;

declaration_specifiers
	: storage_class_specifier declaration_specifiers {
		$$.str = newStr("%s %s", $1.str, $2.str);
	}
	| storage_class_specifier {
		$$.str = newStr("%s", $1.str);
	}
	| type_specifier declaration_specifiers {
		$$.str = newStr("%s %s", $1.str, $2.str);
	}
	| type_specifier {
		$$.str = newStr("%s", $1.str);
	}
	| type_qualifier declaration_specifiers {
		$$.str = newStr("%s %s", $1.str, $2.str);
	}
	| type_qualifier {
		$$.str = newStr("%s", $1.str);
	}
	| function_specifier declaration_specifiers {
		$$.str = newStr("%s %s", $1.str, $2.str);
	}
	| function_specifier {
		$$.str = newStr("%s", $1.str);
	}
	| alignment_specifier declaration_specifiers {
		$$.str = newStr("%s %s", $1.str, $2.str);
	}
	| alignment_specifier {
		$$.str = newStr("%s", $1.str);
	}
	;

init_declarator_list
	: init_declarator {
		strcpy($$.id, $1.id);
		$$.str = newStr("%s", $1.str);
	}
	| init_declarator_list ',' init_declarator {
		$$.str = newStr("%s, %s", $1.str, $3.str);
	}
	;

init_declarator
	: declarator '=' initializer
	{
		strcpy($$.id, $1.id);
		$$.str = newStr("%s = %s", $1.str, $3.str);
	}
	| declarator
	{
		strcpy($$.id, $1.id);
		$$.str = newStr("%s", $1.str);
	}
	;

storage_class_specifier
	: TYPEDEF	/* identifiers must be flagged as TYPEDEF_NAME */{
		hasTypedef = 1;
		$$.str = newStr("%s", $1.str);
	}
	| EXTERN {
		$$.str = newStr("%s", $1.str);
	}
	| STATIC {
		$$.str = newStr("%s", $1.str);
	}
	| THREAD_LOCAL {
		$$.str = newStr("%s", $1.str);
	}
	| AUTO {
		$$.str = newStr("%s", $1.str);
	}
	| REGISTER {
		$$.str = newStr("%s", $1.str);
	}
	;

type_specifier
	: VOID {
		$$.str = newStr("%s", $1.str);
	}
	| CHAR {
		$$.str = newStr("%s", $1.str);
	}
	| SHORT {
		$$.str = newStr("%s", $1.str);
	}
	| INT {
		$$.str = newStr("%s", $1.str);
	}
	| LONG {
		$$.str = newStr("%s", $1.str);
	}
	| FLOAT {
		$$.str = newStr("%s", $1.str);
	}
	| DOUBLE {
		$$.str = newStr("%s", $1.str);
	}
	| SIGNED {
		$$.str = newStr("%s", $1.str);
	}
	| UNSIGNED {
		$$.str = newStr("%s", $1.str);
	}
	| BOOL {
		$$.str = newStr("%s", $1.str);
	}
	| COMPLEX {
		$$.str = newStr("%s", $1.str);
	}
	| IMAGINARY	  	/* non-mandated extension */ {
		$$.str = newStr("%s", $1.str);
	}
	| atomic_type_specifier {
		$$.str = newStr("%s", $1.str);
	}
	| struct_or_union_specifier {
		$$.str = newStr("%s", $1.str);
	}
	| enum_specifier {
		$$.str = newStr("%s", $1.str);
	}
	| TYPEDEF_NAME		/* after it has been defined as such */ {
		$$.str = newStr("%s", $1.str);
		printf("TYPE YAY! %s\n", $$.str);
	}
	;

struct_or_union_specifier
	: struct_or_union '{' struct_declaration_list '}' {
		$$.str = newStr("%s {\n%s\n}", $1.str, $3.str);
	}
	| struct_or_union IDENTIFIER '{' struct_declaration_list '}' {
		$$.str = newStr("%s %s {\n%s\n}", $1.str, $2.str, $4.str);
	}
	| struct_or_union IDENTIFIER {
		$$.str = newStr("%s %s", $1.str, $2.str);
	}
	;

struct_or_union
	: STRUCT {
		$$.str = newStr("%s", $1.str);
	}
	| UNION {
		$$.str = newStr("%s", $1.str);
	}
	;

struct_declaration_list
	: struct_declaration {
		$$.str = newStr("%s", $1.str);
	}
	| struct_declaration_list struct_declaration
	;

struct_declaration
	: specifier_qualifier_list ';'	/* for anonymous struct/union */  {
		$$.str = newStr("%s;\n", $1.str);
	}
	| specifier_qualifier_list struct_declarator_list ';' {
		$$.str = newStr("%s %s;\n", $1.str, $2.str);
	}
	| static_assert_declaration {
		$$.str = newStr("%s\n;", $1.str);
	}
	;

specifier_qualifier_list
	: type_specifier specifier_qualifier_list {
		$$.str = newStr("%s %s", $1.str, $2.str);
	}
	| type_specifier {
		$$.str = newStr("%s", $1.str);
	}
	| type_qualifier specifier_qualifier_list {
		$$.str = newStr("%s %s", $1.str, $2.str);
	}
	| type_qualifier {
		$$.str = newStr("%s", $1.str);
	}
	;

struct_declarator_list
	: struct_declarator {
		$$.str = newStr("%s", $1.str);
	}
	| struct_declarator_list ',' struct_declarator {
		$$.str = newStr("%s, %s", $1.str, $3.str);
	}
	;

struct_declarator
	: ':' constant_expression {
		$$.str = newStr(":%s", $2.str);
	}
	| declarator ':' constant_expression {
		$$.str = newStr("%s: %s", $1.str, $3.str);
	}
	| declarator {
		$$.str = newStr("%s", $1.str);
	}
	;

enum_specifier
	: ENUM '{' enumerator_list '}' {
		$$.str = newStr("%s { %s }", $1.str, $3.str);
	}
	| ENUM '{' enumerator_list ',' '}' {
		$$.str = newStr("%s { %s , }", $1.str, $3.str);
	}
	| ENUM IDENTIFIER '{' enumerator_list '}' {
		$$.str = newStr("%s %s { %s }", $1.str, $2.str, $4.str);
	}
	| ENUM IDENTIFIER '{' enumerator_list ',' '}' {
		$$.str = newStr("%s %s { %s , }", $1.str, $2.str, $4.str);
	}
	| ENUM IDENTIFIER {
		$$.str = newStr("%s", $1.str);
	}
	;

enumerator_list
	: enumerator {
		$$.str = newStr("%s", $1.str);
	}
	| enumerator_list ',' enumerator {
		$$.str = newStr("%s, %s", $1.str, $3.str);
	}
	;

enumerator	/* identifiers must be flagged as ENUMERATION_CONSTANT */
	: enumeration_constant '=' constant_expression {
		$$.str = newStr("%s = %s", $1.str, $3.str);
	}
	| enumeration_constant {
		$$.str = newStr("%s", $1.str);
	}
	;

atomic_type_specifier
	: ATOMIC '(' type_name ')'
	;

type_qualifier
	: CONST {
		$$.str = newStr("%s", $1.str);
	}
	| RESTRICT {
		$$.str = newStr("%s", $1.str);
	}
	| VOLATILE {
		$$.str = newStr("%s", $1.str);
	}
	| ATOMIC {
		$$.str = newStr("%s", $1.str);
	}
	;

function_specifier
	: INLINE {
		$$.str = newStr("%s", $1.str);
	}
	| NORETURN {
		$$.str = newStr("%s", $1.str);
	}
	;

alignment_specifier
	: ALIGNAS '(' type_name ')'
	| ALIGNAS '(' constant_expression ')'
	;

declarator
	: pointer direct_declarator {strcpy($$.id, $2.id);}
	| direct_declarator {strcpy($$.id, $1.id);}
	;

direct_declarator
	: IDENTIFIER {
		printf("HELOOW %s\n", $1.str);
		strcpy($$.id, $1.str);

	}
	| '(' declarator ')'
	| direct_declarator '[' ']'
	| direct_declarator '[' '*' ']'
	| direct_declarator '[' STATIC type_qualifier_list assignment_expression ']'
	| direct_declarator '[' STATIC assignment_expression ']'
	| direct_declarator '[' type_qualifier_list '*' ']'
	| direct_declarator '[' type_qualifier_list STATIC assignment_expression ']'
	| direct_declarator '[' type_qualifier_list assignment_expression ']'
	| direct_declarator '[' type_qualifier_list ']'
	| direct_declarator '[' assignment_expression ']'
	| direct_declarator '(' parameter_type_list ')'
	| direct_declarator '(' ')'
	| direct_declarator '(' identifier_list ')'
	;

pointer
	: '*' type_qualifier_list pointer
	| '*' type_qualifier_list
	| '*' pointer
	| '*'
	;

type_qualifier_list
	: type_qualifier
	| type_qualifier_list type_qualifier
	;


parameter_type_list
	: parameter_list ',' ELLIPSIS
	| parameter_list
	;

parameter_list
	: parameter_declaration
	| parameter_list ',' parameter_declaration
	;

parameter_declaration
	: declaration_specifiers declarator
	| declaration_specifiers abstract_declarator
	| declaration_specifiers
	;

identifier_list
	: IDENTIFIER
	| identifier_list ',' IDENTIFIER
	;

type_name
	: specifier_qualifier_list abstract_declarator
	| specifier_qualifier_list
	;

abstract_declarator
	: pointer direct_abstract_declarator
	| pointer
	| direct_abstract_declarator
	;

direct_abstract_declarator
	: '(' abstract_declarator ')'
	| '[' ']'
	| '[' '*' ']'
	| '[' STATIC type_qualifier_list assignment_expression ']'
	| '[' STATIC assignment_expression ']'
	| '[' type_qualifier_list STATIC assignment_expression ']'
	| '[' type_qualifier_list assignment_expression ']'
	| '[' type_qualifier_list ']'
	| '[' assignment_expression ']'
	| direct_abstract_declarator '[' ']'
	| direct_abstract_declarator '[' '*' ']'
	| direct_abstract_declarator '[' STATIC type_qualifier_list assignment_expression ']'
	| direct_abstract_declarator '[' STATIC assignment_expression ']'
	| direct_abstract_declarator '[' type_qualifier_list assignment_expression ']'
	| direct_abstract_declarator '[' type_qualifier_list STATIC assignment_expression ']'
	| direct_abstract_declarator '[' type_qualifier_list ']'
	| direct_abstract_declarator '[' assignment_expression ']'
	| '(' ')'
	| '(' parameter_type_list ')'
	| direct_abstract_declarator '(' ')'
	| direct_abstract_declarator '(' parameter_type_list ')'
	;

initializer
	: '{' initializer_list '}'
	| '{' initializer_list ',' '}'
	| assignment_expression
	;

initializer_list
	: designation initializer
	| initializer
	| initializer_list ',' designation initializer
	| initializer_list ',' initializer
	;

designation
	: designator_list '='
	;

designator_list
	: designator
	| designator_list designator
	;

designator
	: '[' constant_expression ']'
	| '.' IDENTIFIER
	;

static_assert_declaration
	: STATIC_ASSERT '(' constant_expression ',' STRING_LITERAL ')' ';'
	;

statement
	: labeled_statement
	| compound_statement
	| expression_statement
	| selection_statement
	| iteration_statement
	| jump_statement
	;

labeled_statement
	: IDENTIFIER ':' statement
	| CASE constant_expression ':' statement
	| DEFAULT ':' statement
	;

compound_statement
	: '{' '}'
	| '{'  block_item_list '}'
	;

block_item_list
	: block_item
	| block_item_list block_item
	;

block_item
	: declaration
	| statement
	;

expression_statement
	: ';'
	| expression ';'
	;

selection_statement
	: IF '(' expression ')' statement ELSE statement
	| IF '(' expression ')' statement
	| SWITCH '(' expression ')' statement
	;

iteration_statement
	: WHILE '(' expression ')' statement
	| DO statement WHILE '(' expression ')' ';'
	| FOR '(' expression_statement expression_statement ')' statement
	| FOR '(' expression_statement expression_statement expression ')' statement
	| FOR '(' declaration expression_statement ')' statement
	| FOR '(' declaration expression_statement expression ')' statement
	;

jump_statement
	: GOTO IDENTIFIER ';'
	| CONTINUE ';'
	| BREAK ';'
	| RETURN ';'
	| RETURN expression ';'
	;

translation_unit
	: external_declaration
	| translation_unit external_declaration
	;

external_declaration
	: function_definition
	| declaration
	;

function_definition
	: declaration_specifiers declarator declaration_list compound_statement
	| declaration_specifiers declarator compound_statement
	;

declaration_list
	: declaration
	| declaration_list declaration
	;

%%
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

int main()
{
	init_symtable();
	yyparse();
}

int getDigitCount(int num)
{
	int length = 1;
	if(num < 0)
	{
		num = -1 * num;
		length++; /*  the '-' char */
	}

	while(num > 9)
	{
		length++;
		num = num / 10;
	}
	return length;
}


char* newStr(char const *fmt, ...)
{
	int int_temp;
	char char_temp;
	char *string_temp;
	double double_temp;

	int param_length;

    va_list arg;
	va_start(arg, fmt);

	char ch;
	int count = 0;

	int length = 0;
	int currentBufferSize = 512;

	char *buffer = malloc(sizeof(char) * 512);

	while(ch = fmt[count])
	{
		if(length > currentBufferSize - 2)
		{
			buffer = realloc(buffer, 2*currentBufferSize);
			currentBufferSize = 2*currentBufferSize;
		}
		if(ch == '%')
		{
			count++;
			switch(fmt[count])
			{
				case '%':
					buffer[length] = '%';
					length++;
					break;
				case 'c':
					buffer[length] = va_arg(arg, int);
					length++;
					break;
				case 's':
					string_temp = va_arg(arg, char *);
					param_length = strlen(string_temp);
					while(length + param_length + 1 > currentBufferSize)
					{
						buffer = realloc(buffer, sizeof(2*currentBufferSize));
						currentBufferSize = 2*currentBufferSize;	
					}
					buffer[length] = '\0';
					strcat(buffer, string_temp);

					length += param_length;
					break;
				case 'd':
					int_temp = va_arg(arg, int);
					param_length = getDigitCount(int_temp);
					while(length + param_length + 1 > currentBufferSize)
					{
						buffer = realloc(buffer, sizeof(2*currentBufferSize));
						currentBufferSize = 2*currentBufferSize;	
					}
					sprintf(&buffer[length], "%d", int_temp);
					length += param_length;
			}

		}
		else
		{
			buffer[length] = ch;
			length++;
		}

		count++;
	}

	buffer[length] = '\0';
	return buffer;
}

void yyerror(char *s)
{
	fflush(stdout);
	fprintf(stderr, "*** %s\n", s);
}
