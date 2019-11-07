				Select
				       d.godina, d.vrsta_dok,d.ppartner,
				       SD.PROIZVOD, d.datum_dok, P.NAZIV
				     , p.ZAD_NAB_CENA_DOK_VRED, p.ZAD_NAB_CENA_DOK_DAT
				     , SD.RABAT, SD.POREZ, SD.CENA, Z_TROSKOVI
				     , D.TIP_DOK
				     , CASE WHEN P.TIP_PROIZVODA = 8 THEN
				                 CASE WHEN NVL(Z_TROSKOVI,0) > 0 THEN
				                      ((SD.CENA*SD.KOLICINA)*(1-NVL(SD.RABAT,0)/100) + Z_TROSKOVI) / SD.KOLICINA
				                 ELSE
                                      (SD.CENA)*(1-NVL(SD.RABAT,0)/100)
                                 END
                       ELSE
                            SD.CENA1
				       END Cena1
				     , SD.KOLICINA
				From dokument d
				   , stavka_dok sd
				   , PROIZVOD P
				Where
				d.broj_dok> 0
--				substr(d.broj_dok,1,1)<> '-'
				  and d.godina > 0
				  and (( d.vrsta_dok = '3' and d.tip_dok  in( 10,16,161, 103,124)
				       and d.ppartner not in (select vrednost from PLANIRANJE_MAPIRANJE  where VRSTA ='SIFRA_NASE_FIRME_U_PARTNERIMA' )
				        )
				       or
				       (d.vrsta_dok= '21'
				       and nvl(d.ppartner,(select vrednost from PLANIRANJE_MAPIRANJE  where VRSTA ='SIFRA_NASE_FIRME_U_PARTNERIMA' ))
				       =(select vrednost from PLANIRANJE_MAPIRANJE  where VRSTA ='SIFRA_NASE_FIRME_U_PARTNERIMA' )
				       )
				      )

				  and d.status   in (1,5)
                  and d.org_deo not in (SELECT vrednost from planiranje_mapiranje where vrsta='MAGACIN_UZORAKA')
                  and d.org_deo not in (SELECT magacin from partner_magacin_flag)

				  and sd.broj_dok  = d.broj_dok and sd.vrsta_dok = d.vrsta_dok and sd.godina = d.godina
				  AND P.SIFRA=SD.PROIZVOD
				  And P.TIP_PROIZVODA NOT IN (select vrednost from PLANIRANJE_MAPIRANJE
                                                 where vrsta in ('GOT_PROIZVODI_TIPOVI','POLUPROIZVODI_TIPOVI')                                                )

and p.sifra='433'
				Order by SD.PROIZVOD, d.datum_dok desc;

