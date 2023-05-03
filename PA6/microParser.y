%{
        #include<stdio.h>
        #include<stdlib.h>
        #include<string.h>
        #include <bits/stdc++.h>
        #include <iostream>
        #include <string>
        #include <vector>
        #define global_vars symbolTable[0].size()
        using namespace std;
        int yylex();
        int reg_count=30;
        int func_count=0;
        int link_count = 0;
        int param_decl_in = 0;
        int function_inside = 0;
        int block_inside = 0;
        int fixed_stack = 31;
        string present_function_ret="";
        string present_function_name="";
        string present_block_name="";
        string called_function;
        unordered_map<string,int> arg_space;
        unordered_map<string,string> ret_type;
        vector<int> link_counts;
        vector<string> print_strs;
        extern int line_number;
        void yyerror(const char *err);
        vector<string> blockNames;
        int blockNumbers=0;
        int ret_val_space=0;
        int return_flag=0;
        vector<vector<vector<string>>> symbolTable;
        int declared=0;
        int is_w=0;
        int is_r=0;
        int programScope=-1;
        int temporary_count=0;
        int label=0;
        stack<int> labels;  
        stack<int> loop_start;
        stack<int> loop_end;
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
        vector<struct AST_node*> expr_vec;
        };
        AST_node *main_node = new AST_node();
     // 0 inst 1 instruction
 

     string set_type_id(struct AST_node* node)
     {
         for (int i=programScope;i>=0;i--)
         {
                for (int j=0;j<symbolTable[i].size();j++)
                {
                       
                        if (symbolTable[i][j].size()==4)
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
    string set_var_name(struct AST_node* node)
     {
         for (int i=programScope;i>=1;i--)
         {
                for (int j=0;j<symbolTable[i].size();j++)
                {
                       
                        if (symbolTable[i][j].size()==4)
                        {
                        if (symbolTable[i][j][0]==node->variable_name)
                        {
                                // pass reference else this wont be effective
                                return symbolTable[i][j][2];
                         }  
                       }

                }
          }
          
                for (int j=0;j<symbolTable[0].size();j++)
                {
                       
                        if (symbolTable[0][j].size()==4)
                        {
                        if (symbolTable[0][j][0]==node->variable_name)
                        {
                                // pass reference else this wont be effective
                                return symbolTable[0][j][0];
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
         codeObject.push_back({"move",node->value,node->variable_name});
         return;
        }
        else if (node->variable_type=="float_l")
        {
         node->temp = temporary_count++;
         node->variable_name = "r"+to_string(node->temp);
         codeObject.push_back({"move",node->value,node->variable_name});
         return;     
        }
        else if (node->variable_type=="call")
        {
        codeObject.push_back({"push"});
        
        for (int i=0;i<node->expr_vec.size();i++)
        {
                if (node->expr_vec[i]->left==NULL && node->expr_vec[i]->right==NULL && (node->expr_vec[i]->variable_type=="float"||node->expr_vec[i]->variable_type=="integer" ))
                {
                        
                        codeObject.push_back({"push",node->expr_vec[i]->variable_name});
                }
                else
                {
                        intermediate_code(node->expr_vec[i]);
                        codeObject.push_back({"push","r"+to_string(temporary_count-1)});
                }
                
        }
        for (int i=0;i<reg_count;i++)
        {
                codeObject.push_back({"push r"+to_string(i)});
        }
        codeObject.push_back({"jsr",node->variable_name});
        for (int i=reg_count-1;i>=0;i--)
        {
                codeObject.push_back({"pop","r"+to_string(i)});
        }
        for (int i=0;i<arg_space[node->variable_name];i++)
        {
        codeObject.push_back({"pop"});
        }
        codeObject.push_back({"pop","r"+to_string(temporary_count)});
        node->temp = temporary_count++;
        node->variable_type=ret_type[node->variable_name];
        node->variable_name = "r"+to_string(node->temp);
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
                        if ((node->left->variable_type=="integer"||node->left->variable_type=="int_l") && (node->right->variable_type=="integer"||node->right->variable_type=="int_l"))
                        {
                                if (node->left->temp==-1 && node->right->temp==-1)
                                {
                                        node->left->temp=temporary_count;
                                        node->right->temp=temporary_count;
                                        codeObject.push_back({"move",node->right->variable_name,"r"+to_string(node->left->temp)});
                                        codeObject.push_back({"move","r"+to_string(node->left->temp),node->left->variable_name});
                                        temporary_count++;
                                }
                                else
                                {
                                codeObject.push_back({"move","r"+to_string(node->right->temp),node->left->variable_name});
                                }
                        }
                        else if ((node->left->variable_type=="float"||node->left->variable_type=="float_l") && (node->right->variable_type=="float"||node->right->variable_type=="float_l"))
                        {   
                                if (node->left->temp==-1 && node->right->temp==-1)
                                {
                                        node->left->temp=temporary_count;
                                        node->right->temp=temporary_count;
                                        codeObject.push_back({"move",node->right->variable_name,"r"+to_string(node->left->temp)});
                                        codeObject.push_back({"move","r"+to_string(node->left->temp),node->left->variable_name});
                                        temporary_count++;
                                }
                                else
                                {
                                codeObject.push_back({"move","r"+to_string(node->right->temp),node->left->variable_name});
                                }
                        }
                        else if ((node->left->variable_type=="float") && (node->right->variable_type=="integer"||node->right->variable_type=="int_l"))
                        {   
                                if (node->left->temp==-1 && node->right->temp==-1)
                                {
                                        node->left->temp=temporary_count;
                                        node->right->temp=temporary_count;
                                        codeObject.push_back({"move",node->right->variable_name,"r"+to_string(node->left->temp)});
                                        codeObject.push_back({"move","r"+to_string(node->left->temp),node->left->variable_name});
                                        temporary_count++;
                                }
                                else
                                {
                                codeObject.push_back({"move","r"+to_string(node->right->temp),node->left->variable_name});
                                }
                        }
                        
                 }
                 else if (node->value=="+")
                 {

                        if ((node->left->variable_type=="integer"||node->left->variable_type=="int_l") && (node->right->variable_type=="int_l"||node->right->variable_type=="integer"))
                        {
                                node->variable_type="integer";
                                node->temp = temporary_count++;
                                node->variable_name = "r"+to_string(node->temp);
                                
                                codeObject.push_back({"move",node->left->variable_name,node->variable_name});
                                codeObject.push_back({"addi",node->right->variable_name,node->variable_name});
                        }
                        else if ((node->left->variable_type=="float"||node->left->variable_type=="float_l") && (node->right->variable_type=="float"||node->right->variable_type=="float_l"))
                        {
                                node->variable_type="float";
                                node->temp = temporary_count++;
                                node->variable_name = "r"+to_string(node->temp);

                                codeObject.push_back({"move",node->left->variable_name,node->variable_name});
                                codeObject.push_back({"addr",node->right->variable_name,node->variable_name});
                        }
                        else if ((node->left->variable_type=="float") && (node->right->variable_type=="integer"||node->right->variable_type=="int_l"))
                        {
                                node->variable_type="float";
                                node->temp = temporary_count++;
                                node->variable_name = "r"+to_string(node->temp);

                                codeObject.push_back({"move",node->left->variable_name,node->variable_name});
                                codeObject.push_back({"addr",node->right->variable_name,node->variable_name});
                        }
                 }
                 else if (node->value=="-")
                 {
                        if ((node->left->variable_type=="integer"||node->left->variable_type=="int_l") && (node->right->variable_type=="int_l"||node->right->variable_type=="integer"))
                        {
                                node->variable_type="integer";
                                node->temp = temporary_count++;
                                node->variable_name = "r"+to_string(node->temp);

                                codeObject.push_back({"move",node->left->variable_name,node->variable_name});
                                codeObject.push_back({"subi",node->right->variable_name,node->variable_name});
                        }
                        else if ((node->left->variable_type=="float"||node->left->variable_type=="float_l") && (node->right->variable_type=="float"||node->right->variable_type=="float_l"))
                        {
                                node->variable_type="float";
                                node->temp = temporary_count++;
                                node->variable_name = "r"+to_string(node->temp);

                                codeObject.push_back({"move",node->left->variable_name,node->variable_name});
                                codeObject.push_back({"subr",node->right->variable_name,node->variable_name});
                        }
                        else if ((node->left->variable_type=="float") && (node->right->variable_type=="integer"||node->right->variable_type=="int_l"))
                        {
                                node->variable_type="float";
                                node->temp = temporary_count++;
                                node->variable_name = "r"+to_string(node->temp);

                                codeObject.push_back({"move",node->left->variable_name,node->variable_name});
                                codeObject.push_back({"subr",node->right->variable_name,node->variable_name});
                        }
                 }
                 else if (node->value=="*")
                 {
                        if ((node->left->variable_type=="integer"||node->left->variable_type=="int_l") && (node->right->variable_type=="int_l"||node->right->variable_type=="integer"))
                        {
                                node->variable_type="integer";
                                node->temp = temporary_count++;
                                node->variable_name = "r"+to_string(node->temp);

                                codeObject.push_back({"move",node->left->variable_name,node->variable_name});
                                codeObject.push_back({"muli",node->right->variable_name,node->variable_name});
                        }
                        else if ((node->left->variable_type=="float"||node->left->variable_type=="float_l") && (node->right->variable_type=="float"||node->right->variable_type=="float_l"))
                        {
                                node->variable_type="float";
                                node->temp = temporary_count++;
                                node->variable_name = "r"+to_string(node->temp);

                                codeObject.push_back({"move",node->left->variable_name,node->variable_name});
                                codeObject.push_back({"mulr",node->right->variable_name,node->variable_name});
                        }
                        else if ((node->left->variable_type=="float") && (node->right->variable_type=="integer"||node->right->variable_type=="int_l"))
                        {
                                node->variable_type="float";
                                node->temp = temporary_count++;
                                node->variable_name = "r"+to_string(node->temp);

                                codeObject.push_back({"move",node->left->variable_name,node->variable_name});
                                codeObject.push_back({"mulr",node->right->variable_name,node->variable_name});
                        }

                 }
                 else if (node->value=="/")
                 {
                        if ((node->left->variable_type=="integer"||node->left->variable_type=="int_l") && (node->right->variable_type=="int_l"||node->right->variable_type=="integer"))
                        {
                                node->variable_type="integer";
                                node->temp = temporary_count++;
                                node->variable_name = "r"+to_string(node->temp);
                                codeObject.push_back({"move",node->left->variable_name,node->variable_name});
                                codeObject.push_back({"divi",node->right->variable_name,node->variable_name});                      
                        }
                        else if ((node->left->variable_type=="float"||node->left->variable_type=="float_l") && (node->right->variable_type=="float"||node->right->variable_type=="float_l"))
                        {
                                node->variable_type="float";
                                node->temp = temporary_count++;
                                node->variable_name = "r"+to_string(node->temp);
                                codeObject.push_back({"move",node->left->variable_name,node->variable_name});
                                codeObject.push_back({"divr",node->right->variable_name,node->variable_name});                 
                        }
                        else if ((node->left->variable_type=="float") && (node->right->variable_type=="integer"||node->right->variable_type=="int_l"))
                        {
                                node->variable_type="float";
                                node->temp = temporary_count++;
                                node->variable_name = "r"+to_string(node->temp);
                                codeObject.push_back({"move",node->left->variable_name,node->variable_name});
                                codeObject.push_back({"divr",node->right->variable_name,node->variable_name});                 
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
%type <ast> addop mulop primary postfix_expr factor factor_prefix expr_prefix expr call_expr 
%type <ast_vec> expr_list expr_list_tail
%code requires
{
        #include "head.h"
}
%union
{       
        char *v;
        char *s;  
        char *l;
        char *o;
        struct AST_node *ast;
        vector<AST_node*> *ast_vec;
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
        codeObject.push_back({"end"});
        for (int i=0;i<codeObject.size();i++)
        {
                if (codeObject[i][0]=="str")
                {
                        cout<<codeObject[i][0]<<" "<<codeObject[i][3] <<" "<< codeObject[i][2];
                        cout << endl;
                }
        }
        for (int i=0;i<codeObject.size();i++)
        {
                        if (codeObject[i][0]=="link")
                        {
                                int present_link_count = link_counts[0];
                                cout<< codeObject[i][0] <<" "<<present_link_count;
                                link_counts.erase(link_counts.begin());
                        }
                        else if (codeObject[i][0]=="str")
                        {
                                continue;
                        }
                        else
                        {
                        for (int j=0;j<codeObject[i].size();j++)
                        {
                                cout << codeObject[i][j]<<" ";
                        }
                        }
                        
                        cout <<endl;                
        }
  
}
;
id: IDENTIFIER
    {
        int break_flag=0;
        if (is_r || is_w)
        {
          for (int i=programScope;i>=1;i--)
          {
                for (int j=0;j<symbolTable[i].size();j++)
                {
                       if (symbolTable[i][j].size()==5)
                       {
                        if (symbolTable[i][j][0]==$$)
                        {
                            codeObject[codeObject.size()-1]={codeObject[codeObject.size()-1][0]+"s",symbolTable[i][j][3]};
                            break_flag=1;
                            break;    
                        }
                       } 
                       else
                       {
                         if (symbolTable[i][j][0]==$$){
                                if(symbolTable[i][j][1]=="INT")
                                {
                                codeObject[codeObject.size()-1]={codeObject[codeObject.size()-1][0]+"i",symbolTable[i][j][2]};
                                break_flag=1;
                                break;       
                                }
                                else{
                                codeObject[codeObject.size()-1]={codeObject[codeObject.size()-1][0]+"r",symbolTable[i][j][2]};
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
          if (!break_flag)
          {
                for (int j=0;j<symbolTable[0].size();j++)
                {
                       if (symbolTable[0][j].size()==5)
                       {
                        if (symbolTable[0][j][0]==$$)
                        {
                            codeObject[codeObject.size()-1]={codeObject[codeObject.size()-1][0]+"s",symbolTable[0][j][3]};
                            break;    
                        }
                       } 
                       else
                       {
                         if (symbolTable[0][j][0]==$$){
                                if(symbolTable[0][j][1]=="INT")
                                {
                                codeObject[codeObject.size()-1]={codeObject[codeObject.size()-1][0]+"i",symbolTable[0][j][0]};
                                break;       
                                }
                                else{
                                codeObject[codeObject.size()-1]={codeObject[codeObject.size()-1][0]+"r",symbolTable[0][j][0]};
                                break;     
                                }
                         }
                         
                       }
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
        else if (declared && programScope==0 && function_inside==0)
        {
                // this is for declaring like var a, b, c need to check this also
                // global int kind of variables
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
        
        for (int i=0;i<symbolTable[programScope].size();i++)
        {
                if (symbolTable[programScope][i][0]==$2 && symbolTable[programScope][i][1]=="STRING") /
                {
                        cout << "DECLARATION ERROR "<< $2<<" (previous declaration was at line "<< symbolTable[programScope][i][symbolTable[programScope][i].size()-1]<<")";
                        return 0;
                }
        }
        
        
        vector<string> temp;

        string new_name = $2;
        if (function_inside==0)
        {
                new_name=new_name+"global";
        }
        else
        {
                new_name=new_name+present_function_name;
                if (block_inside==1)
                {
                        new_name=new_name+present_block_name;
                }
        }
        temp={$2,"STRING",$4,new_name,to_string(line_number)};        
        symbolTable[programScope].push_back(temp); 
        codeObject.push_back({"str",$2,$4,new_name});
}
;
str: STRINGLITERAL{};
var_decl: var_type 
{
        declared=1;
        decl_type_in_grammar=$1;
}
id_list SEMICOLON {};
var_type: FLOAT{
        present_function_ret="float";
        } | INT{
        present_function_ret="integer";
        };
any_type: var_type {} | VOID {
        present_function_ret="void";
        };
id_list: id 
{       
        if(declared==1)
        { 
         for (int i=0;i<symbolTable[programScope].size();i++)
        {
                if (symbolTable[programScope][i][0]==$1) 
                {
                        cout << "DECLARATION ERROR "<< $1<<" (previous declaration was at line "<< symbolTable[programScope][i][symbolTable[programScope][i].size()-1]<<")";
                        return 0;
                }
        }
        vector<string> temp={$1,decl_type_in_grammar,to_string(line_number)};
        if (function_inside==0)
        {
        temp={$1,decl_type_in_grammar,"",to_string(line_number)};
        symbolTable[programScope].push_back(temp);      
        }
        else
        {
        if (param_decl_in==0 && function_inside==1)
        {
        link_count++;
        temp={$1,decl_type_in_grammar,"$-"+to_string(link_count),to_string(line_number)};   
        symbolTable[programScope].push_back(temp);      
        }
        }
        
        }
        
       
}
id_tail{}
;
id_tail: COMMA id 
{
        if(declared==1)
        {
         for (int i=0;i<symbolTable[programScope].size();i++)
        {
                if (symbolTable[programScope][i][0]==$2) 
                {
                        cout << "DECLARATION ERROR "<< $2<<" (previous declaration was at line "<< symbolTable[programScope][i][symbolTable[programScope][i].size()-1] <<")";
                        return 0;
                }
        }
        vector<string> temp;
        
        if (function_inside==0)
        {
        temp={$2,decl_type_in_grammar,"",to_string(line_number)};
        symbolTable[programScope].push_back(temp);  
        }
        else
        {
        if (param_decl_in==0 && function_inside==1)
        {
        link_count++;
        temp={$2,decl_type_in_grammar,"$-"+to_string(link_count),to_string(line_number)};       
        symbolTable[programScope].push_back(temp);  
        }
        }
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
        for (int i=0;i<symbolTable[programScope].size();i++)
        {
                if (symbolTable[programScope][i][0]==$2 && symbolTable[programScope][i][1]=="STRING") 
                {
                        cout << "DECLARATION ERROR "<< $2<<" (previous declaration was at line "<< symbolTable[programScope][i][symbolTable[programScope][i].size()-1]<<")";
                        return 0;
                }
        }
        vector<string> temp;
        
        if (function_inside==0)
        {
        temp={$2,$1,"",to_string(line_number)};
        symbolTable[programScope].push_back(temp);
        }
        else
        {
        if (param_decl_in==1)
        {
        link_count++;   
        temp={$2,$1,"$"+to_string(link_count+fixed_stack),to_string(line_number)}; 
        symbolTable[programScope].push_back(temp);
        }
        }
        
        
          
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
        present_function_name = $3;
        ret_type[$3]=present_function_ret;
        if (func_count==0)
        {
        codeObject.push_back({"push"});
        for (int i=0;i<reg_count;i++)
        {
                codeObject.push_back({"push r"+to_string(i)});
        }
        codeObject.push_back({"jsr main"});
        codeObject.push_back({"sys halt"});
        
        }
        
        func_count++;
        blockNames.push_back($3);    
        codeObject.push_back({"label",$3});
        function_inside=1;
}
OPEN_par 
{
        programScope++;
        symbolTable.push_back({});
        param_decl_in=1;
} param_decl_list {
        ret_val_space=link_count;
        arg_space[blockNames[blockNames.size()-1]]=link_count;
        link_count=0;
        param_decl_in=0;
        } CLOSED_par _BEGIN func_body END {
        link_counts.push_back(link_count);
        symbolTable.erase(symbolTable.end());
        programScope--;
        blockNames.erase(blockNames.end());
        function_inside=0;
        link_count=0;
        temporary_count=0;
        present_function_name="";
        
}
;
func_body: {
        codeObject.push_back({"link"});
        } decl stmt_list
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
                assgn_node->temp = -1;
                assgn_node->variable_name = $1;
                assgn_node->variable_type = "identifier";
                assgn_node->value = "";
                assgn_node->left=NULL;
                assgn_node->right=NULL;

                assgn_node->variable_type=set_type_id(assgn_node);
                assgn_node->variable_name = set_var_name(assgn_node);
                
                main_node->op_or=0;
                main_node->variable_name = "";
                main_node->variable_type = "assignment";
                main_node->value = ":=";
                main_node->right = $3;
                main_node->left = assgn_node;
                main_node->temp=-1;
                

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
return_stmt: RETURN expr {
        
        if ($2->left==NULL && $2->right==NULL && $2->variable_type!="call")
        {       
                if ($2->variable_type=="int_l"||$2->variable_type=="float_l")
                {
                        string temporary_string = "r"+to_string(temporary_count);
                        codeObject.push_back({"move", $2->value,temporary_string});
                        codeObject.push_back({"move", temporary_string,"$"+to_string(ret_val_space+1+fixed_stack)});
                        temporary_count++;    
                }
                else
                {
                        string temporary_string = "r"+to_string(temporary_count);
                        codeObject.push_back({"move", $2->variable_name,temporary_string});
                        codeObject.push_back({"move", temporary_string,"$"+to_string(ret_val_space+1+fixed_stack)});
                        temporary_count++;                  
                }
              
                
        }
        else if ($2->variable_type=="call")
        {
                intermediate_code($2);
                
                string temporary_string = "r"+to_string(temporary_count-1);
                codeObject.push_back({"move", temporary_string,"$"+to_string(ret_val_space+1+fixed_stack)});
                temporary_count++;                  
        }
        else
        {
                intermediate_code($2);
                string temporary_string = "r"+to_string(temporary_count);
                codeObject.push_back({"move", $2->variable_name,temporary_string});
                codeObject.push_back({"move", temporary_string,"$"+to_string(ret_val_space+1+fixed_stack)});
                temporary_count++; 
        }
        } SEMICOLON {return_flag=0;} {codeObject.push_back({"unlnk"});codeObject.push_back({"ret"});}
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
                $$ = $1;
            }
            ;
call_expr: id OPEN_par expr_list CLOSED_par 
{
        called_function = $1;        

        AST_node *call_node = new AST_node;
        call_node->op_or = 1;
        call_node->variable_name = $1;
        call_node->variable_type = "call";
        call_node->value = ret_type[$1];
        call_node->temp=-1;
        call_node->left=NULL;
        call_node->right=NULL;
        call_node->expr_vec = (*$3);
        
        $$ = call_node;  
        
}
         ;
expr_list: expr expr_list_tail 
{
        $$=$2;
        $$->push_back($1);
        }
         | { 
        vector<AST_node*>* temp = new vector<AST_node*>;
        $$ = temp;
        }
         ;
expr_list_tail: COMMA expr expr_list_tail {
        $$=$3;
        $$->push_back($2);
}
              |
{
        vector<AST_node*>* temp = new vector<AST_node*>;
        $$ = temp;
}
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
        id_node->temp=-1;
        id_node->left=NULL;
        id_node->right=NULL;
        id_node->variable_type=set_type_id(id_node);
        id_node->variable_name = set_var_name(id_node);
        $$ = id_node;
        }
        | INTLITERAL {
        AST_node *intl_node = new AST_node;
        intl_node->op_or = 1;
        intl_node->variable_name = "";
        intl_node->variable_type = "int_l";
        intl_node->value = $1;
        intl_node->temp=-1;
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
        floatl_node->temp=-1;
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
        plus_node->temp=-1;
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
        sub_node->temp=-1;
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
        mul_node->temp=-1;
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
        div_node->temp=-1;
        div_node->left=NULL;
        div_node->right=NULL;
        $$ = div_node;
     }
     ;
if_stmt: IF {
        
        programScope+=1;
        blockNumbers++;
        present_block_name = "BLOCK"+to_string(blockNumbers);
        symbolTable.push_back({});
        blockNames.push_back("BLOCK "+to_string(blockNumbers));
        label+=2;
        labels.push(label-1);
        block_inside=1;
} OPEN_par cond CLOSED_par decl stmt_list {
        codeObject.push_back({"jmp label"+to_string(labels.top()+1)});
        codeObject.push_back({"label label"+to_string(labels.top())});
        symbolTable.erase(symbolTable.end());
        programScope--;
        blockNames.erase(blockNames.end());
        block_inside=0;
        present_block_name="";
} else_part ENDIF {
        codeObject.push_back({"label label"+to_string(labels.top()+1)});
        labels.pop();
}
        ;
else_part: ELSE {
        programScope++;
        blockNumbers++;
        blockNames.push_back("BLOCK "+to_string(blockNumbers));
        symbolTable.push_back({});
        block_inside=1;
        present_block_name = "BLOCK"+to_string(blockNumbers);
} decl stmt_list {
            symbolTable.erase(symbolTable.end());
            programScope--;    
            blockNames.erase(blockNames.end());
            block_inside=0;
            present_block_name="";
        }
        | ;
cond: expr compop expr {
        
                main_node->op_or=0;
                main_node->variable_name = "compare";
                main_node->variable_type = $2;
                main_node->value = $2;
                main_node->right = $3;
                main_node->left = $1;
                main_node->temp=-1;
                intermediate_code(main_node);
                
                if ($1->temp ==-1 && $3->temp==-1)
                {
                $3->temp = temporary_count;
                temporary_count++;
                codeObject.push_back({"move",$3->variable_name,"r"+to_string($3->temp)});

                if ((($1->variable_type=="integer" || $1->variable_type=="int_l")&& ($3->variable_type=="integer" ||$3->variable_type=="int_l")))
                {
                      codeObject.push_back({"cmpi "+$1->variable_name+" "+"r"+to_string($3->temp)});
                }
                else if ((($1->variable_type=="float" || $1->variable_type=="float_l")&& ($3->variable_type=="float" ||$3->variable_type=="float_l")))
                {
                      codeObject.push_back({"cmpr "+$1->variable_name+" "+"r"+to_string($3->temp)});
                }                
                }
                else
                {
                if ((($1->variable_type=="integer" || $1->variable_type=="int_l")&& ($3->variable_type=="integer" ||$3->variable_type=="int_l")))
                {
                if ($3->temp==-1)
                {
                        codeObject.push_back({"cmpi "+$3->variable_name+" "+$1->variable_name});    
                }
                else
                {
                codeObject.push_back({"cmpi "+$1->variable_name+" "+$3->variable_name});
                }
                }
                else if ((($1->variable_type=="float" || $1->variable_type=="float_l")&& ($3->variable_type=="float" ||$3->variable_type=="float_l")))
                {
                if ($3->temp==-1)
                {
                        codeObject.push_back({"cmpr "+$3->variable_name+" "+$1->variable_name});    
                }  
                else
                {
                codeObject.push_back({"cmpr "+$1->variable_name+" "+$3->variable_name});                       
                }   
                }
                }
                
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
        present_block_name = "BLOCK"+to_string(blockNumbers);
        blockNames.push_back("BLOCK "+to_string(blockNumbers));
        symbolTable.push_back({});
        block_inside=1;
}
OPEN_par {
label+=2;
labels.push(label);
codeObject.push_back({"label label"+to_string(labels.top()-1)});
loop_start.push(labels.top()-1);
loop_end.push(labels.top());
} cond CLOSED_par decl aug_stmt_list {
codeObject.push_back({"jmp label"+to_string(labels.top()-1)});
codeObject.push_back({"label label"+to_string(labels.top())});
labels.pop();
} ENDWHILE {
        loop_start.pop();
        loop_end.pop();
        symbolTable.erase(symbolTable.end());
        programScope--;
        blockNames.erase(blockNames.end());
        present_block_name = "";
        block_inside=0;
}
;
aug_stmt_list: aug_stmt aug_stmt_list 
             |
             ;
aug_stmt: base_stmt | aug_if_stmt | while_stmt | CONTINUE {
codeObject.push_back({"jmp label"+to_string(loop_start.top())});
} SEMICOLON | BREAK {
codeObject.push_back({"jmp label"+to_string(loop_end.top())});
} SEMICOLON
        ;
aug_if_stmt: IF {
        programScope+=1;
        blockNumbers++;
        blockNames.push_back("BLOCK "+to_string(blockNumbers));
        symbolTable.push_back({});
        label+=2;
        labels.push(label-1);
        present_block_name = "BLOCK"+to_string(blockNumbers);
        block_inside=1;
} OPEN_par cond CLOSED_par decl aug_stmt_list {
        codeObject.push_back({"jmp label"+to_string(labels.top()+1)});
        codeObject.push_back({"label label"+to_string(labels.top())});
        symbolTable.erase(symbolTable.end());
        programScope--;
        blockNames.erase(blockNames.end());
        present_block_name = "";
        block_inside=0;
} aug_else_part ENDIF {
        codeObject.push_back({"label label"+to_string(labels.top()+1)});
        labels.pop();
}
        ;
aug_else_part: ELSE {
        programScope++;
        blockNumbers++;
        blockNames.push_back("BLOCK "+to_string(blockNumbers));
        symbolTable.push_back({});
        block_inside=1;
        present_block_name = "BLOCK"+to_string(blockNumbers);
} decl aug_stmt_list {
        symbolTable.erase(symbolTable.end());
        programScope--;    
        blockNames.erase(blockNames.end());
        block_inside=0;
        present_block_name = "";
}
|
        ;
%%