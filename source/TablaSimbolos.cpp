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

/******************/
/* anadirArray */
/******************/

void TablaSimbolos::anadirArray(string id, string tipo, vector<int> dimensiones) {
	InfoSimbolo infoSimbolo;
	infoSimbolo.tipoId = string("variable");
	infoSimbolo.tipoVar = "array";
	infoSimbolo.tipoElemtsArray = tipo;
	infoSimbolo.dimensiones = dimensiones;
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

void TablaSimbolos::anadirParametro(string id, string clasePar, string tipoVar)
{	//Esto sirve para llamar cuando no es un array.
	this->anadirParametro(id, clasePar, tipoVar, "", new std::vector<int>);}

void TablaSimbolos::anadirParametro(string id, string clasePar, string tipoVar, string tipoElemtsArray, vector<int> *dimensiones) {
	if (tabla.count(id) == 0) {
		throw string("Error semántico. Has intentado utilizar el procedimiento " + id + " antes de declararlo.");
	}
	if (tabla.find(id)->second.tipoId != "procedimiento") {
		throw string("Error semántico. El símbolo " + id + " está declarado pero no es un procedimiento.");
	}
	TablaSimbolos::ClasesParametros *tipos = new TablaSimbolos::ClasesParametros;
	tipos->clasePar = clasePar;
	tipos->tipoVar = tipoVar;
	tipos->tipoElemtsArray = tipoElemtsArray;
	tipos->dimensiones = *dimensiones;
	tabla.find(id)->second.parametrosProc.push_back(*tipos);
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

string TablaSimbolos::obtenerTipoElemts(string id) {
	if (tabla.count(id) == 0) {
		throw string("Error semántico. Has intentado utilizar la variable " + id + " antes de declararla.");
	}
	if (tabla.find(id)->second.tipoId != "variable") {
		throw string("Error semántico. El símbolo " + id + " está declarado pero no es una variable.");
	}
	return tabla.find(id)->second.tipoElemtsArray;
}

vector<int> TablaSimbolos::obtenerDimensiones(string id) {
	if (tabla.count(id) == 0) {
		throw string("Error semántico. Has intentado utilizar la variable " + id + " antes de declararla.");
	}
	if (tabla.find(id)->second.tipoId != "variable") {
		throw string("Error semántico. El símbolo " + id + " está declarado pero no es una variable.");
	}
	return tabla.find(id)->second.dimensiones;
}


/*************************/
/* obtenerTiposParametro */
/*************************/

TablaSimbolos::ClasesParametros TablaSimbolos::obtenerTiposParametro(string id, int numParametro) {
	if (tabla.count(id) == 0) {
		throw string("Error semántico. Has intentado utilizar el procedimiento " + id + " antes de declararlo.");
	}
	if (tabla.find(id)->second.tipoId != "procedimiento") {
		throw string("Error semántico. El símbolo " + id + " está declarado pero no es un procedimiento.");
	}
	vector<ClasesParametros> clasesParametros = tabla.find(id)->second.parametrosProc;
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
