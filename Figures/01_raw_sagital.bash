#!/usr/bin/env bash
set -x
mkdir -p raw
# slicer -t -x .5 >(gm convert -scale 200% - raw/raw-sag_angle-20_sbref.png) ../Data/bids-a10/sub-1/func/sub-1_task-rest20_sbref.nii.gz
# slicer -t -x .5 >(gm convert -scale 200% - raw/raw-sag_angle-40_sbref.png) ../Data/bids-a10/sub-1/func/sub-1_task-restn39_sbref.nii.gz

slicer -t -z .5 >(gm convert -scale 200% - raw/raw-axl_angle-20_sbref.png) ../Data/bids-a10/sub-1/func/sub-1_task-rest20_sbref.nii.gz
slicer -t -z .5 >(gm convert -scale 200% - raw/raw-axl_angle-n40_sbref.png) ../Data/bids-a10/sub-1/func/sub-1_task-restn39_sbref.nii.gz

3dcalc -a ../FmapCorrect/wf/resliced.nii.gz'[0]' -expr a -overwrite -prefix /tmp/resliced-neg40.nii.gz
3dcalc -a ../FmapCorrect/wf/resliced.nii.gz'[9]' -expr a -overwrite -prefix /tmp/resliced-20.nii.gz
slicer -u -t -z .5 >(gm convert -scale 200% - raw/resliced-axl_angle-n40_resliced.png) /tmp/resliced-neg40.nii.gz 
slicer -u -t -z .5 >(gm convert -scale 200% - raw/resliced-axl_angle-20_resliced.png) /tmp/resliced-20.nii.gz

3dcalc -a ../FmapCorrect/wf/epi_undistored_masked.nii.gz'[0]' -expr a -overwrite -prefix /tmp/prelude-neg40.nii.gz
3dcalc -a ../FmapCorrect/wf/epi_undistored_masked.nii.gz'[9]' -expr a -overwrite -prefix /tmp/prelude-20.nii.gz
slicer -u -z .5 >(gm convert -scale 200% - raw/corrected-axl_angle-n40_bold.png) /tmp/prelude-neg40.nii.gz 
slicer -u -z .5 >(gm convert -scale 200% - raw/corrected-axl_angle-20_bold.png) /tmp/prelude-20.nii.gz

gm montage -geometry +0+0 -background none raw/raw-axl_angle-{n40,20}_sbref.png raw/raw-axl_angle-n40_20_sbref.png
gm montage -geometry +0+0 -background none raw/resliced-axl_angle-{n40,20}_resliced.png raw/resliced-axl_angle-n40_20_resliced.png  
gm montage -geometry +0+0 -background none raw/corrected-axl_angle-{n40,20}_bold.png raw/corrected-axl_angle-n40_20_bold.png  

slicer /tmp/resliced-20.nii.gz /tmp/prelude-20.nii.gz  -u  -z .5 >(gm convert -scale 200% - raw/corrected-axl_angle-20_sdc-over-reslice.png) 
slicer /tmp/resliced-neg40.nii.gz /tmp/prelude-neg40.nii.gz  -u  -z .5 >(gm convert -scale 200% - raw/corrected-axl_angle-n40_sdc-over-reslice.png) 
gm montage -geometry +0+0 -background none raw/corrected-axl_angle-{n40,20}_sdc-over-reslice.png raw/corrected-axl_angle-n40_20_sdc-over-reslice.png  
