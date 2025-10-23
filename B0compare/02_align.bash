#!/usr/bin/env bash
set -euo pipefail
mkdir -p aligned
cd aligned

#3dTcat -overwrite -prefix mags.nii.gz  ../out/*/sdcflows/sub-*/fmap/*mag*nii.gz
#3dWarp -prefix mags.nii.gz -overwrite -deoblique mags.nii.gz 
mkdir -p deobl/ res/
for f in ../out/*/sdcflows/sub-*/fmap/*{magnitude_fieldmap,preproc_fieldmap}.nii.gz; do
  3dWarp -prefix deobl/$(basename $f) -overwrite -deoblique $f
done
deob=(deobl/*)
for f in ${deob[@]}; do # ${mags[@]:1}
  3dresample -overwrite -master ${deob[0]} -input $f -prefix res/$(basename $f)
done

3dTcat -overwrite -prefix mags.nii.gz  res/*magnitude_fieldmap.nii.gz
3dTcat -overwrite -prefix fmaps.nii.gz  res/*preproc_fieldmap.nii.gz
#3dTcat -overwrite -prefix fmaps.nii.gz ../out/*/sdcflows/sub-*/fmap/*preproc_fieldmap.nii.gz
#3dWarp -prefix fmaps.nii.gz -overwrite -deoblique fmaps.nii.gz

#niinote mags_aligned.nii.gz \
#  mcflirt -in mags.nii.gz -mats -out mags_aligned
#
## applyxfm4D <input volume> <ref volume> <output volume> <transformation matrix file/dir>
#niinote fmaps_aligned.nii.gz \
#  applyxfm4D fmaps.nii.gz mags_aligned.nii.gz fmaps_aligned.nii.gz mags_aligned.mat/ -fourdigit 


# only on one frame!?
#niinote mags_bet.nii.gz \
#  bet2 mags.nii.gz mags_bet.nii.gz
3dvolreg -overwrite -base 2 -dfile mcmat.1D -prefix mags_volreg.nii.gz mags.nii.gz 
3dAllineate -overwrite -input fmaps.nii.gz -master mags_volreg.nii.gz'[2]' -1Dparam_apply mcmat.1D -prefix fmaps_aligned.nii.gz -warp shift_rotate_scale
