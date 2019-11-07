select os2.ident, os.naziv, os.serijski_broj,
       os2.lokacija, os2.naziv lok_naziv,
       os2.org_deo_na, PORGANIZACIONIDEO.NAZIV(os2.ORG_DEO_NA) Org_NAZIV,
       os2.zaduzio, Pradnici.Podaci(os2.ZADUZIO) ZADUZIO_naziv
from OS_RASPORED2 os2, os_sredstvo os
where os.rev_grupa in( '102')
  and os.status = 'A'
--  and upper(os.skraceni_naziv) in (upper('racunar'), upper('monitor'))
--  and (    upper(os.naziv) like upper('%ESPRIMO%')
--        or upper(os.naziv) like upper('%A17-%')
--        or upper(os.naziv) like upper('%fujitsu%')
--      )
  and os2.ident = os.ident
Order by os2.ident
