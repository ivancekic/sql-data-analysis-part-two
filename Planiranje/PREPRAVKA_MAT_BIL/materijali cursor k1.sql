select
        plan.MATERIJAL_TIP
      , plan.MATERIJAL_SIFRA
      , plan.MATERIJAL_NAZIV
      , plan.MATERIJAL_KOL_SUM
      , plan.MATERIJAL_JED_MERE
      , plan.MATERIJAL_ZADNJA_NABAVNA_CENA
      , plan.MATERIJAL_POSGR
from
(
	 select
	        /*+ INDEX(planiranje_stavka planir_s_pk) */
	        materijal_tip
	      , materijal_sifra
	      , materijal_naziv
	      , sum(materijal_plan_potrebna_kol) materijal_kol_sum
	      , materijal_jed_mere
	      , materijal_zadnja_nabavna_cena
		  , MATERIJAL_POSGR
		  ---------------------------------------------------------------------------------------------------
		 from planiranje_view
		where
	           plan_tip_id         = &c_tip_id
	      and  plan_ciklus_id      = &c_ciklus_id
	      and  plan_period_id      = &c_period_id
	      and  plan_trajanje_id    = &c_trajanje_id
	      and  broj_dok   = &c_broj_dok
	      and  broj_dok1  = &c_broj_dok1
	      and  org_deo_id = &c_org_deo_id
		  and  varijanta_id     = &c_varijanta_id
	 	  --**********************************************************************************************************************************--
	 	  --**********************************************************************************************************************************--

		  and  status_stavka       = 1

	 group by
	          materijal_tip
	        , materijal_sifra
	        , materijal_naziv
	        , materijal_jed_mere
	        , materijal_zadnja_nabavna_cena
			, MATERIJAL_POSGR
	 order by
			   MATERIJAL_POSGR
 		     , materijal_naziv
) plan
