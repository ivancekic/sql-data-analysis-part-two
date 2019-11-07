					SELECT
							distinct
										PLV.PLAN_CIKLUS_ID,
										PLV.PLAN_CIKLUS_NAZIV,
										PLV.PLAN_PERIOD_ID,
										PLV.PLAN_PERIOD_NAZIV,
										PLV.PLAN_TRAJANJE_ID,
										PLV.PLAN_TRAJANJE_DATUM_OD,
										PLV.PLAN_TRAJANJE_DATUM_DO,
										PLV.BROJ_DOK,
										PLV.ORG_DEO_ID,
										PLV.ORG_DEO_NAZIV,
										PLV.BROJ_DOK1,
                                        PLV.OPIS_PLAN,
										PLV.STATUS_PLAN,
										PLS.NAZIV STATUS_PLAN_NAZIV,
						                PLV.VARIJANTA_ID,
										PLV.STATUS_VARIJANTA,
										PLVA.OPIS STATUS_VARIJANTA_OPIS
					FROM PLANIRANJE_VIEW plv
				       , PLANIRANJE_STATUS pls
				       , PLANIRANJE_VARIJANTA plva
					WHERE plv.PLAN_CIKLUS_ID= &p_ciklus_id
					  AND plv.PLAN_TIP_ID= &p_tip_id
					  AND plv.PLAN_PERIOD_ID= &p_period_id
					  AND plv.PLAN_TRAJANJE_ID= &p_trajanje_id
					  AND plv.broj_dok= &p_broj_dok
--					  and plv.org_deo_id = &p_org_deo_id
					  and plv.varijanta_id= &p_varijanta_id
				      and plv.PLAN_TIP_ID=pls.PLAN_TIP_ID
				      and plv.STATUS_PLAN=pls.STATUS_ID

				      And plv.PLAN_TIP_ID=plva.PLAN_TIP_ID
				      And plv.PLAN_CIKLUS_ID=plva.PLAN_CIKLUS_ID
				      And plv.PLAN_PERIOD_ID=plva.PLAN_PERIOD_ID
				      And plv.PLAN_TRAJANJE_ID=plva.PLAN_TRAJANJE_ID
				      And plv.BROJ_DOK=plva.BROJ_DOK
				      And plv.VARIJANTA_ID=plva.VARIJANTA_ID
				   ;
