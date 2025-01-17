#Include "Protheus.ch"
#include "rwmake.ch"
#Include "TBIConn.ch"

/*
  Exemplo Totvs
  https://centraldeatendimento.totvs.com/hc/pt-br/articles/360018241371-Cross-Segmentos-TOTVS-Backoffice-Linha-Protheus-ADVPL-Exemplo-Modelo-3
*/

User Function RDMOD3()
  Local _ni
  
	//
	Local lPar01 		:= ""
	Local cPar02 		:= ""
	Local dPar03 		:= CTOD(' / / ')

	Prepare Environment Empresa '01' Filial '01'
    lPar01 := SuperGetMV("MV_PARAM",.F.)
    cPar02 := cFilAnt
    dPar03 := dDataBase
	//

  aRotina := {{ "Pesquisa","AxPesqui", 0 , 1},;
              { "Visual","AxVisual", 0 , 2},;
              { "Inclui","AxInclui", 0 , 3},;
              { "Altera","AxAltera", 0 , 4, 20 },;
              { "Exclui","AxDeleta", 0 , 5, 21 }}


  //+--------------------------------------------------------------+
  //| Opcoes de acesso para a Modelo 3 |
  //+--------------------------------------------------------------+

  cOpcao:="INCLUIR"

  Do Case
    Case cOpcao=="INCLUIR"; nOpcE:=3 ; nOpcG:=3
    Case cOpcao=="ALTERAR"; nOpcE:=3 ; nOpcG:=3
    Case cOpcao=="VISUALIZAR"; nOpcE:=2 ; nOpcG:=2
  EndCase

  DbSelectArea("SC5")
  DbSetOrder(1)
  DbGotop()

  //+--------------------------------------------------------------+
  //| Cria variaveis M->????? da Enchoice |
  //+--------------------------------------------------------------+

  RegToMemory("SC5",(cOpcao=="INCLUIR"))

  //+--------------------------------------------------------------+
  //| Cria aHeader e aCols da GetDados |
  //+--------------------------------------------------------------+

  nUsado:=0
  dbSelectArea("SX3")
  DbSetOrder(1)
  DbSeek("SC6")
  aHeader:={}

  While !Eof().And.(x3_arquivo=="SC6")
    If Alltrim(x3_campo)=="C6_ITEM"
      dbSkip()
      Loop
    ENDIF

    If X3USO(x3_usado).And.cNivel>=x3_nivel
        nUsado:=nUsado+1
        Aadd(aHeader,{ TRIM(x3_titulo), x3_campo, x3_picture,;
        x3_tamanho, x3_decimal,"AllwaysTrue()",;
        x3_usado, x3_tipo, x3_arquivo, x3_context } )
    Endif

    dbSkip()
  ENDDO

  If cOpcao=="INCLUIR"
    aCols:={Array(nUsado+1)}
    aCols[1,nUsado+1]:=.F.

    For _ni:=1 to nUsado
      aCols[1,_ni]:=CriaVar(aHeader[_ni,2])
    Next

  Else
    aCols:={}
    dbSelectArea("SC6")
    dbSetOrder(1)
    dbSeek(xFilial()+M->C5_NUM)

    While!eof().and. SC6->C6_NUM == M->C5_NUM
      AADD(aCols,Array(nUsado+1))
      For _ni:=1 to nUsado
        aCols[Len(aCols),_ni]:=FieldGet(FieldPos(aHeader[_ni,2]))
      Next

      aCols[Len(aCols),nUsado+1]:=.F.

      dbSkip()
    End
  Endif

  If Len(aCols)>0

    //+--------------------------------------------------------------+
    //| Executa a Modelo 3 |
    //+--------------------------------------------------------------+

    cTitulo:="Teste de Modelo3()"
    cAliasEnchoice:="SC5"
    cAliasGetD:="SC6"
    cLinOk:="AllwaysTrue()"
    cTudOk:="AllwaysTrue()"
    cFieldOk:="AllwaysTrue()"

    // aCpoEnchoice:={}
    //{"C5_CLIENTE"}
    _lRet:=Modelo3(cTitulo,cAliasEnchoice,cAliasGetD,,cLinOk,cTudOk,nOpcE,nOpcG,cFieldOk)

    //+--------------------------------------------------------------+
    //| Executar processamento |
    //+--------------------------------------------------------------+

    If _lRet
      Aviso("Modelo3()","Confirmada operacao!",{"Ok"})
    Endif
  Endif

Return
