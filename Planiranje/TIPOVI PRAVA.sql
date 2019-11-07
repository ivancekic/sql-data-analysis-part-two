select TIP_ID_IZ, PTI.TIP_NAZIV
     , TIP_ID_U,PTU.TIP_NAZIV
from planiranje_tip_kopi_prava PK
   , PLANIRANJE_TIP PTI
   , PLANIRANJE_TIP PTU
Where tip_id_iz=PTI.TIP_ID
  AND tip_id_U=PTU.TIP_ID
ORDER BY TIP_ID_IZ,TIP_ID_U
