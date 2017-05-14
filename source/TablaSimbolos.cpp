#include "TablaSimbolos.hpp"

using namespace std;


/*****************/
/* Constructora */
/*****************/

TablaSimbolos::TablaSimbolos() {}


/******************/
/* anadirVariable */
/******************/

void TablaSimbolos::anadirVariable(string id, string tipo) {
	InfoSimbolo infoSimbolo;
	infoSimbolo.tipoId = string("variable");
	infoSimbolo.tipoVar = tipo;
	if (!tabla.insert(pair<string, InfoSimbolo> (id, infoSimbolo)).second) {
		throw string("Error semántico. Has intentado declarar más de una vez el símbolo " + id);
	}
}


/***********************/
/* anadirProcedimiento */
/***********************/

void TablaSimbolos::anadirProcedimiento(std::string id) {
	InfoSimbolo infoSimbolo;
	infoSimbolo.tipoId = string("procedimiento");
	if (!tabla.insert(pair<string, InfoSimbolo> (id, infoSimbolo)).second) {
		throw string("Error semántico. Has intentado declarar más de una vez el símbolo " + id);
	}
}


/*******************/
/* anadirParametro */
/*******************/

void TablaSimbolos::anadirParametro(string id, string clasePar, string tipoVar) {
	if (tabla.count(id) == 0) {
		throw string("Error semántico. Has intentado utilizar el procedimiento " + id + " antes de declararlo.");
	}
	if (tabla.find(id)->second.tipoId != "procedimiento") {
		throw string("Error semántico. El símbolo " + id + " está declarado pero no es un procedimiento.");
	}
	pair<string, string> tipos(clasePar, tipoVar);
	tabla.find(id)->second.parametrosProc.push_back(tipos);
}


/***************/
/* obtenerTipo */
/***************/

string TablaSimbolos::obtenerTipo(string id) {
	if (tabla.count(id) == 0) {
		throw string("Error semántico. Has intentado utilizar la variable " + id + " antes de declararla.");
	}
	if (tabla.find(id)->second.tipoId != "variable") {
		throw string("Error semántico. El símbolo " + id + " está declarado pero no es una variable.");
	}
	return tabla.find(id)->second.tipoVar;
}


/*************************/
/* obtenerTiposParametro */
/*************************/

pair<string, string> TablaSimbolos::obtenerTiposParametro(string id, int numParametro) {
	if (tabla.count(id) == 0) {
		throw string("Error semántico. Has intentado utilizar el procedimiento " + id + " antes de declararlo.");
	}
	if (tabla.find(id)->second.tipoId != "procedimiento") {
		throw string("Error semántico. El símbolo " + id + " está declarado pero no es un procedimiento.");
	}
	ClasesParametros clasesParametros = tabla.find(id)->second.parametrosProc;
	if (clasesParametros.size() <= unsigned(numParametro)) {
		throw string("Error semántico. Número incorrecto de parámetros en la llamada al procedimiento " + id);
	}
	return clasesParametros[numParametro];
}


/************************/
/* numArgsProcedimiento */
/************************/

int TablaSimbolos::numArgsProcedimiento(std::string proc) {
	return tabla.find(proc)->second.parametrosProc.size();
}


/************/
/* existeId */
/************/

bool TablaSimbolos::existeId(string id) {
	return tabla.count(id) > 0;
}


/************/
/* borrarId */
/************/

void TablaSimbolos::borrarId(string id) {
	tabla.erase(id);
}
