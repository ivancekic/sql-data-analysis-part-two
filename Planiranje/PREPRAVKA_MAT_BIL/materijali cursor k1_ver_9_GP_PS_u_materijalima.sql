	 select
GOTOV_PR_POSGR
----	 distinct gotov_pr_sastavnica
------	        /*+ INDEX(planiranje_stavka planir_s_pk) */
------	        materijal_tip
------	      , materijal_sifra
------	      , materijal_naziv
------	      , sum(materijal_plan_potrebna_kol) materijal_kol_sum
------	      , materijal_jed_mere
------	      , materijal_zadnja_nabavna_cena
------		  , MATERIJAL_POSGR
----
----*
----, p.sifra
----, p.naziv

--, p.tip_proizvoda
		  ---------------------------------------------------------------------------------------------------
		 from planiranje_view pv, sastavnica_stavka ss
		 , proizvod p
		where
	           pv.plan_tip_id         = &c_tip_id
	      and  pv.plan_ciklus_id      = &c_ciklus_id
	      and  pv.plan_period_id      = &c_period_id
	      and  pv.plan_trajanje_id    = &c_trajanje_id
	      and  pv.broj_dok   = &c_broj_dok
	      and  pv.broj_dok1  = &c_broj_dok1
	      and  pv.org_deo_id = &c_org_deo_id
		  and  pv.varijanta_id     = &c_varijanta_id
	 	  --**********************************************************************************************************************************--
	 	  --**********************************************************************************************************************************--

		  and  pv.status_stavka       = 1

----	 group by
----	          materijal_tip
----	        , materijal_sifra
----	        , materijal_naziv
----	        , materijal_jed_mere
----	        , materijal_zadnja_nabavna_cena
----			, MATERIJAL_POSGR

--	 order by
--			   MATERIJAL_POSGR
-- 		     , materijal_naziv
and pv.gotov_pr_sastavnica = ss.BROJ_DOK
and p.sifra = ss.proizvod

