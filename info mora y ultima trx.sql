with detalle_dash as (
        select  a.fch_proceso, 
                year(a.fch_proceso)*100+month(a.fch_proceso) fecha_mes, 
                a.SEGMENTO_BANCA,
                a.no_unico, 
                a.segment1, 
                a.segment2,
                a.no_cuenta, 
                int_months_between(a.fch_proceso,a.fch_apertura) meses_tc,
                status, 
                a.producto,
                a.area_financiera,
                a.cod_area_financiera,
                a.cod_producto, 
                a.saldo, 
                a.monto,
                a.dias_mora_max,
                a.fch_ulttransaccion,
        row_number() over (partition by no_unico, no_cuenta, cod_producto, fch_proceso order by ingestion_year desc, 
        ingestion_month desc, ingestion_day desc) as rownum
        from s_bana_productos.basig_dashba_dash_portafolio_his a 
        where year = 2021 
        and year(a.fch_proceso)*100+month(a.fch_proceso) = 202107
        and a.fch_proceso  = '2021-07-18 00:00:00.0'
        and a.status != 'S'
)--, max_trx as (
    select  a.no_unico, 
            a.area_financiera,
            a.cod_area_financiera,
            max(a.fch_ulttransaccion) fch_ulttrx,
            nvl(max(a.dias_mora_max),0) max_dias_mora
    from detalle_dash a 
    join proceso_bana_vbpymp.unicos_nps_competitivo b on a.no_unico = b.no_unico 
    where rownum = 1 
    group by 1,2,3 
;
