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
        int is_w=0;
        int is_r=0;
        int programScope=-1;
        int temporary_count=0;
        int label=0;
        stack<int> labels;     
        string decl_type_in_grammar;
        vector<vector<string>> codeObject; 
        struct AST_node 
        {
        string variable_name;
        string variable_type;
        int op_or; // 0 - operator // 1 - operand
        string value;
        int temp;
        struct AST_node* left;
        struct AST_node* right;
        };
        AST_node *main_node = new AST_node();

 
     string set_type_id(struct AST_node* node)
     {
         for (int i=symbolTable.size()-1;i>=0;i--)
         {
                for (int j=0;j<symbolTable[i].size();j++)
                {
                       if (symbolTable[i][j].size()==2)
                       {
                        if (symbolTable[i][j][0]==node->variable_name)
                        {
                                // pass reference else this wont be effective
                                if(symbolTable[i][j][1]=="INT")
                                {
                                return "integer";    
                                }
                                else
                                {
                                return "float";
                                }
                         }  
                       }

                }
          }
          return "";
     }
     void intermediate_code(struct AST_node* &node)
     {
        if (node->variable_type=="int_l")
        {  
         node->temp = temporary_count++;
         node->variable_name = "r"+to_string(node->temp);
         codeObject.push_back({"STOREI",node->value,node->variable_name});
         return;
        }
        else if (node->variable_type=="float_l")
        {
         node->temp = temporary_count++;
         node->variable_name = "r"+to_string(node->temp);
         codeObject.push_back({"STOREF",node->value,node->variable_name});
         return;     
        }
        else if(node->variable_type=="identifier")
        {
        }
        else if (node->op_or==0)
        {
                if (node->left!=NULL)
                {
                        intermediate_code(node->left);
                }
                if (node->right!=NULL)
                {
                        intermediate_code(node->right);
                }

                 if (node->value==":=")
                 {
                        if (node->left->variable_type=="integer" && (node->right->variable_type=="integer"||node->right->variable_type=="int_l"))
                        {
                                codeObject.push_back({"STOREI","r"+to_string(node->right->temp),node->left->variable_name});
                        }
                        else if (node->left->variable_type=="float" && (node->right->variable_type=="float"||node->right->variable_type=="float_l"))
                        {
                                codeObject.push_back({"STOREF","r"+to_string(node->right->temp),node->left->variable_name});
                        }
                 }
                 else if (node->value=="+")
                 {
                        
                        if ((node->left->variable_type=="integer"||node->left->variable_type=="int_l") && (node->right->variable_type=="int_l"||node->right->variable_type=="integer"))
                        {
                                node->variable_type="integer";
                                node->temp = temporary_count++;
                                node->variable_name = "r"+to_string(node->temp);
                                codeObject.push_back({"addi",node->left->variable_name,node->right->variable_name,node->variable_name});
                        }
                        else if ((node->left->variable_type=="float"||node->left->variable_type=="float_l") && (node->right->variable_type=="float"||node->right->variable_type=="float_l"))
                        {
                                node->variable_type="float";
                                node->temp = temporary_count++;
                                node->variable_name = "r"+to_string(node->temp);
                                codeObject.push_back({"addr",node->left->variable_name,node->right->variable_name,node->variable_name});
                        }
                 }
                 else if (node->value=="-")
                 {
                        if ((node->left->variable_type=="integer"||node->left->variable_type=="int_l") && (node->right->variable_type=="int_l"||node->right->variable_type=="integer"))
                        {
                                node->variable_type="integer";
                                node->temp = temporary_count++;
                                node->variable_name = "r"+to_string(node->temp);
                                codeObject.push_back({"subi",node->left->variable_name,node->right->variable_name,node->variable_name});
                        }
                        else if ((node->left->variable_type=="float"||node->left->variable_type=="float_l") && (node->right->variable_type=="float"||node->right->variable_type=="float_l"))
                        {
                                
                                node->variable_type="float";
                                node->temp = temporary_count++;
                                node->variable_name = "r"+to_string(node->temp);
                                codeObject.push_back({"subr",node->left->variable_name,node->right->variable_name,node->variable_name});
                        }
                 }
                 else if (node->value=="*")
                 {
                        if ((node->left->variable_type=="integer"||node->left->variable_type=="int_l") && (node->right->variable_type=="int_l"||node->right->variable_type=="integer"))
                        {
                                node->variable_type="integer";
                                node->temp = temporary_count++;
                                node->variable_name = "r"+to_string(node->temp);
                                codeObject.push_back({"muli",node->left->variable_name,node->right->variable_name,node->variable_name});
                        }
                        else if ((node->left->variable_type=="float"||node->left->variable_type=="float_l") && (node->right->variable_type=="float"||node->right->variable_type=="float_l"))
                        {
                                node->variable_type="float";
                                node->temp = temporary_count++;
                                node->variable_name = "r"+to_string(node->temp);
                                codeObject.push_back({"mulr",node->left->variable_name,node->right->variable_name,node->variable_name});
                        }
                 }
                 else if (node->value=="/")
                 {
                        if ((node->left->variable_type=="integer"||node->left->variable_type=="int_l") && (node->right->variable_type=="int_l"||node->right->variable_type=="integer"))
                        {
                                node->variable_type="integer";
                                node->temp = temporary_count++;
                                node->variable_name = "r"+to_string(node->temp);
                                codeObject.push_back({"divi",node->left->variable_name,node->right->variable_name,node->variable_name});
                        }
                        else if ((node->left->variable_type=="float"||node->left->variable_type=="float_l") && (node->right->variable_type=="float"||node->right->variable_type=="float_l"))
                        {
                                node->variable_type="float";
                                node->temp = temporary_count++;
                                node->variable_name = "r"+to_string(node->temp);
                                codeObject.push_back({"divr",node->left->variable_name,node->right->variable_name,node->variable_name});
                        }
                 }
        }
        return;
     }
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
%token LT
%token LTE
%token GT
%token GTE
%token EQ
%token NEQ
%token SEMICOLON
%token COMMA
%token ASSGN_op
%token ADD_op
%token SUB_op
%token MUL_op
%token DIV_op
%token OPEN_par
%token CLOSED_par

