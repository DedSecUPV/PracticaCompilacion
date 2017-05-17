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
#include "ErrorDefines.hpp"

expresionstruct makecomparison(std::string &s1, std::string &s2, std::string &s3) ;
expresionstruct makearithmetic(std::string &s1, std::string &s2, std::string &s3) ;
vector<int> *unir(vector<int> &lis1, vector<int> &lis2) ;

void imprimeError(int errno, string id, string id2 = "null", string type = "null", string type2 = "null")
{
	printf("Error en línea %d: ", yylineno);
	switch (errno)
	{
		case ID_VAR_DUPLICADO: 
			cout << "La variable "+id+" ya ha sido declarada anteriormente." << endl; break;
		case ID_PAR_DUPLICADO: 
			cout << "El parámetro "+id+" ya ha sido declarado anteriormente en el procedimiento "+id2+"." << endl; break;
		case ID_PROC_DUPLICADO: 
			cout << "El procedimiento "+id+" ya ha sido declarado anteriormente." << endl; break;
		case TIPO_MISMATCH:
			cout << "Se esperaba un "+type2+" y se ha recibido un "+type+"." << endl; break;
		case TIPO_MISMATCH_VAR:
			cout << "Se ha intentado asignar un "+type+" a la variable "+id+" de tipo "+type2+"." << endl; break;
		case COMP_CON_BOOL: 
			cout << "Se intenta realizar una comparación aritmética entre expresiones booleanas." << endl; break;
		case COMP_SIN_BOOL: 
			cout << "Se intenta realizar una comparación booleana entre expresiones que no son booleanas." << endl; break;
		case OP_TIPOS_DIST: 
			cout << "Se ha intado operar un "+type+" con un "+type2+"." << endl; break;
		case NO_EXISTE_ID:
			cout << "La variable "+id+" no existe." << endl; break;
	}
}

Codigo codigo;
PilaTablaSimbolos pila;
string procActual;
bool noErrores = true;

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
%token <str> TEQ TGTH TLTH TNEQ TNOT TOR TAND
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

%left TOR
%left TAND
%left TNOT
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
                {codigo.anadirInstruccion("halt"); if (noErrores) {codigo.escribir();} pila.desempilar();}
				;

