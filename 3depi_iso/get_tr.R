#!/usr/bin/env Rscript
dcmdir <- Sys.getenv("DCMDIR","../Data/2026.03.24-16.41.55/26.03.24-16:37:16-DST-1.3.12.2.1107.5.2.43.67078/a_ep3d_bold_fid_2mm_R2x2--13_936x936.17")
cmd <- glue::glue("find {dcmdir} -type f -exec dicom_hinfo  -no_name -tag 0008,0032 {{}} \\+")
txt <- system(cmd,intern=T)
tm <- as.POSIXct(txt, format = "%H%M%OS", tz = "UTC")
sort(tm) |> diff() |>as.numeric() |> summary() |> print()

#   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#  2.137   2.138   2.140   2.139   2.140   2.140

# unzip -d /tmp/m13_20260225 ../Data/20260225-18_50_33/a_ep3d_bold_fid_2mm_R2x2\ -13/1.3.12.2.1107.5.2.43.167046.2026022519255611019539640.0.0.0.dicom.zip
#DCMDIR=/tmp/m13_20260225  ./get_tr.R 
#   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#  1.425   1.425   1.425   1.426   1.427   1.427
