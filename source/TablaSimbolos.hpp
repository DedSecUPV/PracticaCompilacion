#ifndef TABLASIMBOLOS_HPP_
#define TABLASIMBOLOS_HPP_

#include <string>
#include <map>
#include <vector>

/* Estructura de datos que representa la Tabla de Símbolos. Permite guardar y consultar
 * los símbolos (variables, procedimientos,...) que se declaran a lo largo del programa 
 * a compilar, e incluye información adicional (tipos, parámetros,...)
 */
class TablaSimbolos {


public:

	/**********************************/
	/* DEFINICION DE TIPOS A UTILIZAR */
	/**********************************/

	/* tipo para expresar las clases de parámetros. Vector de pares.
	 * Cada par guarda la información <clasePar, tipoVar> */

	typedef struct {
		std::string clasePar;
		std::string tipoVar;
		std::string tipoElemtsArray;
		std::vector<int> dimensiones;
	} ClasesParametros;

private:
	/* Estructura para guardar la información adicional de los símbolos. */
	typedef struct {
		std::string tipoId; 				// variable o procedimiento
		std::string tipoVar; 				// si es variable, su tipo (int o real)
		std::vector<ClasesParametros> parametrosProc; 	// si es procedimiento, las clases de sus parámetros.
		std::string tipoElemtsArray;
		std::vector<int> dimensiones;

											// por ejemplo: <"in", "real"> o <"out", "int">
	} InfoSimbolo;


	/**************************/
	/* REPRESENTACION INTERNA */
	/**************************/

	/* Tabla hash formada por pares <IdSimbolo, InfoAdicional>. */
	std::map<std::string, InfoSimbolo> tabla;

public:

	/********************************************/
	/* METODOS PUBLICOS DE LA TABLA DE SIMBOLOS */
	/********************************************/

	/* Constructora */
	TablaSimbolos();

	/* Añade un símbolo de tipo variable y su tipo (int o real). */
	void anadirVariable(std::string id, std::string tipo);

	/* Añade un símbolo de tipo array y su tipo (int o real). */
	void anadirArray(std::string id, std::string tipo, std::vector<int> dimensiones);

	/* Añade un símbolo (nombre) de tipo procedimiento.
     * La información adicional se añade mediante otros métodos. */
	void anadirProcedimiento(std::string id);

	/* Añade un parámetro y su tipo a un procedimiento ya añadido. */
	void anadirParametro(std::string id, std::string clasePar, std::string tipoVar);
	void anadirParametro(std::string id, std::string clasePar, std::string tipoVar, std::string tipoElemtsArray, std::vector<int> *dimensiones);

	/* Obtiene el tipo de una variable ya añadida. */
	std::string obtenerTipo(std::string id);

	std::string obtenerTipoElemts(std::string id);

	std::vector<int> obtenerDimensiones(std::string id);

	/* Devuelve los tipos de un parámetro correspondiente a un procedimiento ya añadido: <clasePar, tipoVar>. */
	ClasesParametros obtenerTiposParametro(std::string id, int numParametro);

	/* Devuelve el numero de parámetros correspondiente a un procedimiento ya añadido. */
	int numArgsProcedimiento(std::string proc);

	/* Dado un Id nos dice si está definido en la T_S o no. */
	bool existeId(std::string id);

	/* Dado un Id lo borra de la T_S. */
	void borrarId(std::string id);

};

#endif /* TABLASIMBOLOS_HPP_ */
