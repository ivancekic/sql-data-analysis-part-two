Select zag.broj_dok , zag.proizvod ,
       sum(st.kolicina),
       p.posebna_grupa, pposebnagrupa.naziv(p.posebna_grupa) st_pg_naziv,
--       pproizvod.posgrupa(st.proizvod) st_pg, pposebnagrupa.naziv(pproizvod.posgrupa(st.proizvod)) st_pg_naziv
       p.grupa_proizvoda , pgrupaproizvoda.naziv(p.grupa_proizvoda) st_g_naziv
from sastavnica_zag zag , sastavnica_stavka st , proizvod p
where zag.proizvod = 1
  and st.broj_dok  = zag.broj_dok
  and st.GODINA    = zag.godina
  and st.proizvod  = p.sifra

group by zag.broj_dok , zag.proizvod ,
       --  pproizvod.posgrupa(st.proizvod),
       p.posebna_grupa,p.grupa_proizvoda

order by to_number(zag.broj_dok),to_number(zag.proizvod) ,  p.posebna_grupa , p.grupa_proizvoda

