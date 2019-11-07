   				SELECT
--						PLAN.PLAN_CIKLUS_ID,
--						PLAN.PLAN_CIKLUS_NAZIV,
--						PLAN.PLAN_PERIOD_ID,
--						PLAN.PLAN_PERIOD_NAZIV,
--						PLAN.PLAN_TRAJANJE_ID,
--						PLAN.PLAN_TRAJANJE_DATUM_OD,
--						PLAN.PLAN_TRAJANJE_DATUM_DO,
--						PLAN.BROJ_DOK,
--						PLAN.ORG_DEO_ID,
--						PLAN.ORG_DEO_NAZIV,
--						PLAN.BROJ_DOK1,
--						PLAN.OPIS_PLAN,
--						PLAN.STATUS_PLAN,
--						PLAN.STATUS_PLAN_NAZIV,
--						PLAN.VARIJANTA_ID,
--						PLAN.STATUS_VARIJANTA,
--						PLAN.STATUS_VARIJANTA_OPIS,

						plan.GOTOV_PR_SIFRA
						, plan.GOTOV_PR_NAZIV
						, plan.GOTOV_PR_JM
						, plan.GOTOV_PR_POSGR
						, plan.GOTOV_PR_PLAN_ZELJENA_KOL GOTOV_PR_PLAN_ZELJENA_KOL_sum
						, plan.TIP_PROIZVODA
						, sum(STANJE_ZAL)STANJE_ZAL
						, sum(STANJE_NA_DAN) STANJE_NA_DAN
						, CASE WHEN proizv.proizvedeno > 0 THEN
						            proizv.proizvedeno
						  Else
						       null
						  End  proizvedeno
						, case when nvl(GOTOV_PR_PLAN_ZELJENA_KOL,0) != 0 then
						            round(PROIZVEDENO / GOTOV_PR_PLAN_ZELJENA_KOL  * 100, 2)
						  else
						               null
						  end PROIZVEDENO_PROC
						, NVL(PROIZVEDENO,0) - NVL(GOTOV_PR_PLAN_ZELJENA_KOL,0) PROIZVEDENO_ODST
				FROM
				(
					SELECT

							distinct
--										PLV.PLAN_CIKLUS_ID,
--										PLV.PLAN_CIKLUS_NAZIV,
--										PLV.PLAN_PERIOD_ID,
--										PLV.PLAN_PERIOD_NAZIV,
--										PLV.PLAN_TRAJANJE_ID,
--										PLV.PLAN_TRAJANJE_DATUM_OD,
--										PLV.PLAN_TRAJANJE_DATUM_DO,
--										PLV.BROJ_DOK,
--										PLV.ORG_DEO_ID,
--										PLV.ORG_DEO_NAZIV,
--										PLV.BROJ_DOK1,
--                                        PLV.OPIS_PLAN,
--										PLV.STATUS_PLAN,
--										PLS.NAZIV STATUS_PLAN_NAZIV,
--						                PLV.VARIJANTA_ID,
--										PLV.STATUS_VARIJANTA,
--										PLVA.OPIS STATUS_VARIJANTA_OPIS,

							         gotov_pr_sifra
							       , gotov_pr_naziv
								   , gotov_pr_jm
								   , GOTOV_PR_POSGR
				                   , gotov_pr_plan_zeljena_kol
				                   , p.tip_proizvoda
--				                   , plv.ORG_DEO_ID
					FROM PLANIRANJE_VIEW plv
				       , PROIZVOD P
				       , PLANIRANJE_STATUS pls
				       , PLANIRANJE_VARIJANTA plva
					WHERE plv.PLAN_CIKLUS_ID= &p_ciklus_id
					  AND plv.PLAN_TIP_ID= &p_tip_id
					  AND plv.PLAN_PERIOD_ID= &p_period_id
					  AND plv.PLAN_TRAJANJE_ID= &p_trajanje_id
					  AND plv.broj_dok= &p_broj_dok
					  and plv.org_deo_id = &p_org_deo_id
					  and plv.varijanta_id= &p_varijanta_id
				      AND p.sifra = plv.gotov_pr_sifra
				      and plv.PLAN_TIP_ID=pls.PLAN_TIP_ID
				      and plv.STATUS_PLAN=pls.STATUS_ID

				      And plv.PLAN_TIP_ID=plva.PLAN_TIP_ID
				      And plv.PLAN_CIKLUS_ID=plva.PLAN_CIKLUS_ID
				      And plv.PLAN_PERIOD_ID=plva.PLAN_PERIOD_ID
				      And plv.PLAN_TRAJANJE_ID=plva.PLAN_TRAJANJE_ID
				      And plv.BROJ_DOK=plva.BROJ_DOK
				      And plv.VARIJANTA_ID=plva.VARIJANTA_ID
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
						     , ROUND(sum(case when d.datum_dok <=  nvl( (select DATUM_OD from PLANIRANJE_TRAJANJE
						                                                 where PLAN_CIKLUS_ID= &p_ciklus_id
						                                                   and PLAN_PERIOD_ID= &p_period_id
						                                                   and TRAJANJE_ID= &p_trajanje_id)
						                                                   ,to_date('01.01.0001','dd.mm.yyyy'))
					                              then
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
			 	          and d.godina= &p_ciklus_id
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
						  and sd.proizvod in
											(
													SELECT

															distinct gotov_pr_sifra
													FROM PLANIRANJE_VIEW plv
													WHERE plv.PLAN_CIKLUS_ID= &p_ciklus_id
													  AND plv.PLAN_TIP_ID= &p_tip_id
													  AND plv.PLAN_PERIOD_ID= &p_period_id
													  AND plv.PLAN_TRAJANJE_ID= &p_trajanje_id
													  AND plv.broj_dok= &p_broj_dok
													  and plv.org_deo_id = &p_org_deo_id
													  and plv.varijanta_id= &p_varijanta_id

											)
						Group by d.org_deo, sd.proizvod, p.tip_proizvoda
				) d
				,(Select sdp.proizvod
				       , Sum( Round( Decode( dp.Vrsta_Dok || dp.Tip_Dok,
					                          '314', sdp.Kolicina,
					                          '414', sdp.Kolicina,
					            sdp.Realizovano ) * sdp.Faktor * sdp.K_Robe, 5 ) ) proizvedeno
				  From dokument dp, stavka_dok sdp
--				     , (select vrednost from PLANIRANJE_MAPIRANJE  where VRSTA ='MAGACINI_PROIZVODI_OK' ) pm
				  Where dp.broj_dok>0
				    and (    dp.vrsta_Dok = '1'
				          or dp.vrsta_Dok = '26'
				          or dp.vrsta_Dok = '45'
				          or dp.vrsta_Dok = '46')
				    and dp.GODINA = &p_ciklus_id
				    and dp.status > 0
--				    and dp.org_Deo = pm.vrednost
				    and dp.datum_dok between nvl( (select DATUM_OD from PLANIRANJE_TRAJANJE
				                                   where PLAN_CIKLUS_ID= &p_ciklus_id
					                                 and PLAN_PERIOD_ID= &p_period_id
					                                 and TRAJANJE_ID= &p_trajanje_id)
					                             ,to_date('01.01.0001','dd.mm.yyyy'))

					                     and nvl( (select DATUM_DO from PLANIRANJE_TRAJANJE
				                                   where PLAN_CIKLUS_ID= &p_ciklus_id
					                                 and PLAN_PERIOD_ID= &p_period_id
					                                 and TRAJANJE_ID= &p_trajanje_id)
					                             ,to_date('01.01.0001','dd.mm.yyyy'))

				    and dp.godina = sdp.godina and dp.vrsta_dok = sdp.vrsta_dok and dp.broj_dok = sdp.broj_dok
				    and sdp.k_robe != 0
				    and sdp.proizvod in
									(
											SELECT

													distinct gotov_pr_sifra
											FROM PLANIRANJE_VIEW plv
											WHERE plv.PLAN_CIKLUS_ID= &p_ciklus_id
											  AND plv.PLAN_TIP_ID= &p_tip_id
											  AND plv.PLAN_PERIOD_ID= &p_period_id
											  AND plv.PLAN_TRAJANJE_ID= &p_trajanje_id
											  AND plv.broj_dok= &p_broj_dok
											  and plv.org_deo_id = &p_org_deo_id
											  and plv.varijanta_id= &p_varijanta_id

									)

				  Group by sdp.proizvod
				 ) proizv

			    WHERE plan.GOTOV_PR_SIFRA=D.PROIZVOD(+)
			      And plan.GOTOV_PR_SIFRA=proizv.proizvod(+)
				Group by
--						PLAN.PLAN_CIKLUS_ID,
--						PLAN.PLAN_CIKLUS_NAZIV,
--						PLAN.PLAN_PERIOD_ID,
--						PLAN.PLAN_PERIOD_NAZIV,
--						PLAN.PLAN_TRAJANJE_ID,
--						PLAN.PLAN_TRAJANJE_DATUM_OD,
--						PLAN.PLAN_TRAJANJE_DATUM_DO,
--						PLAN.BROJ_DOK,
--						PLAN.ORG_DEO_ID,
--						PLAN.ORG_DEO_NAZIV,
--						PLAN.BROJ_DOK1,
--						PLAN.OPIS_PLAN,
--						PLAN.STATUS_PLAN,
--						PLAN.STATUS_PLAN_NAZIV,
--						PLAN.VARIJANTA_ID,
--						PLAN.STATUS_VARIJANTA,
--						PLAN.STATUS_VARIJANTA_OPIS,

				         plan.GOTOV_PR_SIFRA
			 	       , plan.GOTOV_PR_NAZIV
				       , plan.GOTOV_PR_JM
				       , plan.GOTOV_PR_POSGR
				       , plan.GOTOV_PR_PLAN_ZELJENA_KOL
				       , plan.TIP_PROIZVODA
			           , proizv.proizvedeno

			    Order by tip_proizvoda, GOTOV_PR_POSGR, gotov_pr_naziv

 			        ;
