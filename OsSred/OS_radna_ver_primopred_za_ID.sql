SELECT Dok.BROJ
FROM Os_Primopredaja Dok, Os_Primopredaja_Stavka Stavka
WHERE Dok.STATUS = 0    -- radni
  AND Dok.POSLOVNA_GODINA = Stavka.POSLOVNA_GODINA
  AND Dok.BROJ = Stavka.BROJ
  AND Stavka.IDENT = 21
