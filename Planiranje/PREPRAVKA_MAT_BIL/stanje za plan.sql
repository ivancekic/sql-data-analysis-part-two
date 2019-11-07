select
       d.org_deo
     , sd.proizvod
     , p.tip_proizvoda
     , round(Sum(NVL(decode(d.tip_dok,14,Kolicina,realizovano)*Faktor
                            * case when d.vrsta_dok = '90' then
                                        0
                              else
                                        K_ROBE
                              end
                     ,0)
                 )
            ,5) STANJE_ZAL
     , ROUND(sum(case when d.datum_dok <= &dDatDo then
				     NVL(
				           decode(d.tip_dok,14,Kolicina,realizovano)*Faktor
				                     * case when d.vrsta_dok = '90' then
				                                 0
				                       else
				                                 K_ROBE
				                       end

				        ,0)
                 ELSE
                     0
                 End
                )
           ,5) STANJE_NA_DAN
from Stavka_dok sd, dokument d, Proizvod p
   , (select * from PLANIRANJE_MAPIRANJE  where VRSTA ='GOT_PROIZVODI_TIPOVI' ) pm
   , (select * from PLANIRANJE_MAPIRANJE  where VRSTA ='POLUPROIZVODI_TIPOVI' ) pm1
Where
      d.godina = sd.godina and d.vrsta_dok = sd.vrsta_dok and d.broj_dok = sd.broj_dok
  and ( p.tip_proizvoda = pm.vrednost
        or
        p.tip_proizvoda = pm1.vrednost
      )
  and p.sifra=sd.proizvod
  and d.datum_dok between to_date('01.01.'||to_char(sysdate,'yyyy'),'dd.mm.yyyy')
                      and sysdate
  and d.status > 0
  and sd.k_robe <> 0
  and sd.proizvod = 360165

Group by d.org_deo, sd.proizvod, p.tip_proizvoda
