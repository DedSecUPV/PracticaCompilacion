%error-verbose

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
#include "PilaTablaSimbolos.hpp"
#include "TablaSimbolos.hpp"

expresionstruct makecomparison(std::string &s1, std::string &s2, std::string &s3) ;
expresionstruct makearithmetic(std::string &s1, std::string &s2, std::string &s3) ;
vector<int> *unir(vector<int> &lis1, vector<int> &lis2) ;

Codigo codigo;
PilaTablaSimbolos pila;
string procActual;

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
%token <str> TEQ TGTH TLTH TNEQ TNOT
%token <str> RPROGRAM TPROC TKOPEN TKCLOSE
%token <str> TPOPEN TPCLOSE
%token <str> TIN TOUT TINOUT
%token <str> TSI TENTONCES TREPSIEMP TREPETIR THASTA TSALSI
%token <str> TLEER TESCRIBIR

%type <str> programa
%type <str> declaraciones
%type <list> lista_de_ident
%type <list> resto_lista_id
%type <str> tipo
%type <str> decl_de_subprogs
%type <str> decl_de_subprograma
%type <str> argumentos
%type <list> lista_de_param
%type <str> clase_par
%type <str> resto_lis_de_param
%type <numlist> lista_de_sentencias
%type <numlist> sentencia
%type <str> variable
%type <expr> expresion
%type <number> M

%nonassoc TMENOR TMAYOR TEQ TGTH TLTH TNEQ
%left TSUM TRES
%left TMUL TDIV

%start programa

%%

programa: RPROGRAM  TIDENTIFIER {TablaSimbolos st; pila.empilar(st); codigo.anadirInstruccion("prog " + *$2);}
				declaraciones
				decl_de_subprogs
				TKOPEN
				lista_de_sentencias
				TKCLOSE
                {codigo.anadirInstruccion("halt"); codigo.escribir(); pila.desempilar();}
				;

declaraciones: {} 
			| TVAR lista_de_ident TDOSP tipo TSEMIC 
            {
				for(vector<string>::iterator i = $2->begin(); i != $2->end(); i++)
				{pila.tope().anadirVariable(*i, *$4);}
				codigo.anadirDeclaraciones(*$2, *$4); delete $2; delete $4;
			} 
			declaraciones 
			;

lista_de_ident: TIDENTIFIER resto_lista_id
			{$$ = $2;
            $$->push_back(*$1);}
			;

resto_lista_id: {} {$$ = new vector<string>;}
			| TCOMA TIDENTIFIER resto_lista_id
			{ $$ = $3; $$->push_back(*$2); }
			;

tipo: TENTERO {$$ = new string; *$$ = "int";}
	| TREAL {$$ = new string; *$$ = "real";}
	;

decl_de_subprogs: {}
				| decl_de_subprograma decl_de_subprogs
				;

decl_de_subprograma: TPROC TIDENTIFIER {procActual = *$2; pila.tope().anadirProcedimiento(*$2); TablaSimbolos st; pila.empilar(st); codigo.anadirInstruccion("proc "+*$2);}
					argumentos
					declaraciones
					TKOPEN
					lista_de_sentencias
					TKCLOSE
					{pila.desempilar(); codigo.anadirInstruccion("endproc");}
					;

argumentos: {}
			| TPOPEN lista_de_param TPCLOSE
			;

lista_de_param: lista_de_ident TDOSP clase_par tipo 
				{
					for(vector<string>::iterator i = $1->begin(); i != $1->end(); i++)
					{pila.anadirParametro(procActual, *i, *$3, *$4);}
					codigo.anadirParametros(*$1, *$3, *$4);
					delete $1; delete $3; delete $4;
				} 
				resto_lis_de_param
				;

clase_par: TIN {$$ = new string; *$$ = "in";}
        | TOUT {$$ = new string; *$$ = "out";}
        | TINOUT {$$ = new string; *$$ = "in out";}
		;

resto_lis_de_param: {} 
				| TSEMIC lista_de_ident TDOSP clase_par tipo 
				{for(vector<string>::iterator i = $2->begin(); i != $2->end(); i++)
					{pila.anadirParametro(procActual, *i, *$4, *$5);}
				codigo.anadirParametros(*$2, *$4, *$5);}
                resto_lis_de_param
				;

lista_de_sentencias: {} {$$ = new vector<int>;}
				| sentencia lista_de_sentencias
				{$$ = unir(*$1, *$2);
				delete $1;
				delete $2;}
				;

M: {$$ = codigo.obtenRef();};

