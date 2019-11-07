select 1, sd.proizvod pro, p.naziv naziv_pro, d.org_deo MAG, od.naziv naziv_MAG
--     , ZNC.org_deo, ZNC.proizvod
     , ZNC.MAX_D

     ,
     (
	    select sd2.cena
	    from dokument d2, stavka_dok sd2
	    where d2.broj_dok !='0' and d2.vrsta_dok = '3' and d2.godina != 0
	       and d2.tip_dok in ('10','16') and d2.status in ('1','5') and d2.org_deo = d.org_deo
	       and d2.datum_dok=ZNC.MAX_D
	       and d2.broj_dok  = sd2.broj_dok and d2.vrsta_dok = sd2.vrsta_dok and d2.godina    = sd2.godina
	       and sd2.proizvod = sd.proizvod
     ) znc

     ,
     (
	    select round(sd2.cena * (100 - NVL(sd2.rabat,0)) / 100,4)
	    from dokument d2, stavka_dok sd2
	    where d2.broj_dok !='0' and d2.vrsta_dok = '3' and d2.godina != 0
	       and d2.tip_dok in ('10','16') and d2.status in ('1','5') and d2.org_deo = d.org_deo
	       and d2.datum_dok=ZNC.MAX_D
	       and d2.broj_dok  = sd2.broj_dok and d2.vrsta_dok = sd2.vrsta_dok and d2.godina    = sd2.godina
	       and sd2.proizvod = sd.proizvod
     ) znc_sa_rab

     ,
     (
	    select round(sd2.Z_TROSKOVI / sd2.kolicina,4)
	    from dokument d2, stavka_dok sd2
	    where d2.broj_dok !='0' and d2.vrsta_dok = '3' and d2.godina != 0
	       and d2.tip_dok in ('10','16') and d2.status in ('1','5') and d2.org_deo = d.org_deo
	       and d2.datum_dok=ZNC.MAX_D
	       and d2.broj_dok  = sd2.broj_dok and d2.vrsta_dok = sd2.vrsta_dok and d2.godina    = sd2.godina
	       and sd2.proizvod = sd.proizvod
     ) znc_z_tro

     ,
     (
	    select sd2.cena1
	    from dokument d2, stavka_dok sd2
	    where d2.broj_dok !='0' and d2.vrsta_dok = '3' and d2.godina != 0
	       and d2.tip_dok in ('10','16') and d2.status in ('1','5') and d2.org_deo = d.org_deo
	       and d2.datum_dok=ZNC.MAX_D
	       and d2.broj_dok  = sd2.broj_dok and d2.vrsta_dok = sd2.vrsta_dok and d2.godina    = sd2.godina
	       and sd2.proizvod = sd.proizvod
     ) znc_mag
    , CENA_PS
from dokument d, stavka_dok sd, proizvod p, organizacioni_deo od
    , (select org_deo, proizvod, max(MAX_D) MAX_D            
       from
        (
           select d1.org_deo, sd1.proizvod, max(d1.datum_dok) MAX_D
             from dokument   d1, stavka_dok sd1
            where d1.broj_dok !='0' and d1.vrsta_dok = '3' and d1.godina != 0
              and d1.tip_dok in ('10','16') and d1.status in ('1','5')
              and d1.broj_dok  = sd1.broj_dok and d1.vrsta_dok = sd1.vrsta_dok and d1.godina    = sd1.godina
           group by d1.org_deo, sd1.proizvod
         )
       group by org_deo, proizvod            
    ) znc
,
(
	select PROIZVOD, max(sd1.cena) CENA_PS
	from stavka_dok sd1, dokument d1
	where d1.godina = sd1.godina and d1.vrsta_dok = sd1.vrsta_dok and d1.broj_dok = sd1.broj_dok
	  and d1.vrsta_Dok = '21'
	  and d1.status = 1
	  and d1.datum_dok in
	     (
	    	select max(datum_dok)
		    from stavka_dok sd, dokument d
	  	    Where d.godina = sd.godina and d.vrsta_dok = sd.vrsta_dok and d.broj_dok = sd.broj_dok
		      and d.vrsta_Dok = '21'
	          and d.status = 1
	    	  and SD.proizvod = SD1.proizvod
	    )
    GROUP BY PROIZVOD
) PS
Where
  -- veza tabela
      d.godina = sd.godina and d.vrsta_dok = sd.vrsta_dok and d.broj_dok = sd.broj_dok
  and p.sifra = sd.proizvod
  and od.id = d.org_deo
  and d.vrsta_Dok = 3
  and d.tip_dok = 10
  and d.tip_dok   in ('10','16','116')
  and d.status    in ('1','5')

  AND d.ORG_DEO   = ZNC.ORG_DEO
  AND sd.proizvod = ZNC.PROIZVOD
  AND SD.PROIZVOD = PS.PROIZVOD (+)

  and d.org_deo not in (select MAGACIN FROM PARTNER_MAGACIN_FLAG)

Group by sd.proizvod, p.naziv, d.org_deo, od.naziv
       , ZNC.org_deo, ZNC.proizvod, ZNC.MAX_D--, ZNC.MAX_DU
       , CENA_PS
order by sd.proizvod, d.org_deo
