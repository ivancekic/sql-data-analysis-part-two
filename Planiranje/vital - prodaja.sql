select PLAN_TIP_ID,PLAN_CIKLUS_ID,PLAN_PERIOD_ID,PLAN_TRAJANJE_ID,BROJ_DOK,VARIJANTA_ID,GOTOV_PR_SIFRA,GOTOV_PR_NAZIV,GOTOV_PR_JM,GOTOV_PR_TIP
     , GOTOV_PR_TIP_NAZIV,GOTOV_PR_GRUPA,GOTOV_PR_SASTAVNICA,GOTOV_PR_SASTAVNICA_SARZA,GOTOV_PR_PLAN_ZELJENA_KOL,GOTOV_PR_PLANIRANA_PRODAJA
     , GOTOV_PR_OPTIMALNA_ZALIHA,GRUPA_PROIZVODA,GOTOV_PR_POS_GR,GOTOV_PR_POS_GR_NAZIV,GOTOV_PR_PROD_JM,GOTOV_PR_FAK_TREB,PROD_CENA
from
(
	SELECT PLAN_TIP_ID,PLAN_CIKLUS_ID,PLAN_PERIOD_ID,PLAN_TRAJANJE_ID,BROJ_DOK,VARIJANTA_ID,GOTOV_PR_SIFRA,GOTOV_PR_NAZIV,GOTOV_PR_JM
	     , GOTOV_PR_TIP,GOTOV_PR_TIP_NAZIV,GOTOV_PR_GRUPA,GOTOV_PR_SASTAVNICA,GOTOV_PR_SASTAVNICA_SARZA,GOTOV_PR_PLAN_ZELJENA_KOL
	     , GOTOV_PR_PLANIRANA_PRODAJA,GOTOV_PR_OPTIMALNA_ZALIHA,GRUPA_PROIZVODA
	     , gotov_pr_pos_gr
	     , gotov_pr_pos_gr_naziv
	     , gotov_pr_prod_JM
	     , gotov_pr_fak_treb
	     , PProdajniCenovnik.Cena(GOTOV_PR_SIFRA,to_date('01.09.2011','dd.mm.yyyy'),'YUD',1) prod_cena

	FROM
	(
	   select
	          ps.plan_tip_id
		    , ps.plan_ciklus_id
	        , ps.plan_period_id
		    , ps.plan_trajanje_id
		    , ps.broj_dok
		    , ps.varijanta_id

	        , ps.proizvod          gotov_pr_sifra
		    , p.naziv              gotov_pr_naziv
		    , p.jed_mere           gotov_pr_jm
	        , p.tip_proizvoda      gotov_pr_tip
	        , tp.naziv             gotov_pr_tip_naziv
	        ,
	          case when Pmapiranje.VLASNIK_CONN_STR = 'RUBIN' then
	             case when p.grupa_proizvoda = 323 then
	                  'GP-INO'
	             else
	                  'GP-DOM'
	             end
	          else
	              to_char(p.grupa_proizvoda)
	          end     gotov_pr_grupa

		    , ps.broj_sastavnice   gotov_pr_sastavnica
	        , sz.kolicina          gotov_pr_sastavnica_sarza

		    , ps.kolicina          gotov_pr_plan_zeljena_kol
	        , ps.planirana_prodaja gotov_pr_planirana_prodaja

	        , ps.optimalna_zaliha  gotov_pr_optimalna_zaliha

	        , p.grupa_proizvoda
	        , p.posebna_grupa      gotov_pr_pos_gr
	        , pg.naziv             gotov_pr_pos_gr_naziv
	        , p.prodajna_JM        gotov_pr_prod_JM
	        , p.faktor_trebovne    gotov_pr_fak_treb

	     from planiranje_stavka ps
	        , proizvod p
	        , sastavnica_zag sz
	        , tip_proizvoda tp
	        , posebna_grupa pg
		where
	          ps.plan_tip_id         = &c_tip_id
	      and ps.plan_ciklus_id      = &c_ciklus_id
	      and ps.plan_period_id      = &c_period_id
	      and ps.plan_trajanje_id    = &c_trajanje_id
	      and ps.broj_dok            = &c_broj_dok
	      and ps.varijanta_id        = &c_varijanta_id

	      and ps.proizvod            = p.sifra
	      and p.tip_proizvoda        = tp.sifra
	      and p.posebna_grupa = pg.grupa

	      and ps.broj_sastavnice     = sz.broj_dok (+)

	)
)
order by
case when Pmapiranje.VLASNIK_CONN_STR = 'RUBIN' then
          gotov_pr_grupa
     else
          GOTOV_PR_TIP
     end
, gotov_pr_pos_gr_naziv
, gotov_pr_prod_JM desc
, gotov_pr_fak_treb
, gotov_pr_naziv
