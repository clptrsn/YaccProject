O   [0-7]
D   [0-9]
NZ  [1-9]
L   [a-zA-Z_]
A   [a-zA-Z_0-9]
H   [a-fA-F0-9]
HP  (0[xX])
E   ([Ee][+-]?{D}+)
P   ([Pp][+-]?{D}+)
FS  (f|F|l|L)
IS  (((u|U)(l|L|ll|LL)?)|((l|L|ll|LL)(u|U)?))
CP  (u|U|L)
SP  (u8|u|U|L)
ES  (\\(['"\?\\abfnrtv]|[0-7]{1,3}|x[a-fA-F0-9]+))
WS  [ \t\v\n\f]

%{
#include <stdio.h>
#include "symtab.c"
#include "functab.c"

typedef struct {
    int ival;
    char *str;
	char id[64];
	int hasTypedef;
} tstruct;

#define YYSTYPE tstruct

#include "inSure.tab.h"

char *newStr(char *format, ...);

void yyerror(char *);  /* prints grammar violation message */

static void comment(void);
static int check_type(void);
%}

%%
"#ifndef"               {  yylval.str = newStr("%s", yytext);return(IFNDEF); }
"#endif"                {  yylval.str = newStr("%s", yytext);return(ENDIF); }
"OMITGOOD"              { yylval.str = newStr("%s", yytext);return(OMITGOOD); }
"OMITBAD"               { yylval.str = newStr("%s", yytext);return(OMITBAD); }
#USERPROGRAM            { yylval.str = newStr("%s", yytext);return(USERPROGRAM); }
#SYSPROGRAM             { yylval.str = newStr("%s", yytext);return(SYSPROGRAM); }
#[^\n]*

"/*"                                    { comment(); }
"//".*                                    { /* consume //-comment */ }
"__extension__"
"auto"					{ yylval.str = newStr("%s", yytext);return(AUTO); }
"break"					{ yylval.str = newStr("%s", yytext);return(BREAK); }
"case"					{ yylval.str = newStr("%s", yytext);return(CASE); }
"char"					{ yylval.str = newStr("%s", yytext); return(CHAR); }
"const"					{ yylval.str = newStr("%s", yytext); return(CONST); }
"continue"				{ yylval.str = newStr("%s", yytext); return(CONTINUE); }
"default"				{ yylval.str = newStr("%s", yytext); return(DEFAULT); }
"do"					{ yylval.str = newStr("%s", yytext); return(DO); }
"double"				{ yylval.str = newStr("%s", yytext); return(DOUBLE); }
"else"					{ yylval.str = newStr("%s", yytext); return(ELSE); }
"enum"					{ yylval.str = newStr("%s", yytext); return(ENUM); }
"extern"				{ yylval.str = newStr("%s", yytext); return(EXTERN); }
"float"					{ yylval.str = newStr("%s", yytext); return(FLOAT); }
"for"					{ yylval.str = newStr("%s", yytext); return(FOR); }
"goto"					{ yylval.str = newStr("%s", yytext); return(GOTO); }
"if"					{ yylval.str = newStr("%s", yytext); return(IF); }
"inline"				{ yylval.str = newStr("%s", yytext); return(INLINE); }
"int"					{ yylval.str = newStr("%s", yytext); return(INT); }
"long"					{ yylval.str = newStr("%s", yytext); return(LONG); }
"register"				{ yylval.str = newStr("%s", yytext); return(REGISTER); }
"__restrict"            { yylval.str = newStr("%s", yytext); return(RESTRICT); }
"restrict"				{ yylval.str = newStr("%s", yytext); return(RESTRICT); }
"return"				{ yylval.str = newStr("%s", yytext); return(RETURN); }
"short"					{ yylval.str = newStr("%s", yytext); return(SHORT); }
"signed"				{ yylval.str = newStr("%s", yytext); return(SIGNED); }
"sizeof"				{ yylval.str = newStr("%s", yytext); return(SIZEOF); }
"static"				{ yylval.str = newStr("%s", yytext); return(STATIC); }
"struct"				{ yylval.str = newStr("%s", yytext); return(STRUCT); }
"switch"				{ yylval.str = newStr("%s", yytext); return(SWITCH); }
"typedef"				{ yylval.str = newStr("%s", yytext); return(TYPEDEF); }
"union"					{ yylval.str = newStr("%s", yytext); return(UNION); }
"unsigned"				{ yylval.str = newStr("%s", yytext); return(UNSIGNED); }
"void"					{ yylval.str = newStr("%s", yytext); return(VOID); }
"volatile"				{ yylval.str = newStr("%s", yytext); return(VOLATILE); }
"while"					{ yylval.str = newStr("%s", yytext); return(WHILE); }
"_Alignas"                              { yylval.str = newStr("%s", yytext); return ALIGNAS; }
"_Alignof"                              { yylval.str = newStr("%s", yytext); return ALIGNOF; }
"_Atomic"                               { yylval.str = newStr("%s", yytext); return ATOMIC; }
"_Bool"                                 { yylval.str = newStr("%s", yytext); return BOOL; }
"_Complex"                              { yylval.str = newStr("%s", yytext); return COMPLEX; }
"_Generic"                              { yylval.str = newStr("%s", yytext); return GENERIC; }
"_Imaginary"                            { yylval.str = newStr("%s", yytext); return IMAGINARY; }
"_Noreturn"                             { yylval.str = newStr("%s", yytext); return NORETURN; }
"_Static_assert"                        { yylval.str = newStr("%s", yytext); return STATIC_ASSERT; }
"_Thread_local"                         { yylval.str = newStr("%s", yytext); return THREAD_LOCAL; }
"__func__"                              { yylval.str = newStr("%s", yytext); return FUNC_NAME; }

"__builtin_va_list"     { yylval.str = newStr("%s", yytext); return TYPEDEF_NAME; }

{L}{A}*					{yylval.str = newStr("%s", yytext); return check_type(); }

{HP}{H}+{IS}?				{ yylval.str = newStr("%s", yytext); return I_CONSTANT; }
{NZ}{D}*{IS}?				{ yylval.str = newStr("%s", yytext); return I_CONSTANT; }
"0"{O}*{IS}?				{ yylval.str = newStr("%s", yytext); return I_CONSTANT; }
{CP}?"'"([^'\\\n]|{ES})+"'"		{ yylval.str = newStr("%s", yytext); return I_CONSTANT; }

{D}+{E}{FS}?				{ yylval.str = newStr("%s", yytext); return F_CONSTANT; }
{D}*"."{D}+{E}?{FS}?			{ yylval.str = newStr("%s", yytext); return F_CONSTANT; }
{D}+"."{E}?{FS}?			{ yylval.str = newStr("%s", yytext); return F_CONSTANT; }
{HP}{H}+{P}{FS}?			{ yylval.str = newStr("%s", yytext); return F_CONSTANT; }
{HP}{H}*"."{H}+{P}{FS}?			{ yylval.str = newStr("%s", yytext); return F_CONSTANT; }
{HP}{H}+"."{P}{FS}?			{ yylval.str = newStr("%s", yytext); return F_CONSTANT; }

({SP}?\"([^"\\\n]|{ES})*\"{WS}*)+	{ yylval.str = newStr("%s", yytext); return STRING_LITERAL; }

"..."					{ yylval.str = newStr("%s", yytext); return ELLIPSIS; }
". . ."                 { yylval.str = newStr("..."); return ELLIPSIS; }
">>="					{ yylval.str = newStr("%s", yytext); return RIGHT_ASSIGN; }
"<<="					{ yylval.str = newStr("%s", yytext); return LEFT_ASSIGN; }
"+="					{ yylval.str = newStr("%s", yytext); return ADD_ASSIGN; }
"-="					{ yylval.str = newStr("%s", yytext); return SUB_ASSIGN; }
"*="					{ yylval.str = newStr("%s", yytext); return MUL_ASSIGN; }
"/="					{ yylval.str = newStr("%s", yytext); return DIV_ASSIGN; }
"%="					{ yylval.str = newStr("%s", yytext); return MOD_ASSIGN; }
"&="					{ yylval.str = newStr("%s", yytext); return AND_ASSIGN; }
"^="					{ yylval.str = newStr("%s", yytext); return XOR_ASSIGN; }
"|="					{ yylval.str = newStr("%s", yytext); return OR_ASSIGN; }
">>"					{ yylval.str = newStr("%s", yytext); return RIGHT_OP; }
"<<"					{ yylval.str = newStr("%s", yytext); return LEFT_OP; }
"++"					{ yylval.str = newStr("%s", yytext); return INC_OP; }
"--"					{ yylval.str = newStr("%s", yytext); return DEC_OP; }
"->"					{ yylval.str = newStr("%s", yytext); return PTR_OP; }
"&&"					{ yylval.str = newStr("%s", yytext); return AND_OP; }
"||"					{ yylval.str = newStr("%s", yytext); return OR_OP; }
"<="					{ yylval.str = newStr("%s", yytext); return LE_OP; }
">="					{ yylval.str = newStr("%s", yytext); return GE_OP; }
"=="					{ yylval.str = newStr("%s", yytext); return EQ_OP; }
"!="					{ yylval.str = newStr("%s", yytext); return NE_OP; }
";"					{ return ';'; }
("{"|"<%")				{ return '{'; }
("}"|"%>")				{ return '}'; }
","					{ return ','; }
":"					{ return ':'; }
"="					{ return '='; }
"("					{ return '('; }
")"					{ return ')'; }
("["|"<:")				{ return '['; }
("]"|":>")				{ return ']'; }
"."					{ return '.'; }
"&"					{ return '&'; }
"!"					{ return '!'; }
"~"					{ return '~'; }
"-"					{ return '-'; }
"+"					{ return '+'; }
"*"					{ return '*'; }
"/"					{ return '/'; }
"%"					{ return '%'; }
"<"					{ return '<'; }
">"					{ return '>'; }
"^"					{ return '^'; }
"|"					{ return '|'; }
"?"					{ return '?'; }

{WS}+					{ /* whitespace separates tokens */ }
.					{ /* discard bad characters */ }

%%

int yywrap(void)        /* called at end of input */
{
    return 1;           /* terminate now */
}

static void comment(void)
{
    int c;

    while ((c = input()) != 0)
        if (c == '*')
        {
            while ((c = input()) == '*')
                ;

            if (c == '/')
                return;

            if (c == 0)
                break;
        }
    yyerror("unterminated comment");
}

static int check_type(void)
{
    switch (get_type(yytext))
    {
        case TYPEDEF_NAME:                /* previously defined */
            return TYPEDEF_NAME;
        case ENUMERATION_CONSTANT:        /* previously defined */
            return ENUMERATION_CONSTANT;
        default:                          /* includes undefined */
            return IDENTIFIER;
    }
}