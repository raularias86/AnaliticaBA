with cliente AS 
(
    select 
    fco.fecha_proceso,
    fco.no_unico,
    fco.nombre_completo,
    fco.genero,
    fco.nsegmento,
    fco.nsubsegmento,
    fco.codigo_ejecutivo, 
    fco.nombre_ejecutivo,
    fco.rango_edad,
    fco.flag_vicepresidencia,
    fco.status_cliente
    from resultados_bana_vghi.fco_cliente fco
    where fco.fecha_proceso = '2021-06-30 00:00:00.0'
    and fco.flag_vicepresidencia = 'VP PERSONAS' 
    --and fco.status_cliente = 'ACTIVO'
    --and fco.nsegmento in ('BANCA PREFERENCIAL','PYME')
),  visitas_agencia as (
select  qf.anio_gestion,
        qf.mes_gestion,
        qf.dia_gestion,
        qf.anio_gestion*100+qf.mes_gestion anio_mes_gestion,
        qf.anio_gestion*10000+qf.mes_gestion*100+qf.dia_gestion fch_gestion,
        CAST(qf.cod_agencia AS INT) COD_AGENCIA,
        qf.agencia,
        qf.zona,
        qf.servicetypename PLATAFORMA,
        qf.servicename Servicio, 
--        qf.nounico,
        cl.no_unico,
        cl.nombre_completo,        
        qf.username dpd_empleado,
        nvl(pl.nombre,'S/I') nombre_ejecutivo_atendiendo,
        qf.abandono,
--        clus.CLUSTER_N,
        cl.nsegmento,
        cl.NSUBSEGMENTO,
        cl.codigo_ejecutivo, 
        cl.nombre_ejecutivo
--        case when qf.servicename='CAJA EXTERNA' then 1 else 0 end caja_externa,        
from resultados_bana_vghi.qf_casos_tiempos qf
 JOIN cliente cl on qf.nounico = cl.no_unico
 left join proceso_bana_vbpymp.pgc_planilla_hist pl on qf.username = cast(pl.cod_empleado as bigint)
where CAST(qf.cod_agencia AS INT) = 41 and qf.anio_gestion >= 2021
and qf.anio_gestion = 2021
--and qf.mes_gestion = 7
--and qf.dia_gestion = day(now())
and qf.servicetypename != 'CAJA'
--limit 100
), info_mora as (
select  year(a.fch_proceso)*10000+month(a.fch_proceso)*100+day(a.fch_proceso) as sk_fecha, 
        a.no_unico, 
        a.dias_mora_max
from s_bana_productos.basig_dashba_dash_portafolio_his a 
where year = 2021 
and a.segment1 = '1. PORTAFOLIO PRESTAMOS'
and a.status != 'S'
), flag_mora as (
select  a.sk_fecha, 
            a.no_unico, 
            max(a.dias_mora_max) dias_mora_max,
            case when max(a.dias_mora_max) = 0 then 'SIN MORA' 
                when max(a.dias_mora_max) < 31 then 'MORA 30'
                when max(a.dias_mora_max) >= 31 then 'MORA +30' 
                else 'mora x ' End as flag_dias_mora
    from info_mora a 
    where sk_fecha = (select max(sk_fecha) from info_mora)
    group by 1,2
), info_contacto as (
select  a.cuscun no_unico, 
        a.cusphn telefono1,
        a.cusph1 telefono2,
        a.cusfax telefono3, 
        a.cusiad email1,
        b.email1 email2
from  s_bana_clientes.basig_stageba_cumst a 
left join proceso_bana_vbpymp.ra_clientes_email b on a.cuscun = b.numero_unico
where year = 2021  --is not null
--and cuscun = 3202252
and fchsys = (select max(fchsys) from s_bana_clientes.basig_stageba_cumst)
)
select  distinct 
        fch_gestion,
        agencia,
        cod_agencia,
        zona, 
        PLATAFORMA,
        Servicio,
        dpd_empleado,
        nombre_ejecutivo_atendiendo,
        a.no_unico,
        nombre_completo,
        nsegmento,
        nsubsegmento,
        codigo_ejecutivo,
        nombre_ejecutivo, 
        b.sk_fecha,
        nvl(b.flag_dias_mora, "SIN MORA") flag_dias_mora,
        nvl(b.dias_mora_max, 0) dias_mora_max,
        c.email1,
        c.email2,
        c.telefono1,
        c.telefono2,
        c.telefono3       
from visitas_agencia a
left join flag_mora b on a.no_unico = b.no_unico 
left join info_contacto c on a.no_unico = c.no_unico 
where fch_gestion = (select max(fch_gestion) from visitas_agencia)
and abandono = 0 
and flag_dias_mora != 'MORA +30' 
--limit 100
;