	Select PS.ROWID, PLAN_TIP_ID,PLAN_CIKLUS_ID,PLAN_PERIOD_ID,PLAN_TRAJANJE_ID,BROJ_DOK,VARIJANTA_ID,STAVKA_ID,PROIZVOD,BROJ_SASTAVNICE,KOLICINA,OPTIMALNA_ZALIHA,PLANIRANA_PRODAJA,STATUS_ID,KORISNIK,DATUM
	From planiranje_stavka@MEDELA ps
	Where
			      ps.plan_tip_id			= &c_tip_id
			  and ps.PLAN_CIKLUS_ID			= &c_ciklus_id
			  and ps.PLAN_period_ID			= &c_period_id
			  and ps.plan_trajanje_id		= &c_trajanje_id
			  and ps.broj_dok				in (&c_broj_dok)


	Order by to_number(ps.proizvod)
