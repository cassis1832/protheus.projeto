#INCLUDE "Protheus.ch"

User Function sql02(cCodCli, cLojCli)

    // Salvar area quando usar ponto de entrada de outro programa
    Local aArea := GetArea()
    Local aSA1  := SA1->(GetArea())

    // Não usado
    //DBSELECTAREA( "SA1" )   // abre uma area que porventura esteja fechada - normalmente não necessario
    //DBCLOSEAREA( "SA1" )    // fecha - pode fechar uma área que não deve ser fechada pois o sisteam já deixa tudo aberto
    //*
    
    ChkFile("SZ0")          // abre uma tabela particular - não padrão do sistema

    // Tabela SIX - guarda os indices das tabelas
    SA1-> (DBSETORDER( 1 ))
    
    if SA1-> (DBSEEK( xFilial("SA1") + cCodCli + cLojCli ))
        Alert("Achei o registro") 
    ENDIF

    RestArea(aSA1)
    RestArea(aArea)
RETURN