declaraciones: {} 
			| TVAR lista_de_ident TDOSP tipo TSEMIC 
            {
				for(vector<string>::iterator i = $2->begin(); i != $2->end(); i++)
				{
					if (!pila.tope().existeId(*i)) pila.tope().anadirVariable(*i, *$4);
					else {noErrores = false; imprimeError(ID_VAR_DUPLICADO, *i);}
				}
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

decl_de_subprograma: TPROC TIDENTIFIER 
					{
						procActual = *$2; 
						if (!pila.tope().existeId(*$2))
							pila.tope().anadirProcedimiento(*$2);
						else {noErrores = false; imprimeError(ID_PROC_DUPLICADO, *$2); return 1;}
						TablaSimbolos st; 
						pila.empilar(st); 
						codigo.anadirInstruccion("proc "+*$2);
					}
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
					{
						if (!pila.tope().existeId(*i)) pila.anadirParametro(procActual, *i, *$3, *$4);
						else {noErrores = false; imprimeError(ID_PAR_DUPLICADO, *i, procActual);}
					}
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
				{
					if (!pila.tope().existeId(*i)) pila.anadirParametro(procActual, *i, *$4, *$5);
					else {noErrores = false; imprimeError(ID_PAR_DUPLICADO, *i, procActual);}
				}
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

sentencia: variable TASSIG expresion TSEMIC 
			{codigo.anadirInstruccion(*$1+":="+$3->str);
			if (pila.tope().existeId(*$1))
			{
				if ($3->tipo.compare(pila.tope().obtenerTipo(*$1)) != 0)
				{
					noErrores = false;
					imprimeError(TIPO_MISMATCH_VAR, *$1, "", $3->tipo, pila.tope().obtenerTipo(*$1));
				}
			}
			else
			{
				noErrores = false;
				imprimeError(NO_EXISTE_ID, *$1);
			}
			$$ = new vector<int>;}

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
		{
			if ($2->tipo != "bool")
			{
				noErrores = false;
				imprimeError(TIPO_MISMATCH, "", "", $2->tipo, "bool");
			} 
		$$ = new expresionstruct;
		$$->trues = $2->falses;
		$$->falses = $2->trues;
		delete $2; }

		| expresion TOR M expresion
		{
			$$ = new expresionstruct;
			if ($1->tipo != "bool" || $4->tipo != "bool")
			{
				noErrores = false;
				imprimeError(COMP_SIN_BOOL, "");
			}
			codigo.completarInstrucciones($1->falses, $3);
			$$->trues = *unir($1->trues, $4->trues);
			$$->falses = $4->falses;
			$$->tipo = "bool";
			delete $1; delete $4;
		}

		| expresion TAND M expresion
		{
			$$ = new expresionstruct;
			if ($1->tipo != "bool" || $4->tipo != "bool")
			{
				noErrores = false;
				imprimeError(COMP_SIN_BOOL, "");
			}
			codigo.completarInstrucciones($1->falses, $3);
			$$->trues = $4->trues;
			$$->falses = *unir($1->falses, $4->falses);
			$$->tipo = "bool";
			delete $1; delete $4;
		}

		| expresion TEQ expresion 
		{ $$ = new expresionstruct;
		if ($1->tipo == "bool" || $3->tipo == "bool")
		{
			noErrores = false;
			imprimeError(COMP_CON_BOOL, "");
		}
		*$$ = makecomparison($1->str,*$2,$3->str) ;
		delete $1; delete $3; }

		| expresion TMENOR expresion 
		{ $$ = new expresionstruct;
		if ($1->tipo == "bool" || $3->tipo == "bool")
		{
			noErrores = false;
			imprimeError(COMP_CON_BOOL, "");
		}
		*$$ = makecomparison($1->str,*$2,$3->str) ;
		delete $1; delete $3; }

		| expresion TMAYOR expresion 
		{ $$ = new expresionstruct;
		if ($1->tipo == "bool" || $3->tipo == "bool")
		{
			noErrores = false;
			imprimeError(COMP_CON_BOOL, "");
		}
		*$$ = makecomparison($1->str,*$2,$3->str) ;
		delete $1; delete $3; }

		| expresion TLTH expresion 
		{ $$ = new expresionstruct;
		if ($1->tipo == "bool" || $3->tipo == "bool")
		{
			noErrores = false;
			imprimeError(COMP_CON_BOOL, "");
		}
		*$$ = makecomparison($1->str,*$2,$3->str) ;
		delete $1; delete $3; }

		| expresion TGTH expresion 
		{ $$ = new expresionstruct;
		if ($1->tipo == "bool" || $3->tipo == "bool")
		{
			noErrores = false;
			imprimeError(COMP_CON_BOOL, "");
		}
		*$$ = makecomparison($1->str,*$2,$3->str) ;
		delete $1; delete $3; }

		| expresion TNEQ expresion 
		{ $$ = new expresionstruct;
		if ($1->tipo == "bool" || $3->tipo == "bool")
		{
			noErrores = false;
			imprimeError(COMP_CON_BOOL, "");
		}
		*$$ = makecomparison($1->str,*$2,$3->str) ;
		delete $1; delete $3; }

		| expresion TSUM expresion 
		{ $$ = new expresionstruct;
		if ($1->tipo.compare($3->tipo) != 0)
		{
			noErrores = false;
			imprimeError(OP_TIPOS_DIST, "", "", $1->tipo, $3->tipo);
		}
		*$$ = makearithmetic($1->str,*$2,$3->str) ;
		$$->tipo = $1->tipo;
		delete $1; delete $3; }

		| expresion TRES expresion 
		{ $$ = new expresionstruct;
		if ($1->tipo.compare($3->tipo) != 0)
		{
			noErrores = false;
			imprimeError(OP_TIPOS_DIST, "", "", $1->tipo, $3->tipo);
		}
		*$$ = makearithmetic($1->str,*$2,$3->str) ;
		$$->tipo = $1->tipo;
		delete $1; delete $3; }

		| expresion TMUL expresion 
		{ $$ = new expresionstruct;
		if ($1->tipo.compare($3->tipo) != 0)
		{
			noErrores = false;
			imprimeError(OP_TIPOS_DIST, "", "", $1->tipo, $3->tipo);
		}
		*$$ = makearithmetic($1->str,*$2,$3->str) ;
		$$->tipo = $1->tipo;
		delete $1; delete $3; }

		| expresion TDIV expresion 
		{ $$ = new expresionstruct;
		if ($1->tipo.compare($3->tipo) != 0)
		{
			noErrores = false;
			imprimeError(OP_TIPOS_DIST, "", "", $1->tipo, $3->tipo);
		}
		codigo.anadirInstruccion("if "+$3->str+" = 0 goto ERRORDIVNULL");
		*$$ = makearithmetic($1->str,*$2,$3->str) ;
		$$->tipo = $1->tipo;
		delete $1; delete $3; }

		| TIDENTIFIER 
		{ 
			$$ = new expresionstruct; 
			if (!pila.tope().existeId(*$1))
			{
				noErrores = false;
				imprimeError(NO_EXISTE_ID, *$1);
			}
			$$->str = *$1; $$->tipo = pila.tope().obtenerTipo(*$1);
		}
		| TINTEGER { $$ = new expresionstruct; $$->str = *$1; $$->tipo = "int";}
		| TDOUBLE { $$ = new expresionstruct; $$->str = *$1; $$->tipo = "real";}
		| TPOPEN expresion TPCLOSE {$$ = $2;}
		;

%%

expresionstruct makecomparison(std::string &s1, std::string &s2, std::string &s3) {
	expresionstruct tmp ; 
	tmp.trues.push_back(codigo.obtenRef()) ;
	tmp.falses.push_back(codigo.obtenRef()+1) ;
	tmp.tipo = "bool";
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