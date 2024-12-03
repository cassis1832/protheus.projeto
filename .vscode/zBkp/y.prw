#include "protheus.ch"
USER FUNCTION MyProg()
	Local oWindow
	Local abInit:= {||msgstop("ativando!")}
	Local abValid:= {|| msgstop("encerrando!"),.T.}
	oWindow:= tWindow():New( 10, 10, 200, 200, "Meu programa";
		,,,,,,,,CLR_WHITE,CLR_BLACK,,,,,,,.T. )
	oWindow:Activate("MAXIMIZED",,,,,,abInit,,,,,,,,,abValid,,)
Return nil
