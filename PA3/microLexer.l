%{
    #include <stdio.h>
    #include <stdlib.h> 
    #include <string.h>
    #include"microParser.tab.h"
    
    int line_number = 1;
%}
DIGIT [0-9]
OPERATOR [:]|[+]|[-]|[*]|[/]|[=]|[!]|[<]|[>]|[(]|[)]|[,]|[;]
STRINGLITERAL \"(\\.|[^"\\])*\"
IDENTIFIER [a-zA-Z]+[a-zA-Z0-9]*
INTLITERAL {DIGIT}+
FLOATLITERAL {DIGIT}\.{DIGIT}+
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
{OPERATOR} {return *yytext;}
{STRINGLITERAL} {
                yylval.s = strdup(yytext);
                return STRINGLITERAL;
                }
{IDENTIFIER} {
            yylval.s = strdup(yytext);
            return IDENTIFIER;
            }
{INTLITERAL} {return INTLITERAL;}
{FLOATLITERAL} {return FLOATLITERAL;}
{COMMENT} {}
. {}
\n {line_number+=1;}
%%
int yywrap()
{
  	return 1;
}