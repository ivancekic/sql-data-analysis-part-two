			       SELECT
			              k.datum, KUPAC_SIFRA, pp.naziv naziv_kupca
			            , KUPAC_MI, mi.NAZIV_KORISNIKA, mi.adresa, mi.adresa2, mi.polje1 									mesto_krace
			            , case when mi.polje1 is null Then 0 else 1 end 													mesto_krace_br
			       From poslovni_partner pp, mesto_isporuke mi, komerc_plan_prodaje@konsolid k
			       WHERE

			             pp.sifra = k.KUPAC_SIFRA
			         and mi.ppartner=pp.sifra and mi.sifra_mesta=k.KUPAC_MI
                     AND mi.polje1 IS NULL
                     AND K.DATUM BETWEEN  to_date('20.10.2011','dd.mm.yyyy') and to_date('31.10.2011','dd.mm.yyyy')
			    GROUP BY k.datum, k.KUPAC_SIFRA, pp.naziv, k.KUPAC_MI
			           , mi.NAZIV_KORISNIKA, mi.adresa, mi.adresa2, mi.polje1
			    ORDER BY k.datum, to_number(KUPAC_SIFRA), to_number(KUPAC_MI)
