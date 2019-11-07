			       SELECT P.POSEBNA_GRUPA, PGG.GRUPNI_NAZIV

			       From PROIZVOD P
			          , (select * from POSEBNA_GRUPA_GRUPNO where firma = 1) pgg
			          , komerc_plan_prodaje@konsolid k
			       WHERE
			             p.sifra = k.proizvod
			         AND P.POSEBNA_GRUPA = PGG.GRUPA (+)
			         AND K.DATUM BETWEEN  to_date('20.10.2011','dd.mm.yyyy') and to_date('11.11.2011','dd.mm.yyyy')
                     AND PGG.GRUPNI_NAZIV IS NULL
                  GROUP BY P.POSEBNA_GRUPA, PGG.GRUPNI_NAZIV
