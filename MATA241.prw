#INCLUDE "RWMAKE.CH" 
#INCLUDE "TBICONN.CH"

User Function TMATA241()

    Local _aCab1 := {}
    Local _aItem := {}
    Local _atotitem:={}
    Local cCodigoTM:="503"
    Local cCodProd:="PRODUTO "
    Local cUnid:="PC "

    Private lMsHelpAuto := .t. // se .t. direciona as mensagens de help
    Private lMsErroAuto := .f. //necessario a criacao

    //Private _acod:={"1","MP1"}
    //PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "EST"

    _aCab1 := {{"D3_DOC" ,NextNumero("SD3",2,"D3_DOC",.T.), NIL},;
            {"D3_TM" ,cCodigoTM , NIL},;
            {"D3_CC" ,"        ", NIL},;
            {"D3_EMISSAO" ,ddatabase, NIL}}


    _aItem:={{"D3_COD" ,cCodProd ,NIL},;
    {"D3_UM" ,cUnid ,NIL},; 
    {"D3_QUANT" ,1 ,NIL},;
    {"D3_LOCAL" ,"01" ,NIL},;
    {"D3_LOTECTL" ,"",NIL},;
    {"D3_LOCALIZ" , "ENDEREÇO            ",NIL}}

    aadd(_atotitem,_aitem) 

    MSExecAuto({|x,y,z| MATA241(x,y,z)},_aCab1,_atotitem,3)

    If lMsErroAuto 
        Mostraerro() 
        DisarmTransaction() 
        break
    EndIf

Return 