%type <o> compop GT EQ NEQ LTE GTE LT
%type <v> var_type 
%type <s> id str
%type <l> FLOATLITERAL INTLITERAL
%type <ast> addop mulop primary postfix_expr factor factor_prefix expr_prefix expr 
%union
{
        char *v;
        char *s;  
        char *l;
        char *o;
        struct AST_node *ast;
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
        // in code object it is of mix and mix so not printing it in comments
        
        for (int i=0;i<codeObject.size();i++)
        {
               
                if (codeObject[i][0]=="var"|| codeObject[i][0]=="str" || codeObject[i][0].find("sys") != std::string::npos)
                {
                        for (int j=0;j<codeObject[i].size();j++)
                        {
                                cout << codeObject[i][j]<<" ";
                        }
                        cout <<endl;
                }
                
                else if (codeObject[i][0].find("STORE")!=std::string::npos)
                {
                        codeObject[i][0]="move";
                        for (int j=0;j<codeObject[i].size();j++)
                        {
                                cout << codeObject[i][j]<<" ";
                        }
                        cout <<endl;
                }
                else if (codeObject[i][0].find("cmpi")!=std::string::npos)
                {
                        cout << codeObject[i][0]<<endl;
                }
                else if (codeObject[i][0].find("label")!=std::string::npos)
                {
                        cout << codeObject[i][0]<<endl;
                }
                else
                {
                        cout << "move"<<" "<<codeObject[i][1]<<" "<<codeObject[i][3]<<endl;
                        cout << codeObject[i][0]<<" "<<codeObject[i][2]<<" "<<codeObject[i][3]<<endl;
                        
                }
             
                
        }
    cout <<"sys halt";   
}
;
id: IDENTIFIER
    {
        int break_flag=0;
        
        if (is_r || is_w)
        {
          for (int i=symbolTable.size()-1;i>=0;i--)
          {
                for (int j=0;i<symbolTable[i].size();j++)
                {
                       if (symbolTable[i][j].size()==3)
                       {
                        if (symbolTable[i][j][0]==$$)
                        {
                            codeObject[codeObject.size()-1]={codeObject[codeObject.size()-1][0]+"s",$$};
                            break_flag=1;
                            break;    
                        }
                       } 
                       else
                       {
                         if (symbolTable[i][j][0]==$$){
                                if(symbolTable[i][j][1]=="INT")
                                {
                                codeObject[codeObject.size()-1]={codeObject[codeObject.size()-1][0]+"i",$$};
                                break_flag=1;
                                break;       
                                }
                                else{
                                codeObject[codeObject.size()-1]={codeObject[codeObject.size()-1][0]+"r",$$};
                                break_flag=1;
                                break;     
                                }
                         }
                         
                       }
                }
                if (break_flag)
                {
                        break;
                }
          }
          if (is_r)
                {
                codeObject.push_back({"sys read"});
                }
                else
                {
                codeObject.push_back({"sys write"});
                }
        }
        else if (declared && !programScope)
        {
                codeObject.push_back({"var",$$});
        }

    }
    ;
