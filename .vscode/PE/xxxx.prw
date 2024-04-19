#include 'totvs.ch'

//--------------------------------------------------------------------
/*/{Protheus.doc} A410CONS
Ponto de entrada que permite a criação de um menu na tela de de pedido de venda.
@source A410CONS.prw
@author Eduardo Patriani
@since 20/12/2022
@return  Array, Array com os novos botões que serão incluídos
/*/
//--------------------------------------------------------------------
User Function A410CONS()
	Local aButton	:= {}

	aAdd(aButton, {"PENDENTE", {|| u_fGeraEstr(aHeader,aCols,n) }, "[F9] Estr.Prod."})
	SetKey(VK_F9, {|| u_fGeraEstr(aHeader,aCols,n) })

Return aButton

//------------------------------------------------------------------------------
/*/{Protheus.doc} fGeraEstr
    Função que carrega a Estrutura do Produto no Pedido de Venda

	@sample	    fGeraEstr(aHeader,aCols,nX)
    @param		aHeader , Array     , Array do Cabeçalho
	@param		aCols   , Array	    , Array dos Itens
	@param		nX      , Numérico 	, Número da linha posicionada
	@return		.T.		, Lógico

    @author     Eduardo Patriani
    @since      20/12/2022
    @version	1.0
/*/
//------------------------------------------------------------------------------
User Function fGeraEstr(aHeader,aCols,nX)

	Local aArea     := GetArea()
	Local aBOM      := {}
	Local nPProduto := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_PRODUTO"})
	Local nPTES     := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_TES"})
	Local nPQtdVen  := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_QTDVEN"})
	Local nPItem    := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_ITEM"})
	Local nPTotal   := aScan(aHeader,{|x| AllTrim(x[2]) == "C6_VALOR"})
	Local nY        := 0
	Local cItem     := ""

	Private N 	    := nX
	Private nEstru  := 0

	//Localiza todos os componentes do primeiro nível da estrutura.
	A410Explod(aCols[nX][nPProduto],aCols[nX][nPQtdVen],@aBOM)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Adiciona os produtos no aCols                        ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	For nX := 1 To Len(aBOM)
		cItem := aCols[Len(aCols)][nPItem]
		aAdd(aCOLS,Array(Len(aHeader)+1))
		For nY	:= 1 To Len(aHeader)
			If ( AllTrim(aHeader[nY][2]) == "C6_ITEM" )
				aCols[Len(aCols)][nY] := Soma1(cItem)
			Else
				If (aHeader[nY,2] <> "C6_REC_WT") .And. (aHeader[nY,2] <> "C6_ALI_WT")
					aCols[Len(aCols)][nY] := CriaVar(aHeader[nY][2])
				EndIf
			EndIf
		Next nY
		N := Len(aCols)
		aCOLS[N][Len(aHeader)+1] := .F.
		A410Produto(aBom[nX][1],.F.)
		aCols[N][nPProduto] := aBom[nX][1]
		A410MultT("M->C6_PRODUTO",aBom[nX][1])
		If ExistTrigger("C6_PRODUTO")
			RunTrigger(2,N,Nil,,"C6_PRODUTO")
		EndIf
		A410SegUm(.T.)
		A410MultT("M->C6_QTDVEN",aBom[nX][2])
		If ExistTrigger("C6_QTDVEN ")
			RunTrigger(2,N,Nil,,"C6_QTDVEN ")
		EndIf
		If Empty(aCols[N][nPTotal]) .Or. Empty(aCols[N][nPTES])
			aCOLS[N][Len(aHeader)+1] := .T.
		EndIf
	Next nX

	RestArea(aArea)
Return(.T.)

//------------------------------------------------------------------------------
/*/{Protheus.doc} A410Explod
    Função recursiva para localizar todos os componentes do primeiro nível
	da estrutura.

    @sample	    A410Explod(cProduto,nQuant,aNewStruct)
	@param		cProduto   , Caractere 	, Código do Produto Pai
	@param		nQuant     , Numérico  	, Quantidade do Produto Pai
    @param		aNewStruct , Array     	, Array de retorno
	@return		Nil

    @author     Eduardo Patriani
    @since      20/12/2022
    @version	1.0
/*/
//------------------------------------------------------------------------------
Static Function A410Explod(cProduto,nQuant,aNewStruct)

	Local aAreaAnt	 := GetArea()
	Local nX		 := 0
	Local aArrayAux  := {}

	//Variável private declarada na função fGeraEstr()
	nEstru := 0
	//Faz a explosão de uma estrutura a partir do SG1
	aArrayAux := Estrut(cProduto,nQuant,.T.)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//| Processa todos os componentes do 1 nível da estrutura,  |
	//| verificando a existência de produtos fantasmas.         |
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	dbSelectArea("SB1")
	dbSetOrder(1)
	For nX := 1 to Len(aArrayAux)
		If MsSeek(xFilial("SB1")+aArrayAux[nx,3]) 	//Filial+Componente
			SG1->(dbSetOrder(1)) //G1_FILIAL+G1_COD+G1_COMP+G1_TRT
			if SG1->(MsSeek(fwxfilial('SG1')+SB1->B1_COD))
				if SB1->B1_AGREGCU == '1'
					aAdd(aNewStruct,{aArrayAux[nx,3],aArrayAux[nx,4],SB1->B1_DESC})
				endif
				A410Explod(aArrayAux[nx,3],aArrayAux[nx,4],aNewStruct) 	//Componente+Qtde
			else
				if SB1->B1_AGREGCU == '1'
					aAdd(aNewStruct,{aArrayAux[nx,3],aArrayAux[nx,4],SB1->B1_DESC})
				endif
			endif
		endif
	Next nX

	RestArea(aAreaAnt)
Return Nil
