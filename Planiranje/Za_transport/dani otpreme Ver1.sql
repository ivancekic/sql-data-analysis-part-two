--09.10 ned 	1		uto
--10.10 pon		2		sre
--11.10 uto		3		cet
--12.10 sre		4		pet
--13.10 cet		5		pon(sub)
--14.10 pet 	6		pon(ned)
--15.10 sub 	7		pon
declare
  dDat Date := to_date('09.10.2011','dd.mm.yyyy');

  Cursor podaci_cur is
     Select
		         dDat TEK_DAT
		     ,   TO_CHAR(dDat,'D') 		DAN_POSETE_D
		     ,   TO_CHAR(dDat,'Day')		DAN_POSETE_DAY

		     ,   dDat + 2 				DAN_POSETE_2
		     ,   TO_CHAR(dDat + 2,'D')	DAN_POSETE_2_D
		     ,   TO_CHAR(dDat + 2,'Day')	DAN_POSETE_2_DAY

		     ,   DECODE(TO_CHAR(dDat + 2,'D'), 1, dDat + 3
		                                       , 2, dDat + 3
		                                       ,    dDat + 2
		               ) 					DAN_POSETE_2_KORIGUJ

		     ,   TO_CHAR(DECODE(TO_CHAR(dDat + 2,'D')
		                                       , 1, dDat + 3
		                                       , 2, dDat + 3
		                                       ,    dDat + 2
		               ),'Day') DAN_POSETE_2_DAY_KORIGUJ
     From Dual
               ;

  podaci podaci_cur % Rowtype;
--  SITAN SITAN_CUR % ROWTYPE;

Begin
  Dbms_output.put_line(rpad('TEK_DAT',10||' '||
                       rpad('Dan',3)    ||' '||
                       rpad('DAY',7)    ||' '||
                       DAN_POSETE_2     ||' '||
                       DAN_POSETE_2_D   ||' '||
                       DAN_POSETE_2_DAY ||' '||
                       DAN_POSETE_2_KORIGUJ ||' '||
                       DAN_POSETE_2_DAY_KORIGUJ
                     )
  while dDat <  to_date('16.10.2011','dd.mm.yyyy')
  Loop
     Open Podaci_cur;
     Fetch Podaci_cur Into Podaci;
                      null;
     Close Podaci_cur;
     dDat := dDat + 1;
  End Loop;

End;
