%{
        #include<stdio.h>
        #include<stdlib.h>
        #include<string.h>
        #include <bits/stdc++.h>
        #include <iostream>
        #include <string>
        using namespace std;
        int yylex();
        extern int line_number;
        void yyerror(const char *err);
        vector<string> blockNames;
        map<string, vector<vector<int>>> line_map;
        int blockNumbers=0;
        vector<vector<vector<string>>> symbolTable;
        int declared=0;
        int programScope=-1;
        string decl_type_in_grammar;
     
%}

%token PROGRAM
%token IDENTIFIER
%token STRING
%token STRINGLITERAL
%token FLOAT
%token INT
%token VOID
%token FUNCTION
%token _BEGIN
%token END
%token READ
%token WRITE
%token RETURN
%token INTLITERAL
%token FLOATLITERAL
%token WHILE
%token IF
%token ELSE
%token ENDWHILE
%token CONTINUE
%token BREAK
%token ENDIF
%type <v> var_type 
%type <s> id str

%union
{
        char *v;
        char *s;            
}

%%

program: PROGRAM id _BEGIN 
{
      
        blockNames.push_back("GLOBAL");
        programScope++;
        symbolTable.push_back({});
}
pgm_body END 
{
 for (int i=0;i<symbolTable.size();i++)
 {
        if (i>=1)
        {
        cout<<endl;
        }
        cout<<"Symbol table "<< blockNames[i]<<endl;
        for (int j=0;j<symbolTable[i].size();j++)
        {
                if (symbolTable[i][j].size()==3)
                {
                        cout << "name "<<symbolTable[i][j][0]<<" type "<<symbolTable[i][j][1]<<" value "<<symbolTable[i][j][2];
                }
                else
                {
                        cout << "name "<<symbolTable[i][j][0]<<" type "<<symbolTable[i][j][1];       
                }
                cout << endl;
        }
 }
       
}
;
id: IDENTIFIER{};
pgm_body: decl func_declarations
        ;
decl: string_decl decl
    | var_decl decl
    |
    ;
string_decl: STRING id ':''=' str ';'
{
        if (line_map.find($2)!=line_map.end())
        {
                vector<vector<int>> tempVec=line_map[$2];
                for (int i=0;i<tempVec.size();i++)
                {
                        if (tempVec[i][0]==programScope)
                        {
                                cout << "DECLARATION ERROR "<< $2<<" (previous declaration was at line "<< tempVec[i][1]<<")";
                                return 0;
                        }
                }
        }
        vector<string> temp={$2,"STRING",$5};
        symbolTable[programScope].push_back(temp);
        line_map[$2].push_back({programScope,line_number});
}
;
str: STRINGLITERAL{};
var_decl: var_type 
{
        declared=1;
        decl_type_in_grammar=$1;
}
id_list ';'{};
var_type: FLOAT{} | INT{};
any_type: var_type | VOID;
id_list: id 
{       
        if(declared==1)
        { 
        if (line_map.find($1)!=line_map.end())
        {
                vector<vector<int>> tempVec=line_map[$1];
                for (int i=0;i<tempVec.size();i++)
                {
                        if (tempVec[i][0]==programScope)
                        {
                                cout << "DECLARATION ERROR "<< $1<<" (previous declaration was at line "<< tempVec[i][1]<<")";
                                return 0;
                        }
                }
        }
        vector<string> temp={$1,decl_type_in_grammar};
        symbolTable[programScope].push_back(temp);
        line_map[$1].push_back({programScope,line_number});
        line_map[$1].push_back({programScope,line_number});
        }
        

}
id_tail{}
;
id_tail: ',' id 
{
        if(declared==1)
        {
        if (line_map.find($2)!=line_map.end())
        {
                vector<vector<int>> tempVec=line_map[$2];
                for (int i=0;i<tempVec.size();i++)
                {
                        if (tempVec[i][0]==programScope)
                        {
                                cout << "DECLARATION ERROR "<< $2<<" (previous declaration was at line "<< tempVec[i][1]<<")";
                                return 0;
                        }
                }
        }
        vector<string> temp={$2,decl_type_in_grammar};
        symbolTable[programScope].push_back(temp);
        line_map[$2].push_back({programScope,line_number});
        }
} 
id_tail{} | 
{
declared=0;
decl_type_in_grammar.clear();
}
;
param_decl_list: param_decl param_decl_tail
                |
                ;
