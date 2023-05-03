%{
        // command to run tiny g++ --std=c++0x tinyNew.C

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
        int reg_count=2;
        int func_count=0;
        int link_count = 0;
        int param_decl_in = 0;
        int function_inside = 0;
        int block_inside = 0;
        int fixed_stack = reg_count+1;
        int global_temp_count=0;
        vector<int> temp_stack;
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
        int present_temp;
        vector<int> global_temporaries;
        int label=0;
        stack<int> labels;  
        stack<int> loop_start;
        stack<int> loop_end;
        string decl_type_in_grammar;
        vector<vector<string>> codeObject; 
        struct code_obj_nodes
        {
                string op1;
                string op2;
                string op3;
                string type;
        };
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
        vector<struct code_obj_nodes*> asm_data;
        struct code_obj_nodes* temp_code_obj;

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
         node->variable_name = "_r"+to_string(node->temp);
         codeObject.push_back({"move",node->value,node->variable_name});

         temp_code_obj = new code_obj_nodes();
         temp_code_obj->type="move";
         temp_code_obj->op1=node->value;
         temp_code_obj->op2=node->variable_name;
         asm_data.push_back(temp_code_obj);

         return;
        }
        else if (node->variable_type=="float_l")
        {
         node->temp = temporary_count++;
         node->variable_name = "_r"+to_string(node->temp);
         codeObject.push_back({"move",node->value,node->variable_name});

         temp_code_obj = new code_obj_nodes();
         temp_code_obj->type="move";
         temp_code_obj->op1=node->value;
         temp_code_obj->op2=node->variable_name;
         asm_data.push_back(temp_code_obj);

         return;     
        }
        else if (node->variable_type=="call")
        {
        codeObject.push_back({"push"});

        temp_code_obj = new code_obj_nodes();
        temp_code_obj->type="push";
        temp_code_obj->op1="";
        asm_data.push_back(temp_code_obj);

        for (int i=0;i<node->expr_vec.size();i++)
        {
                if (node->expr_vec[i]->left==NULL && node->expr_vec[i]->right==NULL && (node->expr_vec[i]->variable_type=="float"||node->expr_vec[i]->variable_type=="integer" ))
                {
                        
                        codeObject.push_back({"push",node->expr_vec[i]->variable_name});

                        temp_code_obj = new code_obj_nodes();
                        temp_code_obj->type="pusharg";
                        temp_code_obj->op1 = node->expr_vec[i]->variable_name;
                        asm_data.push_back(temp_code_obj);
                }
                else
                {
                        intermediate_code(node->expr_vec[i]);
                        codeObject.push_back({"push","_r"+to_string(temporary_count-1)});

                        temp_code_obj = new code_obj_nodes();
                        temp_code_obj->type="pusharg";
                        temp_code_obj->op1 = "_r"+to_string(temporary_count-1);
                        asm_data.push_back(temp_code_obj);
                }
                
        }
        for (int i=0;i<reg_count;i++)
        {
                codeObject.push_back({"push _r"+to_string(i)});

                temp_code_obj = new code_obj_nodes();
                temp_code_obj->type="pushreg";
                temp_code_obj->op1="r"+to_string(i);
                asm_data.push_back(temp_code_obj);
        }
        codeObject.push_back({"jsr",node->variable_name});

        temp_code_obj = new code_obj_nodes();
        temp_code_obj->type="jsr";
        temp_code_obj->op1=node->variable_name;
        asm_data.push_back(temp_code_obj);

        for (int i=reg_count-1;i>=0;i--)
        {
                codeObject.push_back({"pop","_r"+to_string(i)});

                temp_code_obj = new code_obj_nodes();
                temp_code_obj->type="popreg";
                temp_code_obj->op1 = "r"+to_string(i);
                asm_data.push_back(temp_code_obj);
        }
        for (int i=0;i<arg_space[node->variable_name];i++)
        {
        codeObject.push_back({"pop"});

        temp_code_obj = new code_obj_nodes();
        temp_code_obj->type="pop";
        temp_code_obj->op1="";
        asm_data.push_back(temp_code_obj);

        }
        codeObject.push_back({"pop","_r"+to_string(temporary_count)});

        temp_code_obj = new code_obj_nodes();
        temp_code_obj->type="popret";
        temp_code_obj->op1="_r"+to_string(temporary_count);
        asm_data.push_back(temp_code_obj);

        node->temp = temporary_count++;
        node->variable_type=ret_type[node->variable_name];
        node->variable_name = "_r"+to_string(node->temp);

        

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
                                        codeObject.push_back({"move",node->right->variable_name,"_r"+to_string(node->left->temp)});

                                        temp_code_obj = new code_obj_nodes();
                                        temp_code_obj->type="move";
                                        temp_code_obj->op1 = node->right->variable_name;
                                        temp_code_obj->op2 = "_r"+to_string(node->left->temp);
                                        asm_data.push_back(temp_code_obj);

                                        codeObject.push_back({"move","_r"+to_string(node->left->temp),node->left->variable_name});

                                        temp_code_obj = new code_obj_nodes();
                                        temp_code_obj->type="move";
                                        temp_code_obj->op1 = "_r"+to_string(node->left->temp);
                                        temp_code_obj->op2 = node->left->variable_name;
                                        asm_data.push_back(temp_code_obj);

                                        temporary_count++;
                                }
                                else
                                {
                                codeObject.push_back({"move","_r"+to_string(node->right->temp),node->left->variable_name});

                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type="move";
                                temp_code_obj->op1 = "_r"+to_string(node->right->temp);
                                temp_code_obj->op2 = node->left->variable_name;
                                asm_data.push_back(temp_code_obj);
                                }
                        }
                        else if ((node->left->variable_type=="float"||node->left->variable_type=="float_l") && (node->right->variable_type=="float"||node->right->variable_type=="float_l"))
                        {   
                                if (node->left->temp==-1 && node->right->temp==-1)
                                {
                                        node->left->temp=temporary_count;
                                        node->right->temp=temporary_count;
                                        codeObject.push_back({"move",node->right->variable_name,"_r"+to_string(node->left->temp)});

                                        temp_code_obj = new code_obj_nodes();
                                        temp_code_obj->type="move";
                                        temp_code_obj->op1 = node->right->variable_name;
                                        temp_code_obj->op2 = "_r"+to_string(node->left->temp);
                                        asm_data.push_back(temp_code_obj);

                                        codeObject.push_back({"move","_r"+to_string(node->left->temp),node->left->variable_name});

                                        temp_code_obj = new code_obj_nodes();
                                        temp_code_obj->type="move";
                                        temp_code_obj->op1 = "_r"+to_string(node->left->temp);
                                        temp_code_obj->op2 = node->left->variable_name;
                                        asm_data.push_back(temp_code_obj);

                                        temporary_count++;
                                }
                                else
                                {
                                codeObject.push_back({"move","_r"+to_string(node->right->temp),node->left->variable_name});

                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type="move";
                                temp_code_obj->op1 = "_r"+to_string(node->right->temp);
                                temp_code_obj->op2 = node->left->variable_name;
                                asm_data.push_back(temp_code_obj);
                                }
                        }
                        else if ((node->left->variable_type=="float") && (node->right->variable_type=="integer"||node->right->variable_type=="int_l"))
                        {   
                                if (node->left->temp==-1 && node->right->temp==-1)
                                {
                                        node->left->temp=temporary_count;
                                        node->right->temp=temporary_count;
                                        codeObject.push_back({"move",node->right->variable_name,"_r"+to_string(node->left->temp)});
                                        
                                        temp_code_obj = new code_obj_nodes();
                                        temp_code_obj->type="move";
                                        temp_code_obj->op1 = node->right->variable_name;
                                        temp_code_obj->op2 = "_r"+to_string(node->left->temp);
                                        asm_data.push_back(temp_code_obj);

                                        codeObject.push_back({"move","_r"+to_string(node->left->temp),node->left->variable_name});

                                        temp_code_obj = new code_obj_nodes();
                                        temp_code_obj->type="move";
                                        temp_code_obj->op1 = "_r"+to_string(node->left->temp);
                                        temp_code_obj->op2 = node->left->variable_name;
                                        asm_data.push_back(temp_code_obj);

                                        temporary_count++;
                                }
                                else
                                {
                                codeObject.push_back({"move","_r"+to_string(node->right->temp),node->left->variable_name});

                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type="move";
                                temp_code_obj->op1 = "_r"+to_string(node->right->temp);
                                temp_code_obj->op2 = node->left->variable_name;
                                asm_data.push_back(temp_code_obj);

                                }
                        }
                        
                 }
                 else if (node->value=="+")
                 {

                        if ((node->left->variable_type=="integer"||node->left->variable_type=="int_l") && (node->right->variable_type=="int_l"||node->right->variable_type=="integer"))
                        {
                                node->variable_type="integer";
                                node->temp = temporary_count++;
                                node->variable_name = "_r"+to_string(node->temp);
                                
                                codeObject.push_back({"move",node->left->variable_name,node->variable_name});
                                codeObject.push_back({"addi",node->right->variable_name,node->variable_name});

                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type="move";
                                temp_code_obj->op1 = node->left->variable_name;
                                temp_code_obj->op2 = node->variable_name;
                                asm_data.push_back(temp_code_obj);


                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type="addi";
                                temp_code_obj->op1 = node->right->variable_name;
                                temp_code_obj->op2 = node->variable_name;
                                asm_data.push_back(temp_code_obj);
                        }
                        else if ((node->left->variable_type=="float"||node->left->variable_type=="float_l") && (node->right->variable_type=="float"||node->right->variable_type=="float_l"))
                        {
                                node->variable_type="float";
                                node->temp = temporary_count++;
                                node->variable_name = "_r"+to_string(node->temp);
                                
                                codeObject.push_back({"move",node->left->variable_name,node->variable_name});
                                codeObject.push_back({"addr",node->right->variable_name,node->variable_name});


                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type="move";
                                temp_code_obj->op1 = node->left->variable_name;
                                temp_code_obj->op2 = node->variable_name;
                                asm_data.push_back(temp_code_obj);

                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type="addr";
                                temp_code_obj->op1 = node->right->variable_name;
                                temp_code_obj->op2 = node->variable_name;
                                asm_data.push_back(temp_code_obj);

                                
                        }
                        else if ((node->left->variable_type=="float") && (node->right->variable_type=="integer"||node->right->variable_type=="int_l"))
                        {
                                node->variable_type="float";
                                node->temp = temporary_count++;
                                node->variable_name = "_r"+to_string(node->temp);

                                codeObject.push_back({"move",node->left->variable_name,node->variable_name});
                                codeObject.push_back({"addr",node->right->variable_name,node->variable_name});

                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type="move";
                                temp_code_obj->op1 = node->left->variable_name;
                                temp_code_obj->op2 = node->variable_name;
                                asm_data.push_back(temp_code_obj);

                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type="addr";
                                temp_code_obj->op1 = node->right->variable_name;
                                temp_code_obj->op2 = node->variable_name;
                                asm_data.push_back(temp_code_obj);


                     }
                 }
                 else if (node->value=="-")
                 {
                        if ((node->left->variable_type=="integer"||node->left->variable_type=="int_l") && (node->right->variable_type=="int_l"||node->right->variable_type=="integer"))
                        {
                                node->variable_type="integer";
                                node->temp = temporary_count++;
                                node->variable_name = "_r"+to_string(node->temp);

                                codeObject.push_back({"move",node->left->variable_name,node->variable_name});
                                codeObject.push_back({"subi",node->right->variable_name,node->variable_name});

                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type="move";
                                temp_code_obj->op1 = node->left->variable_name;
                                temp_code_obj->op2 = node->variable_name;
                                asm_data.push_back(temp_code_obj);


                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type="subi";
                                temp_code_obj->op1 = node->right->variable_name;
                                temp_code_obj->op2 = node->variable_name;
                                asm_data.push_back(temp_code_obj);
                        }
                        else if ((node->left->variable_type=="float"||node->left->variable_type=="float_l") && (node->right->variable_type=="float"||node->right->variable_type=="float_l"))
                        {
                                node->variable_type="float";
                                node->temp = temporary_count++;
                                node->variable_name = "_r"+to_string(node->temp);

                                codeObject.push_back({"move",node->left->variable_name,node->variable_name});
                                codeObject.push_back({"subr",node->right->variable_name,node->variable_name});

                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type="move";
                                temp_code_obj->op1 = node->left->variable_name;
                                temp_code_obj->op2 = node->variable_name;
                                asm_data.push_back(temp_code_obj);


                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type="subr";
                                temp_code_obj->op1 = node->right->variable_name;
                                temp_code_obj->op2 = node->variable_name;
                                asm_data.push_back(temp_code_obj);
                        }
                        else if ((node->left->variable_type=="float") && (node->right->variable_type=="integer"||node->right->variable_type=="int_l"))
                        {
                                node->variable_type="float";
                                node->temp = temporary_count++;
                                node->variable_name = "_r"+to_string(node->temp);

                                codeObject.push_back({"move",node->left->variable_name,node->variable_name});
                                codeObject.push_back({"subr",node->right->variable_name,node->variable_name});

                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type="move";
                                temp_code_obj->op1 = node->left->variable_name;
                                temp_code_obj->op2 = node->variable_name;
                                asm_data.push_back(temp_code_obj);


                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type="subr";
                                temp_code_obj->op1 = node->right->variable_name;
                                temp_code_obj->op2 = node->variable_name;
                                asm_data.push_back(temp_code_obj);
                        }
                 }
                 else if (node->value=="*")
                 {
                        if ((node->left->variable_type=="integer"||node->left->variable_type=="int_l") && (node->right->variable_type=="int_l"||node->right->variable_type=="integer"))
                        {
                                node->variable_type="integer";
                                node->temp = temporary_count++;
                                node->variable_name = "_r"+to_string(node->temp);
                                codeObject.push_back({"move",node->left->variable_name,node->variable_name});
                                codeObject.push_back({"muli",node->right->variable_name,node->variable_name});

                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type="move";
                                temp_code_obj->op1 = node->left->variable_name;
                                temp_code_obj->op2 = node->variable_name;
                                asm_data.push_back(temp_code_obj);


                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type="muli";
                                temp_code_obj->op1 = node->right->variable_name;
                                temp_code_obj->op2 = node->variable_name;
                                asm_data.push_back(temp_code_obj);
                        }
                        else if ((node->left->variable_type=="float"||node->left->variable_type=="float_l") && (node->right->variable_type=="float"||node->right->variable_type=="float_l"))
                        {
                                node->variable_type="float";
                                node->temp = temporary_count++;
                                node->variable_name = "_r"+to_string(node->temp);
                                codeObject.push_back({"move",node->left->variable_name,node->variable_name});
                                codeObject.push_back({"mulr",node->right->variable_name,node->variable_name});

                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type="move";
                                temp_code_obj->op1 = node->left->variable_name;
                                temp_code_obj->op2 = node->variable_name;
                                asm_data.push_back(temp_code_obj);


                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type="mulr";
                                temp_code_obj->op1 = node->right->variable_name;
                                temp_code_obj->op2 = node->variable_name;
                                asm_data.push_back(temp_code_obj);
                        }
                        else if ((node->left->variable_type=="float") && (node->right->variable_type=="integer"||node->right->variable_type=="int_l"))
                        {
                                node->variable_type="float";
                                node->temp = temporary_count++;
                                node->variable_name = "_r"+to_string(node->temp);
                                codeObject.push_back({"move",node->left->variable_name,node->variable_name});
                                codeObject.push_back({"mulr",node->right->variable_name,node->variable_name});

                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type="move";
                                temp_code_obj->op1 = node->left->variable_name;
                                temp_code_obj->op2 = node->variable_name;
                                asm_data.push_back(temp_code_obj);


                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type="mulr";
                                temp_code_obj->op1 = node->right->variable_name;
                                temp_code_obj->op2 = node->variable_name;
                                asm_data.push_back(temp_code_obj);
                        }

                 }
                 else if (node->value=="/")
                 {
                        if ((node->left->variable_type=="integer"||node->left->variable_type=="int_l") && (node->right->variable_type=="int_l"||node->right->variable_type=="integer"))
                        {
                                node->variable_type="integer";
                                node->temp = temporary_count++;
                                node->variable_name = "_r"+to_string(node->temp);
                                codeObject.push_back({"move",node->left->variable_name,node->variable_name});
                                codeObject.push_back({"divi",node->right->variable_name,node->variable_name});   

                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type="move";
                                temp_code_obj->op1 = node->left->variable_name;
                                temp_code_obj->op2 = node->variable_name;
                                asm_data.push_back(temp_code_obj);


                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type="divi";
                                temp_code_obj->op1 = node->right->variable_name;
                                temp_code_obj->op2 = node->variable_name;
                                asm_data.push_back(temp_code_obj);                   
                        }
                        else if ((node->left->variable_type=="float"||node->left->variable_type=="float_l") && (node->right->variable_type=="float"||node->right->variable_type=="float_l"))
                        {
                                node->variable_type="float";
                                node->temp = temporary_count++;
                                node->variable_name = "_r"+to_string(node->temp);
                                codeObject.push_back({"move",node->left->variable_name,node->variable_name});
                                codeObject.push_back({"divr",node->right->variable_name,node->variable_name});      

                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type="move";
                                temp_code_obj->op1 = node->left->variable_name;
                                temp_code_obj->op2 = node->variable_name;
                                asm_data.push_back(temp_code_obj);


                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type="divr";
                                temp_code_obj->op1 = node->right->variable_name;
                                temp_code_obj->op2 = node->variable_name;
                                asm_data.push_back(temp_code_obj);           
                        }
                        else if ((node->left->variable_type=="float") && (node->right->variable_type=="integer"||node->right->variable_type=="int_l"))
                        {
                                node->variable_type="float";
                                node->temp = temporary_count++;
                                node->variable_name = "_r"+to_string(node->temp);
                                codeObject.push_back({"move",node->left->variable_name,node->variable_name});
                                codeObject.push_back({"divr",node->right->variable_name,node->variable_name});   

                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type="move";
                                temp_code_obj->op1 = node->left->variable_name;
                                temp_code_obj->op2 = node->variable_name;
                                asm_data.push_back(temp_code_obj);


                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type="divr";
                                temp_code_obj->op1 = node->right->variable_name;
                                temp_code_obj->op2 = node->variable_name;
                                asm_data.push_back(temp_code_obj);              
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

        temp_code_obj = new code_obj_nodes();
        temp_code_obj->type = "end";


        for (int i=0;i<asm_data.size();i++)
        {
                if (asm_data[i]->type=="str")
                {
                        cout << asm_data[i]->type<< " "<<asm_data[i]->op3<<" "<<asm_data[i]->op2<<endl;
                }
                if (asm_data[i]->type=="var")
                {
                        cout << asm_data[i]->type <<" "<< asm_data[i]->op1<<endl;
                }
        }
        for (int i=0;i<global_temp_count+1;i++)
        {
                cout << "var" <<" "<< "T"<<i<<endl;
        }
        
        //var things here 

        for (int i=0;i<asm_data.size();i++)
        {
                if (asm_data[i]->type == "link")
                {
                        int present_link_count = link_counts[0];

                        cout<< asm_data[i]->type <<" "<<present_link_count<<endl;
                        link_counts.erase(link_counts.begin());

                        present_temp = temp_stack[0];
                        temp_stack.erase(temp_stack.begin());
                        
                }
                else if (asm_data[i]->type=="unlnk" || asm_data[i]->type=="ret")
                {
                        cout<< asm_data[i]->type <<endl;    
                }
                else if (asm_data[i]->type == "sys halt")
                {
                        cout <<asm_data[i]->type <<endl;
                }
                else if (asm_data[i]->type.find("sys")!=string::npos)
                {
                        cout << asm_data[i]->type<<" "<<asm_data[i]->op1<<endl;
                }
                else if (asm_data[i]->type == "label" || asm_data[i]->type == "jmp" || asm_data[i]->type == "jgt" || asm_data[i]->type == "jlt" || asm_data[i]->type == "jne" || asm_data[i]->type == "jeq" || asm_data[i]->type == "jge" || asm_data[i]->type == "jle")
                {
                        cout << asm_data[i]->type << " "<<asm_data[i]->op1<<endl;
                }
                else if (asm_data[i]->type == "jsr")
                {
                        cout <<asm_data[i]->type <<" "<<asm_data[i]->op1<<endl;
                }
                else if (asm_data[i]->type=="str" || asm_data[i]->type=="var")
                {
                        continue;
                } 
                else if (asm_data[i]->type == "move")
                {

                        if (asm_data[i]->op1.find("$")==string::npos)
                        {
                                if (asm_data[i]->op1.find("_r")!=string::npos)
                                {
                                        int index = 2; 
                                        int length = strlen(asm_data[i]->op1.c_str());
                                        string substr = asm_data[i]->op1.substr(index, length - index);
                                        int real_num = stoi(substr)+present_temp;
                                        asm_data[i]->op1="T"+to_string(real_num);

                                }
                                
                        }
                        
                        cout << "move"<<" "<<asm_data[i]->op1<<" "<<"r0"<<endl;

                        if (asm_data[i]->op2.find("$")==string::npos)
                        {
                                if (asm_data[i]->op2.find("_r")!=string::npos)
                                {
                                       int index = 2; 
                                        int length = strlen(asm_data[i]->op2.c_str());
                                        string substr = asm_data[i]->op2.substr(index, length - index);
                                        int real_num = stoi(substr)+present_temp;
                                        asm_data[i]->op2="T"+to_string(real_num);
                                }
                               
                        }
                        
                        cout << "move"<<" "<<"r0"<<" "<<asm_data[i]->op2<<endl;
                                             
                }
                else if (asm_data[i]->type.find("add")!=string::npos || asm_data[i]->type.find("mul")!=string::npos || asm_data[i]->type.find("div")!=string::npos || asm_data[i]->type.find("sub")!=string::npos)
                {
                        if (asm_data[i]->op1.find("$")==string::npos)
                        {
                                if (asm_data[i]->op1.find("_r")!=string::npos)
                                {
                                       int index = 2; 
                                        int length = strlen(asm_data[i]->op1.c_str());
                                        string substr = asm_data[i]->op1.substr(index, length - index);
                                        int real_num = stoi(substr)+present_temp;
                                        asm_data[i]->op1="T"+to_string(real_num);
                                }
                                
                        }
                        cout << "move"<<" "<<asm_data[i]->op1<<" "<<"r1"<<endl;

                        if (asm_data[i]->op2.find("$")==string::npos)
                        {
                                if (asm_data[i]->op2.find("_r")!=string::npos)
                                {
                                       int index = 2; 
                                        int length = strlen(asm_data[i]->op2.c_str());
                                        string substr = asm_data[i]->op2.substr(index, length - index);
                                        int real_num = stoi(substr)+present_temp;
                                        asm_data[i]->op2="T"+to_string(real_num);
                                }
                               
                        }
                        cout << "move"<< " "<<asm_data[i]->op2<<" "<<"r0"<<endl;

                        cout << asm_data[i]->type<<" "<<"r1"<<" "<<"r0"<<endl;
                        cout << "move"<< " "<<"r0"<<" "<<asm_data[i]->op2<<endl; 
                        
                }
                else if (asm_data[i]->type.find("cmp")!=string::npos)
                {
                        if (asm_data[i]->op2.find("_r")!=string::npos)
                        {
                                int index = 2; 
                                int length = strlen(asm_data[i]->op2.c_str());
                                string substr = asm_data[i]->op2.substr(index, length - index);
                                int real_num = stoi(substr)+present_temp;
                                asm_data[i]->op2="T"+to_string(real_num);
                        }
                        

                        if (asm_data[i]->op1.find("$")==string::npos)
                        {
                                if (asm_data[i]->op1.find("_r")!=string::npos)
                                {
                                        int index = 2; 
                                        int length = strlen(asm_data[i]->op1.c_str());
                                        string substr = asm_data[i]->op1.substr(index, length - index);
                                        int real_num = stoi(substr)+present_temp;
                                        asm_data[i]->op1="T"+to_string(real_num);
                                }
                                
                        }
                        
                        cout << "move"<< " "<<asm_data[i]->op1<<" "<<"r1"<<endl;
                        cout << "move"<< " "<<asm_data[i]->op2<<" "<<"r0"<<endl; 
                        cout << asm_data[i]->type << " "<< "r1"<<" "<<"r0"<<endl;
                        
                }
                else if (asm_data[i]->type == "push")
                {
                        cout << asm_data[i]->type << endl;                    
                }
                else if (asm_data[i]->type == "pusharg")
                {
                        if (asm_data[i]->op1.find("_r")!=string::npos && asm_data[i]->op1.find("$")==string::npos)
                        {
                               int index = 2; 
                                int length = strlen(asm_data[i]->op1.c_str());
                                string substr = asm_data[i]->op1.substr(index, length - index);
                                int real_num = stoi(substr)+present_temp;
                                asm_data[i]->op1="T"+to_string(real_num);
                        }
                        
                        cout << "push"<<" "<<asm_data[i]->op1<<endl;
                }
                else if (asm_data[i]->type == "pushreg")
                {
                        cout << "push"<<" "<<asm_data[i]->op1 << endl;                    
                }
                else if (asm_data[i]->type == "pop")
                {
                        cout << asm_data[i]->type << endl;                    
                }
                else if (asm_data[i]->type == "popreg")
                {
                        cout << "pop"<<" "<<asm_data[i]->op1<< endl;                    
                }
                else if (asm_data[i]->type == "popret")
                {
                        if (asm_data[i]->op1.find("_r")!=string::npos)
                        {
                                int index = 2; 
                                int length = strlen(asm_data[i]->op1.c_str());
                                string substr = asm_data[i]->op1.substr(index, length - index);
                                int real_num = stoi(substr)+present_temp;
                                asm_data[i]->op1="T"+to_string(real_num);
                        }
                        
                        cout << "pop"<<" "<<asm_data[i]->op1<<endl;
                }
        }
        cout << "end"<<endl;
        
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

                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type = codeObject[codeObject.size()-1][0];
                                temp_code_obj->op1 = symbolTable[i][j][3];
                                asm_data.push_back(temp_code_obj);

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
                                        temp_code_obj = new code_obj_nodes();
                                        temp_code_obj->type = codeObject[codeObject.size()-1][0];
                                        temp_code_obj->op1 = symbolTable[i][j][2];
                                        asm_data.push_back(temp_code_obj);
                                break_flag=1;
                                break;       
                                }
                                else{
                                codeObject[codeObject.size()-1]={codeObject[codeObject.size()-1][0]+"r",symbolTable[i][j][2]};
                                        temp_code_obj = new code_obj_nodes();
                                        temp_code_obj->type = codeObject[codeObject.size()-1][0];
                                        temp_code_obj->op1 = symbolTable[i][j][2];
                                        asm_data.push_back(temp_code_obj);
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
                                
                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type = codeObject[codeObject.size()-1][0];
                                temp_code_obj->op1 = symbolTable[0][j][3];
                                asm_data.push_back(temp_code_obj);
                            break;    
                        }
                       } 
                       else
                       {
                         if (symbolTable[0][j][0]==$$){
                                if(symbolTable[0][j][1]=="INT")
                                {
                                codeObject[codeObject.size()-1]={codeObject[codeObject.size()-1][0]+"i",symbolTable[0][j][0]};
                                
                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type = codeObject[codeObject.size()-1][0];
                                temp_code_obj->op1 = symbolTable[0][j][0];
                                asm_data.push_back(temp_code_obj);
                                break;       
                                }
                                else{
                                codeObject[codeObject.size()-1]={codeObject[codeObject.size()-1][0]+"r",symbolTable[0][j][0]};
                                
                                temp_code_obj = new code_obj_nodes();
                                temp_code_obj->type = codeObject[codeObject.size()-1][0];
                                temp_code_obj->op1 = symbolTable[0][j][0];
                                asm_data.push_back(temp_code_obj);
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
               
                codeObject.push_back({"var",$$});

                temp_code_obj = new code_obj_nodes();
                temp_code_obj->type = "var";
                temp_code_obj->op1 = $$;
                asm_data.push_back(temp_code_obj);
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
                if (symbolTable[programScope][i][0]==$2 && symbolTable[programScope][i][1]=="STRING") 
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

        temp_code_obj = new code_obj_nodes();
        temp_code_obj->type = "str";
        temp_code_obj->op1 = $2;
        temp_code_obj->op2 = $4;
        temp_code_obj->op3 = new_name;
        asm_data.push_back(temp_code_obj);
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
        temp_code_obj = new code_obj_nodes();
        temp_code_obj->type="push";
        asm_data.push_back(temp_code_obj);
        
        for (int i=0;i<reg_count;i++)
        {
                codeObject.push_back({"push _r"+to_string(i)});

                temp_code_obj = new code_obj_nodes();
                temp_code_obj->type="pushreg";
                temp_code_obj->op1="r"+to_string(i);
                asm_data.push_back(temp_code_obj);
        }
        codeObject.push_back({"jsr main"});

        temp_code_obj = new code_obj_nodes();
        temp_code_obj->type="jsr";
        temp_code_obj->op1="main";
        asm_data.push_back(temp_code_obj);

        codeObject.push_back({"sys halt"});

        temp_code_obj = new code_obj_nodes();
        temp_code_obj->type="sys halt";
        asm_data.push_back(temp_code_obj);
        
        }
        
        func_count++;
        blockNames.push_back($3);    
        codeObject.push_back({"label",$3});

        temp_code_obj = new code_obj_nodes();
        temp_code_obj->type="label";
        temp_code_obj->op1=$3;
        asm_data.push_back(temp_code_obj);

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
        temp_stack.push_back(global_temp_count);
        global_temp_count+=temporary_count;
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
        temp_code_obj = new code_obj_nodes();
        temp_code_obj->type="link";
        asm_data.push_back(temp_code_obj);

        
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
                        string temporary_string = "_r"+to_string(temporary_count);
                        codeObject.push_back({"move", $2->value,temporary_string});


                        temp_code_obj = new code_obj_nodes();
                        temp_code_obj->type="move";
                        temp_code_obj->op1=$2->value;
                        temp_code_obj->op2=temporary_string;
                        asm_data.push_back(temp_code_obj);

                        codeObject.push_back({"move", temporary_string,"$"+to_string(ret_val_space+1+fixed_stack)});

                        temp_code_obj = new code_obj_nodes();
                        temp_code_obj->type="move";
                        temp_code_obj->op1=temporary_string;
                        temp_code_obj->op2="$"+to_string(ret_val_space+1+fixed_stack);
                        asm_data.push_back(temp_code_obj);

                        temporary_count++;    
                }
                else
                {
                        string temporary_string = "_r"+to_string(temporary_count);
                        codeObject.push_back({"move", $2->variable_name,temporary_string});
                        
                        temp_code_obj = new code_obj_nodes();
                        temp_code_obj->type="move";
                        temp_code_obj->op1=$2->variable_name;
                        temp_code_obj->op2=temporary_string;
                        asm_data.push_back(temp_code_obj);

                        
                        codeObject.push_back({"move", temporary_string,"$"+to_string(ret_val_space+1+fixed_stack)});

                        temp_code_obj = new code_obj_nodes();
                        temp_code_obj->type="move";
                        temp_code_obj->op1=temporary_string;
                        temp_code_obj->op2="$"+to_string(ret_val_space+1+fixed_stack);
                        asm_data.push_back(temp_code_obj);

                        temporary_count++;                  
                }
              
                
        }
        else if ($2->variable_type=="call")
        {
                intermediate_code($2);
                
                string temporary_string = "_r"+to_string(temporary_count-1);
                codeObject.push_back({"move", temporary_string,"$"+to_string(ret_val_space+1+fixed_stack)});

                temp_code_obj = new code_obj_nodes();
                temp_code_obj->type="move";
                temp_code_obj->op1=temporary_string;
                temp_code_obj->op2="$"+to_string(ret_val_space+1+fixed_stack);
                asm_data.push_back(temp_code_obj);

                temporary_count++;                  
        }
        else
        {
                intermediate_code($2);
                string temporary_string = "_r"+to_string(temporary_count);
                codeObject.push_back({"move", $2->variable_name,temporary_string});

                temp_code_obj = new code_obj_nodes();
                temp_code_obj->type="move";
                temp_code_obj->op1=$2->variable_name;
                temp_code_obj->op2=temporary_string;
                asm_data.push_back(temp_code_obj);

                codeObject.push_back({"move", temporary_string,"$"+to_string(ret_val_space+1+fixed_stack)});

                temp_code_obj = new code_obj_nodes();
                temp_code_obj->type="move";
                temp_code_obj->op1=temporary_string;
                temp_code_obj->op2="$"+to_string(ret_val_space+1+fixed_stack);
                asm_data.push_back(temp_code_obj);

                temporary_count++; 
        }
        } SEMICOLON {return_flag=0;} {
                codeObject.push_back({"unlnk"});
                codeObject.push_back({"ret"});
                temp_code_obj = new code_obj_nodes();
                temp_code_obj->type="unlnk";
                asm_data.push_back(temp_code_obj);

                temp_code_obj = new code_obj_nodes();
                temp_code_obj->type="ret";
                asm_data.push_back(temp_code_obj);
                }
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

        temp_code_obj = new code_obj_nodes();
        temp_code_obj->type="jmp";
        temp_code_obj->op1 = "label"+to_string(labels.top()+1);
        asm_data.push_back(temp_code_obj);


        codeObject.push_back({"label label"+to_string(labels.top())});

        temp_code_obj = new code_obj_nodes();
        temp_code_obj->type="label";
        temp_code_obj->op1 = "label"+to_string(labels.top());
        asm_data.push_back(temp_code_obj);

        symbolTable.erase(symbolTable.end());
        programScope--;
        blockNames.erase(blockNames.end());
        block_inside=0;
        present_block_name="";
} else_part ENDIF {
        codeObject.push_back({"label label"+to_string(labels.top()+1)});

        temp_code_obj = new code_obj_nodes();
        temp_code_obj->type="label";
        temp_code_obj->op1 = "label"+to_string(labels.top()+1);
        asm_data.push_back(temp_code_obj);

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
                codeObject.push_back({"move",$3->variable_name,"_r"+to_string($3->temp)});

                temp_code_obj = new code_obj_nodes();
                temp_code_obj->type="move";
                temp_code_obj->op1 = $3->variable_name;
                temp_code_obj->op2 = "_r"+to_string($3->temp);
                asm_data.push_back(temp_code_obj);

                if ((($1->variable_type=="integer" || $1->variable_type=="int_l")&& ($3->variable_type=="integer" ||$3->variable_type=="int_l")))
                {
                        codeObject.push_back({"cmpi "+$1->variable_name+" "+"_r"+to_string($3->temp)});
                        temp_code_obj = new code_obj_nodes();
                        temp_code_obj->type="cmpi";
                        temp_code_obj->op1 = $1->variable_name;
                        temp_code_obj->op2 = "_r"+to_string($3->temp);
                        asm_data.push_back(temp_code_obj);
                }
                else if ((($1->variable_type=="float" || $1->variable_type=="float_l")&& ($3->variable_type=="float" ||$3->variable_type=="float_l")))
                {
                        
                        codeObject.push_back({"cmpr "+$1->variable_name+" "+"_r"+to_string($3->temp)});
                        temp_code_obj = new code_obj_nodes();
                        temp_code_obj->type="cmpr";
                        temp_code_obj->op1 = $1->variable_name;
                        temp_code_obj->op2 = "_r"+to_string($3->temp);
                        asm_data.push_back(temp_code_obj);
                }    
                else if ((($1->variable_type=="float" || $1->variable_type=="float_l")&& ($3->variable_type=="integer" ||$3->variable_type=="int_l")))   
                {
                        
                        codeObject.push_back({"cmpr "+$1->variable_name+" "+"_r"+to_string($3->temp)});
                        temp_code_obj = new code_obj_nodes();
                        temp_code_obj->type="cmpr";
                        temp_code_obj->op1 = $1->variable_name;
                        temp_code_obj->op2 = "_r"+to_string($3->temp);
                        asm_data.push_back(temp_code_obj);
                }     
                else if ((($1->variable_type=="integer" || $1->variable_type=="int_l")&& ($3->variable_type=="float" ||$3->variable_type=="float_l")))   
                {
                        
                        codeObject.push_back({"cmpr "+$1->variable_name+" "+"_r"+to_string($3->temp)});
                        temp_code_obj = new code_obj_nodes();
                        temp_code_obj->type="cmpr";
                        temp_code_obj->op1 = $1->variable_name;
                        temp_code_obj->op2 = "_r"+to_string($3->temp);
                        asm_data.push_back(temp_code_obj);
                }      
                }
                else
                {
                if ((($1->variable_type=="integer" || $1->variable_type=="int_l")&& ($3->variable_type=="integer" ||$3->variable_type=="int_l")))
                {
                if ($3->temp==-1)
                {
                        codeObject.push_back({"cmpi "+$3->variable_name+" "+$1->variable_name});  

                        temp_code_obj = new code_obj_nodes();
                        temp_code_obj->type="cmpi";
                        temp_code_obj->op1 = $1->variable_name;
                        temp_code_obj->op2 = $3->variable_name;
                        asm_data.push_back(temp_code_obj);  
                }
                else
                {
                        codeObject.push_back({"cmpi "+$1->variable_name+" "+$3->variable_name});
                        temp_code_obj = new code_obj_nodes();

                        temp_code_obj->type="cmpi";
                        temp_code_obj->op1 = $1->variable_name;
                        temp_code_obj->op2 = $3->variable_name;
                        asm_data.push_back(temp_code_obj);  
                }
                }
                else if ((($1->variable_type=="float" || $1->variable_type=="float_l")&& ($3->variable_type=="float" ||$3->variable_type=="float_l")))
                {
                if ($3->temp==-1)
                {
                        codeObject.push_back({"cmpr "+$3->variable_name+" "+$1->variable_name});

                        temp_code_obj = new code_obj_nodes();
                        temp_code_obj->type="cmpr";
                        temp_code_obj->op1 = $1->variable_name;
                        temp_code_obj->op2 = $3->variable_name;
                        asm_data.push_back(temp_code_obj);     
                }  
                else
                {
                        codeObject.push_back({"cmpr "+$1->variable_name+" "+$3->variable_name});  
                        temp_code_obj = new code_obj_nodes();

                        temp_code_obj->type="cmpr";
                        temp_code_obj->op1 = $1->variable_name;
                        temp_code_obj->op2 = $3->variable_name;
                        asm_data.push_back(temp_code_obj);                      
                }   
                }
                else if ((($1->variable_type=="float" || $1->variable_type=="float_l")&& ($3->variable_type=="integer" ||$3->variable_type=="int_l")))
                {
                        
                if ($3->temp==-1)
                {
                        codeObject.push_back({"cmpr "+$3->variable_name+" "+$1->variable_name});

                        temp_code_obj = new code_obj_nodes();
                        temp_code_obj->type="cmpr";
                        temp_code_obj->op1 = $1->variable_name;
                        temp_code_obj->op2 = $3->variable_name;
                        asm_data.push_back(temp_code_obj);     
                }  
                else
                {
                        codeObject.push_back({"cmpr "+$1->variable_name+" "+$3->variable_name});  
                        temp_code_obj = new code_obj_nodes();

                        temp_code_obj->type="cmpr";
                        temp_code_obj->op1 = $1->variable_name;
                        temp_code_obj->op2 = $3->variable_name;
                        asm_data.push_back(temp_code_obj);                      
                }   
                }
                else if ((($1->variable_type=="integer" || $1->variable_type=="int_l")&& ($3->variable_type=="float" ||$3->variable_type=="float_l")))
                {
                if ($3->temp==-1)
                {
                        codeObject.push_back({"cmpr "+$3->variable_name+" "+$1->variable_name});

                        temp_code_obj = new code_obj_nodes();
                        temp_code_obj->type="cmpr";
                        temp_code_obj->op1 = $1->variable_name;
                        temp_code_obj->op2 = $3->variable_name;
                        asm_data.push_back(temp_code_obj);     
                }  
                else
                {
                        codeObject.push_back({"cmpr "+$1->variable_name+" "+$3->variable_name});  
                        temp_code_obj = new code_obj_nodes();

                        temp_code_obj->type="cmpr";
                        temp_code_obj->op1 = $1->variable_name;
                        temp_code_obj->op2 = $3->variable_name;
                        asm_data.push_back(temp_code_obj);                      
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

                temp_code_obj = new code_obj_nodes();
                temp_code_obj->type=jump_comp[$2];
                temp_code_obj->op1 = "label"+to_string(labels.top());
                asm_data.push_back(temp_code_obj); 
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

temp_code_obj = new code_obj_nodes();
temp_code_obj->type="label";
temp_code_obj->op1 = "label"+to_string(labels.top()-1);
asm_data.push_back(temp_code_obj); 

loop_start.push(labels.top()-1);
loop_end.push(labels.top());
} cond CLOSED_par decl aug_stmt_list {
codeObject.push_back({"jmp label"+to_string(labels.top()-1)});

temp_code_obj = new code_obj_nodes();
temp_code_obj->type="jmp";
temp_code_obj->op1 = "label"+to_string(labels.top()-1);
asm_data.push_back(temp_code_obj);

codeObject.push_back({"label label"+to_string(labels.top())});

temp_code_obj = new code_obj_nodes();
temp_code_obj->type="label";
temp_code_obj->op1 = "label"+to_string(labels.top());
asm_data.push_back(temp_code_obj);

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

temp_code_obj = new code_obj_nodes();
temp_code_obj->type="jmp";
temp_code_obj->op1 = "label"+to_string(loop_start.top());
asm_data.push_back(temp_code_obj);

} SEMICOLON | BREAK {
codeObject.push_back({"jmp label"+to_string(loop_end.top())});

temp_code_obj = new code_obj_nodes();
temp_code_obj->type="jmp";
temp_code_obj->op1 = "label"+to_string(loop_end.top());
asm_data.push_back(temp_code_obj);
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

        temp_code_obj = new code_obj_nodes();
        temp_code_obj->type="jmp";
        temp_code_obj->op1 = "label"+to_string(labels.top()+1);
        asm_data.push_back(temp_code_obj);

        codeObject.push_back({"label label"+to_string(labels.top())});

        temp_code_obj = new code_obj_nodes();
        temp_code_obj->type="label";
        temp_code_obj->op1 = "label"+to_string(labels.top());
        asm_data.push_back(temp_code_obj);

        symbolTable.erase(symbolTable.end());
        programScope--;
        blockNames.erase(blockNames.end());
        present_block_name = "";
        block_inside=0;
} aug_else_part ENDIF {
        codeObject.push_back({"label label"+to_string(labels.top()+1)});

        temp_code_obj = new code_obj_nodes();
        temp_code_obj->type="label";
        temp_code_obj->op1 = "label"+to_string(labels.top()+1);
        asm_data.push_back(temp_code_obj);

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