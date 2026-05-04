#!/usr/bin/env bash
for f in wf/human-largefov*/sub-*/epi_undistorted_masked.nii.gz;do 
  mask=$(dirname $f)/mean_epi_brain.nii.gz
  blur=${f/.nii.gz/_smooth4.nii.gz}
  skip-exist $blur \
   3dBlurToFWHM \
    -input $f -prefix __SKIPFILE \
    -mask $mask \
    -FWHM 4 

  skip-exist $(dirname $f)/angles_at_max_smooth4.nii.gz \
   ./angle_at_max.py -i $blur \
     -m $mask -o __SKIPFILE
done
