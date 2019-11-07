Select zag.broj_dok , zag.proizvod, pproizvod.posgrupa(zag.proizvod) zag_pg, pposebnagrupa.naziv(pproizvod.posgrupa(zag.proizvod)) zag_pg_naziv,
       st.STAVKA, st.PROIZVOD,st.KOLICINA, st.JED_MERE, st.SKART ,
       pproizvod.posgrupa(st.proizvod) st_pg , pposebnagrupa.naziv(pproizvod.posgrupa(st.proizvod)) st_pg_naziv
from sastavnica_zag zag , sastavnica_stavka st
where zag.proizvod = 1
  and st.broj_dok  = zag.broj_dok
  and st.GODINA    = zag.godina
order by to_number(zag.broj_dok),to_number(zag.proizvod)
