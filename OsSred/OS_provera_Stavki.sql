select stavka,ident
from Os_dokument_stavka
where
tip=705
and godina = 2005
and dokument = 36
and stavka+1-stavka = 1
