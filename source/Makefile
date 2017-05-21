CFLAGS=-Wall
FUENTES=parser.cpp main.cpp tokens.cpp Codigo.cpp PilaTablaSimbolos.cpp TablaSimbolos.cpp

all: parser

clean:
	rm parser.cpp parser.hpp parser tokens.cpp *~

parser.cpp parser.hpp: parser.y Codigo.hpp Auxiliar.hpp PilaTablaSimbolos.hpp TablaSimbolos.hpp ErrorDefines.hpp
	bison -d -o $@ $<

tokens.cpp: tokens.l parser.hpp Auxiliar.hpp PilaTablaSimbolos.hpp TablaSimbolos.hpp ErrorDefines.hpp
	lex -o $@ $<

parser: $(FUENTES) Codigo.hpp Auxiliar.hpp PilaTablaSimbolos.hpp TablaSimbolos.hpp ErrorDefines.hpp
	g++ $(CFLAGS) -o $@ $(FUENTES) 

prueba:  
	./parser < ./pruebas/PruebasObjetivosGenerales/Correcta_1.in
	./parser < ./pruebas/Booleanos/correcta_1.in
	./parser < ./pruebas/LlamadasAFunciones/prueba_correcta_1.in
	./parser < ./pruebas/Arrays/prueba_correcta.in