#!/usr/bin/env bash
for bold in \
	../Data/preproc/bids-a10/fmriprep-25.2.3/sub-*/func/sub-*_task-*_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz\
	../Data/preproc/bids-3depi*/fmriprep-25.2.3/sub-*/func/sub-*_task-*_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz\
	; do
  ! test -r "$bold" && echo "no file like $bold" && continue
  ! [[ $bold =~ bids-([^/]*) ]] && echo "acq version not like bids-* in $bold" && continue
  acqver=${BASH_REMATCH[1]}
  out=../Data/tsnr/$acqver/$(basename $bold| sed 's/_space.*/_tsnr.nii.gz/')
  # skip when we have output (needed to comment out for making sd below)
  test -r $out && echo "# have $out" && continue

  test -d $(dirname $out) || dryrun mkdir -p  "$_"
  mask=${bold/desc-preproc_bold/desc-brain_mask}
  test -r $out || \
	  MASK=$mask dryrun tsnr $bold $out

  # 20260430 - also calculate sd
  test -r ${out/_tsnr.nii.gz/_sd.nii.gz} || \
    dryrun 3dTstat -stdev -prefix $_ -mask $mask $bold

  dryrun 3dROIstats -nomeanout -nzmean -minmax -nzsigma -median -mask "$mask" "$out"
done
