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
#include <sstream>

#define SSTR( x ) static_cast< std::ostringstream & >( \
        ( std::ostringstream() << std::dec << x ) ).str()

expresionstruct makecomparison(std::string &s1, std::string &s2, std::string &s3) ;
expresionstruct makearithmetic(std::string &s1, std::string &s2, std::string &s3) ;
vector<int> *unir(vector<int> &lis1, vector<int> &lis2) ;
int tamano_total(vector<int> &lis) ;

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
			cout << "Se intenta realizar una operación booleana entre expresiones que no son booleanas." << endl; break;
		case OP_TIPOS_DIST: 
			cout << "Se ha intentado operar un "+type+" con un "+type2+"." << endl; break;
		case NO_EXISTE_ID:
			cout << "La variable "+id+" no existe." << endl; break;
		case PROC_INEXISTENTE:
			cout << "El procedimiento "+id+" no existe." << endl; break;
		case NUM_PARAM_NO_MATCH:
			cout << "El numero de argumentos en la llamada al procedimiento "+id+" no coincide con los requeridos." << endl; break;
		case ARRAY_MISMATCH:
			cout << "Se recibe un array que no tiene el mismo número de elementos o elementos de los mismos tipos requeridos en la llamada." << endl; break;
		case ID_NO_ARRAY:
			cout << "La variable "+id+" no es un array." << endl; break;
		case DIMENSIONES_MISMATCH:
			cout << "Las dimensiones del array "+id+" no coinciden con lo que se intenta acceder." << endl; break;
		case OUT_OF_BOUNDS:
			cout << "Acceso al array "+id+" fuera de rango." << endl; break;
		case DIV_CERO_CONST:
			cout << "Se realiza una división entre 0 con una constante." << endl; break;
		case OP_CON_BOOL:
			cout << "Se intenta realizar una operación aritmética entre expresiones booleanas." << endl; break;
		case REF_NO_VAR:
			cout << "La referencia "+id+" no es una variable." << endl; break;
		case OP_DIR_NO_INT:
			cout << "Se ha recibido una expresión no entera para la dirección a acceder del array." << endl; break;
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
	vector<expresionstruct> *list_e;
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
%token <str> TARRAY TOF TCORCHA TCORCHC

%type <str> programa
%type <str> declaraciones
%type <numlist> dimensiones_array
%type <list_e> array_acceso
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
%type <expr> variable
%type <expr> expresion
%type <list_e> list_expr resto_lista_expr
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
			| TVAR lista_de_ident TDOSP TARRAY dimensiones_array TOF tipo TSEMIC
			{
				for(vector<string>::iterator i = $2->begin(); i != $2->end(); i++)
				{
					if (!pila.tope().existeId(*i)) pila.tope().anadirArray(*i, *$7, *$5);
					else {noErrores = false; imprimeError(ID_VAR_DUPLICADO, *i);}
					codigo.anadirInstruccion("array_"+*$7+" "+*i+","+SSTR(tamano_total(*$5)));
				}
				delete $2; delete $5; delete $7;
			}
			declaraciones
			;

dimensiones_array: TCORCHA TINTEGER TCORCHC {$$ = new vector<int>; $$->push_back(atoi($2->c_str()));}
			| TCORCHA TINTEGER TCORCHC dimensiones_array
			{$$ = new vector<int>; $$->push_back(atoi($2->c_str())); $$ = unir(*$$, *$4);}
			;

array_acceso: TCORCHA expresion TCORCHC {$$ = new vector<expresionstruct>; $$->push_back(*$2);}
			| TCORCHA expresion TCORCHC array_acceso
			{$$ = $4; $$->push_back(*$2);}
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
				} resto_lis_de_param
				| lista_de_ident TDOSP clase_par TARRAY dimensiones_array TOF tipo
				{
					for(vector<string>::iterator i = $1->begin(); i != $1->end(); i++)
					{
						if (!pila.tope().existeId(*i)) pila.anadirParametroArray(procActual, *i, *$3, *$7, $5);
						else {noErrores = false; imprimeError(ID_VAR_DUPLICADO, *i);}
						codigo.anadirInstruccion(*$3+"_array_"+*$7+" "+*i+","+SSTR(tamano_total(*$5)));
					}
					delete $2; delete $5; delete $7;
				}
				resto_lis_de_param
				;

