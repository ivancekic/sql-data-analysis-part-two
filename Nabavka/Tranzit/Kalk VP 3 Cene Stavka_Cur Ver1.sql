										 select st.STAVKA,
														st.PROIZVOD,
														st.NAZIV,
														st.JED_MERE,
														st.PDV_STOPA,
														st.KOLICINA,
														st.CENA,
														st.IZNOS,

														st.PROC_RABATA,
														st.PROC_KASE,

														st.RABAT+st.KASA RABAT_KASA,
														st.OSNOVICA,
														st.PDV PDV_IZNOS,
														st.osnovica+st.pdv FAKT_VREDNOST,

														st.Z_TROSKOVI,
														ST.VP_VREDNOST-ST.OSNOVICA-ST.Z_troskovi raz_u_ceni,
														st.VP_VREDNOST,
														st.VPCENA

											 from (
														 SELECT
																		st.stavka,
																		st.proizvod,
																		p.naziv,
																		st.jed_mere,
																		st.kolicina,
--																		st.cena,

CASE WHEN &cNewValuta <> st.Valuta Then
						            Case When &cBrDecimalaCena = 2 or  &cBrDecimalaCena = -2 Then
									          round(nvl(Cena,0) * Pkurs.KursNaDan(st.valuta, d.datum_dok, 'S'),2)
 						            else
                                              case when D.Datum_dok < to_date('01.01.2012','dd.mm.yyyy') and d.PPartner = 138 Then
									             round(nvl(Cena,0) * Pkurs.KursNaDan(st.valuta, d.datum_dok, 'S'),2)

                                              Else
									             round(nvl(Cena,0) * Pkurs.KursNaDan(st.valuta, d.datum_dok, 'S'),4)
									          end
						            End
ELSE
        ST.CENA
END																		CENA,




																		ROUND(st.cena1 * ST.FAKTOR, 4) VPCENA,
																		st.rabat proc_rabata,
																		nvl(d.kasa,0) proc_kase,
																		nvl(st.z_troskovi,0) z_troskovi,
																		---------------------------------------------------------------------------------------------------------------
--																		round(NVL(st.Kolicina * st.K_Robe*st.Cena,0),2)
                     Case When D.Datum_dok >= &dDatumVeci Then
                          Case When upper(VratiTipIzvoza(D.Org_Deo)) = 'DA' Then
						       Case When &cNewValuta = 'YUD' And &cNewValuta <> st.Valuta Then
						            Case When &cBrDecimalaCena = 2 or  &cBrDecimalaCena = -2 Then
									          round(NVL(st.Kolicina * st.K_Robe *
 									                                                    round(nvl(Cena,0) * Pkurs.KursNaDan(st.valuta, &dDatumDok, 'S'),2)
									                    ,0),2)
 						            else
                                              case when D.Datum_dok < to_date('01.01.2012','dd.mm.yyyy') and d.PPartner = 138 Then
									          round(NVL(st.Kolicina * st.K_Robe*
 									                                                    round(nvl(Cena,0) * Pkurs.KursNaDan(st.valuta, &dDatumDok, 'S'),2)
									                    ,0),2)

                                              Else
									             round(NVL(st.Kolicina * st.K_Robe*
 									                                                    round(nvl(Cena,0) * Pkurs.KursNaDan(st.valuta, &dDatumDok, 'S'),4)
									                    ,0),2)
									          end
						            End
                               else
                                    round(NVL(st.Kolicina * st.K_Robe*st.Cena,0),2)
						       End
						   else
                               round(NVL(st.Kolicina * st.K_Robe*st.Cena,0),2)
                           End
                     Else
  						  round(NVL(st.Kolicina * st.K_Robe*st.Cena,0),2)
                     End
																		IZNOS,
																		---------------------------------------------------------------------------------------------------------------
--																		round(nvl(st.Kolicina * st.K_Robe*st.Cena*(st.Rabat/100),0),2)
                     Case When D.Datum_dok >= &dDatumVeci  Then
                          Case When upper(VratiTipIzvoza(D.Org_Deo)) = 'DA' Then
						       Case When &cNewValuta = 'YUD' And &cNewValuta <> st.Valuta Then
						            Case When &cBrDecimalaCena = 2 or  &cBrDecimalaCena = -2 Then
                                              round(nvl(st.Kolicina * st.K_Robe *
                                                                    round(nvl(Cena,0) * Pkurs.KursNaDan(st.valuta, &dDatumDok, 'S'),2) *
                                                                    (st.Rabat/100),0),2)
 						            else
                                              round(nvl(st.Kolicina * st.K_Robe *
                                                                    round(nvl(Cena,0) * Pkurs.KursNaDan(st.valuta, &dDatumDok, 'S'),4) *
                                                                    (st.Rabat/100),0),2)
						            End
                               else
                                    round(nvl(st.Kolicina * st.K_Robe*st.Cena*(st.Rabat/100),0),2)
						       End
						   else
                               round(nvl(st.Kolicina * st.K_Robe*st.Cena*(st.Rabat/100),0),2)
                           End
                     Else
  						  round(nvl(st.Kolicina * st.K_Robe*st.Cena*(st.Rabat/100),0),2)
                     End

																		RABAT,
																		---------------------------------------------------------------------------------------------------------------
--																		round(nvl(st.Kolicina * st.K_Robe*st.Cena*(1-st.Rabat/100),0) *
--																		         (CASE WHEN nvl(ST.RABAT,0)<>0 THEN
--																							nvl(d.kasa,0)/100
--																				  ELSE
--																				       0
--                                                                                  END),2)
                     Case When D.Datum_dok >= &dDatumVeci  Then
                          Case When upper(VratiTipIzvoza(D.Org_Deo)) = 'DA' Then
						       Case When &cNewValuta = 'YUD' And &cNewValuta <> st.Valuta Then
						            Case When &cBrDecimalaCena = 2 or  &cBrDecimalaCena = -2 Then

																		round(nvl(st.Kolicina * st.K_Robe *
                                                                                  round(nvl(Cena,0) * Pkurs.KursNaDan(st.valuta, &dDatumDok, 'S'),2) *
																		         (1-st.Rabat/100),0) *
																		         (CASE WHEN nvl(ST.RABAT,0)<>0 THEN
																							nvl(d.kasa,0)/100
																				  ELSE
																				       0
                                                                                  END),2)
 						            else

																		round(nvl(st.Kolicina * st.K_Robe *
																		             round(nvl(Cena,0) * Pkurs.KursNaDan(st.valuta, &dDatumDok, 'S'),2) *
																		             (1-st.Rabat/100),0) *
																		         (CASE WHEN nvl(ST.RABAT,0)<>0 THEN
																							nvl(d.kasa,0)/100
																				  ELSE
																				       0
                                                                                  END),2)
						            End
                               else

																		round(nvl(st.Kolicina * st.K_Robe*st.Cena*(1-st.Rabat/100),0) *
																		         (CASE WHEN nvl(ST.RABAT,0)<>0 THEN
																							nvl(d.kasa,0)/100
																				  ELSE
																				       0
                                                                                  END),2)
						       End
						   else

																		round(nvl(st.Kolicina * st.K_Robe*st.Cena*(1-st.Rabat/100),0) *
																		         (CASE WHEN nvl(ST.RABAT,0)<>0 THEN
																							nvl(d.kasa,0)/100
																				  ELSE
																				       0
                                                                                  END),2)
                           End
                     Else

																		round(nvl(st.Kolicina * st.K_Robe*st.Cena*(1-st.Rabat/100),0) *
																		         (CASE WHEN nvl(ST.RABAT,0)<>0 THEN
																							nvl(d.kasa,0)/100
																				  ELSE
																				       0
                                                                                  END),2)
                     End

																		KASA,
																		---------------------------------------------------------------------------------------------------------------
--																		round(NVL(st.Kolicina * st.K_Robe*st.Cena,0),2)
--																						-
--																		round(nvl(st.Kolicina * st.K_Robe*st.Cena*(st.Rabat/100),0),2)
--																						-
--																		round(nvl(st.Kolicina * st.K_Robe*st.Cena*(1-st.Rabat/100),0) *
--																		               (CASE WHEN nvl(ST.RABAT,0)<>0 THEN
--																						          nvl(d.kasa,0)/100
--																						ELSE
--																						     0
--																						END),2)
                     Case When D.Datum_dok >= &dDatumVeci  Then
                          Case When upper(VratiTipIzvoza(D.Org_Deo)) = 'DA' Then
						       Case When &cNewValuta = 'YUD' And &cNewValuta <> st.Valuta Then
						            Case When &cBrDecimalaCena = 2 or  &cBrDecimalaCena = -2 Then
																		round(NVL(st.Kolicina * st.K_Robe *
																		round(nvl(Cena,0) * Pkurs.KursNaDan(st.valuta, &dDatumDok, 'S'),2)
																		,0),2)
																						-
																		round(nvl(st.Kolicina * st.K_Robe *
																		round(nvl(Cena,0) * Pkurs.KursNaDan(st.valuta, &dDatumDok, 'S'),2) *
																		(st.Rabat/100),0),2)
																						-
																		round(nvl(st.Kolicina * st.K_Robe *
																		round(nvl(Cena,0) * Pkurs.KursNaDan(st.valuta, &dDatumDok, 'S'),2) *
																		(1-st.Rabat/100),0) *
																		               (CASE WHEN nvl(ST.RABAT,0)<>0 THEN
																						          nvl(d.kasa,0)/100
																						ELSE
																						     0
																						END),2)
 						            else
																		round(NVL(st.Kolicina * st.K_Robe *
																		round(nvl(Cena,0) * Pkurs.KursNaDan(st.valuta, &dDatumDok, 'S'),4)
																		,0),2)
																						-
																		round(nvl(st.Kolicina * st.K_Robe *
																		round(nvl(Cena,0) * Pkurs.KursNaDan(st.valuta, &dDatumDok, 'S'),4) *
																		(st.Rabat/100),0),2)
																						-
																		round(nvl(st.Kolicina * st.K_Robe *
																		round(nvl(Cena,0) * Pkurs.KursNaDan(st.valuta, &dDatumDok, 'S'),4) *
																		(1-st.Rabat/100),0) *
																		               (CASE WHEN nvl(ST.RABAT,0)<>0 THEN
																						          nvl(d.kasa,0)/100
																						ELSE
																						     0
																						END),2)							            End
                               else
																		round(NVL(st.Kolicina * st.K_Robe*st.Cena,0),2)
																						-
																		round(nvl(st.Kolicina * st.K_Robe*st.Cena*(st.Rabat/100),0),2)
																						-
																		round(nvl(st.Kolicina * st.K_Robe*st.Cena*(1-st.Rabat/100),0) *
																		               (CASE WHEN nvl(ST.RABAT,0)<>0 THEN
																						          nvl(d.kasa,0)/100
																						ELSE
																						     0
																						END),2)
						       End
						   else
																		round(NVL(st.Kolicina * st.K_Robe*st.Cena,0),2)
																						-
																		round(nvl(st.Kolicina * st.K_Robe*st.Cena*(st.Rabat/100),0),2)
																						-
																		round(nvl(st.Kolicina * st.K_Robe*st.Cena*(1-st.Rabat/100),0) *
																		               (CASE WHEN nvl(ST.RABAT,0)<>0 THEN
																						          nvl(d.kasa,0)/100
																						ELSE
																						     0
																						END),2)
                           End
                     Else
																		round(NVL(st.Kolicina * st.K_Robe*st.Cena,0),2)
																						-
																		round(nvl(st.Kolicina * st.K_Robe*st.Cena*(st.Rabat/100),0),2)
																						-
																		round(nvl(st.Kolicina * st.K_Robe*st.Cena*(1-st.Rabat/100),0) *
																		               (CASE WHEN nvl(ST.RABAT,0)<>0 THEN
																						          nvl(d.kasa,0)/100
																						ELSE
																						     0
																						END),2)
                     End

																		OSNOVICA,
																		---------------------------------------------------------------------------------------------------------------
																		st.porez
																		PDV_STOPA,
																		---------------------------------------------------------------------------------------------------------------
--																		ROUND(
--																					(round(NVL(st.Kolicina * st.K_Robe*st.Cena,0),2)
--																									-
--																					round(nvl(st.Kolicina * st.K_Robe*st.Cena*(st.Rabat/100),0),2)
--																									-
--																					round(nvl(st.Kolicina * st.K_Robe*st.Cena*(1-st.Rabat/100),0) *
--																					                      (CASE WHEN nvl(ST.RABAT,0)<>0 THEN
--																					                                 nvl(d.kasa,0)/100
--																					                       ELSE
--																											    0
--  																										   END),2)
--																					 ) * ST.POREZ/100
-- 																			 ,2)
                     Case When D.Datum_dok >= &dDatumVeci  Then
                          Case When upper(VratiTipIzvoza(D.Org_Deo)) = 'DA' Then
						       Case When &cNewValuta = 'YUD' And &cNewValuta <> st.Valuta Then
						            Case When &cBrDecimalaCena = 2 or  &cBrDecimalaCena = -2 Then
																		ROUND(
																				(round(NVL(st.Kolicina * st.K_Robe *
																				           round(nvl(Cena,0) * Pkurs.KursNaDan(st.valuta, &dDatumDok, 'S'),2)
																				           ,0),2)
																									-
																			 	 round(nvl(st.Kolicina * st.K_Robe *
																			 	           round(nvl(Cena,0) * Pkurs.KursNaDan(st.valuta, &dDatumDok, 'S'),2) *
																			 	                 (st.Rabat/100)
																			 	           ,0),2)
																									-
																				 round(nvl(st.Kolicina * st.K_Robe *
																				           round(nvl(Cena,0) * Pkurs.KursNaDan(st.valuta, &dDatumDok, 'S'),2) *
																				           (1-st.Rabat/100),0) *
																					                      (CASE WHEN nvl(ST.RABAT,0)<>0 THEN
																					                                 nvl(d.kasa,0)/100
																					                       ELSE
																											    0
  																										   END),2)
																				 ) * ST.POREZ/100
 																			 ,2)
 						            else
																		ROUND(
																				(round(NVL(st.Kolicina * st.K_Robe *
																				           round(nvl(Cena,0) * Pkurs.KursNaDan(st.valuta, &dDatumDok, 'S'),4)
																				           ,0),2)
																									-
																			 	 round(nvl(st.Kolicina * st.K_Robe *
																			 	           round(nvl(Cena,0) * Pkurs.KursNaDan(st.valuta, &dDatumDok, 'S'),4) *
																			 	                 (st.Rabat/100)
																			 	           ,0),2)
																									-
																				 round(nvl(st.Kolicina * st.K_Robe *
																				           round(nvl(Cena,0) * Pkurs.KursNaDan(st.valuta, &dDatumDok, 'S'),4) *
																				           (1-st.Rabat/100),0) *
																					                      (CASE WHEN nvl(ST.RABAT,0)<>0 THEN
																					                                 nvl(d.kasa,0)/100
																					                       ELSE
																											    0
  																										   END),2)
																				 ) * ST.POREZ/100
 																			 ,2)

						            End
                               else
																		ROUND(
																					(round(NVL(st.Kolicina * st.K_Robe*st.Cena,0),2)
																									-
																					round(nvl(st.Kolicina * st.K_Robe*st.Cena*(st.Rabat/100),0),2)
																									-
																					round(nvl(st.Kolicina * st.K_Robe*st.Cena*(1-st.Rabat/100),0) *
																					                      (CASE WHEN nvl(ST.RABAT,0)<>0 THEN
																					                                 nvl(d.kasa,0)/100
																					                       ELSE
																											    0
  																										   END),2)
																					 ) * ST.POREZ/100
 																			 ,2)

						       End
						   else
																		ROUND(
																					(round(NVL(st.Kolicina * st.K_Robe*st.Cena,0),2)
																									-
																					round(nvl(st.Kolicina * st.K_Robe*st.Cena*(st.Rabat/100),0),2)
																									-
																					round(nvl(st.Kolicina * st.K_Robe*st.Cena*(1-st.Rabat/100),0) *
																					                      (CASE WHEN nvl(ST.RABAT,0)<>0 THEN
																					                                 nvl(d.kasa,0)/100
																					                       ELSE
																											    0
  																										   END),2)
																					 ) * ST.POREZ/100
 																			 ,2)

                           End
                     Else
																		ROUND(
																					(round(NVL(st.Kolicina * st.K_Robe*st.Cena,0),2)
																									-
																					round(nvl(st.Kolicina * st.K_Robe*st.Cena*(st.Rabat/100),0),2)
																									-
																					round(nvl(st.Kolicina * st.K_Robe*st.Cena*(1-st.Rabat/100),0) *
																					                      (CASE WHEN nvl(ST.RABAT,0)<>0 THEN
																					                                 nvl(d.kasa,0)/100
																					                       ELSE
																											    0
  																										   END),2)
																					 ) * ST.POREZ/100
 																			 ,2)

                     End
																	    PDV,
																		---------------------------------------------------------------------------------------------------------------
																						round(NVL(st.Kolicina * st.K_Robe*ROUND(st.Cena1*ST.FAKTOR,4),0),2)
																		VP_VREDNOST
																		---------------------------------------------------------------------------------------------------------------

															 FROM Dokument d, Stavka_Dok st, proizvod p
															WHERE d.vrsta_dok = st.vrsta_dok
																and d.godina    = st.godina
																and d.broj_dok  = st.broj_dok
																and st.proizvod = p.sifra
																------------------------------------------------------------
																and d.vrsta_dok = '73'
																and d.godina    = &nGodina
																and d.broj_dok  = &cBrojDok
																------------------------------------------------------------
															ORDER By stavka
														 ) st;
