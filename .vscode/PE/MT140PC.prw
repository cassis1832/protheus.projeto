#Include 'Protheus.ch'

/*/{Protheus.doc} MT140PC
Não obrigar o pedido de compra na pre-nota
@type function
@version 1.0
@author Carlos Assis
@since 01/03/2024
https://tdn.totvs.com/pages/releaseview.action?pageId=6085510
/*/

User Function MT140PC()

	Local ExpL1 := PARAMIXB[1]

	//Validações do Usuário

	ExpL1 := .F. // Não será obrigatório informar o numero do Pedido de Compras na Pré-Nota, desconsiderando o conteúdo do parâmetro MV_PCNFE

Return ExpL1

