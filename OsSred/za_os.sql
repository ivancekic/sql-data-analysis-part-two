
declare
 pera number;
 zika number;
begin

zika:= POsGrAmortizacija.Amortizacija_Sredstva( '5316',
                                                sysdate,
                                                pera );

dbms_output.put_line              ('funkcija vraca  otp. vrednost');
dbms_output.put_line              ('--------------  -------------');
dbms_output.put_line (to_char(zika,'999999999.999')||' '||to_char(nvl(pera,0),'999999999.999'));

end;
