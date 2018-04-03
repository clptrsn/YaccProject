D			[0-9]
L			[a-zA-Z_]
H			[a-fA-F0-9]
E			[Ee][+-]?{D}+
FS			(f|F|l|L)
IS			(u|U|l|L)*

%{
#include <stdio.h>
#include "inSure.tab.h"

void count();
%}

%%

"#ifndef OMITGOOD" {return OMITGOOD;}
"#ifndef OMITBAD" {return OMITBAD;}
"#endif" 			{return ENDIF;}

"auto"					{ return EVERYTHING; }
"break"					{ return EVERYTHING; }
"case"					{ return EVERYTHING; }
"char"					{ return EVERYTHING; }
"const"					{ return EVERYTHING; }
"continue"				{ return EVERYTHING; }
"default"				{ return EVERYTHING; }
"do"					{ return EVERYTHING; }
"double"				{ return EVERYTHING; }
"else"					{ return EVERYTHING; }
"enum"					{ return EVERYTHING; }
"extern"				{ return EVERYTHING; }
"float"					{ return EVERYTHING; }
"for"					{ return EVERYTHING; }
"goto"					{ return EVERYTHING; }
"if"					{ return EVERYTHING; }
"inline"				{ return EVERYTHING; }
"int"					{ return EVERYTHING; }
"long"					{ return EVERYTHING; }
"register"				{ return EVERYTHING; }
"restrict"				{ return EVERYTHING; }
"return"				{ return EVERYTHING; }
"short"					{ return EVERYTHING; }
"signed"				{ return EVERYTHING; }
"sizeof"				{ return EVERYTHING; }
"static"				{ return EVERYTHING; }
"struct"				{ return EVERYTHING; }
"switch"				{ return EVERYTHING; }
"typedef"				{ return EVERYTHING; }
"union"					{ return EVERYTHING; }
"unsigned"				{ return EVERYTHING; }
"void"					{ return EVERYTHING; }
"volatile"				{ return EVERYTHING; }
"while"					{ return EVERYTHING; }
"_Alignas"                              { return EVERYTHING; }
"_Alignof"                              { return EVERYTHING; }
"_Atomic"                               { return EVERYTHING; }
"_Bool"                                 { return EVERYTHING; }
"_Complex"                              { return EVERYTHING; }
"_Generic"                              { return EVERYTHING; }
"_Imaginary"                            { return EVERYTHING; }
"_Noreturn"                             { return EVERYTHING; }
"_Static_assert"                        { return EVERYTHING; }
"_Thread_local"                         { return EVERYTHING; }
"__func__"                              { return EVERYTHING; }


{ {	return yytext[0]; }
} {	return yytext[0]; }
\( {	return yytext[0]; }
\) {	return yytext[0]; }

L?\"(\\.|[^\\"])*\" {return STRINGLIT;}

{L}({L}|{D})*	{return IDENTIFIER; }

. {return EVERYTHING;}

%%

