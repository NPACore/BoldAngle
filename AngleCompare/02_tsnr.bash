#!/usr/bin/env bash
for bold in ../Data/preproc/fmriprep-25.2.3/sub-cm20230803/func/sub-cm20230803_task-*_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz; do
  out=../Data/tsnr/$(basename $bold| sed 's/_space.*/_tsnr.nii.gz/')
  mask=${bold/desc-preproc_bold/desc-brain_mask}
  test -r $out || MASK=$mask tsnr $bold $out
  3dROIstats -nomeanout -nzmean -minmax -nzsigma -median -mask "$mask" "$out"
done
