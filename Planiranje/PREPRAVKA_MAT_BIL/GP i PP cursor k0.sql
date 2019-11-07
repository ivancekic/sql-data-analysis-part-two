SELECT
       plan.GOTOV_PR_SIFRA
     , plan.GOTOV_PR_NAZIV
     , plan.GOTOV_PR_JM
     , plan.GOTOV_PR_POSGR
     , plan.GOTOV_PR_PLAN_ZELJENA_KOL
     , plan.TIP_PROIZVODA
     , plan.ORG_DEO_ID
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
       , PLANIRANJE_ORG_DEO_MAGACIN pom
	WHERE plv.PLAN_CIKLUS_ID=2011
	  AND plv.PLAN_TIP_ID=3
	  AND plv.PLAN_PERIOD_ID=3
	  AND plv.PLAN_TRAJANJE_ID=4
      AND p.sifra = plv.gotov_pr_sifra
      And plv.ORG_DEO_ID = pom.ORG_DEO_ID
) plan
    order by tip_proizvoda, GOTOV_PR_POSGR, gotov_pr_naziv

