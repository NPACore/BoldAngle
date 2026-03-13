#!/usr/bin/env bash
for bold in \
	../Data/preproc/bids-a10/fmriprep-25.2.3/sub-*/func/sub-*_task-*_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz\
	../Data/preproc/bids-3depi/fmriprep-25.2.3/sub-*/func/sub-*_task-*_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz\
	; do
  ! test -r "$bold" && echo "no file like $bold" && continue
  ! [[ $bold =~ bids-([^/]*) ]] && echo "acq version not like bids-* in $bold" && continue
  acqver=${BASH_REMATCH[1]}
  out=../Data/tsnr/$acqver/$(basename $bold| sed 's/_space.*/_tsnr.nii.gz/')
  test -d $(dirname $out) || dryrun mkdir -p  "$_"
  test -r $out && echo "# have $out" && continue
  mask=${bold/desc-preproc_bold/desc-brain_mask}
  test -r $out || MASK=$mask dryrun tsnr $bold $out
  dryrun 3dROIstats -nomeanout -nzmean -minmax -nzsigma -median -mask "$mask" "$out"
done
