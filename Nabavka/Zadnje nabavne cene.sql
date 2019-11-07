select sd.proizvod, d.org_deo
from dokument d, stavka_dok sd
Where
  -- veza tabela
      d.godina = sd.godina and d.vrsta_dok = sd.vrsta_dok and d.broj_dok = sd.broj_dok
  and d.vrsta_Dok = 3
  and d.tip_dok = 10
  and d.tip_dok   in ('10','16')
  and d.status    in ('1','5')

  and d.org_deo not between 103 and 108
  
Group by sd.proizvod, d.org_deo
Order by sd.proizvod, d.org_deo




------------

    select sd2.cena1
	  into l_zadnja_cena    
      from dokument		d2
         , stavka_dok	sd2

     where
                d2.vrsta_dok = '3'
--       and d2.tip_dok   = '10'
       and d2.tip_dok   in ('10','16')
       and d2.status    in ('1','5')

--       and d2.datum_dok =
--         (
--           select max(d.datum_dok)
       and (d2.datum_dok,d2.datum_unosa) in
         (
           select max(d.datum_dok), max(d.datum_unosa)
             from dokument   d
                , stavka_dok sd

            where
                  d.vrsta_dok = '3'
--              and d.tip_dok   = '10'
              and d.tip_dok   in ('10','16')
              and d.status    in ('1','5')

              and d.broj_dok  = sd.broj_dok
              and d.vrsta_dok = sd.vrsta_dok
              and d.godina    = sd.godina

              and sd.vrsta_dok = '3'

              and sd.proizvod = p_proizvod
          )

      and (d2.broj_dok,d2.vrsta_dok,d2.godina)
          not in (select vd2.broj_dok,vd2.vrsta_dok,vd2.godina
                  from vezni_dok vd2
                  where vd2.za_vrsta_dok = '3'
                 )

       and d2.broj_dok  = sd2.broj_dok
       and d2.vrsta_dok = sd2.vrsta_dok
       and d2.godina    = sd2.godina

       and sd2.vrsta_dok = '3'
       and sd2.proizvod = p_proizvod;
