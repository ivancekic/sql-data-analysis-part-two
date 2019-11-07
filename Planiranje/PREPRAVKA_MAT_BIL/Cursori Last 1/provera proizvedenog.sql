select sd.proizvod, d.org_deo, porganizacioniDeo.naziv(org_deo) naz_mag, sd.kolicina, sd.vrsta_dok
from stavka_dok sd, dokument d , PROIZVOD P , GRUPA_PR  GPR
Where
      d.godina = sd.godina and d.vrsta_dok = sd.vrsta_dok and d.broj_dok = sd.broj_dok
  AND SD.PROIZVOD = P.SIFRA AND P.GRUPA_PROIZVODA=  GPR.ID
  -----------------------------
  -- ostali uslovi
  and d.godina = 2012
  and d.vrsta_Dok in( '1','26','45','46')
--  AND D.ORG_DEO = 104
  and SD.proizvod in ('115106','115207','222111')
  and d.datum_dok between to_date('02.04.2012','dd.mm.yyyy') and  to_date('08.04.2012','dd.mm.yyyy')

  and d.status>0
order by sd.proizvod, d.datum_dok,d.datum_unosa;
