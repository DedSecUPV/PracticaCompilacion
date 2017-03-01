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
%token <str> TVAR
%token <str> TSUM TRES TMUL TDIV
%token <str> TENTERO TREAL
%token <str> TDOSP TSEMIC TASSIG TMENOR TMAYOR TCOMA
%token <str> RPROGRAM TPROC TKOPEN TKCLOSE
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

programa : RPROGRAM  TIDENTIFIER
				declaraciones
				decl_de_subprogs
				TKOPEN
				lista_de_sentencias
				TKCLOSE
				{ cout << "\n<programa>\n" << *$1 + tab + *$2 + tab + *$3 + tab + *$4 + tab + *$5 + tab + *$6 + "\n<\\programa>\n" << endl ;}
				;

declaraciones: /* empty */ 
						| TVAR lista_de_ident TDOSP tipo TSEMIC declaraciones
						;

lista_de_ident: TIDENTIFIER resto_lista_id
						;

resto_lista_id: /* empty */
						| TCOMA TIDENTIFIER resto_lista_id
						;

tipo: TENTERO
		| TREAL
		;

decl_de_subprogs: /* empty */
							| decl_de_subprograma decl_de_subprogs
							;

decl_de_subprograma: TPROC TIDENTIFIER
									argumentos
									declaraciones
									TKOPEN
									lista_de_sentencias
									TKCLOSE
									;

argumentos: /* empty */
						| TPOPEN lista_de_param TPCLOSE
						;

lista_de_param: lista_de_ident TDOSP clase_par tipo resto_lis_de_param
							;

clase_par: TIN | TOUT | TINOUT
					;

resto_lis_de_param: /* empty */
									| TSEMIC lista_de_ident TDOSP clase_par tipo resto_lis_de_param
									;

lista_de_sentencias: /* empty */
									| sentencia lista_de_sentencias
									;

sentencia: variable TASSIG expresion TSEMIC
				| TSI expresion TENTONCES TKOPEN lista_de_sentencias TKCLOSE
				| TREPETIR TKOPEN lista_de_sentencias TKCLOSE THASTA expresion TSEMIC
				| TREPSIEMP TKOPEN lista_de_sentencias TKCLOSE
				| TSALSI expresion TSEMIC
				| TLEER TPOPEN variable TPCLOSE TSEMIC
				| TESCRIBIR TPOPEN expresion TPCLOSE TSEMIC
				;

variable: TIDENTIFIER
				;

expresion: expresion TASSIG TASSIG expresion
				| expresion TMENOR expresion
				| expresion TMAYOR expresion
				| expresion TMENOR TASSIG expresion
				| expresion TMAYOR TASSIG expresion
				| expresion TDIV TASSIG expresion
				| expresion TSUM expresion
				| expresion TRES expresion
				| expresion TMUL expresion
				| expresion TDIV expresion
				| TIDENTIFIER
				| TINTEGER
				| TDOUBLE
				| TPOPEN expresion TPCLOSE
				;