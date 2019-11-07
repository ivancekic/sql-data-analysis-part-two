select p.sifra, p.GRUPA_PROIZVODA, p.posebna_grupa, p.GRUPA_POREZA
     , pr.sifra, pr.GRUPA_PROIZVODA, pr.posebna_grupa, pr.GRUPA_POREZA
from PROIZVOD p, PROIZVOD_PRE_MUR pr

where p.sifra = pr.sifra
--  and p.GRUPA_POREZA <> pr.GRUPA_POREZA
--  and nvl(p.posebna_grupa,'-9876') <> nvl(pr.posebna_grupa,'-9876')
and p.GRUPA_PROIZVODA <> pr.GRUPA_PROIZVODA