pgm_body: decl func_declarations
        ;
decl: string_decl decl
    | var_decl decl
    |
    ;
string_decl: STRING id ASSGN_op str SEMICOLON
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
        vector<string> temp={$2,"STRING",$4};
        symbolTable[programScope].push_back(temp);
        line_map[$2].push_back({programScope,line_number});
        codeObject.push_back({"str",$2,$4});
}
;
str: STRINGLITERAL{};
var_decl: var_type 
{
        declared=1;
        decl_type_in_grammar=$1;
}
id_list SEMICOLON {};
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
id_tail: COMMA id 
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
param_decl_tail: COMMA param_decl param_decl_tail
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
OPEN_par param_decl_list CLOSED_par _BEGIN func_body END
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
assign_stmt: assign_expr SEMICOLON
           ;
assign_expr: id ASSGN_op expr 
                {
                // main nodes get overwritten everytime we need to store 3ac codes in the codeObject vector
                // main node is just a per expression node
                AST_node *assgn_node = new AST_node;
                assgn_node->op_or = 1;
                assgn_node->temp = 0;
                assgn_node->variable_name = $1;
                assgn_node->variable_type = "identifier";
                assgn_node->value = "";
                assgn_node->left=NULL;
                assgn_node->right=NULL;
                assgn_node->variable_type=set_type_id(assgn_node);
                
                
                main_node->op_or=0;
                main_node->variable_name = "";
                main_node->variable_type = "assignment";
                main_node->value = ":=";
                main_node->right = $3;
                main_node->left = assgn_node;
                main_node->temp=0;
                intermediate_code(main_node);
                 
                }
           ;
read_stmt: READ 
        {
        is_r=1;
        codeObject.push_back({"sys read"});
        } 
        OPEN_par id_list CLOSED_par SEMICOLON
        {
        is_r=0;
        codeObject.erase(codeObject.end());
        }
        ;
write_stmt: WRITE 
          {
          is_w=1;
          codeObject.push_back({"sys write"});
          }
          OPEN_par id_list CLOSED_par SEMICOLON
          {
          is_w=0;
          codeObject.erase(codeObject.end());
          }
          ;
return_stmt: RETURN expr SEMICOLON
            ;
expr: expr_prefix factor
        {
             if ($1==NULL){
                $$=$2;
             }   
             else{
                $1->right=$2;
                $$=$1;
             }
        }
    ;
expr_prefix: expr_prefix factor addop {
        if ($1==NULL)
        {
               $3->left = $2;
               $$=$3; 
        }
        else
        {
                $1->right = $2;
                $3->left = $1;
                $$=$3;
        }
}
            | {
                $$ = NULL;
            }
            ;
factor: factor_prefix postfix_expr {        
        if($1==NULL)
        {
                $$=$2;                
        }
        else
        {
                $1->right=$2;
                $$=$1;
        }
        }
      ;
factor_prefix: factor_prefix postfix_expr mulop {
                if (NULL==$1)
                {
                       $3->left = $2;
                       $$=$3;
                }
                else
                {
                        $1->right=$2;
                        $3->left=$1;
                        $$=$3;
                }
             }
             | {
                $$ = NULL;
             }
             ;
postfix_expr: primary {
                $$=$1;   
                }
            | call_expr {
                // to avoid the warning
                $$ = NULL;
            }
            ;
call_expr: id OPEN_par expr_list CLOSED_par
         ;
expr_list: expr expr_list_tail 
         |
         ;
expr_list_tail: COMMA expr expr_list_tail 
              |
              ;
