SELECT Dok.DOKUMENT, Dok.TIP
FROM Os_Dokument_Stavka Stavka, Os_Dokument Dok
WHERE Dok.STATUS <= 3       -- radni, ili predraèun
  AND Dok.GODINA   = Stavka.GODINA
  AND Dok.VRSTA    = Stavka.VRSTA
  AND Dok.TIP      = Stavka.TIP
  AND Dok.DOKUMENT = Stavka.DOKUMENT
--  AND Dok.VRSTA    = NVL(cVrsta, 'OS')
  AND Stavka.IDENT = 21
