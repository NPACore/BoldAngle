mkdir -p raw
slicer -t -x .5 >(gm convert -scale 200% - raw/raw-sag_angle-20_sbref.png) ../Data/bids-a10/sub-1/func/sub-1_task-rest20_sbref.nii.gz
slicer -t -x .5 >(gm convert -scale 200% - raw/raw-sag_angle-40_sbref.png) ../Data/bids-a10/sub-1/func/sub-1_task-restn39_sbref.nii.gz
