select
        plan.MATERIJAL_TIP
      , plan.MATERIJAL_SIFRA
      , plan.MATERIJAL_NAZIV
      , plan.MATERIJAL_KOL_SUM
      , plan.MATERIJAL_JED_MERE
      , plan.MATERIJAL_ZADNJA_NABAVNA_CENA
      , plan.MATERIJAL_POSGR
      , plan.org_deo_id
--      , D.nabavljeno
--      , D.OCEKIVANO

--      , (plan.MATERIJAL_KOL_SUM + 0) - (STANJE_NA_DAN + OCEKIVANO) MIN_ZA_NAB


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

	 	  --**********************************************************************************************************************************
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
	      , Sum( CASE WHEN    dp.vrsta_Dok IN( '3','4','5','30' )
	                       OR dp.ppartner not in (select vrednost from PLANIRANJE_MAPIRANJE  where VRSTA ='SIFRA_NASE_FIRME_U_PARTNERIMA' ) THEN

	                       Round( Decode( dp.Vrsta_Dok || dp.Tip_Dok,
		                                  '314', sdp.Kolicina,
		                                  '414', sdp.Kolicina,
 		                                   sdp.Realizovano ) * sdp.Faktor * sdp.K_Robe, 5 )
		         ELSE
		            NULL
		         END
		       )     nabavljeno
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
          AND DP.VRSTA_DOK> 0
--          and (    dp.vrsta_Dok = '3'
--	            or dp.vrsta_Dok = '4'
--	            or dp.vrsta_Dok = '5'
--	            or dp.vrsta_Dok = '30')
          AND DP.VRSTA_DOK NOT IN ('80','90')
	      and dp.GODINA =&c_ciklus_id
	      and dp.status > 0
	      and dp.status != 8
	      and pm.magacin_id=dp.org_Deo
	      and dp.datum_dok between to_date('01.01.'||&c_ciklus_id,'dd.mm.yyyy')
		                       and &g_trajanje_datum_od
   	      and dp.ppartner not in (select vrednost from PLANIRANJE_MAPIRANJE  where VRSTA ='SIFRA_NASE_FIRME_U_PARTNERIMA' )
 	      and dp.godina = sdp.godina and dp.vrsta_dok = sdp.vrsta_dok and dp.broj_dok = sdp.broj_dok
 	      and pv.materijal_sifra=sdp.proizvod(+)
 	      and sdp.k_robe!=0
	 	  --**********************************************************************************************************************************
	 group by
	          pv.materijal_sifra
			, pv.org_deo_id
) NAB

where plan.org_deo_id=D.org_deo_id (+)
  and plan.MATERIJAL_SIFRA=D.MATERIJAL_SIFRA(+)

order by
			  plan.MATERIJAL_POSGR
 		    , plan.materijal_naziv
