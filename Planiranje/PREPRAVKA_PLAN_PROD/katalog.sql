select DOBAVLJAC,pp.naziv naziv_dobavljaca,PROIZVOD,NABAVNA_SIFRA,NABAVNI_NAZIV,CENA,VALUTA,KOL_CENA,JM_CENA,DATUM
     , RABAT,KOMENTAR,VALUTA_PLACANJA
from katalog k, poslovni_partner pp
where dobavljac in ('90','206','342','172','594','127','711','965','138','1138','1226')
  and proizvod = 3815
  and proizvod in (
                    Select proizvod
 				     from
				          planiranje_stavka ps
					where
					      ps.PLAN_CIKLUS_ID			= &c_ciklus_id
				      and ps.plan_tip_id			= &c_tip_id
					  and ps.PLAN_period_ID			= &c_period_id
				      and ps.plan_trajanje_id		= &c_trajanje_id

				      and ps.broj_dok				= &c_broj_dok
				      and ps.varijanta_id			= &c_varijanta_id

                )
  and pp.sifra = k.dobavljac
order by to_number(proizvod)
