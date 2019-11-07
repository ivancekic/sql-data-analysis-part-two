--09.10 ned 	1		uto
--10.10 pon		2		sre
--11.10 uto		3		cet
--12.10 sre		4		pet
--13.10 cet		5		pon(sub)
--14.10 pet 	6		pon(ned)
--15.10 sub 	7		pon

SELECT
         &DATUM TEK_DAT
     ,   TO_CHAR(&DATUM,'D') 		DAN_POSETE_D
     ,   TO_CHAR(&DATUM,'Day')		DAN_POSETE_DAY

     ,   &DATUM + 2 				DAN_POSETE_2
     ,   TO_CHAR(&DATUM + 2,'D')	DAN_POSETE_2_D
     ,   TO_CHAR(&DATUM + 2,'Day')	DAN_POSETE_2_DAY

     ,   DECODE(TO_CHAR(&DATUM + 2,'D'), 1, &DATUM + 3
                                       , 2, &DATUM + 3
                                       ,    &DATUM + 2
               ) 					DAN_POSETE_2_KORIGUJ

     ,   TO_CHAR(DECODE(TO_CHAR(&DATUM + 2,'D')
                                       , 1, &DATUM + 3
                                       , 2, &DATUM + 3
                                       ,    &DATUM + 2
               ),'Day') DAN_POSETE_2_DAY_KORIGUJ

FROM DUAL
--Datum_Unosa - 0.00001
