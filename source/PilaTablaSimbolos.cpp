#include "PilaTablaSimbolos.hpp"

#include <iostream>

using namespace std;


/****************/
/* Constructora */
/****************/

PilaTablaSimbolos::PilaTablaSimbolos() {}


/********/
/* tope */
/********/

TablaSimbolos& PilaTablaSimbolos::tope() {
	return pila.top().st;
}


/************/
/* empilar */
/************/

void PilaTablaSimbolos::empilar(const TablaSimbolos& st) {
	Elemento *ambitoSuperior;
	if (pila.empty()) {
		ambitoSuperior = 0;
	}
	else {
		ambitoSuperior = &(pila.top());
	}
	Elemento elemento;
	elemento.ambitoSuperior = ambitoSuperior;
	elemento.st = st;
	pila.push(elemento);
}


/**************/
/* desempilar */
/**************/

void PilaTablaSimbolos::desempilar() {
	pila.pop();
}


/***************/
/* obtenerTipo */
/***************/

string PilaTablaSimbolos::obtenerTipo(string id) {
	string tipo;

	if (pila.empty()) {
		throw string("Error semántico. Has intentado utilizar la variable " + id + " antes de declararla.");
	}

	Elemento *elemento = &pila.top();

	while (elemento != 0) {
		try {
			tipo = elemento->st.obtenerTipo(id);
			return tipo;
		}
		catch (string error) {
			elemento = elemento->ambitoSuperior;
		}
	}
	throw string("Error semántico. Has intentado utilizar la variable " + id + " antes de declararla.");
}


/*************************/
/* obtenerTiposParametro */
/*************************/

pair<string, string> PilaTablaSimbolos::obtenerTiposParametro(string id, int numParametro) {
	pair<string, string> tipos;

	if (pila.empty()) {
		throw string("Error semántico. Has intentado llamar al procedimiento " + id + " antes de declararlo.");
	}

	Elemento *elemento = &pila.top();

	while (elemento != 0) {
		try {
			tipos = elemento->st.obtenerTiposParametro(id, numParametro);
			return tipos;
		}
		catch (string errore) {
			elemento = elemento->ambitoSuperior;
		}
	}
	throw string("Error semántico. No se ha encontrado procedimiento con esas características."
			     " Puede que el nombre o el número de parámetros sean incorrectos.");
}


/*******************/
/* anadirParametro */
/*******************/

void PilaTablaSimbolos::anadirParametro(string proc, string idVar, string clasePar, string tipoVar) {
	pila.top().ambitoSuperior->st.anadirParametro(proc, clasePar, tipoVar);
	pila.top().st.anadirVariable(idVar, tipoVar);
}


/********************/
/* verificarNumArgs */
/********************/

void PilaTablaSimbolos::verificarNumArgs(string proc, int numArgs) {
	int numArgsAutentico = pila.top().st.numArgsProcedimiento(proc);
	if (numArgsAutentico != numArgs) {
		throw string("Error semántico. Número de argumentos incorrecto en la llamada al procedimiento " + proc);
	}
}