clase_par: TIN {$$ = new string; *$$ = "val";}
        | TOUT {$$ = new string; *$$ = "ref";}
        | TINOUT {$$ = new string; *$$ = "ref";}
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
				| TSEMIC lista_de_ident TDOSP clase_par TARRAY dimensiones_array TOF tipo
				{
					for(vector<string>::iterator i = $2->begin(); i != $2->end(); i++)
					{
						if (!pila.tope().existeId(*i)) pila.anadirParametroArray(procActual, *i, *$4, *$8, $6);
						else {noErrores = false; imprimeError(ID_VAR_DUPLICADO, *i);}
						codigo.anadirInstruccion(*$4+"_array_"+*$8+" "+*i+","+SSTR(tamano_total(*$6)));
					}
					delete $2; delete $5; delete $7;
				}
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
			{codigo.anadirInstruccion($1->str+":="+$3->str);
			if ($3->tipo.compare($1->tipo) != 0)
			{
				noErrores = false;
				imprimeError(TIPO_MISMATCH_VAR, $1->str, "", $3->tipo, $1->tipo);
			}
			$$ = new vector<int>;}

				| TSI expresion TENTONCES M TKOPEN lista_de_sentencias TKCLOSE M 
				{
					if ($2->tipo != "bool")
					{
						noErrores = false;
						imprimeError(TIPO_MISMATCH, "", "", $2->tipo, "bool");
					}
					codigo.completarInstrucciones($2->trues, $4);
				codigo.completarInstrucciones($2->falses, $8);
				delete $2;
				$$ = $6;}

				| TREPETIR M TKOPEN lista_de_sentencias TKCLOSE THASTA expresion TSEMIC M
				{
					if ($7->tipo != "bool")
					{
						noErrores = false;
						imprimeError(TIPO_MISMATCH, "", "", $7->tipo, "bool");
					}
					codigo.completarInstrucciones($7->falses, $2);
				codigo.completarInstrucciones($7->trues, $9);
				codigo.completarInstrucciones(*$4, $9);
				$$ = new vector<int>;
				delete $7;}
				
				| M TREPSIEMP TKOPEN lista_de_sentencias TKCLOSE M
				{codigo.anadirInstruccion("goto "+SSTR($1));
				codigo.completarInstrucciones(*$4, $6+1);
				$$ = new vector<int>;
				delete $4;}

				| TSALSI expresion TSEMIC M
				{
					if ($2->tipo != "bool")
					{
						noErrores = false;
						imprimeError(TIPO_MISMATCH, "", "", $2->tipo, "bool");
					}
					codigo.completarInstrucciones($2->falses, $4);
				$$ = new vector<int>;
				*$$ = $2->trues;
				delete $2;}

				| TLEER TPOPEN variable TPCLOSE TSEMIC 
				{codigo.anadirInstruccion("read "+$3->str);
				$$ = new vector<int>;}

				| TESCRIBIR TPOPEN expresion TPCLOSE TSEMIC 
				{codigo.anadirInstruccion("write "+$3->str);
				codigo.anadirInstruccion("writeln");
				$$ = new vector<int>;}

				| TIDENTIFIER TPOPEN list_expr TPCLOSE TSEMIC
				{
					if (!pila.tope().existeId(*$1))
					{
						noErrores = false;
						imprimeError(PROC_INEXISTENTE, *$1);
					}
					else if ((int) $3->size() == pila.tope().numArgsProcedimiento(*$1))
					{
						int param = 0;
						TablaSimbolos::ClasesParametros parametro;
						for (vector<expresionstruct>::iterator i = $3->end()-1; i != $3->begin()-1; i--)
						{
								parametro = pila.tope().obtenerTiposParametro(*$1, param);
								if (i->tipo.compare(parametro.tipoVar) == 0)
								{
									if (i->tipo == "array" && i->tipoElemtsArray.compare(parametro.tipoElemtsArray) == 0 && i->dimensiones.size() == parametro.dimensiones.size())
									{
										bool dimensiones_iguales = true;
										vector<int>::iterator a1 = i->dimensiones.begin();
										vector<int>::iterator a2 = parametro.dimensiones.begin();
										while (dimensiones_iguales && a1 != i->dimensiones.end())
										{
											if (*a1 != *a2) dimensiones_iguales = false;
											a1++;
											a2++;
										}
										if (dimensiones_iguales)
										{
											codigo.anadirInstruccion("param_"+parametro.clasePar+" "+i->str);
										}
										else
										{
											noErrores = false;
											imprimeError(ARRAY_MISMATCH, "");
										}

									}
									else if (i->tipo != "array")
									{
										if(parametro.clasePar =="ref" && !i->esVAR)
										{
											noErrores = false;
											imprimeError(REF_NO_VAR, i->str);
										}
										codigo.anadirInstruccion("param_"+parametro.clasePar+" "+i->str);
									}
									else
									{
										noErrores = false;
										imprimeError(ARRAY_MISMATCH, "");	
									}
								}
								else
								{
									
									noErrores = false;
									imprimeError(TIPO_MISMATCH, "", "", i->tipo, parametro.tipoVar);
								}
							param++;
						}
						codigo.anadirInstruccion("call "+*$1);
					}
					else
					{
						noErrores = false;
						imprimeError(NUM_PARAM_NO_MATCH, *$1);
					}
					delete $3;
					$$ = new vector<int>;
				}
				;

