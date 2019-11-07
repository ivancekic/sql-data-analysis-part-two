SELECT
        ot.naziv, ot.invej_sifra, ot.jed_mere_invej, ot.firma
      , ot.sifra_firma, ot.jed_mere_firma, ot.magacin, ot.status, ot.mag
      , d.datum_dok, d.ocekivano
FROM
	(
		select d.datum_dok, d.org_deo, sd.proizvod
	     , nvl(sum(sd.kolicina-sd.realizovano),0) ocekivano
		from DOKUMENT@INVEJ d
		   , STAVKA_DOK@INVEJ sd
		where d.broj_dok = sd.broj_dok
		and d.vrsta_dok  = sd.vrsta_dok
		and d.godina     = sd.godina

--		and d.status in (0,1,3)
		and d.status in (1,3)

		and sd.vrsta_dok=2
		and (sd.kolicina-sd.realizovano)>0

		group by  d.datum_dok, sd.proizvod ,d.org_deo
	) d
    ,
    (
	   select
			  f.naziv
			, ot.*
			, m.iz01 mag

		from OTPREMA_PROIZVODI_FIRME@INVEJ ot
		   , MAPIRANJE@INVEJ m
		   , FIRME@INVEJ  f


		where ot.status = 1
		  and ot.firma  = m.ul02
		  and m.modul ='OTPREMA_KA_FIRMAMA'
		  and m.ul01 = 'MAG'

		  and ot.firma = f.id
    ) ot
WHERE d.org_deo  = ot.mag
  AND d.proizvod = ot.invej_sifra;
