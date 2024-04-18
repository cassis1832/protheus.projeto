#INCLUDE "Protheus.ch"

User Function sql01()

    Local cQuery := ""    
    Local cALiasTop := ""

    cQuery := "Select * "                                   + CRLF
    cQuery += " From " + RetSqlName("SA1") + " SA1"         + CRLF
    cQuery += " Where"                                      + CRLF
    cQuery += " SA1.D_E_L_E_T_ = ' ' "                      + CRLF
    cQuery += " And SA1.filial ='" + xFilial("SA1") + "' "  + CRLF
    cAliasTop := MPSysOpenQuery(cQuery)

    while (cALiasTop)-> (!EOF())
        // Tratamento
        (cAliasTop)->(DBSKIP())
    end

    // Vai para o primeiro registro, só usar em query para não desposicionar o registro e afetar outros programas
    (cAliasTop)->(DBGOTOP())

    // Fecha a area da query - não usar para tabelas padrão
    (cAliasTop)->(DBCLOSEAREA()) 
Return 



