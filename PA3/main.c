/* acknowledgements https://github.com/rishitsaiya/CS316-Compilers-Lab/tree/main/Lab-3/pa1-rishitsaiya-pa3submission */
#include <stdio.h>
#include <stdlib.h>
#include "head.h"
#include "microParser.tab.h"

extern FILE *yyin;
int yylex();
int yyparse();
void yyerror(const char *s)
{
  if (0)
    ;
}

int main(int argc, char *argv[])
{

  if (argc > 1)
  {
    FILE *fp = fopen(argv[1], "r");
    if (fp)
    {
      yyin = fp;
    }
  }

  if (yyparse() == 0)
  {
    return 0;
  }
}
