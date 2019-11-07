--select * from
--(

   				SELECT
						  plan.GOTOV_PR_SIFRA
						, plan.GOTOV_PR_NAZIV
						, plan.GOTOV_PR_JM
						, plan.GOTOV_PR_POSGR
						, plan.GOTOV_PR_POSGR_NAZIV
						, plan.GOTOV_PR_SASTAVNICA
						, plan.GOTOV_PR_SAST_SARZA
						, plan.GOTOV_PR_PLAN_UMNOZAK_SARZE

						, round(plan.GOTOV_PR_PLAN_ZELJENA_KOL,2) GOTOV_PR_PLAN_ZELJENA_KOL_sum
						, pm.vrsta
						, plan.TIP_PROIZVODA
						, sum(STANJE_ZAL)STANJE_ZAL
						, sum(STANJE_NA_DAN) STANJE_NA_DAN
						, sum(proizvedeno) proizvedeno
						, case when nvl(GOTOV_PR_PLAN_ZELJENA_KOL,0) != 0 then
						            round(sum(proizvedeno) / GOTOV_PR_PLAN_ZELJENA_KOL  * 100, 2)
						  else
						               null
						  end PROIZVEDENO_PROC

						, round(NVL(sum(proizvedeno),0) - NVL(GOTOV_PR_PLAN_ZELJENA_KOL,0),2) PROIZVEDENO_ODST
				FROM
				(
					SELECT

							distinct
									  gotov_pr_sifra
									, gotov_pr_naziv
									, gotov_pr_jm
									, GOTOV_PR_POSGR
									, pg.naziv GOTOV_PR_POSGR_NAZIV
									, gotov_pr_plan_zeljena_kol
									, p.tip_proizvoda
									, plv.GOTOV_PR_SASTAVNICA
									, plv.GOTOV_PR_SAST_SARZA
									, plv.GOTOV_PR_PLAN_UMNOZAK_SARZE
					FROM PLANIRANJE_VIEW plv
				       , PROIZVOD P
				       , PLANIRANJE_STATUS pls
				       , PLANIRANJE_VARIJANTA plva
				       , posebna_grupa pg
				       , PLANIRANJE_ORG_DEO_MAGACIN plm
					WHERE plv.PLAN_CIKLUS_ID=&p_ciklus_id
					  AND plv.PLAN_TIP_ID=&p_tip_id
					  AND plv.PLAN_PERIOD_ID=&p_period_id
					  AND plv.PLAN_TRAJANJE_ID=&p_trajanje_id
					  AND plv.broj_dok=&p_broj_dok
					  and plv.varijanta_id=&p_varijanta_id
				      AND p.sifra = plv.gotov_pr_sifra
				      and plv.PLAN_TIP_ID=pls.PLAN_TIP_ID
				      and plv.STATUS_PLAN=pls.STATUS_ID

				      And plv.PLAN_TIP_ID=plva.PLAN_TIP_ID
				      And plv.PLAN_CIKLUS_ID=plva.PLAN_CIKLUS_ID
				      And plv.PLAN_PERIOD_ID=plva.PLAN_PERIOD_ID
				      And plv.PLAN_TRAJANJE_ID=plva.PLAN_TRAJANJE_ID
				      And plv.BROJ_DOK=plva.BROJ_DOK
				      And plv.VARIJANTA_ID=plva.VARIJANTA_ID

				      And pg.grupa=p.posebna_grupa
				      And plv.org_deo_Id=plm.ORG_DEO_ID
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
						                                                 where PLAN_CIKLUS_ID=&p_ciklus_id
						                                                   and PLAN_PERIOD_ID=&p_period_id
						                                                   and TRAJANJE_ID=&p_trajanje_id)
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

				       , Sum( case when d.vrsta_Dok in( '1','26','45','46')
									and d.datum_dok between nvl( (select DATUM_OD from PLANIRANJE_TRAJANJE
													                                   where PLAN_CIKLUS_ID=&p_ciklus_id
														                                 and PLAN_PERIOD_ID=&p_period_id
														                                 and TRAJANJE_ID=&p_trajanje_id)
														                             ,to_date('01.01.0001','dd.mm.yyyy'))

														                     and nvl( (select DATUM_DO from PLANIRANJE_TRAJANJE
													                                   where PLAN_CIKLUS_ID=&p_ciklus_id
														                                 and PLAN_PERIOD_ID=&p_period_id
														                                 and TRAJANJE_ID=&p_trajanje_id)
														                             ,to_date('01.01.0001','dd.mm.yyyy'))

				       			then
				                   Round( Decode( d.Vrsta_Dok || d.Tip_Dok,
					                          '314', sd.Kolicina,
					                          '414', sd.Kolicina,
					            sd.Realizovano ) * sd.Faktor * sd.K_Robe, 5 )
					          end
				            ) proizvedeno

						from Stavka_dok sd, dokument d, Proizvod p
						   , (select VREDNOST from PLANIRANJE_MAPIRANJE  where VRSTA ='GOT_PROIZVODI_TIPOVI' ) pm
						   , (select VREDNOST from PLANIRANJE_MAPIRANJE  where VRSTA ='POLUPROIZVODI_TIPOVI' ) pm1
						Where d.broj_dok>0
			 	          and (   d.vrsta_Dok != '2'
			 	               or d.vrsta_Dok != '9'
			 	               or d.vrsta_Dok != '10'
			 	              )
			 	          and d.godina=&p_ciklus_id
						  and d.status > 0
--						  and d.org_Deo in (select vrednost from PLANIRANJE_MAPIRANJE  where VRSTA ='MAGACINI_PROIZVODI_OK' )
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
													WHERE plv.PLAN_CIKLUS_ID=&p_ciklus_id
													  AND plv.PLAN_TIP_ID=&p_tip_id
													  AND plv.PLAN_PERIOD_ID=&p_period_id
													  AND plv.PLAN_TRAJANJE_ID=&p_trajanje_id
													  AND plv.broj_dok=&p_broj_dok
													  and plv.varijanta_id=&p_varijanta_id

											)
						Group by d.org_deo, sd.proizvod, p.tip_proizvoda
				) d
                ,
                (
					Select vrsta,
					       case when vrsta = 'GOT_PROIZVODI_TIPOVI' then
					                 1
					       else
					                 2
					       end Order_By_Tip
					     , VREDNOST
					from planiranje_mapiranje
					where vrsta in('GOT_PROIZVODI_TIPOVI','POLUPROIZVODI_TIPOVI')
                ) pm
			    WHERE plan.GOTOV_PR_SIFRA=D.PROIZVOD(+)
			      and plan.TIP_PROIZVODA=pm.vrednost
				Group by

				         plan.GOTOV_PR_SIFRA
			 	       , plan.GOTOV_PR_NAZIV
			 	       , plan.GOTOV_PR_POSGR_NAZIV
				       , plan.GOTOV_PR_JM
				       , plan.GOTOV_PR_POSGR
				       , plan.GOTOV_PR_PLAN_ZELJENA_KOL
				       , plan.TIP_PROIZVODA
						, plan.GOTOV_PR_SASTAVNICA
						, plan.GOTOV_PR_SAST_SARZA
						, plan.GOTOV_PR_PLAN_UMNOZAK_SARZE
				       , pm.vrsta

			    Order by Order_By_Tip, GOTOV_PR_POSGR, gotov_pr_naziv
