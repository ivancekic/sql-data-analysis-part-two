CONNECT &usr/&pass@&sid;

--select * from PLANIRANJE_CIKLUS;
--
    insert into PLANIRANJE_CIKLUS (CIKLUS_ID, CIKLUS_GODINA, CIKLUS_NAZIV)
           values(&ciklus,&ciklus,'CIKLUS '|| to_char(&ciklus))
    ;

	exec    planiranje_package.planGenerisiTrajanje(&ciklus,1);--godisnji
	exec    planiranje_package.planGenerisiTrajanje(&ciklus,2);--kvartalni
	exec    planiranje_package.planGenerisiTrajanje(&ciklus,3);--mesecni
	exec    planiranje_package.planGenerisiTrajanje(&ciklus,4);--nedeljni
	exec    planiranje_package.planGenerisiTrajanje(&ciklus,5);--dnevni
	exec    planiranje_package.planGenerisiTrajanje(&ciklus,6);--tromesecni

    commit;

DISCONNECT;
