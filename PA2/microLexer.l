%{
    #include"microParser.tab.h"
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
FLOAT {return FLOAT;}
INT {return INT;}
VOID {return VOID;}
RETURN {return RETURN;}
WHILE {return WHILE;}
ENDWHILE {return ENDWHILE;}
ENDIF {return ENDIF;}
CONTINUE {return CONTINUE;}
BREAK {return BREAK;}
{OPERATOR} {return *yytext;}
{STRINGLITERAL} {return STRINGLITERAL;}
{IDENTIFIER} {return IDENTIFIER;}
{INTLITERAL} {return INTLITERAL;}
{FLOATLITERAL} {return FLOATLITERAL;}
{COMMENT} {}
. {}
\n {}
%%
int yywrap()
{
  	return 1;
}