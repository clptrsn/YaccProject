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

%token IFNDEF_GOOD IFNDEF_BAD ENDIF

%token USERPROGRAM SYSPROGRAM

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

#define USER_DEFINED 0
#define SYSTEM_DEFINED 1
#define BANNED_DEFINED 2

int hasTypedef = 0;
int isUserCode = 1;

extern void init_symtable();
extern void add_type(char* id, int type);
extern void add_table(char* id);
extern int in_table(char* id);
extern int get_type(char* id);
extern void print_symtable();

extern void init_functable();
extern void add_functype(char* id, int type);
extern void add_functable(char* id);
extern int in_functable(char* id);
extern int get_functype(char* id);

extern FILE* yyin;

char* newStr(char const *fmt, ...);
int yylex();
void yyerror(char *s);

FILE* badOut;
FILE* goodOut;
%}
%%

primary_expression
	: IDENTIFIER {
		$$.str = newStr("var");
		free($1.str);
	}
	| constant {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| string {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| '(' expression ')' {
		$$.str = newStr("(%s)", $2.str);
		free($2.str);
	}
	| generic_selection {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	;

constant
	: I_CONSTANT		/* includes character_constant */ {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| F_CONSTANT {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| ENUMERATION_CONSTANT	/* after it has been defined as such */ {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	;

enumeration_constant		/* before it has been defined as such */
	: IDENTIFIER {
		add_type($1.str, ENUMERATION_CONSTANT);

		$$.str = newStr("var");
		free($1.str);
	}
	;

string
	: STRING_LITERAL {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| FUNC_NAME {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	;

generic_selection
	: GENERIC '(' assignment_expression ',' generic_assoc_list ')' {
		$$.str = newStr("%s(%s,%s)", $1.str, $3.str, $5.str);
		free($1.str);
		free($3.str);
		free($5.str);
	}
	;

generic_assoc_list
	: generic_association {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| generic_assoc_list ',' generic_association {
		$$.str = newStr("%s, $s", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	;

generic_association
	: type_name ':' assignment_expression {
		$$.str = newStr("%s: %s", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	| DEFAULT ':' assignment_expression {
		$$.str = newStr("%s: %s", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	;

postfix_expression
	: primary_expression {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| postfix_expression '[' expression ']' {
		$$.str = newStr("%s[%s]", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	| postfix_expression '(' ')' {
		if(get_functype($1.str) == USER_DEFINED)
		{
			$$.str = newStr("userdefinedfunction()");
		}
		else if(get_functype($1.str) == BANNED_DEFINED)
		{
			$$.str = newStr("bannedfunction()");
		}
		else
		{
			$$.str = newStr("libraryfunction()");
		}
		free($1.str);
	}
	| postfix_expression '(' argument_expression_list ')' {
		if(get_functype($1.str) == USER_DEFINED)
		{
			$$.str = newStr("userdefinedfunction(%s)", $3.str);
		}
		else if(get_functype($1.str) == BANNED_DEFINED)
		{
			$$.str = newStr("bannedfunction(%s)", $3.str);
		}
		else
		{
			$$.str = newStr("libraryfunction(%s)", $3.str);
		}
		free($1.str);
		free($3.str);
	}
	| postfix_expression '.' IDENTIFIER {
		$$.str = newStr("%s.var", $1.str);
		free($1.str);
		free($3.str);
	}
	| postfix_expression PTR_OP IDENTIFIER {
		$$.str = newStr("%s%svar", $1.str, $2.str);
		free($1.str);
		free($2.str);
		free($3.str);
	}
	| postfix_expression INC_OP {
		$$.str = newStr("%s%s", $1.str, $2.str);
		free($1.str);
		free($2.str);
	}
	| postfix_expression DEC_OP {
		$$.str = newStr("%s%s", $1.str, $2.str);
		free($1.str);
		free($2.str);
	}
	| '(' type_name ')' '{' initializer_list '}' {
		$$.str = newStr("(%s) $BEGIN %s $END", $2.str, $5.str);
		free($2.str);
		free($5.str);
	}
	| '(' type_name ')' '{' initializer_list ',' '}' {
		$$.str = newStr("(%s) $BEGIN %s, $END", $2.str, $5.str);
		free($2.str);
		free($5.str);
	}
	;

argument_expression_list
	: assignment_expression {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| argument_expression_list ',' assignment_expression {
		$$.str = newStr("%s, %s", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	;

unary_expression
	: postfix_expression {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| INC_OP unary_expression {
		$$.str = newStr("%s%s", $1.str, $2.str);
		free($1.str);
		free($2.str);
	}
	| DEC_OP unary_expression {
		$$.str = newStr("%s%s", $1.str, $2.str);
		free($1.str);
		free($2.str);
	}
	| unary_operator cast_expression {
		$$.str = newStr("%s%s", $1.str, $2.str);
		free($1.str);
		free($2.str);
	}
	| SIZEOF unary_expression {
		$$.str = newStr("%s%s", $1.str, $2.str);
		free($1.str);
		free($2.str);
	}
	| SIZEOF '(' type_name ')' {
		$$.str = newStr("%s(%s)", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	| ALIGNOF '(' type_name ')' {
		$$.str = newStr("%s(%s)", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	;

unary_operator
	: '&' {
		$$.str = newStr("&");
	}
	| '*' {
		$$.str = newStr("*");
	}
	| '+' {
		$$.str = newStr("+");
	}
	| '-' {
		$$.str = newStr("-");
	}
	| '~' {
		$$.str = newStr("~");
	}
	| '!' {
		$$.str = newStr("!");
	}
	;

cast_expression
	: unary_expression {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| '(' type_name ')' cast_expression {	
		$$.str = newStr("(%s) %s", $2.str, $4.str);
		free($2.str);
		free($4.str);
	}
	;

multiplicative_expression
	: cast_expression {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| multiplicative_expression '*' cast_expression {
		$$.str = newStr("%s * %s", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	| multiplicative_expression '/' cast_expression {
		$$.str = newStr("%s / %s", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	| multiplicative_expression '%' cast_expression {
		$$.str = newStr("%s % %s", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	;

additive_expression
	: multiplicative_expression {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| additive_expression '+' multiplicative_expression {
		$$.str = newStr("%s + %s", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	| additive_expression '-' multiplicative_expression {
		$$.str = newStr("%s - %s", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	;

shift_expression
	: additive_expression {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| shift_expression LEFT_OP additive_expression {
		$$.str = newStr("%s %s %s", $1.str, $2.str, $3.str);
		free($1.str);
		free($2.str);
		free($3.str);
	}
	| shift_expression RIGHT_OP additive_expression {
		$$.str = newStr("%s %s %s", $1.str, $2.str, $3.str);
		free($1.str);
		free($2.str);
		free($3.str);
	}
	;

relational_expression
	: shift_expression {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| relational_expression '<' shift_expression {
		$$.str = newStr("%s < %s", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	| relational_expression '>' shift_expression {
		$$.str = newStr("%s > %s", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	| relational_expression LE_OP shift_expression {
		$$.str = newStr("%s %s %s", $1.str, $2.str, $3.str);
		free($1.str);
		free($2.str);
		free($3.str);
	}
	| relational_expression GE_OP shift_expression {
		$$.str = newStr("%s %s %s", $1.str, $2.str, $3.str);
		free($1.str);
		free($2.str);
		free($3.str);
	}
	;

equality_expression
	: relational_expression {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| equality_expression EQ_OP relational_expression {
		$$.str = newStr("%s %s %s", $1.str, $2.str, $3.str);
		free($1.str);
		free($2.str);
		free($3.str);
	}
	| equality_expression NE_OP relational_expression {
		$$.str = newStr("%s %s %s", $1.str, $2.str, $3.str);
		free($1.str);
		free($2.str);
		free($3.str);
	}
	;

and_expression
	: equality_expression {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| and_expression '&' equality_expression {
		$$.str = newStr("%s & %s", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	;

exclusive_or_expression
	: and_expression {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| exclusive_or_expression '^' and_expression {
		$$.str = newStr("%s ^ %s", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	;

inclusive_or_expression
	: exclusive_or_expression {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| inclusive_or_expression '|' exclusive_or_expression {
		$$.str = newStr("%s | %s", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	;

logical_and_expression
	: inclusive_or_expression {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| logical_and_expression AND_OP inclusive_or_expression {
		$$.str = newStr("%s %s %s", $1.str, $2.str, $3.str);
		free($1.str);
		free($2.str);
		free($3.str);
	}
	;

logical_or_expression
	: logical_and_expression {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| logical_or_expression OR_OP logical_and_expression {
		$$.str = newStr("%s %s %s", $1.str, $2.str, $3.str);
		free($1.str);
		free($2.str);
		free($3.str);
	}
	;

conditional_expression
	: logical_or_expression {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| logical_or_expression '?' expression ':' conditional_expression {
		$$.str = newStr("%s ? %s : %s", $1.str, $2.str, $3.str);
		free($1.str);
		free($2.str);
		free($3.str);
	}
	;

assignment_expression
	: conditional_expression {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| unary_expression assignment_operator assignment_expression {
		$$.str = newStr("%s%s%s", $1.str, $2.str, $3.str);
		free($1.str);
		free($2.str);
		free($3.str);
	}
	;

assignment_operator
	: '=' {
		$$.str = newStr("=");
	}
	| MUL_ASSIGN  {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| DIV_ASSIGN  {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| MOD_ASSIGN  {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| ADD_ASSIGN  {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| SUB_ASSIGN  {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| LEFT_ASSIGN  {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| RIGHT_ASSIGN  {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| AND_ASSIGN  {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| XOR_ASSIGN  {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| OR_ASSIGN  {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	;

expression
	: assignment_expression {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| expression ',' assignment_expression {
		$$.str = newStr("%s, %s", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	;

constant_expression
	: conditional_expression	/* with constraints */  {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	;

declaration
	: declaration_specifiers ';' {
		$$.str = newStr("%s;\n", $1.str);

		if(isUserCode && strncmp($$.str, "typedef", strlen("typedef")) == 0)
		{
			fprintf(badOut, "%s", $$.str);
			fprintf(goodOut, "%s", $$.str);
		}
		free($1.str);
	}
	| declaration_specifiers init_declarator_list ';' {
		$$.str = newStr("%s %s;\n", $1.str, $2.str);
		free($1.str);
		free($2.str);

		if(isUserCode && strncmp($$.str, "typedef", strlen("typedef")) == 0)
		{
			fprintf(badOut, "%s", $$.str);
			fprintf(goodOut, "%s", $$.str);
		}

		if(hasTypedef == 1)
		{
			add_type($2.id, TYPEDEF_NAME);
		}
		
		hasTypedef = 0;
	}
	| static_assert_declaration {
		$$.str = newStr("%s;\n", $1.str);
		free($1.str);
	}
	;

declaration_specifiers
	: storage_class_specifier declaration_specifiers {
		$$.str = newStr("%s %s", $1.str, $2.str);
		free($1.str);
		free($2.str);
	}
	| storage_class_specifier {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| type_specifier declaration_specifiers {
		$$.str = newStr("%s %s", $1.str, $2.str);
		free($1.str);
		free($2.str);
	}
	| type_specifier {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| type_qualifier declaration_specifiers {
		$$.str = newStr("%s %s", $1.str, $2.str);
		free($1.str);
		free($2.str);
	}
	| type_qualifier {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| function_specifier declaration_specifiers {
		$$.str = newStr("%s %s", $1.str, $2.str);
		free($1.str);
		free($2.str);
	}
	| function_specifier {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| alignment_specifier declaration_specifiers {
		$$.str = newStr("%s %s", $1.str, $2.str);
		free($1.str);
		free($2.str);
	}
	| alignment_specifier {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	;

init_declarator_list
	: init_declarator {
		strcpy($$.id, $1.id);
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| init_declarator_list ',' init_declarator {
		$$.str = newStr("%s, %s", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	;

init_declarator
	: declarator '=' initializer {
		strcpy($$.id, $1.id);
		$$.str = newStr("%s = %s", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	| declarator {
		strcpy($$.id, $1.id);
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	;

storage_class_specifier
	: TYPEDEF	/* identifiers must be flagged as TYPEDEF_NAME */{
		hasTypedef = 1;
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| EXTERN {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| STATIC {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| THREAD_LOCAL {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| AUTO {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| REGISTER {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	;

type_specifier
	: VOID {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| CHAR {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| SHORT {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| INT {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| LONG {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| FLOAT {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| DOUBLE {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| SIGNED {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| UNSIGNED {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| BOOL {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| COMPLEX {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| IMAGINARY	  	/* non-mandated extension */ {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| atomic_type_specifier {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| struct_or_union_specifier {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| enum_specifier {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| TYPEDEF_NAME		/* after it has been defined as such */ {
		$$.str = newStr("STRUCT");
		free($1.str);
	}
	;

struct_or_union_specifier
	: struct_or_union '{' struct_declaration_list '}' {
		$$.str = newStr("%s $BEGIN\n%s$END", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	| struct_or_union IDENTIFIER '{' struct_declaration_list '}' {
		$$.str = newStr("%s %s $BEGIN\n%s$END", $1.str, $2.str, $4.str);
		free($1.str);
		free($2.str);
		free($4.str);
	}
	| struct_or_union IDENTIFIER {
		$$.str = newStr("%s %s", $1.str, $2.str);
		free($1.str);
		free($2.str);
	}
	| struct_or_union TYPEDEF_NAME {
		$$.str = newStr("%s %s", $1.str, $2.str);
		free($1.str);
		free($2.str);
	}
	;

struct_or_union
	: STRUCT {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| UNION {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	;

struct_declaration_list
	: struct_declaration {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| struct_declaration_list struct_declaration {
		$$.str = newStr("%s%s", $1.str, $2.str);
		free($1.str);
		free($2.str);
	}
	;

struct_declaration
	: specifier_qualifier_list ';'	/* for anonymous struct/union */  {
		$$.str = newStr("%s;\n", $1.str);
		free($1.str);
	}
	| specifier_qualifier_list struct_declarator_list ';' {
		$$.str = newStr("%s %s;\n", $1.str, $2.str);
		free($1.str);
		free($2.str);
	}
	| static_assert_declaration {
		$$.str = newStr("%s\n;", $1.str);
		free($1.str);
	}
	;

specifier_qualifier_list
	: type_specifier specifier_qualifier_list {
		$$.str = newStr("%s %s", $1.str, $2.str);
		free($1.str);
		free($2.str);
	}
	| type_specifier {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| type_qualifier specifier_qualifier_list {
		$$.str = newStr("%s %s", $1.str, $2.str);
		free($1.str);
		free($2.str);
	}
	| type_qualifier {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	;

struct_declarator_list
	: struct_declarator {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| struct_declarator_list ',' struct_declarator {
		$$.str = newStr("%s, %s", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	;

struct_declarator
	: ':' constant_expression {
		$$.str = newStr(":%s", $2.str);
		free($2.str);
	}
	| declarator ':' constant_expression {
		$$.str = newStr("%s: %s", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	| declarator {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	;

enum_specifier
	: ENUM '{' enumerator_list '}' {
		$$.str = newStr("%s $BEGIN %s $END", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	| ENUM '{' enumerator_list ',' '}' {
		$$.str = newStr("%s $BEGIN %s , $END", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	| ENUM IDENTIFIER '{' enumerator_list '}' {
		$$.str = newStr("%s %s $BEGIN %s $END", $1.str, $2.str, $4.str);
		free($1.str);
		free($2.str);
		free($4.str);
	}
	| ENUM IDENTIFIER '{' enumerator_list ',' '}' {
		$$.str = newStr("%s %s $BEGIN %s , $END", $1.str, $2.str, $4.str);
		free($1.str);
		free($2.str);
		free($4.str);
	}
	| ENUM IDENTIFIER {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	;

enumerator_list
	: enumerator {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| enumerator_list ',' enumerator {
		$$.str = newStr("%s, %s", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	;

enumerator	/* identifiers must be flagged as ENUMERATION_CONSTANT */
	: enumeration_constant '=' constant_expression {
		$$.str = newStr("%s = %s", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	| enumeration_constant {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	;

atomic_type_specifier
	: ATOMIC '(' type_name ')' {
		$$.str = newStr("%s(%s) ", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	;

type_qualifier
	: CONST {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| RESTRICT {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| VOLATILE {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| ATOMIC {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	;

function_specifier
	: INLINE {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| NORETURN {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	;

alignment_specifier
	: ALIGNAS '(' type_name ')' {
		$$.str = newStr("%s(%s) ", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	| ALIGNAS '(' constant_expression ')' {
		$$.str = newStr("%s(%s) ", $1.str, $3.str);		
		free($1.str);
		free($3.str);
	}
	;

declarator
	: pointer direct_declarator {
		$$.str = newStr("%s %s", $2.str, $1.str);
		free($1.str);
		free($2.str);
		strcpy($$.id, $2.id);
	}
	| direct_declarator {
		$$.str = newStr("%s", $1.str);
		free($1.str);
		strcpy($$.id, $1.id);
	}
	;

direct_declarator
	: IDENTIFIER {
		$$.str = newStr("var");
		strcpy($$.id, $1.str);
		free($1.str);
		
	}
	| '(' declarator ')' {
		$$.str = newStr("(%s)", $2.str);
		free($2.str);
		strcpy($$.id, $2.id);
	}
	| direct_declarator '[' ']' {
		$$.str = newStr("%s ARRAY", $1.str);
		free($1.str);
		strcpy($$.id, $1.id);
	}
	| direct_declarator '[' '*' ']' {
		$$.str = newStr("%s ARRAY", $1.str);
		free($1.str);
		strcpy($$.id, $1.id);
	}
	| direct_declarator '[' STATIC type_qualifier_list assignment_expression ']' {
		$$.str = newStr("%s ARRAY size=%s", $1.str, $5.str);
		free($1.str);
		free($3.str);
		free($4.str);
		free($5.str);
		strcpy($$.id, $1.id);
	}
	| direct_declarator '[' STATIC assignment_expression ']' {
		$$.str = newStr("%s ARRAY size=%s", $1.str, $4.str);
		free($1.str);
		free($3.str);
		free($4.str);
		strcpy($$.id, $1.id);
	}
	| direct_declarator '[' type_qualifier_list '*' ']' {
		$$.str = newStr("%s ARRAY", $1.str, $3.str);
		free($1.str);
		free($3.str);
		strcpy($$.id, $1.id);
	}
	| direct_declarator '[' type_qualifier_list STATIC assignment_expression ']' {
		$$.str = newStr("%s ARRAY size=%s", $1.str, $5.str);
		free($1.str);
		free($3.str);
		free($4.str);
		free($5.str);
		strcpy($$.id, $1.id);
	}
	| direct_declarator '[' type_qualifier_list assignment_expression ']' {
		$$.str = newStr("%s ARRAY", $1.str, $3.str, $4.str);
		free($1.str);
		free($3.str);
		free($4.str);
		strcpy($$.id, $1.id);
	}
	| direct_declarator '[' type_qualifier_list ']' {
		$$.str = newStr("%s ARRAY", $1.str);
		free($1.str);
		free($3.str);
		strcpy($$.id, $1.id);
	}
	| direct_declarator '[' assignment_expression ']' {
		$$.str = newStr("%s ARRAY size=%s", $1.str, $3.str);
		free($1.str);
		free($3.str);
		strcpy($$.id, $1.id);
	}
	| direct_declarator '(' parameter_type_list ')' {
		if(isUserCode)
		{
			add_functable($1.str);
			add_functype($1.str, USER_DEFINED);
			$$.str = newStr("userdefinedfunction(%s)", $3.str);
		}
		else
		{
			add_functable($1.str);
			add_functype($1.str, SYSTEM_DEFINED);
			if(get_functype($1.str) == BANNED_DEFINED)
			{
				$$.str = newStr("bannedfunction(%s)", $3.str);
			}
			else
			{
				$$.str = newStr("libraryfunction(%s)", $3.str);
			}
		}
		free($1.str);
		free($3.str);
		strcpy($$.id, $1.id);
	}
	| direct_declarator '(' ')' {
		if(isUserCode)
		{
			add_functable($1.str);
			add_functype($1.str, USER_DEFINED);
			$$.str = newStr("userdefinedfunction()");
		}
		else
		{
			add_functable($1.str);
			add_functype($1.str, SYSTEM_DEFINED);
			if(get_functype($1.str) == BANNED_DEFINED)
			{
				$$.str = newStr("bannedfunction()");
			}
			else
			{
				$$.str = newStr("libraryfunction()");
			}
		}
		free($1.str);
		strcpy($$.id, $1.id);
	}
	| direct_declarator '(' identifier_list ')' {
		if(isUserCode)
		{
			add_functable($1.str);
			add_functype($1.str, USER_DEFINED);
			$$.str = newStr("userdefinedfunction(%s)", $3.str);
		}
		else
		{
			add_functable($1.str);
			add_functype($1.str, SYSTEM_DEFINED);
			if(get_functype($1.str) == BANNED_DEFINED)
			{
				$$.str = newStr("bannedfunction(%s)", $3.str);
			}
			else
			{
				$$.str = newStr("libraryfunction(%s)", $3.str);
			}
		}
		free($1.str);
		free($3.str);
		strcpy($$.id, $1.id);
	}
	;

pointer
	: '*' type_qualifier_list pointer {
		$$.str = newStr("%s %s PTR", $2.str, $3.str);
		free($2.str);
		free($3.str);
	}
	| '*' type_qualifier_list {
		$$.str = newStr("%s PTR", $2.str);
		free($2.str);
	}
	| '*' pointer {
		$$.str = newStr("%s PTR", $2.str);
		free($2.str);
	}
	| '*' {
		$$.str = newStr("PTR");
	}
	;

type_qualifier_list
	: type_qualifier {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| type_qualifier_list type_qualifier {
		$$.str = newStr("%s %s", $1.str, $2.str);
		free($1.str);
		free($2.str);
	}
	;


parameter_type_list
	: parameter_list ',' ELLIPSIS {
		$$.str = newStr("%s, %s", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	| parameter_list {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	;

parameter_list
	: parameter_declaration {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| parameter_list ',' parameter_declaration {
		$$.str = newStr("%s, %s", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	;

parameter_declaration
	: declaration_specifiers declarator {
		$$.str = newStr("%s %s", $1.str, $2.str);
		free($1.str);
		free($2.str);
	}
	| declaration_specifiers abstract_declarator {
		$$.str = newStr("%s %s", $1.str, $2.str);
		free($1.str);
		free($2.str);
	}
	| declaration_specifiers {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	;

identifier_list
	: IDENTIFIER {
		$$.str = newStr("var");
		free($1.str);
	}
	| identifier_list ',' IDENTIFIER {
		$$.str = newStr("%s, var", $1.str);
		free($1.str);
		free($3.str);
	}
	;

type_name
	: specifier_qualifier_list abstract_declarator {
		$$.str = newStr("%s %s", $1.str, $2.str);
		free($1.str);
		free($2.str);
	}
	| specifier_qualifier_list {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	;

abstract_declarator
	: pointer direct_abstract_declarator {
		$$.str = newStr("%s%s", $1.str, $2.str);
		free($1.str);
		free($2.str);
	}
	| pointer {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| direct_abstract_declarator {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	;

direct_abstract_declarator
	: '(' abstract_declarator ')' {
		$$.str = newStr("(%s)", $2.str);
		free($2.str);
	}
	| '[' ']' {
		$$.str = newStr("[]");
	}
	| '[' '*' ']' {
		$$.str = newStr("[*]");
	}
	| '[' STATIC type_qualifier_list assignment_expression ']' {
		$$.str = newStr("[%s %s %s]", $2.str, $3.str, $4.str);
		free($2.str);
		free($3.str);
		free($4.str);
	}
	| '[' STATIC assignment_expression ']' {
		$$.str = newStr("[%s %s]", $2.str, $3.str);
		free($2.str);
		free($3.str);
	}
	| '[' type_qualifier_list STATIC assignment_expression ']' {
		$$.str = newStr("[%s %s %s]", $2.str, $3.str, $4.str);
		free($2.str);
		free($3.str);
		free($4.str);
	}
	| '[' type_qualifier_list assignment_expression ']' {
		$$.str = newStr("[%s %s]", $2.str, $3.str);
		free($2.str);
		free($3.str);
	}
	| '[' type_qualifier_list ']' {
		$$.str = newStr("[%s]", $2.str);
		free($2.str);
	}
	| '[' assignment_expression ']' {
		$$.str = newStr("[%s]", $2.str);
		free($2.str);
	}
	| direct_abstract_declarator '[' ']' {
		$$.str = newStr("%s[]", $1.str);
		free($1.str);
	}
	| direct_abstract_declarator '[' '*' ']' {
		$$.str = newStr("%s[*]", $1.str);
		free($1.str);
	}
	| direct_abstract_declarator '[' STATIC type_qualifier_list assignment_expression ']' {
		$$.str = newStr("%s[%s %s %s]", $1.str, $3.str, $4.str, $5.str);
		free($1.str);
		free($3.str);
		free($4.str);
		free($5.str);
	}
	| direct_abstract_declarator '[' STATIC assignment_expression ']' {
		$$.str = newStr("%s[%s %s]", $1.str, $3.str, $4.str);
		free($1.str);
		free($3.str);
		free($4.str);
	}
	| direct_abstract_declarator '[' type_qualifier_list assignment_expression ']' {
		$$.str = newStr("%s[%s %s]", $1.str, $3.str, $4.str);
		free($1.str);
		free($3.str);
		free($4.str);
	}
	| direct_abstract_declarator '[' type_qualifier_list STATIC assignment_expression ']' {
		$$.str = newStr("%s[%s %s %s]", $1.str, $3.str, $4.str, $5.str);
		free($1.str);
		free($3.str);
		free($4.str);
		free($5.str);
	}
	| direct_abstract_declarator '[' type_qualifier_list ']' {
		$$.str = newStr("%s[%s]", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	| direct_abstract_declarator '[' assignment_expression ']' {
		$$.str = newStr("%s[%s]", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	| '(' ')' {
		$$.str = newStr("()");
	}
	| '(' parameter_type_list ')' {
		$$.str = newStr("(%s)", $2.str);
		free($2.str);
	}
	| direct_abstract_declarator '(' ')' {
		$$.str = newStr("%s()", $1.str);
		free($1.str);
	}
	| direct_abstract_declarator '(' parameter_type_list ')' {
		$$.str = newStr("%s(%s)", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	;

initializer
	: '{' initializer_list '}' {
	$$.str = newStr("$BEGIN %s $END", $2.str);
		free($2.str);
	}
	| '{' initializer_list ',' '}' {
		$$.str = newStr("$BEGIN %s , $END", $2.str);
		free($2.str);
	}
	| assignment_expression {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	;

initializer_list
	: designation initializer {
		$$.str = newStr("%s %s", $1.str, $2.str);
		free($1.str);
		free($2.str);
	}
	| initializer {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| initializer_list ',' designation initializer {
		$$.str = newStr("%s, %s %s", $1.str, $3.str, $4.str);
		free($1.str);
		free($3.str);
		free($4.str);
	}
	| initializer_list ',' initializer {
		$$.str = newStr("%s, %s", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	;

designation
	: designator_list '=' {
		$$.str = newStr("%s =", $1.str);
		free($1.str);
	}
	;

designator_list
	: designator {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| designator_list designator {
		$$.str = newStr("%s%s", $1.str, $2.str);
		free($1.str);
		free($2.str);
	}
	;

designator
	: '[' constant_expression ']' {
		$$.str = newStr("[%s]", $2.str);
		free($2.str);
	}
	| '.' IDENTIFIER {
		$$.str = newStr(".var");
		free($2.str);
	}
	;

static_assert_declaration
	: STATIC_ASSERT '(' constant_expression ',' STRING_LITERAL ')' ';' {
		$$.str = newStr("%s(%s, %s);\n", $1.str, $3.str, $5.str);
		free($1.str);
		free($3.str);
		free($5.str);
	}
	;

statement
	: labeled_statement {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| compound_statement {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| expression_statement {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| selection_statement {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| iteration_statement {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| jump_statement {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| ifdef_statement {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	;

ifdef_statement
	: IFNDEF_GOOD block_item_list ENDIF {
		$$.str = newStr("%s", $2.str);
		free($2.str);

		fprintf(goodOut, "%s", $$.str);
		
	}
	| IFNDEF_BAD block_item_list ENDIF {
		$$.str = newStr("%s", $2.str);
		free($2.str);
		
		fprintf(badOut, "%s", $$.str);
	}
	;

labeled_statement
	: IDENTIFIER ':' statement {
		$$.str = newStr("%s:\n%s", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	| CASE constant_expression ':' statement {
		$$.str = newStr("%s %s:\n%s", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	| DEFAULT ':' statement {
		$$.str = newStr("%s:\n%s", $1.str, $3.str);
		free($1.str);
		free($3.str);
	}
	;

compound_statement
	: '{' '}' {
		$$.str = newStr("$BEGIN\n$END");
	}
	| '{'  block_item_list '}' {
		$$.str = newStr("$BEGIN\n%s$END", $2.str);
		free($2.str);
	}
	;

block_item_list
	: block_item {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| block_item_list block_item {
		$$.str = newStr("%s%s", $1.str, $2.str);
		free($1.str);
		free($2.str);
	}
	;

block_item
	: declaration {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| statement {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	;

expression_statement
	: ';' {
		$$.str = newStr(";\n");
	}
	| expression ';' {
		$$.str = newStr("%s;\n", $1.str);
		free($1.str);
	}
	;

selection_statement
	: IF '(' expression ')' statement ELSE statement {
		$$.str = newStr("%s(%s)\n%s\n%s\n%s\n", $1.str, $3.str, $5.str, $6.str, $7.str);
		free($1.str);
		free($3.str);
		free($5.str);
		free($6.str);
		free($7.str);
	}
	| IF '(' expression ')' statement {
		$$.str = newStr("%s(%s)\n%s\n", $1.str, $3.str, $5.str);
		free($1.str);
		free($3.str);
		free($5.str);
	}
	| SWITCH '(' expression ')' statement {
		$$.str = newStr("%s(%s)\n%s\n", $1.str, $3.str, $5.str);
		free($1.str);
		free($3.str);
		free($5.str);
	}
	;

iteration_statement
	: WHILE '(' expression ')' statement {
		$$.str = newStr("%s(%s)\n%s\n", $1.str, $3.str, $5.str);
		free($1.str);
		free($3.str);
		free($5.str);
	}
	| DO statement WHILE '(' expression ')' ';' {
		$$.str = newStr("%s\n%s\n%s(%s);\n", $1.str, $2.str, $3.str, $5.str);
		free($1.str);
		free($2.str);
		free($3.str);
		free($5.str);
	}
	| FOR '(' expression_statement expression_statement ')' statement {
		$$.str = newStr("%s(%s %s)\n%s\n", $1.str, $3.str, $4.str, $6.str);
		free($1.str);
		free($3.str);
		free($4.str);
		free($6.str);
	}
	| FOR '(' expression_statement expression_statement expression ')' statement {
		$$.str = newStr("%s(%s %s %s)\n%s\n", $1.str, $3.str, $4.str, $5.str, $7.str);
		free($1.str);
		free($3.str);
		free($4.str);
		free($5.str);
		free($7.str);
	}
	| FOR '(' declaration expression_statement ')' statement {
		$$.str = newStr("%s(%s %s)\n%s\n", $1.str, $3.str, $4.str, $6.str);
		free($1.str);
		free($3.str);
		free($4.str);
		free($6.str);
	}
	| FOR '(' declaration expression_statement expression ')' statement {
		$$.str = newStr("%s(%s %s %s)\n%s\n", $1.str, $3.str, $4.str, $5.str, $7.str);
		free($1.str);
		free($3.str);
		free($4.str);
		free($5.str);
		free($7.str);
	}
	;

jump_statement
	: GOTO IDENTIFIER ';' {
		$$.str = newStr("%s %s;\n", $1.str, $2.str);
		free($1.str);
		free($2.str);
	}
	| CONTINUE ';' {
		$$.str = newStr("%s;\n", $1.str);
		free($1.str);
	}
	| BREAK ';' {
		$$.str = newStr("%s;\n", $1.str);
		free($1.str);
	}
	| RETURN ';' {
		$$.str = newStr("%s;\n", $1.str);
		free($1.str);
	}
	| RETURN expression ';' {
		$$.str = newStr("%s %s;\n", $1.str, $2.str);
		free($1.str);
		free($2.str);
	}
	;

translation_unit
	: external_declaration {
		$$.str = newStr("%s", $1.str);
		free($1.str);
		printf("%s\n", $$.str);
	}
	| translation_unit external_declaration {
		$$.str = newStr("%s%s", $1.str, $2.str);
		printf("%s\n", $2.str);
		free($1.str);
		free($2.str);
	}
	;

external_declaration
	: function_definition {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| declaration {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| ifdef_statement {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| USERPROGRAM {
		isUserCode = 1;
		$$.str = newStr("");
	}
	| SYSPROGRAM {
		isUserCode = 0;
		$$.str = newStr("");
	}
	;

function_definition
	: declaration_specifiers declarator declaration_list compound_statement {
		$$.str = newStr("%s %s\n%s%s", $1.str, $2.str, $3.str, $4.str);
		free($1.str);
		free($2.str);
		free($3.str);
		free($4.str);
	}
	| declaration_specifiers declarator compound_statement {
		$$.str = newStr("%s %s\n%s", $1.str, $2.str, $3.str);
		free($1.str);
		free($2.str);
		free($3.str);
	}
	;

declaration_list
	: declaration {
		$$.str = newStr("%s", $1.str);
		free($1.str);
	}
	| declaration_list declaration {
		$$.str = newStr("%s%s", $1.str, $2.str);
		free($1.str);
		free($2.str);
	}
	;

%%
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <dirent.h>
#include <limits.h>

int main(int argc, char* argv[])
{
	if(argc < 3)
	{
		printf("Error: no directory specified\n");
		return -1;
	}

	char* output_dir = argv[2];
	char* input_dir = argv[1];
	DIR *input_files = opendir(input_dir);

	if(!input_files)
	{
		printf("Error: couldn't open the directories\n");
		//return -1;
	}
	init_symtable();
	init_functable();

	struct dirent *dir;
	dir = readdir(input_files);
	while(dir != NULL)
	{
		printf("%s\n", dir->d_name);

		char* goodFile = newStr("%s/good_%s", output_dir, dir->d_name);
		char* badFile = newStr("%s/bad_%s", output_dir, dir->d_name);
		if(strcmp(dir->d_name + strlen(dir->d_name) - 7, ".c_proc") == 0)
		{
			yyin = fopen(newStr("%s/%s", input_dir, dir->d_name), "r");
			goodOut = fopen(goodFile, "w+");
			badOut = fopen(badFile, "w+");

			if(yyin && goodOut && badOut)
			{
				printf("Processing %s\n", dir->d_name);
				yyparse();
				printf("Done\n");
			}

			fclose(yyin);
			fclose(goodOut);
			fclose(badOut);
		}

		dir = readdir(input_files);
	}
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
	int currentBufferSize = 64;

	char *buffer = malloc(sizeof(char) * currentBufferSize);

	while(ch = fmt[count])
	{
		if(length > currentBufferSize - 2)
		{
			buffer = realloc(buffer, sizeof(char) * 2*currentBufferSize);
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
						buffer = realloc(buffer, sizeof(char) * 2*currentBufferSize);
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
						buffer = realloc(buffer, sizeof(char) * 2*currentBufferSize);
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