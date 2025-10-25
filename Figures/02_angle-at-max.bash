mkdir -p angle-at-max/
# ../FmapCorrect/01b_proc-10a.sh runs:
# ./angle_at_max.py -i wf/human-largefov/sub-1/epi_undistorted_masked.nii.gz -m wf/human-largefov/sub-1/mean_epi_brain.nii.gz -o wf/human-largefov/sub-1/angles_at_max.nii.gz
# creates $fmapsub1/angles_at_max.nii.gz

fmapsub1=../FmapCorrect/wf/human-largefov/sub-1
test -r angle-at-max/sub1_nosd.nii.gz ||
 ../FmapCorrect/angle_at_max.py \
   -i $fmapsub1/epi_undistorted_masked.nii.gz \
   -m $fmapsub1/mean_epi_brain.nii.gz \
   -l ../FmapCorrect/angle.txt \
   --nosd \
   -o $_

slicer_big(){ slice -a >(gm convert -scale 200% - "$1") "$2"; }

slicer_big angle-at-max/sub-1_aam-nosd.png  angle-at-max/sub1_nosd.nii.gz
slicer_big angle-at-max/sub-1_aam.png  $fmapsub1/angles_at_max.nii.gz
slicer_big angle-at-max/sub-1_phasediff.png ../FmapCorrect/wf/human-largefov/sub-1/sub-1_acq-largefov_phasediff.nii.gz
