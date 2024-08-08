//--------------------------------------------------------------------
/*/{Protheus.doc} A250FSD4
    LOCALIZAÇÃO : Executado nas funções A250Atu(), A250Estoq(), LotesSD4() e ExplodeSD4().
    EM QUE PONTO : O Ponto de entrada é executado na tela de atualização do MATA250. 

    Utilizado para filtrar as requisições empenhadas na atualização do mesmo.
    https://tdn.totvs.com/pages/releaseview.action?pageId=6087502

    @source A250FSD4.prw
    @author Carlos Assis
    @since 07/08/2024
    @return  
/*/
//--------------------------------------------------------------------
User Function A250FSD4()
	Local lRet        := .T.
	Local nIndice     := PARAMIXB[1]
	Local lAtuSaldo   := PARAMIXB[2]

	If SB1->(dbSeek(xFilial("SB1")+aDados[nx,nz,1]))

		If SD4->D4_COD == 'MP-001' .And. nIndice < 1 //SD4 está posicionada no empenho que está sendo validado.
			lRet := .F.
		EndIf

		Return lRet
