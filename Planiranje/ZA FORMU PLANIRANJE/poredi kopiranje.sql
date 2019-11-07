select ps.*,ps1.*
from
(
	Select ps.proizvod, sum(ps.KOLICINA) kol, sum(ps.OPTIMALNA_ZALIHA) opt_zal
	From planiranje_stavka ps
	Where
			      ps.plan_tip_id			= &c_tip_id
			  and ps.PLAN_CIKLUS_ID			= &c_ciklus_id
			  and ps.PLAN_period_ID			= &c_period_id
			  and ps.plan_trajanje_id		= &c_trajanje_id
			  and ps.broj_dok				in (&c_broj_dok)

	Group by ps.proizvod
	Order by to_number(ps.proizvod)
) ps
,
(
	Select ps.proizvod, sum(ps.KOLICINA) kol, sum(ps.OPTIMALNA_ZALIHA) opt_zal
	From planiranje_stavka ps
	Where
			      ps.plan_tip_id			= &c_tip_id
			  and ps.PLAN_CIKLUS_ID			= &c_ciklus_id
			  and ps.PLAN_period_ID			= &c_period_id
			  and ps.plan_trajanje_id		= &c_trajanje_id
			  and ps.broj_dok				in (&c_broj_dok1)

	Group by ps.proizvod
) ps1
Where ps.proizvod = ps1.proizvod
  and ps.kol<> ps1.kol
--  and ps.opt_zal<> ps1.opt_zal
Order by to_number(ps.proizvod)
