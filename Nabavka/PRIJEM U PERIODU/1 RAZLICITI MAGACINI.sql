SELECT
       d.org_deo, od.naziv naziv_org
FROM dokument  d, organizacioni_deo od

WHERE d.godina = 2011
  and d.org_deo not in (select magacin from partner_magacin_flag)
  and d.vrsta_dok in (3,73)
--  AND D.ORG_DEO NOT BETWEEN 300 AND 517
  AND D.org_deo NOT IN (  103,104,105,106,107,108				-- GR i PP dom prodaja
                         ,123,124,125,126,127,128				-- GR i PP ino prodaja
                         ,133,134,135,136,137,138				-- evidentna ambalaza
                         ,153,154,155,156,157,158				-- povracaj robe kontrola
                         )
--  AND D.ORG_DEO NOT BETWEEN 113 AND 118							-- opsta nabavka za fabrike
--  AND D.ORG_DEO NOT in (680,690)								-- reality
--  and D.ORG_DEO NOT in  (90,91,92,97,161,163,185,186,201,202)	-- invejova roab u drugim firmama
--  And D.org_deo NOT in (99,102)									-- tranzitni magacini sir nabavke
--  And D.org_deo NOT in (100,101,151)							-- Opsta nabavka
--
--  And D.org_deo NOT in (146)						        -- tranzitni magacini nabavke
--
  and od.id = d.org_deo
Group by d.org_deo, od.naziv
Order by d.org_deo

