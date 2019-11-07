select d.org_deo, od.naziv naziv_org, sd.proizvod, p.naziv naziv_pro, d.user_id
from stavka_dok sd, dokument d , PROIZVOD P , GRUPA_PR  GPR, organizacioni_deo od
Where
  -- veza tabela
      d.godina = sd.godina and d.vrsta_dok = sd.vrsta_dok and d.broj_dok = sd.broj_dok
  AND SD.PROIZVOD = P.SIFRA AND P.GRUPA_PROIZVODA=  GPR.ID
  and od.id = d.org_deo
  and d.vrsta_dok in (3,73)
  and d.datum_dok between to_date('01.01.2011','dd.mm.yyyy') and to_date('31.12.2011','dd.mm.yyyy')
  and d.org_deo not in (select magacin from partner_magacin_flag)
  AND D.ORG_DEO NOT BETWEEN 300 AND 517
  AND D.org_deo NOT IN (  103,104,105,106,107,108		-- GR i PP dom prodaja
                         ,123,124,125,126,127,128		-- GR i PP ino prodaja
                         ,153,154,155,156,157,158		-- povracaj robe kontrola
                         )
  and org_deo in (168)
Group by d.org_deo, od.naziv, sd.proizvod, p.naziv, d.user_id
Order by d.org_deo, sd.proizvod, p.naziv
