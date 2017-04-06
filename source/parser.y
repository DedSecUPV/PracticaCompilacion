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
     printf("Línea %d: %s en '%s'\n", yylineno, msg, yytext);
   }

#include "Codigo.hpp"
#include "Auxiliar.hpp"


expresionstruct makecomparison(std::string &s1, std::string &s2, std::string &s3) ;
expresionstruct makearithmetic(std::string &s1, std::string &s2, std::string &s3) ;
vector<int> *unir(vector<int> &lis1, vector<int> &lis2) ;

Codigo codigo;

%}

/* 
   qué atributos tienen los tokens 
*/
%union {
    string *str ; 
	vector<string> *list ;
	expresionstruct *expr ;
	int number ;
	vector<int> *numlist ;
}

/* 
   declaración de tokens. Esto debe coincidir con tokens.l 
*/
%token <str> TIDENTIFIER TINTEGER TDOUBLE
%token <str> TVAR
%token <str> TSUM TRES TMUL TDIV
%token <str> TENTERO TREAL
%token <str> TDOSP TSEMIC TASSIG TMENOR TMAYOR TCOMA
%token <str> TEQ TGTH TLTH TNEQ
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

%nonassoc TMENOR TMAYOR TEQ TGTH TLTH TNEQ
%left TSUM TRES
%left TMUL TDIV

%start programa

%%

programa : RPROGRAM  TIDENTIFIER
				declaraciones
				decl_de_subprogs
				TKOPEN
				lista_de_sentencias
				TKCLOSE
				{ cout << "\n<programa>\n" << *$1 + " " + *$2 + "\n  <declaraciones>\n" + *$3 + "\n  <\\declaraciones>\n" + "\n  <decl_de_subprogs>\n" +*$4 + "\n  <\\decl_de_subprogs>\n" + *$5 + "\n  <lista_de_sentencias>\n" + *$6 +  "\n  <\\lista_de_sentencias>\n" + *$7 + "\n<\\programa>\n" << endl ;}
				;

declaraciones: {} {$$ = new string; *$$ = "";} 
						| TVAR lista_de_ident TDOSP tipo TSEMIC declaraciones 
						{ $$ = new string; *$$= "\n    <declaración>\n     " + *$1 + " " + *$2 + " " + *$3 + " " + *$4 + " " + *$5 + " " + "\n    <\\declaración>\n" + *$6;}
						;

lista_de_ident: TIDENTIFIER resto_lista_id
					{ $$ = new string; *$$= "<lista_de_ident> " + *$1 + *$2 + " <\\lista_de_ident>";}
						;

resto_lista_id: {} {$$ = new string; *$$ = "";}
						| TCOMA TIDENTIFIER resto_lista_id
						{ $$ = new string; *$$= "" + *$1 + " " + *$2 + *$3;}
						;

tipo: TENTERO
		| TREAL
		;

decl_de_subprogs: {} {$$ = new string; *$$ = "";}
							| decl_de_subprograma decl_de_subprogs
							{ $$ = new string; *$$= "\n    <declaración_de_subprograma>\n" + *$1 + tab + "\n    <\\declaración_de_subprograma>\n" + *$2;}
							;

decl_de_subprograma: TPROC TIDENTIFIER
									argumentos
									declaraciones
									TKOPEN
									lista_de_sentencias
									TKCLOSE
					{ $$ = new string; *$$= "\n     <subprograma>\n" +  *$1 + " " + *$2 + " " + *$3 + " \n      <declaraciones>\n" + *$4 + "\n      <\\declaraciones>\n" + *$5 + "\n      <lista_de_sentencias>\n" + *$6 + "\n      <\\lista_de_sentencias>\n" + *$7 + "\n     <\\subprograma>\n";}
									;

argumentos: {} {$$ = new string; *$$ = "";}
						| TPOPEN lista_de_param TPCLOSE
						{ $$ = new string; *$$= "<argumentos>" + *$1 + *$2 + *$3 + "<\\argumentos>\n";}
						;

lista_de_param: lista_de_ident TDOSP clase_par tipo resto_lis_de_param
					{ $$ = new string; *$$= "" + *$1 + *$2 + " " + *$3 + " " + *$4 + " " + *$5;}
							;

clase_par: TIN | TOUT | TINOUT
					;

