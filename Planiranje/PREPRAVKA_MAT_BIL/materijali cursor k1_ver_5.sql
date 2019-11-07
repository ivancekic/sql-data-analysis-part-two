select
        plan.MATERIJAL_TIP
      , plan.MATERIJAL_SIFRA
      , plan.MATERIJAL_NAZIV
      , plan.MATERIJAL_KOL_SUM
      , plan.MATERIJAL_JED_MERE
      , plan.MATERIJAL_ZADNJA_NABAVNA_CENA
      , plan.MATERIJAL_POSGR
      , plan.org_deo_id
      , nab.nabavljeno

--      , (plan.MATERIJAL_KOL_SUM + 0) - (d.STANJE_NA_DAN +)

      , d.STANJE_ZAL
      , d.STANJE_NA_DAN

from
(
	 select
	        /*+ INDEX(planiranje_stavka planir_s_pk) */
	        pv.materijal_tip
	      , pv.materijal_sifra
	      , pv.materijal_naziv
	      , sum(pv.materijal_plan_potrebna_kol) materijal_kol_sum
	      , pv.materijal_jed_mere
	      , pv.materijal_zadnja_nabavna_cena
		  , pv.MATERIJAL_POSGR
		  , pv.org_deo_id
		  ---------------------------------------------------------------------------------------------------
		 from planiranje_view pv
		where
	           pv.plan_tip_id         = &c_tip_id
	      and  pv.plan_ciklus_id      = &c_ciklus_id
	      and  pv.plan_period_id      = &c_period_id
	      and  pv.plan_trajanje_id    = &c_trajanje_id
	      and  pv.broj_dok   = &c_broj_dok
	      and  pv.broj_dok1  = &c_broj_dok1
	      and  pv.org_deo_id = &c_org_deo_id
		  and  pv.varijanta_id     = &c_varijanta_id
		  and  pv.status_stavka = 1

	 	  --**********************************************************************************************************************************--
	 group by
	          pv.materijal_tip
	        , pv.materijal_sifra
	        , pv.materijal_naziv
	        , pv.materijal_jed_mere
	        , pv.materijal_zadnja_nabavna_cena
			, pv.MATERIJAL_POSGR
			, pv.org_deo_id
) plan
,
(
	 select
	        /*+ INDEX(planiranje_stavka planir_s_pk) */
	        pv.materijal_sifra
		  , pv.org_deo_id
	      , Sum( Round( Decode( dp.Vrsta_Dok || dp.Tip_Dok,
		                          '314', sdp.Kolicina,
		                          '414', sdp.Kolicina,
		            sdp.Realizovano ) * sdp.Faktor * sdp.K_Robe, 5 ) ) nabavljeno
		  ---------------------------------------------------------------------------------------------------
		 from planiranje_view pv
		    , (SELECT * FROM PLANIRANJE_ORG_DEO_MAGACIN) pm
		    , dokument dp, stavka_dok sdp
		where
	           pv.plan_tip_id         = &c_tip_id
	      and  pv.plan_ciklus_id      = &c_ciklus_id
	      and  pv.plan_period_id      = &c_period_id
	      and  pv.plan_trajanje_id    = &c_trajanje_id
	      and  pv.broj_dok   = &c_broj_dok
	      and  pv.broj_dok1  = &c_broj_dok1
	      and  pv.org_deo_id = &c_org_deo_id
		  and  pv.varijanta_id  = &c_varijanta_id
		  and  pv.status_stavka = 1
          and  pv.org_deo_id=pm.org_deo_id

          and dp.broj_dok>0
          and (    dp.vrsta_Dok = '3'
	            or dp.vrsta_Dok = '4'
	            or dp.vrsta_Dok = '5'
	            or dp.vrsta_Dok = '30')
	      and dp.GODINA =&c_ciklus_id
	      and dp.status > 0
	      and pm.magacin_id=dp.org_Deo
	      and dp.datum_dok between to_date('01.01.'||&c_ciklus_id,'dd.mm.yyyy')
		                       and &g_trajanje_datum_od
   	      and dp.ppartner not in (select vrednost from PLANIRANJE_MAPIRANJE  where VRSTA ='SIFRA_NASE_FIRME_U_PARTNERIMA' )
 	      and dp.godina = sdp.godina and dp.vrsta_dok = sdp.vrsta_dok and dp.broj_dok = sdp.broj_dok
 	      and pv.materijal_sifra=sdp.proizvod(+)
 	      and sdp.k_robe!=0
	 	  --**********************************************************************************************************************************--
	 group by
	          pv.materijal_sifra
			, pv.org_deo_id
) nab
,
(
	 select
	        /*+ INDEX(planiranje_stavka planir_s_pk) */
	        pv.materijal_sifra
		  , pv.org_deo_id

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
		  ---------------------------------------------------------------------------------------------------
		 from planiranje_view pv
		    , (SELECT * FROM PLANIRANJE_ORG_DEO_MAGACIN) pm
		    , dokument d, stavka_dok sd
		where
	           pv.plan_tip_id         = &c_tip_id
	      and  pv.plan_ciklus_id      = &c_ciklus_id
	      and  pv.plan_period_id      = &c_period_id
	      and  pv.plan_trajanje_id    = &c_trajanje_id
	      and  pv.broj_dok   = &c_broj_dok
	      and  pv.broj_dok1  = &c_broj_dok1
	      and  pv.org_deo_id = &c_org_deo_id
		  and  pv.varijanta_id  = &c_varijanta_id
		  and  pv.status_stavka = 1
          and  pv.org_deo_id=pm.org_deo_id

          and d.broj_dok>0
          and d.vrsta_Dok != '2'
	      AND d.vrsta_Dok != '9'
	      AND d.vrsta_Dok != '10'
	      AND d.vrsta_Dok != '90'
	      and d.GODINA =&c_ciklus_id
	      and d.status > 0
	      and pm.magacin_id=d.org_Deo
	      and d.datum_dok between to_date('01.01.'||&c_ciklus_id,'dd.mm.yyyy')
		                       and &g_trajanje_datum_od
 	      and d.godina = sd.godina and d.vrsta_dok = sd.vrsta_dok and d.broj_dok = sd.broj_dok
 	      and pv.materijal_sifra=sd.proizvod(+)
 	      and sd.k_robe!=0
	 	  --**********************************************************************************************************************************--
	 group by
	          pv.materijal_sifra
			, pv.org_deo_id
) d
where plan.org_deo_id=nab.org_deo_id (+)
  and plan.MATERIJAL_SIFRA=nab.MATERIJAL_SIFRA(+)

  and plan.org_deo_id=d.org_deo_id (+)
  and plan.MATERIJAL_SIFRA=d.MATERIJAL_SIFRA(+)

order by
			  plan.MATERIJAL_POSGR
 		    , plan.materijal_naziv
