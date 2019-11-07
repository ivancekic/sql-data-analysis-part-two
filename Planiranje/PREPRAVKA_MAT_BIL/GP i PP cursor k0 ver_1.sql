SELECT
       plan.GOTOV_PR_SIFRA
     , plan.GOTOV_PR_NAZIV
     , plan.GOTOV_PR_JM
     , plan.GOTOV_PR_POSGR
     , plan.GOTOV_PR_PLAN_ZELJENA_KOL
     , plan.TIP_PROIZVODA
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
	WHERE plv.PLAN_CIKLUS_ID=2011
	  AND plv.PLAN_TIP_ID=3
	  AND plv.PLAN_PERIOD_ID=3
	  AND plv.PLAN_TRAJANJE_ID=4
      AND p.sifra = plv.gotov_pr_sifra
) plan
order by plan.tip_proizvoda, plan.GOTOV_PR_POSGR, plan.gotov_pr_naziv