resto_lis_de_param: {} {$$ = new string; *$$ = "";}
									| TSEMIC lista_de_ident TDOSP clase_par tipo resto_lis_de_param
									{ $$ = new string; *$$= "" + *$1 + " " + *$2 + " " + *$3 + " " + *$4 + " " + *$5;}
									;

lista_de_sentencias: {} {$$ = new string; *$$ = "";}
									| sentencia lista_de_sentencias
									{ $$ = new string; *$$= "\n     <sentencia>\n      " + *$1 + " " + "\n     <\\sentencia>\n"  + *$2;}
									;

sentencia: variable TASSIG expresion TSEMIC {$$ = new string; *$$ = "     " + *$1 + " " + *$2 + " " + *$3 + " " + *$4;}
				| TSI expresion TENTONCES TKOPEN lista_de_sentencias TKCLOSE {$$ = new string; *$$ = "     " + *$1 + " " + *$2 + " " + *$3 + " " + *$4 + " " + *$5 + " " + *$6;}
				| TREPETIR TKOPEN lista_de_sentencias TKCLOSE THASTA expresion TSEMIC {$$ = new string; *$$ = "     " + *$1 + " " + *$2 + " " + *$3 + " " + *$4 + " " + *$5 + " " + *$6 + " " + *$7;}
				| TREPSIEMP TKOPEN lista_de_sentencias TKCLOSE {$$ = new string; *$$ = "     " + *$1 + " " + *$2 + " " + *$3 + " " + *$4;}
				| TSALSI expresion TSEMIC {$$ = new string; *$$ = "     " + *$1 + " " + *$2 + " " + *$3;}
				| TLEER TPOPEN variable TPCLOSE TSEMIC {$$ = new string; *$$ = "     " + *$1 + " " + *$2 + " " + *$3 + " " + *$4 + " " + *$5;}
				| TESCRIBIR TPOPEN expresion TPCLOSE TSEMIC {$$ = new string; *$$ = "     " + *$1 + " " + *$2 + " " + *$3 + " " + *$4 + " " + *$5;}
				;

variable: TIDENTIFIER
				;

expresion: expresion TEQ expresion {$$ = new string; *$$ = *$1 + " " + *$2 + " " + *$3;}
				| expresion TMENOR expresion {$$ = new string; *$$ = *$1 + " " + *$2 + " " + *$3;}
				| expresion TMAYOR expresion {$$ = new string; *$$ = *$1 + " " + *$2 + " " + *$3;}
				| expresion TLTH expresion {$$ = new string; *$$ = *$1 + " " + *$2 + " " + *$3;}
				| expresion TGTH expresion {$$ = new string; *$$ = *$1 + " " + *$2 + " " + *$3;}
				| expresion TNEQ expresion {$$ = new string; *$$ = *$1 + " " + *$2 + " " + *$3;}
				| expresion TSUM expresion {$$ = new string; *$$ = *$1 + " " + *$2 + " " + *$3;}
				| expresion TRES expresion {$$ = new string; *$$ = *$1 + " " + *$2 + " " + *$3;}
				| expresion TMUL expresion {$$ = new string; *$$ = *$1 + " " + *$2 + " " + *$3;}
				| expresion TDIV expresion {$$ = new string; *$$ = *$1 + " " + *$2 + " " + *$3;}
				| TIDENTIFIER
				| TINTEGER
				| TDOUBLE
				| TPOPEN expresion TPCLOSE {$$ = new string; *$$ = *$1 + " " + *$2 + " " + *$3;}
				;


expresionstruct makecomparison(std::string &s1, std::string &s2, std::string &s3) {
	expresionstruct tmp ; 
	tmp.trues.push_back(codigo.obtenRef()) ;
	tmp.falses.push_back(codigo.obtenRef()+1) ;
	codigo.anadirInstruccion("if " + s1 + s2 + s3 + " goto") ;
	codigo.anadirInstruccion("goto") ;
	return tmp ;
}


expresionstruct makearithmetic(std::string &s1, std::string &s2, std::string &s3) {
	expresionstruct tmp ; 
	tmp.str = codigo.nuevoId() ;
	codigo.anadirInstruccion(tmp.str + ":=" + s1 + s2 + s3 + ";") ;     
	return tmp ;
}

vector<int> *unir(vector<int> &lis1, vector<int> &lis2) {
    vector<int> *nueva;
    nueva = new vector<int>;
    *nueva = lis1;

    for (vector<int>::iterator i = lis2.begin(); i != lis2.end(); i++) {
      nueva->push_back(*i);
    }

    return nueva;
}