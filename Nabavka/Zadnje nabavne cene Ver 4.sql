Select C1,C2,C3,C4,C5
		,
		case when c2!='PRO' Then
		(
		    select sd2.cena
		    from dokument d2, stavka_dok sd2
		    where
		           d2.vrsta_dok = '3' and d2.tip_dok in ('10','16') and d2.status in ('1','5') and to_char(d2.org_deo) = c4
		       and (d2.datum_dok,d2.datum_unosa) in
		         (
		           select max(d1.datum_dok), max(d1.datum_unosa)
		             from dokument   d1, stavka_dok sd1
		            where d1.vrsta_dok = '3' and d1.tip_dok in ('10','16') and d1.status in ('1','5') and to_char(d1.org_deo) = c4
		              and d1.broj_dok  = sd1.broj_dok and d1.vrsta_dok = sd1.vrsta_dok and d1.godina    = sd1.godina
		              and sd1.proizvod = c2

		          )
		       and (d2.broj_dok,d2.vrsta_dok,d2.godina)
		            not in (select vd2.broj_dok,vd2.vrsta_dok,vd2.godina from vezni_dok vd2 where vd2.za_vrsta_dok = '3')
		       and d2.broj_dok  = sd2.broj_dok and d2.vrsta_dok = sd2.vrsta_dok and d2.godina    = sd2.godina
		       and sd2.vrsta_dok = '3' and sd2.proizvod = c2
		    )


end znc

from report_tmp_pdf
order by c1, c2, c4
