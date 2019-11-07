
--Create table ZALIHE_GOD_MAG_DATUMI
--as
select * from
(
Select d.org_deo, d.godina, sd.proizvod
	    , (Select max(to_date(d1.datum_dok)) From dokument d1
		   Where d1.vrsta_Dok = '21' And d1.Status = 1 And d1.org_Deo = d.org_Deo
		     and d1.godina = d.godina
		  --   and
	      )  max_dat_ps
	    , (Select min(to_date(d1.datum_dok)) From dokument d1
		   Where d1.vrsta_Dok != '21' And d1.Status = 1 And
		   d1.org_Deo = d.org_Deo
		     and d1.godina = d.godina
		     and d1.datum_dok > to_date('31.12.1995','dd.mm.yyyy')
	      )  min_dat_dok
        , (Select MAX(to_date(d1.datum_dok)) From dokument d1
		   Where d1.vrsta_Dok != '21' And d1.Status = 1 And d1.org_Deo = d.org_Deo
		     and d1.godina = d.godina
		     and d1.datum_dok > to_date('31.12.1995','dd.mm.yyyy')
	      )  max_dat_dok


From Dokument d, stavka_Dok sd
Where d.godina = sd.godina and d.vrsta_dok = sd.vrsta_dok and d.broj_dok = sd.broj_dok
  and d.status > 0
  and d.org_Deo not in (select magacin from partner_magacin_flag)
  and k_robe <> 0
Group by d.godina, d.org_deo, sd.proizvod
)
--where godina= 2006
--Order by org_deo, to_number(proizvod), godina
Order by org_deo, godina, to_number(proizvod)