variable: TIDENTIFIER 
		{ 
			$$ = new expresionstruct; 
			if (!pila.tope().existeId(*$1))
			{
				noErrores = false;
				imprimeError(NO_EXISTE_ID, *$1);
				$$->tipo = "null";
			}
			else
			{
					$$->tipo = pila.tope().obtenerTipo(*$1);
					$$->tipoElemtsArray = pila.tope().obtenerTipoElemts(*$1);
					$$->dimensiones = pila.tope().obtenerDimensiones(*$1);
			}
			$$->str = *$1;
		}
		| TIDENTIFIER array_acceso
		{
			$$ = new expresionstruct;
			if (!pila.tope().existeId(*$1))
			{
				noErrores = false;
				imprimeError(NO_EXISTE_ID, *$1);
				$$->tipo = "null";
			}
			else if (pila.tope().obtenerTipo(*$1) != "array")
			{
				noErrores = false;
				imprimeError(ID_NO_ARRAY, *$1);
				$$->tipo = "null";
			}
			else if ($2->size() != pila.tope().obtenerDimensiones(*$1).size())
			{
				noErrores = false;
				imprimeError(DIMENSIONES_MISMATCH, *$1);
				$$->tipo = "null";
			}
			else
			{
				string dir, ndir;
				vector<int> d = pila.tope().obtenerDimensiones(*$1);
				vector<int>::iterator a1 = d.begin();
				vector<expresionstruct>::iterator a2 = $2->end()-1;
				dir = codigo.nuevaDir();
				codigo.anadirInstruccion(dir+":=0");
				$$->tipo = pila.tope().obtenerTipoElemts(*$1);
				while (a1 != d.end())
				{
					if (a2->tipo != "int")
					{
						noErrores = false;
						imprimeError(OP_DIR_NO_INT, "");
						$$->tipo = "error";
					}
					if (!a2->constante) codigo.anadirInstruccion("if "+SSTR(*a1)+" <= "+a2->str+" goto ERROR_OUT_OF_BOUNDS");
					else
					{
						if((*a1) <= atoi(a2->str.c_str()))
						{
							noErrores = false;
							imprimeError(OUT_OF_BOUNDS, *$1);
						}
					}
					if (a1 != d.begin())
					{
						ndir = codigo.nuevaDir();
						codigo.anadirInstruccion(ndir+":="+dir+"*"+SSTR(*a1));
						dir = ndir;
					}
					ndir = codigo.nuevaDir();
					codigo.anadirInstruccion(ndir+":="+dir+"+"+a2->str);
					dir = ndir;
					a1++;
					a2--;
				}
				$$->str = *$1+"["+dir+"]";
			}
		}
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
		$$->tipo = "bool";
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
			codigo.completarInstrucciones($1->trues, $3);
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
		*$$ = makearithmetic($1->str,*$2,$3->str) ;
		$$->tipo = $1->tipo;
		if ($1->tipo.compare($3->tipo) != 0)
		{
			noErrores = false;
			imprimeError(OP_TIPOS_DIST, "", "", $1->tipo, $3->tipo);
			$$->tipo = "error";
		}
		else if ($1->tipo == "bool" || $3->tipo == "bool")
		{
			noErrores = false;
			imprimeError(OP_CON_BOOL, "");
			$$->tipo = "error";
		}
		delete $1; delete $3; }

		| expresion TRES expresion 
		{ $$ = new expresionstruct;
		*$$ = makearithmetic($1->str,*$2,$3->str) ;
		$$->tipo = $1->tipo;
		if ($1->tipo.compare($3->tipo) != 0)
		{
			noErrores = false;
			imprimeError(OP_TIPOS_DIST, "", "", $1->tipo, $3->tipo);
			$$->tipo = "error";
		}
		else if ($1->tipo == "bool" || $3->tipo == "bool")
		{
			noErrores = false;
			imprimeError(OP_CON_BOOL, "");
			$$->tipo = "error";
		}
		delete $1; delete $3; }

		| expresion TMUL expresion 
		{ $$ = new expresionstruct;
		*$$ = makearithmetic($1->str,*$2,$3->str) ;
		$$->tipo = $1->tipo;
		if ($1->tipo.compare($3->tipo) != 0)
		{
			noErrores = false;
			imprimeError(OP_TIPOS_DIST, "", "", $1->tipo, $3->tipo);
			$$->tipo = "error";
		}
		else if ($1->tipo == "bool" || $3->tipo == "bool")
		{
			noErrores = false;
			imprimeError(OP_CON_BOOL, "");
			$$->tipo = "error";
		}
		delete $1; delete $3; }

		| expresion TDIV expresion 
		{ $$ = new expresionstruct;
		*$$ = makearithmetic($1->str,*$2,$3->str) ;
		$$->tipo = $1->tipo;
		if ($1->tipo.compare($3->tipo) != 0)
		{
			noErrores = false;
			imprimeError(OP_TIPOS_DIST, "", "", $1->tipo, $3->tipo);
		}
		else if ($1->tipo == "bool" || $3->tipo == "bool")
		{
			noErrores = false;
			imprimeError(OP_CON_BOOL, "");
			$$->tipo = "error";
		}
		if (!$3->constante) codigo.anadirInstruccion("if "+$3->str+" == 0 goto ERRORDIVNULL");
		else
		{
			if (atoi($3->str.c_str()) == 0)
			{
				noErrores = false;
				imprimeError(DIV_CERO_CONST, "");
				$$->tipo = "error";
			}
		}
		delete $1; delete $3; }

		| TIDENTIFIER 
		{ 
			$$ = new expresionstruct;
			$$->constante = false;
			$$->esVAR = true;
			if (!pila.tope().existeId(*$1))
			{
				noErrores = false;
				imprimeError(NO_EXISTE_ID, *$1);
				$$->tipo = "null";
			}
			else
			{
					$$->tipo = pila.tope().obtenerTipo(*$1);
					$$->tipoElemtsArray = pila.tope().obtenerTipoElemts(*$1);
					$$->dimensiones = pila.tope().obtenerDimensiones(*$1);
			}
			$$->str = *$1;
		}
		| TIDENTIFIER array_acceso
		{
			$$ = new expresionstruct;
			$$->constante = false;
			$$->esVAR = true;
			if (!pila.tope().existeId(*$1))
			{
				noErrores = false;
				imprimeError(NO_EXISTE_ID, *$1);
				$$->tipo = "null";
			}
			else if (pila.tope().obtenerTipo(*$1) != "array")
			{
				noErrores = false;
				imprimeError(ID_NO_ARRAY, *$1);
				$$->tipo = "null";
			}
			else if ($2->size() != pila.tope().obtenerDimensiones(*$1).size())
			{
				noErrores = false;
				imprimeError(DIMENSIONES_MISMATCH, *$1);
				$$->tipo = "null";
			}
			else
			{
				string dir, ndir;
				vector<int> d = pila.tope().obtenerDimensiones(*$1);
				vector<int>::iterator a1 = d.begin();
				vector<expresionstruct>::iterator a2 = $2->end()-1;
				dir = codigo.nuevaDir();
				codigo.anadirInstruccion(dir+":=0");
				$$->tipo = pila.tope().obtenerTipoElemts(*$1);
				while (a1 != d.end())
				{
					if (a2->tipo != "int")
					{
						noErrores = false;
						imprimeError(OP_DIR_NO_INT, "");
						$$->tipo = "error";
					}
					if (!a2->constante) codigo.anadirInstruccion("if "+SSTR(*a1)+" <= "+a2->str+" goto ERROR_OUT_OF_BOUNDS");
					else
					{
						if((*a1) <= atoi(a2->str.c_str()))
						{
							noErrores = false;
							imprimeError(OUT_OF_BOUNDS, *$1);
						}
					}
					if (a1 != d.begin())
					{
						ndir = codigo.nuevaDir();
						codigo.anadirInstruccion(ndir+":="+dir+"*"+SSTR(*a1));
						dir = ndir;
					}
					ndir = codigo.nuevaDir();
					codigo.anadirInstruccion(ndir+":="+dir+"+"+a2->str);
					dir = ndir;
					a1++;
					a2--;
				}
				$$->str = *$1+"["+dir+"]";
			}
		}
		| TINTEGER { $$ = new expresionstruct; $$->str = *$1; $$->constante = true; $$->esVAR = false; $$->tipo = "int";}
		| TDOUBLE { $$ = new expresionstruct; $$->str = *$1; $$->constante = true; $$->esVAR = false; $$->tipo = "real";}
		| TPOPEN expresion TPCLOSE {$$ = $2;}
		;

	list_expr: expresion resto_lista_expr
		{$$ = $2; $$->push_back(*$1);}
		| {$$ = new vector<expresionstruct>;}
		;

	resto_lista_expr: {$$ = new vector<expresionstruct>;}
		| TCOMA expresion resto_lista_expr
		{$$ = $3; $$->push_back(*$2);}
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
	tmp.constante = false;
	tmp.esVAR = false;
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
int tamano_total(vector<int> &lis){
	int tam_total = 1;
	for (vector<int>::iterator i = lis.begin(); i != lis.end(); i++) {
      tam_total = tam_total*(*i);
    }
	return tam_total;
}