param_decl: var_type id
{
        if (line_map.find($2)!=line_map.end())
        {
                vector<vector<int>> tempVec=line_map[$2];
                for (int i=0;i<tempVec.size();i++)
                {
                        if (tempVec[i][0]==programScope)
                        {
                                cout << "DECLARATION ERROR "<< $2<<" (previous declaration was at line "<< tempVec[i][1]<<")";
                                return 0;
                        }
                }
        }
        vector<string> temp={$2,$1};
        symbolTable[programScope].push_back(temp);
        line_map[$2].push_back({programScope,line_number});
}
;
param_decl_tail: ',' param_decl param_decl_tail
                |
                ;
func_declarations: func_decl func_declarations
                 |
                 ;
func_decl: FUNCTION any_type id 
{
        programScope++;
        blockNames.push_back($3);
        symbolTable.push_back({});
}
'('param_decl_list')' _BEGIN func_body END
;
func_body: decl stmt_list
         ;
stmt_list: stmt stmt_list
         |
         ;
stmt: base_stmt
    | if_stmt
    | while_stmt
    ;
base_stmt: assign_stmt
         | read_stmt
         | write_stmt
         | return_stmt
         ;
assign_stmt: assign_expr ';'
           ;
assign_expr: id ':''=' expr
           ;
read_stmt: READ '(' id_list ')'';'
         ;
write_stmt: WRITE '(' id_list ')'';'
          ;
return_stmt: RETURN expr ';'
            ;
expr: expr_prefix factor
    ;
expr_prefix: expr_prefix factor addop
            |
            ;
factor: factor_prefix postfix_expr
      ;
factor_prefix: factor_prefix postfix_expr mulop
             |
             ;
postfix_expr: primary 
            | call_expr
            ;
call_expr: id '(' expr_list ')'
         ;
expr_list: expr expr_list_tail 
         |
         ;
expr_list_tail: ',' expr expr_list_tail 
              |
              ;
primary: '(' expr ')' 
        | id 
        | INTLITERAL 
        | FLOATLITERAL
        ;
addop: '+' 
     | '-'
     ;
mulop: '*' 
     | '/'
     ;
if_stmt: IF 
{
        programScope+=1;
        blockNumbers++;
        blockNames.push_back("BLOCK "+to_string(blockNumbers));
        symbolTable.push_back({});
}
'(' cond ')' decl stmt_list else_part ENDIF
;
else_part: ELSE 
{
        programScope+=1;
        blockNumbers++;
        blockNames.push_back("BLOCK "+to_string(blockNumbers));
        symbolTable.push_back({});
}
decl stmt_list 
|
;
cond: expr compop expr
    ;
compop: '<' | '>' | '=' | '!''=' | '<''=' | '>''='
      ;
while_stmt: WHILE 
{   
        programScope+=1;
        blockNumbers++;
        blockNames.push_back("BLOCK "+to_string(blockNumbers));
        symbolTable.push_back({});
}
'(' cond ')' decl aug_stmt_list ENDWHILE
;
aug_stmt_list: aug_stmt aug_stmt_list 
             |
             ;
aug_stmt: base_stmt | aug_if_stmt | while_stmt | CONTINUE';' | BREAK';'
        ;
aug_if_stmt: IF '(' cond ')' decl aug_stmt_list aug_else_part ENDIF
        ;
aug_else_part: ELSE decl aug_stmt_list |
        ;
%%
