	SELECT
	       plan.GOTOV_PR_SIFRA
	     , plan.GOTOV_PR_NAZIV
	     , plan.GOTOV_PR_JM
	     , plan.GOTOV_PR_POSGR
	     , plan.GOTOV_PR_PLAN_ZELJENA_KOL
	     , plan.TIP_PROIZVODA
	     , sum(STANJE_ZAL)STANJE_ZAL
	     , sum(STANJE_NA_DAN) STANJE_NA_DAN
	     , proizv.proizvedeno proizvedeno
	     , case when nvl(GOTOV_PR_PLAN_ZELJENA_KOL,0) != 0 then
	                 round(PROIZVEDENO / GOTOV_PR_PLAN_ZELJENA_KOL  * 100, 2)
	       else
                     null
	       end PROIZVEDENO_PROC
	     , NVL(PROIZVEDENO,0) - NVL(GOTOV_PR_PLAN_ZELJENA_KOL,0) PROIZVEDENO_ODST
	FROM
	(
		SELECT

				distinct gotov_pr_sifra
				       , gotov_pr_naziv
					   , gotov_pr_jm
					   , GOTOV_PR_POSGR
	                   , gotov_pr_plan_zeljena_kol
	                   , p.tip_proizvoda
	                   , plv.ORG_DEO_ID
		FROM PLANIRANJE_VIEW plv
	       , PROIZVOD P
		WHERE plv.PLAN_CIKLUS_ID=&c_ciklus_id
		  AND plv.PLAN_TIP_ID=&c_tip_id
		  AND plv.PLAN_PERIOD_ID=&c_period_id
		  AND plv.PLAN_TRAJANJE_ID=&c_trajanje_id
		  AND plv.broj_dok=&c_broj_dok
		  and plv.varijanta_id=&c_varijanta_id

	      AND p.sifra = plv.gotov_pr_sifra
	) plan
	,
	(
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
			     , ROUND(sum(case when d.datum_dok <= &g_trajanje_datum_od then
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
			   , (select VREDNOST from PLANIRANJE_MAPIRANJE  where VRSTA ='GOT_PROIZVODI_TIPOVI' ) pm
			   , (select VREDNOST from PLANIRANJE_MAPIRANJE  where VRSTA ='POLUPROIZVODI_TIPOVI' ) pm1
			Where d.broj_dok>0
 	          and (   d.vrsta_Dok != '2'
 	               or d.vrsta_Dok != '9'
 	               or d.vrsta_Dok != '10'
 	              )
 	          and d.godina=&c_ciklus_id
			  and d.status > 0
			  and d.org_Deo in (select vrednost from PLANIRANJE_MAPIRANJE  where VRSTA ='MAGACINI_PROIZVODI_OK' )
			  and d.datum_dok between to_date('01.01.'||TO_CHAR(SYSDATE,'YYYY'),'dd.mm.yyyy')
			                      and sysdate
			  and d.godina = sd.godina and d.vrsta_dok = sd.vrsta_dok and d.broj_dok = sd.broj_dok
			  and sd.k_robe != 0
			  and p.sifra=sd.proizvod
			  and ( p.tip_proizvoda = pm.vrednost
			        or
			        p.tip_proizvoda = pm1.vrednost
			      )
			Group by d.org_deo, sd.proizvod, p.tip_proizvoda
	) d
	,(Select sdp.proizvod
	       , Sum( Round( Decode( dp.Vrsta_Dok || dp.Tip_Dok,
		                          '314', sdp.Kolicina,
		                          '414', sdp.Kolicina,
		            sdp.Realizovano ) * sdp.Faktor * sdp.K_Robe, 5 ) ) proizvedeno
	  From dokument dp, stavka_dok sdp
	     , (select vrednost from PLANIRANJE_MAPIRANJE  where VRSTA ='MAGACINI_PROIZVODI_OK' ) pm
	  Where dp.broj_dok>0
	    and (    dp.vrsta_Dok = '1'
	          or dp.vrsta_Dok = '26'
	          or dp.vrsta_Dok = '45'
	          or dp.vrsta_Dok = '46')
	    and dp.GODINA =&c_ciklus_id
	    and dp.status > 0
	    and dp.org_Deo = pm.vrednost
	    and dp.datum_dok between to_date('01.01.'||TO_CHAR(&C_CIKLUS_ID),'dd.mm.yyyy')
		                     and &g_trajanje_datum_od
	    and dp.godina = sdp.godina and dp.vrsta_dok = sdp.vrsta_dok and dp.broj_dok = sdp.broj_dok
	    and sdp.k_robe != 0
	  Group by sdp.proizvod
	 ) proizv
    WHERE plan.GOTOV_PR_SIFRA=D.PROIZVOD(+)
      And plan.GOTOV_PR_SIFRA=proizv.proizvod(+)
	Group by plan.GOTOV_PR_SIFRA
 	       , plan.GOTOV_PR_NAZIV
	       , plan.GOTOV_PR_JM
	       , plan.GOTOV_PR_POSGR
	       , plan.GOTOV_PR_PLAN_ZELJENA_KOL
	       , plan.TIP_PROIZVODA
,proizv.proizvedeno

    Order by tip_proizvoda, GOTOV_PR_POSGR, gotov_pr_naziv

