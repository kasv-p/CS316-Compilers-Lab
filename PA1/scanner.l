%{
%}
DIGIT [0-9]
KEYWORD "PROGRAM"|"BEGIN"|"END"|"FUNCTION"|"READ"|"WRITE"|"IF"|"ELSE"|"ENDIF"|"WHILE"|"ENDWHILE"|"BREAK"|"CONTINUE"|"RETURN"|"INT"|"VOID"|"STRING"|"FLOAT"
OPERATOR ":="|"+"|"-"|"*"|"/"|"="|"!="|"<"|">"|"("|")"|";"|","|"<="|">="
STRINGLITERAL \"(\\.|[^"\\])*\"
IDENTIFIER [a-zA-Z]+[a-zA-Z0-9]*
INTLITERAL {DIGIT}+
FLOATLITERAL {DIGIT}\.{DIGIT}+
COMMENT "//".*
%%
{KEYWORD} {fprintf(yyout,"Token Type: KEYWORD\n"); fprintf(yyout,"Value: %s\n",yytext);}
{OPERATOR} {fprintf(yyout,"Token Type: OPERATOR\n"); fprintf(yyout,"Value: %s\n",yytext);}
{STRINGLITERAL} {fprintf(yyout,"Token Type: STRINGLITERAL\n"); fprintf(yyout,"Value: %s\n",yytext);}
{IDENTIFIER} {fprintf(yyout,"Token Type: IDENTIFIER\n"); fprintf(yyout,"Value: %s\n",yytext);}
{INTLITERAL} {fprintf(yyout,"Token Type: INTLITERAL\n"); fprintf(yyout,"Value: %s\n",yytext);}
{FLOATLITERAL} {fprintf(yyout,"Token Type: FLOATLITERAL\n"); fprintf(yyout,"Value: %s\n",yytext);}
{COMMENT} {if(0);}
. {if(0);}
\n {if(0);}
%%
int yywrap()
{
}
int main(int argc, char* argv[])
{
    extern FILE *yyin,*yyout;
    yyin = fopen(argv[1],"r");
    yyout = fopen(argv[2],"w");
    yylex();
    return 0;
}
