#ifndef PILATABLASIMBOLOS_HPP_
#define PILATABLASIMBOLOS_HPP_

#include <stack>
#include "TablaSimbolos.hpp"

/* Estructura que representa la pila de tablas de símbolos. Se posiciona entre el analizador/traductor
 * y la tabla de símbolos. Así, cuando se le pide la información de un símbolo, lo busca en la tabla
 * del tope de la pila. Si no lo encuentra, sigue buscando en la tabla enlazada a esta (ambitoSuperior)
 * hasta analizar la pila completa.
 */
class PilaTablaSimbolos {

private :

	/*************************************/
	/* DEFINICION DE TIPOS A UTILIZAR */
	/*************************************/

	/* Elemento de la pila. Este elemento tiene dos componenetes, la tabla de símbolos y la referencia
     * al elemento de ámbito superior (tabla de símbolos + otra referencia).
	 */
	typedef struct par {
		TablaSimbolos st;
		par* ambitoSuperior;
	} Elemento;


	/**************************/
	/* REPRESENTACION INTERNA */
	/**************************/

	/* Pila formada por pares <tabla de símbolos,referencia>. */
	std::stack<Elemento> pila;

public:

	/********************/
	/* METODOS PUBLICOS */
	/********************/

	/* Constructora */
	PilaTablaSimbolos();

	/* Devuelve la tabla de símbolos del tope. */
	TablaSimbolos& tope();

	/* Introduce una nueva tabla de símbolos en la pila, sieno su referencia de ámbito superior
     * el elemento en el tope en ese momento. */
	void empilar(const TablaSimbolos& st);

	/* Borra de la pila el elemento del tope. */
	void desempilar();

	/* Dada una variable, intenta encontrar su tipo empezando desde la tabla de símbolos en el
	 * tope de la pila y lo devuelve, si lo encuentra. */
	std::string obtenerTipo(std::string id);

	/* Este método tiene dos funciones:
	 * => Añade el identificador como un nuevo parámetro al procedimiento que se está declarando en la 
	 * tabla de símbolos en vigor al declarar el procedimiento (en ambitoSuperior).
	 * => Añade el identificador como variable local en la tabla de símbolos actual (la correspondiente
	 * al procedimiento que se está declarando).
	 */
	void anadirParametro(std::string proc, std::string idVar, std::string clasePar, std::string tipoVar);

	/* Devuelve clasePar y tipoVar del parámetro número numParametro del procedimiento id. */
	std::pair<std::string, std::string> obtenerTiposParametro(std::string id, int numParametro);

	/* Verifica que el número de argumentos del procedimiento proc es numArgs. Si no coincide
	 * eleva una excepción. */
	void verificarNumArgs(std::string proc, int numArgs);

};

#endif /* PILATABLASIMBOLOS_HPP_ */
