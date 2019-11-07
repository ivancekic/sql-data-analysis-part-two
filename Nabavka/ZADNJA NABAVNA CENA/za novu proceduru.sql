select
       proizvod,NAZIV,ZAD_NAB_CENA_DOK_VRED,ZAD_NAB_CENA_DOK_DAT,PR_MAX_DAT
     , datum_dok, GODINA,VRSTA_DOK,PPARTNER,RABAT,POREZ,CENA,Z_TROSKOVI
     , TIP_DOK,CENA1,KOLICINA,PS_CENA1,PS_DATUM_DOK
from
(
	select p.SIFRA proizvod ,p.NAZIV,p.ZAD_NAB_CENA_DOK_VRED,p.ZAD_NAB_CENA_DOK_DAT,p.PR_MAX_DAT
	     , pr.GODINA,pr.VRSTA_DOK,pr.PPARTNER,pr.datum_dok
	     , pr.RABAT,pr.POREZ,pr.CENA,pr.Z_TROSKOVI,pr.TIP_DOK,pr.CENA1,pr.KOLICINA

	     , ps.CENA1 ps_cena1, ps.datum_Dok ps_Datum_Dok
	from
	(
		select p.sifra, P.NAZIV
		     , p.ZAD_NAB_CENA_DOK_VRED, p.ZAD_NAB_CENA_DOK_DAT
		     , pr_max_dat
		from proizvod p
		   , (
						Select
						       SD.PROIZVOD, max(d.datum_dok) pr_max_dat
						From dokument d
						   , stavka_dok sd
						   , PROIZVOD P
						Where d.broj_dok> 0
						  and d.godina > 0
						  and ((     d.vrsta_dok = '3' and d.tip_dok  in( 10,16,161, 103,124)
						         and d.ppartner not in (select vrednost from PLANIRANJE_MAPIRANJE  where VRSTA ='SIFRA_NASE_FIRME_U_PARTNERIMA' )
						        )
						      )

						  and d.status   in (1,5)
		                  and d.org_deo not in (SELECT vrednost from planiranje_mapiranje where vrsta='MAGACIN_UZORAKA')
		                  and d.org_deo not in (SELECT magacin from partner_magacin_flag)

						  and sd.broj_dok  = d.broj_dok and sd.vrsta_dok = d.vrsta_dok and sd.godina = d.godina
						  AND P.SIFRA=SD.PROIZVOD
						  And P.TIP_PROIZVODA NOT IN (select vrednost from PLANIRANJE_MAPIRANJE
		                                                 where vrsta in ('GOT_PROIZVODI_TIPOVI','POLUPROIZVODI_TIPOVI'))
						group by proizvod
		     ) prij_max_dat
		where P.TIP_PROIZVODA NOT IN (select vrednost from PLANIRANJE_MAPIRANJE
		                                                 where vrsta in ('GOT_PROIZVODI_TIPOVI','POLUPROIZVODI_TIPOVI'))
		  and prij_max_dat.proizvod (+) = p.sifra
	) p
	,
	(
					Select
					       d.godina, d.vrsta_dok,d.ppartner,
					       SD.PROIZVOD, d.datum_dok
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
					Where d.broj_dok> 0
					  and d.godina > 0
					  and (( d.vrsta_dok = '3' and d.tip_dok  in( 10,16,161, 103,124)
					       and d.ppartner not in (select vrednost from PLANIRANJE_MAPIRANJE  where VRSTA ='SIFRA_NASE_FIRME_U_PARTNERIMA' )
					        )
					      )

					  and d.status   in (1,5)
	                  and d.org_deo not in (SELECT vrednost from planiranje_mapiranje where vrsta='MAGACIN_UZORAKA')
	                  and d.org_deo not in (SELECT magacin from partner_magacin_flag)

					  and sd.broj_dok  = d.broj_dok and sd.vrsta_dok = d.vrsta_dok and sd.godina = d.godina
					  AND P.SIFRA=SD.PROIZVOD
					  And P.TIP_PROIZVODA NOT IN (select vrednost from PLANIRANJE_MAPIRANJE
	                                                 where vrsta in ('GOT_PROIZVODI_TIPOVI','POLUPROIZVODI_TIPOVI'))
	)  pr
	,
	(
					Select
					       SD.PROIZVOD, SD.CENA1, max(d.datum_dok) datum_dok
					From dokument d
					   , stavka_dok sd
					   , PROIZVOD P
					Where d.broj_dok> 0
					  and d.godina > 0
					  and d.vrsta_dok= '21'
	--		          and nvl(d.ppartner,(select vrednost from PLANIRANJE_MAPIRANJE  where VRSTA ='SIFRA_NASE_FIRME_U_PARTNERIMA' ))
	--		                   =(select vrednost from PLANIRANJE_MAPIRANJE  where VRSTA ='SIFRA_NASE_FIRME_U_PARTNERIMA' )
					  and d.status   in (1,5)
	                  and d.org_deo not in (SELECT vrednost from planiranje_mapiranje where vrsta='MAGACIN_UZORAKA')
	                  and d.org_deo not in (SELECT magacin from partner_magacin_flag)

					  and sd.broj_dok  = d.broj_dok and sd.vrsta_dok = d.vrsta_dok and sd.godina = d.godina
					  AND P.SIFRA=SD.PROIZVOD
					  And P.TIP_PROIZVODA NOT IN (select vrednost from PLANIRANJE_MAPIRANJE
	                                                 where vrsta in ('GOT_PROIZVODI_TIPOVI','POLUPROIZVODI_TIPOVI'))
	                Group by  SD.PROIZVOD, SD.CENA1
	)  ps
	where pr.proizvod (+) = p.sifra
	  and pr.datum_dok (+)= p.PR_MAX_DAT
	  and ps.proizvod (+) = p.sifra
) p
where
      nvl(ZAD_NAB_CENA_DOK_VRED,0) <> nvl(cena1,nvl(ps_cena1,0))
--   or nvl(ZAD_NAB_CENA_DOK_VRED,0) <> nvl(ps_cena1,0)

order by to_number(p.proizvod), nvl(p.datum_dok,p.PS_DATUM_DOK);
