#!/usr/bin/env bash
for f in ../Data/preproc/bids-*/fmriprep-25.2.3/sub-*/func/sub-*_task-*_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz; do
    ! test -r "$f" && echo "ERROR: bad glob! '$f' DNE" && exit 1
    skip-exist ${f/desc-*/desc-mean_bold.nii.gz} \
      dryrun 3dTstat -mean -mask ${f/preproc_bold/brain_mask} -prefix __SKIPFILE "$f"
done
