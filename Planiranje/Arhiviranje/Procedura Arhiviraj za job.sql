Declare
	cursor k0 is
		 select pz.*
		      , (
		            Select 1
		    		From planiranje_zaglavlje
				    Where PLAN_TIP_ID = pz.PLAN_TIP_ID
				      and PLAN_CIKLUS_ID = pz.plan_ciklus_id
				      and PLAN_PERIOD_ID = pz.plan_period_id
				      and PLAN_TRAJANJE_ID = pz.plan_trajanje_id
				      and BROJ_DOK = -1 * pz.broj_dok
		        ) ima_arhivu
		 from planiranje_zaglavlje pz


		where nvl(
					(
			            Select 1
			    		From planiranje_zaglavlje
					    Where PLAN_TIP_ID = pz.PLAN_TIP_ID
					      and PLAN_CIKLUS_ID = pz.plan_ciklus_id
					      and PLAN_PERIOD_ID = pz.plan_period_id
					      and PLAN_TRAJANJE_ID = pz.plan_trajanje_id
					      and BROJ_DOK = -1 * pz.broj_dok
					)
					,-1
				)=-1

		For Update Of STATUS_ID;
	kk0 k0 % rowtype;
--    nTrebaCommit Number;
	p_poruka Varchar2(200);
Begin          
--	nTrebaCommit := 0;
	Open k0;
	Loop
	Fetch k0 into kk0;
	Exit When k0 % notfound;
		planiranje_package.ArhivirajPlan(	 kk0.plan_tip_id      
											,kk0.plan_ciklus_id   
											,kk0.plan_period_id   
											,kk0.plan_trajanje_id 
											,kk0.broj_dok  
											,p_poruka
                          )
		
	End Loop;
	Close k0;            
	
--	if 	nTrebaCommit = 1 Then
--	
--	end if;
End;
