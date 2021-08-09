select  a.*, 
        b.email1, 
        b.email2, 
        b.movil1,
        b.movil2,
        b.movil3
from INPGC.VIEW_CLIENTE_AGENCIA@bapgec a
left join bdclientes.tabla_contacto b on a.cod_cliente = b.cifcodcliente 
where a.cod_domicilio = 41 
and a.fch_estatus_pagar = (select max(fch_estatus_pagar) from INPGC.VIEW_CLIENTE_AGENCIA@bapgec)
;