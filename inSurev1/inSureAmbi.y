
%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>


typedef struct 
{
 int ival;
 int type;
 char str[500];
}tstruct ; 

#define YYSTYPE  tstruct 

int yylex();
void yyerror( char *s );

%}

%token OMITGOOD
%token OMITBAD
%token ENDIF
%token IDENTIFIER
%token STRINGLIT
%token EVERYTHING
%%
program
   :  input     { 
                }
   ;

input
    :  /* empty */
    |  input line  
                   {
                     strcpy( $$.str, $1.str);
                     strcat( $$.str, $2.str);  
                   }
    ;

line
	: EVERYTHING
	| '(' innerParentheses ')'
	| IDENTIFIER '(' innerParentheses ')' //function
	| IDENTIFIER EVERYTHING
	| '{' input '}'
	| section 
    ;

section
	: OMITGOOD innerBlock ENDIF {printf("OMIT GOOD\n"); }
	| OMITBAD innerBlock ENDIF  {printf("OMIT BAD\n"); }
	;

innerBlock
	:
	| nonEmptyInnerBlock;

nonEmptyInnerBlock
	: nonEmptyInnerBlock validInnerBlock
	| validInnerBlock
	;

validInnerBlock
	: EVERYTHING
	| '(' innerParentheses ')'
	| IDENTIFIER '(' innerParentheses ')' //function
	| IDENTIFIER EVERYTHING
	| '{' innerBlock '}'
	;

innerParentheses
	: 
	| nonEmptyInnerParentheses
	;
nonEmptyInnerParentheses
	: EVERYTHING
	| nonEmptyInnerParentheses EVERYTHING
	;

%%


int main()
{
  yyparse();
  return 0;
}


void yyerror(char *s)  /* Called by yyparse on error */
{
  printf ("\terror: %s\n", s);
}


