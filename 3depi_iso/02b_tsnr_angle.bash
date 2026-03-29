#!/usr/bin/env bash
# calc best angle based on tsnr
# copied from ../AngleCompare/02b_tsnr_angle.bash
# still depends on ../AngleCompare/02_tsnr.bash to generate tsnr files

mkdir -p ../AngleCompare/maxangle_mni/3depi_iso/
skip-exist ./maxangle_mni/3depi_iso/sub-1_tsnr-3depi222all4d.nii.gz \
  dryrun 3dTcat -prefix __SKIPFILE \
     ../Data/tsnr/3depi_iso/sub-1_task-rest_acq-{n40,n33,n13,p13,p20}_tsnr.nii.gz

printf "%s\n" -40 -33 -13 13 20 | drytee ./maxangle_mni/3depi_iso/angles.txt
skip-exist ./maxangle_mni/3depi_iso/sub-1_angleatmax-tsnr.nii.gz  \
  dryrun ../FmapCorrect/angle_at_max.py  \
        --nosd \
        -l ./maxangle_mni/3depi_iso/angles.txt \
        -i ./maxangle_mni/3depi_iso/sub-1_tsnr-3depi222all4d.nii.gz  \
        -m ../Data/preproc/bids-3depi2x2x2/fmriprep-25.2.3/sub-1/func/sub-1_task-rest_acq-p13_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz \
        -o __SKIPFILE
