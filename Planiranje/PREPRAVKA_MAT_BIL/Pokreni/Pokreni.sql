delete report_tmp_pdf;
Exec PLANIRANJE_MATBILANS_TEST_XLS.MatBilXLS (
                           &p_tip_id
                         , &p_ciklus_id
                         , &p_period_id
                         , &p_trajanje_id
                         , &p_broj_dok

                         , &p_org_deo_id
                         , &p_broj_dok1

                         , &p_varijanta_id
                         , &p_status_varijanta

                         , &p_vrsta_izvestaja

                         , &p_sastavnice_u_gppp
                         , &p_sastavnice_u_gppp_detalji
                         , &p_materijal_u_gppp
                         , &p_stanje_magacini
                         , &p_ocekivane_datumi
                         , &p_rezervisane_planovi

                         , &p_prikazi_pp_u_stavkama_mat

                         , &p_tip_izvestaja             --0=plan materijala - kolicine, &1=plan materijala - kolicine + cene

                         , &p_plan_zbir_podperioda

                         , &p_samo_overeni

                         );
