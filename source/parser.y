%{
   #include <stdio.h>
   #include <iostream>
   #include <vector>
   #include <string>
   using namespace std; 

   extern int yylex();
   extern int yylineno;
   extern char *yytext;
   string tab = "\t" ;
   void yyerror (const char *msg) {
     printf("line %d: %s at '%s'\n", yylineno, msg, yytext) ;
   }

%}

/* 
   qué atributos tienen los tokens 
*/
%union {
    string *str ; 
}

/* 
   declaración de tokens. Esto debe coincidir con tokens.l 
*/
%token <str> TIDENTIFIER TINTEGER TDOUBLE
%token <str> TMUL
%token <str> TSEMIC TASSIG
%token <str> RPROGRAM TKOPEN TKCLOSE
%token <str> TPOPEN TPCLOSE
%token <str> TIN TOUT TINOUT
%token <str> TSI TENTONCES TREPSIEMP TREPETIR THASTA TSALSI
%token <str> TLEER TESCRIBIR

%type <str> programa
%type <str> declaraciones
%type <str> lista_de_ident
%type <str> resto_lista_id
%type <str> tipo
%type <str> decl_de_subprogs
%type <str> decl_de_subprograma
%type <str> argumentos
%type <str> lista_de_param
%type <str> clase_par
%type <str> resto_lis_de_param
%type <str> lista_de_sentencias
%type <str> sentencia
%type <str> variable
%type <str> expresion

%start programa

%%

programa : RPROGRAM  
           declaraciones
	   decl_de_subprogs
	   TKOPEN
		lista_de_sentencias
		TKCLOSE
           { cout << "\n<programa>\n" << *$1 + tab + *$2 + tab + *$3 + tab + *$4 + tab + *$5 + tab + *$6 + "\n<\\programa>\n" << endl ;}
        ;

listasentencias : sentencia TSEMIC
         { $$ = new string ; *$$ = "\n<listasentencias1>\n" + *$1 + tab + *$2 + "\n<\\listasentencias1>\n" ;}      | listasentencias sentencia TSEMIC
         { $$ = new string ; *$$ = "\n<listasentencias2>\n" + *$1 + tab + *$2 + tab + *$3 + "\n<\\listasentencias2>\n" ;}
        ;

sentencia :  TIDENTIFIER TASSIG expr 
         { $$ = new string ; *$$ = "\n<sentencia>\n" + *$1 + tab + *$2 + tab + *$3 + "\n<\\sentencia>\n" ;}
        ;

expr : TIDENTIFIER	{ $$ = new string; *$$ = *$1; delete $1; }
     | TINTEGER		{ $$ = new string; *$$ = *$1; delete $1; }
     | TDOUBLE		{ $$ = new string; *$$ = *$1; delete $1; }
     ;

