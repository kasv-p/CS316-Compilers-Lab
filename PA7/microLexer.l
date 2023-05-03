%{
    #include <stdio.h>
    #include <stdlib.h> 
    #include <string.h>
    #include "microParser.tab.h"
    int line_number = 1;
%}
DIGIT [0-9]
LT  "<"
LTE  "<="
GT ">"
GTE ">="
EQ "="
NEQ "!="
SEMICOLON ";"
COMMA ","
ASSGN_op ":="
ADD_op "+"
SUB_op "-"
MUL_op "*"
DIV_op "/"
OPEN_par "("
CLOSED_par ")"

STRINGLITERAL \"(\\.|[^"\\])*\"
IDENTIFIER [a-zA-Z]+[a-zA-Z0-9]*
INTLITERAL {DIGIT}+
FLOATLITERAL {DIGIT}*\.{DIGIT}+
COMMENT "//".*
%%
BEGIN {return _BEGIN;}
PROGRAM {return PROGRAM;}
END {return END;}
FUNCTION {return FUNCTION;}
READ {return READ;}
WRITE {return WRITE;}
IF {return IF;}
ELSE {return ELSE;}
STRING {return STRING;}
FLOAT {
     yylval.v=strdup(yytext);
     return FLOAT;
     }
INT {
    yylval.v=strdup(yytext);
    return INT;
    }
VOID {return VOID;}
RETURN {return RETURN;}
WHILE {return WHILE;}
ENDWHILE {return ENDWHILE;}
ENDIF {return ENDIF;}
CONTINUE {return CONTINUE;}
BREAK {return BREAK;}
{ASSGN_op} {
    return ASSGN_op;
}
{ADD_op} {return ADD_op;}
{SUB_op} {return SUB_op;}
{MUL_op} {return MUL_op;}
{DIV_op} {return DIV_op;}
{SEMICOLON} {
    return SEMICOLON;
}
{COMMA} {
    return COMMA;
}
{OPEN_par} {
    return OPEN_par;
}
{CLOSED_par} {
    return CLOSED_par;
}
{LT} {
    yylval.o=strdup(yytext);
    return LT;
}
{LTE} {
    yylval.o=strdup(yytext);
    return LTE;
}
{GT} {
    yylval.o=strdup(yytext);
    return GT;
}
{GTE} {
    yylval.o=strdup(yytext);
    return GTE;
}
{EQ} {
    yylval.o=strdup(yytext);
    return EQ;
}
{NEQ} {
    yylval.o=strdup(yytext);
    return NEQ;
}

{STRINGLITERAL} {
                yylval.s = strdup(yytext);
                return STRINGLITERAL;
                }
{IDENTIFIER} {
            yylval.s = strdup(yytext);
            return IDENTIFIER;
            }
{INTLITERAL} {
    yylval.l=strdup(yytext);
    return INTLITERAL;}
{FLOATLITERAL} {
    yylval.l=strdup(yytext);
    return FLOATLITERAL;}
{COMMENT} {}
. {}
\n {line_number+=1;}
%%
int yywrap()
{
  	return 1;
}