primary: OPEN_par expr CLOSED_par {
                $$=$2;
        }
        | id {
        AST_node *id_node = new AST_node;
        id_node->op_or = 1;
        id_node->variable_name = $1;
        id_node->variable_type = "identifier";
        id_node->value = "";
        id_node->temp=0;
        id_node->left=NULL;
        id_node->right=NULL;
        id_node->variable_type=set_type_id(id_node);
        $$ = id_node;
        }
        | INTLITERAL {
        AST_node *intl_node = new AST_node;
        intl_node->op_or = 1;
        intl_node->variable_name = "";
        intl_node->variable_type = "int_l";
        intl_node->value = $1;
        intl_node->temp=0;
        intl_node->left=NULL;
        intl_node->right=NULL;
        $$ = intl_node;
        }
        | FLOATLITERAL {
        AST_node *floatl_node = new AST_node;
        floatl_node->op_or = 1;
        floatl_node->variable_name = "";
        floatl_node->variable_type = "float_l";
        floatl_node->value = $1;
        floatl_node->temp=0;
        floatl_node->left=NULL;
        floatl_node->right=NULL;
        $$ = floatl_node;
        }
        ;
addop: ADD_op {
        AST_node *plus_node = new AST_node;
        plus_node->op_or = 0;
        plus_node->variable_name = "";
        plus_node->variable_type = "operator";
        plus_node->value = "+";
        plus_node->temp=0;
        plus_node->left=NULL;
        plus_node->right=NULL;
        $$ = plus_node;
        }
     | SUB_op {
        AST_node *sub_node = new AST_node;
        sub_node->op_or = 0;
        sub_node->variable_name = "";
        sub_node->variable_type = "operator";
        sub_node->value = "-";
        sub_node->temp=0;
        sub_node->left=NULL;
        sub_node->right=NULL;
        $$ = sub_node;
     }
     ;
mulop: MUL_op {
        AST_node *mul_node = new AST_node;
        mul_node->op_or = 0;
        mul_node->variable_name = "";
        mul_node->variable_type = "operator";
        mul_node->value = "*";
        mul_node->temp=0;
        mul_node->left=NULL;
        mul_node->right=NULL;
        $$ = mul_node;
}
     | DIV_op {
        AST_node *div_node = new AST_node;
        div_node->op_or = 0;
        div_node->variable_name = "";
        div_node->variable_type = "operator";
        div_node->value = "/";
        div_node->temp=0;
        div_node->left=NULL;
        div_node->right=NULL;
        $$ = div_node;
     }
     ;
if_stmt: IF {
        programScope+=1;
        blockNumbers++;
        blockNames.push_back("BLOCK "+to_string(blockNumbers));
        symbolTable.push_back({});
        label+=2;
        labels.push(label-1);
} OPEN_par cond CLOSED_par decl stmt_list {
        codeObject.push_back({"jmp label"+to_string(labels.top()+1)});
        codeObject.push_back({"label label"+to_string(labels.top())});
} else_part ENDIF {
                codeObject.push_back({"label label"+to_string(labels.top()+1)});
                labels.pop();
                }
        ;
else_part: ELSE {
        programScope+=1;
        blockNumbers++;
        blockNames.push_back("BLOCK "+to_string(blockNumbers));
        symbolTable.push_back({});
}
        decl stmt_list 
        | ;
cond: expr compop expr {
        
                main_node->op_or=0;
                main_node->variable_name = "compare";
                main_node->variable_type = $2;
                main_node->value = $2;
                main_node->right = $3;
                main_node->left = $1;
                main_node->temp=0;
                intermediate_code(main_node);
               
                
                codeObject.push_back({"cmpi "+$1->variable_name+" "+$3->variable_name});
                unordered_map<string, string> jump_comp;
                jump_comp["<="] = "jgt";
                jump_comp[">="] = "jlt";
                jump_comp["="] = "jne";
                jump_comp["!="] = "jeq";
                jump_comp["<"] = "jge";
                jump_comp[">"] = "jle";
             
                codeObject.push_back({jump_comp[$2]+" label"+to_string(labels.top())});
}
    ;
compop: LT | GT | EQ | NEQ | LTE | GTE 
      ;
while_stmt: WHILE 
{   
        programScope+=1;
        blockNumbers++;
        blockNames.push_back("BLOCK "+to_string(blockNumbers));
        symbolTable.push_back({});
}
OPEN_par cond CLOSED_par decl aug_stmt_list ENDWHILE
;
aug_stmt_list: aug_stmt aug_stmt_list 
             |
             ;
aug_stmt: base_stmt | aug_if_stmt | while_stmt | CONTINUE SEMICOLON | BREAK SEMICOLON
        ;
aug_if_stmt: IF OPEN_par cond CLOSED_par decl aug_stmt_list aug_else_part ENDIF
        ;
aug_else_part: ELSE decl aug_stmt_list |
        ;
%%