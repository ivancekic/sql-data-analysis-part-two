select sd.proizvod pro, p.naziv naziv_pro, d.org_deo MAG, od.naziv naziv_MAG
,
(
    select sd2.cena
    from dokument d2, stavka_dok sd2
    where
           d2.vrsta_dok = '3' and d2.tip_dok in ('10','16') and d2.status in ('1','5') and d2.org_deo = d.org_deo
       and (d2.datum_dok,d2.datum_unosa) in
         (
           select max(d1.datum_dok), max(d1.datum_unosa)
             from dokument   d1, stavka_dok sd1

            where d1.vrsta_dok = '3' and d1.tip_dok in ('10','16') and d1.status in ('1','5') and d1.org_deo = d.org_deo
              and d1.broj_dok  = sd1.broj_dok and d1.vrsta_dok = sd1.vrsta_dok and d1.godina    = sd1.godina
              and sd1.vrsta_dok = '3' and sd1.proizvod = sd.proizvod
          )
       and (d2.broj_dok,d2.vrsta_dok,d2.godina)
            not in (select vd2.broj_dok,vd2.vrsta_dok,vd2.godina from vezni_dok vd2 where vd2.za_vrsta_dok = '3')
       and d2.broj_dok  = sd2.broj_dok and d2.vrsta_dok = sd2.vrsta_dok and d2.godina    = sd2.godina
       and sd2.vrsta_dok = '3' and sd2.proizvod = sd.proizvod
    ) znc
,
(
    select round(sd2.cena * (100 - NVL(sd2.rabat,0)) / 100,4)
    from dokument d2, stavka_dok sd2
    where
           d2.vrsta_dok = '3' and d2.tip_dok in ('10','16') and d2.status in ('1','5') and d2.org_deo = d.org_deo
       and (d2.datum_dok,d2.datum_unosa) in
         (
           select max(d1.datum_dok), max(d1.datum_unosa)
             from dokument   d1, stavka_dok sd1
            where d1.vrsta_dok = '3' and d1.tip_dok in ('10','16') and d1.status in ('1','5') and d1.org_deo = d.org_deo
              and d1.broj_dok  = sd1.broj_dok and d1.vrsta_dok = sd1.vrsta_dok and d1.godina    = sd1.godina
              and sd1.vrsta_dok = '3' and sd1.proizvod = sd.proizvod
          )
       and (d2.broj_dok,d2.vrsta_dok,d2.godina)
            not in (select vd2.broj_dok,vd2.vrsta_dok,vd2.godina from vezni_dok vd2 where vd2.za_vrsta_dok = '3')
       and d2.broj_dok  = sd2.broj_dok and d2.vrsta_dok = sd2.vrsta_dok and d2.godina    = sd2.godina
       and sd2.vrsta_dok = '3' and sd2.proizvod = sd.proizvod
    ) znc_sa_rab
,
(
    select round(sd2.Z_TROSKOVI / sd2.kolicina,4)
    from dokument d2, stavka_dok sd2
    where
           d2.vrsta_dok = '3' and d2.tip_dok in ('10','16') and d2.status in ('1','5') and d2.org_deo = d.org_deo
       and (d2.datum_dok,d2.datum_unosa) in
         (
           select max(d1.datum_dok), max(d1.datum_unosa)
             from dokument   d1, stavka_dok sd1
            where d1.vrsta_dok = '3' and d1.tip_dok in ('10','16') and d1.status in ('1','5') and d1.org_deo = d.org_deo
              and d1.broj_dok  = sd1.broj_dok and d1.vrsta_dok = sd1.vrsta_dok and d1.godina    = sd1.godina
              and sd1.vrsta_dok = '3' and sd1.proizvod = sd.proizvod
          )
       and (d2.broj_dok,d2.vrsta_dok,d2.godina)
            not in (select vd2.broj_dok,vd2.vrsta_dok,vd2.godina from vezni_dok vd2 where vd2.za_vrsta_dok = '3')
       and d2.broj_dok  = sd2.broj_dok and d2.vrsta_dok = sd2.vrsta_dok and d2.godina    = sd2.godina
       and sd2.vrsta_dok = '3' and sd2.proizvod = sd.proizvod
    ) znc_z_tro
,
(
    select sd2.cena1
    from dokument d2, stavka_dok sd2
    where
           d2.vrsta_dok = '3' and d2.tip_dok in ('10','16') and d2.status in ('1','5') and d2.org_deo = d.org_deo
       and (d2.datum_dok,d2.datum_unosa) in
         (
           select max(d1.datum_dok), max(d1.datum_unosa)
             from dokument d1, stavka_dok sd1
            where d1.vrsta_dok = '3' and d1.tip_dok in ('10','16') and d1.status in ('1','5') and d1.org_deo = d.org_deo
              and d1.broj_dok  = sd1.broj_dok and d1.vrsta_dok = sd1.vrsta_dok and d1.godina    = sd1.godina
              and sd1.vrsta_dok = '3' and sd1.proizvod = sd.proizvod
          )
       and (d2.broj_dok,d2.vrsta_dok,d2.godina)
            not in (select vd2.broj_dok,vd2.vrsta_dok,vd2.godina from vezni_dok vd2 where vd2.za_vrsta_dok = '3')
       and d2.broj_dok  = sd2.broj_dok and d2.vrsta_dok = sd2.vrsta_dok and d2.godina    = sd2.godina
       and sd2.vrsta_dok = '3' and sd2.proizvod = sd.proizvod
    ) znc_mag
from dokument d, stavka_dok sd, proizvod p, organizacioni_deo od
Where
  -- veza tabela
      d.godina = sd.godina and d.vrsta_dok = sd.vrsta_dok and d.broj_dok = sd.broj_dok
  and p.sifra = sd.proizvod
  and od.id = d.org_deo
  and d.vrsta_Dok = 3
  and d.tip_dok = 10
  and d.tip_dok   in ('10','16','116')
  and d.status    in ('1','5')

--  and d.org_deo not in (select MAGACIN FROM PARTNER_MAGACIN_FLAG)


Group by sd.proizvod, p.naziv, d.org_deo, od.naziv
order by sd.proizvod, d.org_deo