sentencia: variable TASSIG expresion TSEMIC {codigo.anadirInstruccion(*$1+":="+$3->str); $$ = new vector<int>;}

				| TSI expresion TENTONCES M TKOPEN lista_de_sentencias TKCLOSE M 
				{codigo.completarInstrucciones($2->trues, $4);
				codigo.completarInstrucciones($2->falses, $8);
				delete $2;
				$$ = $6;}

				| TREPETIR M TKOPEN lista_de_sentencias TKCLOSE THASTA expresion TSEMIC M
				{codigo.completarInstrucciones($7->trues, $2);
				codigo.completarInstrucciones($7->falses, $9);
				codigo.completarInstrucciones(*$4, $9);
				$$ = new vector<int>;
				delete $7;}
				
				| M TREPSIEMP TKOPEN lista_de_sentencias TKCLOSE M
				{codigo.anadirInstruccion("goto "+$1);
				codigo.completarInstrucciones(*$4, $6+1);
				$$ = new vector<int>;}

				| TSALSI expresion TSEMIC M
				{codigo.completarInstrucciones($2->falses, $4);
				$$ = new vector<int>;
				*$$ = $2->trues;
				delete $2;}

				| TLEER TPOPEN variable TPCLOSE TSEMIC 
				{codigo.anadirInstruccion("read "+*$3);
				$$ = new vector<int>;}

				| TESCRIBIR TPOPEN expresion TPCLOSE TSEMIC 
				{codigo.anadirInstruccion("write "+$3->str);
				$$ = new vector<int>;}
				;

variable: TIDENTIFIER {$$ = new string; *$$ = *$1;}
				;

expresion: TNOT expresion
		{ $$ = new expresionstruct;
		$$->trues = $2->falses;
		$$->falses = $2->trues;
		delete $2; }
		| expresion TEQ expresion 
		{ $$ = new expresionstruct;
		*$$ = makecomparison($1->str,*$2,$3->str) ;
		delete $1; delete $3; }

		| expresion TMENOR expresion 
		{ $$ = new expresionstruct;
		*$$ = makecomparison($1->str,*$2,$3->str) ;
		delete $1; delete $3; }

		| expresion TMAYOR expresion 
		{ $$ = new expresionstruct;
		*$$ = makecomparison($1->str,*$2,$3->str) ;
		delete $1; delete $3; }

		| expresion TLTH expresion 
		{ $$ = new expresionstruct;
		*$$ = makecomparison($1->str,*$2,$3->str) ;
		delete $1; delete $3; }

		| expresion TGTH expresion 
		{ $$ = new expresionstruct;
		*$$ = makecomparison($1->str,*$2,$3->str) ;
		delete $1; delete $3; }

		| expresion TNEQ expresion 
		{ $$ = new expresionstruct;
		*$$ = makecomparison($1->str,*$2,$3->str) ;
		delete $1; delete $3; }

		| expresion TSUM expresion 
		{ $$ = new expresionstruct;
		*$$ = makearithmetic($1->str,*$2,$3->str) ;
		delete $1; delete $3; }

		| expresion TRES expresion 
		{ $$ = new expresionstruct;
		*$$ = makearithmetic($1->str,*$2,$3->str) ;
		delete $1; delete $3; }

		| expresion TMUL expresion 
		{ $$ = new expresionstruct;
		*$$ = makearithmetic($1->str,*$2,$3->str) ;
		delete $1; delete $3; }

		| expresion TDIV expresion 
		{ $$ = new expresionstruct;
		*$$ = makearithmetic($1->str,*$2,$3->str) ;
		delete $1; delete $3; }

		| TIDENTIFIER { $$ = new expresionstruct; $$->str = *$1; }
		| TINTEGER { $$ = new expresionstruct; $$->str = *$1; }
		| TDOUBLE { $$ = new expresionstruct; $$->str = *$1; }
		| TPOPEN expresion TPCLOSE {$$ = $2;}
		;

%%

expresionstruct makecomparison(std::string &s1, std::string &s2, std::string &s3) {
	expresionstruct tmp ; 
	tmp.trues.push_back(codigo.obtenRef()) ;
	tmp.falses.push_back(codigo.obtenRef()+1) ;
	codigo.anadirGoto("if " + s1 + s2 + s3 + " goto") ;
	codigo.anadirGoto("goto") ;
	return tmp ;
}


expresionstruct makearithmetic(std::string &s1, std::string &s2, std::string &s3) {
	expresionstruct tmp; 
	tmp.str = codigo.nuevoId();
	codigo.anadirInstruccion(tmp.str + ":=" + s1 + s2 + s3) ;
	return tmp;
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