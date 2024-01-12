User Function matimp()

Local aRegs:={{}}
nOpcao:=paramixbIf 
nOpcao == 1
/* Estrutura que deve ter o array aRegs Estrutura do array para importacao dos dados
COLUNA 01- Codigo do produto
COLUNA 02- Almoxarifado
COLUNA 03- Lote
COLUNA 04- Data de validade do Lote
COLUNA 05- Localizacao
COLUNA 06- Numero de Serie
COLUNA 07- Quantidade
COLUNA 08- Quantidade na segunda UM
COLUNA 09- Valor do movimento Moeda 1
COLUNA 10- Valor do movimento Moeda 2
COLUNA 11- Valor do movimento Moeda 3
COLUNA 12- Valor do movimento Moeda 4
COLUNA 13- Valor do movimento Moeda 5 
*/
// Adiciona registro em array para LogFor nz:=1 to 5000
// Adiciona registro em array para Log
If Len(aRegs[Len(aRegs)]) > 4095
    AADD(aRegs,{})
EndIf
 
AADD(aRegs[Len(aRegs)],{PRODUTO,LOCAL,LOTE,VALIDADE,LOCALIZACAO,NUMERO DE ? SERIE,QTD,QTD 2A UM,VALOR INICIAL MOEDA 1,VALOR INICIAL MOEDA 2,VALOR ? INICIAL MOEDA 3,VALOR INICIAL MOEDA 4,VALOR INICIAL MOEDA 5})
Next nz
EndIf

RETURN(aRegs)
