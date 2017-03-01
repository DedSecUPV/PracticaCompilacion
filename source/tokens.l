%option yylineno 

%{
 #include <string>
 #include <iostream>
 #include <vector>
 using namespace std ;
 #include "parser.hpp" 

 #define TOKEN(t) yylval.str = new std::string(yytext, yyleng) ; return t 

 extern "C" int yywrap() { return(1) ; }  

%}

%option nounput

%%
programa																										TOKEN(RPROGRAM) ;

"*"																														TOKEN(TMUL);

"="																														TOKEN(TASSIG);

";"																														TOKEN(TSEMIC);

"{"																														TOKEN(TKOPEN);
"}"																														TOKEN(TKCLOSE);

"("																														TOKEN(TPOPEN);
")"																														TOKEN(TPCLOSE);

in																														TOKEN(TIN);
out																														TOKEN(TOUT);
in out																												TOKEN(TINOUT);

si																														TOKEN(TSI);
entonces																											TOKEN(TENTONCES);
repetir siempre																							TOKEN(TREPSIEMP);
repetir																												TOKEN(TREPETIR);
hasta																													TOKEN(THASTA);
salir si																												TOKEN(TSALSI);

leer																													TOKEN(TLEER);
escribir_linea																								TOKEN(TESCRIBIR);

\/\/.+\n																											;
\(\*+([^*]|\*[^)])*\*+\)																			;

[ \t\n]																												;

[a-zA-Z](\_?[a-zA-Z0-9])*																		TOKEN(TIDENTIFIER); 
[0-9]+\.[0-9]+([eE][\+\-]?[0-9]+)?															TOKEN(TDOUBLE);
[0-9]+ 																												TOKEN(TINTEGER);

.																															{ cout << "Token desconocido: " << yytext << endl; yyterminate();}
%%
