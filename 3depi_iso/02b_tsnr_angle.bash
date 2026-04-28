#!/usr/bin/env bash
set -xuo pipefail
# calc best angle based on tsnr
# copied from ../AngleCompare/02b_tsnr_angle.bash
# still depends on ../AngleCompare/02_tsnr.bash to generate tsnr files

sub=sub-1iso3d
maxang_dir=../AngleCompare/maxangle_mni/3depi2x2x2 # creating now
tsnr_dir=../Data/tsnr/3depi2x2x2 # from ../AngleCompare/02_tsnr.bash
prep_dir=../Data/preproc/bids-3depi2x2x2/fmriprep-25.2.3
angles=(-40 -33 -13 13 20)
tsnr_files=($tsnr_dir/${sub}_task-rest_acq-{n40,n33,n13,p13,p20}_tsnr.nii.gz)

dryrun mkdir -p $maxang_dir
skip-exist $maxang_dir/${sub}_tsnr-3depi222all4d.nii.gz \
  dryrun 3dTcat -prefix __SKIPFILE ${tsnr_files[@]}

printf "%s\n" ${angles[@]} | drytee $maxang_dir/angles.txt
skip-exist $maxang_dir/${sub}_angleatmax-tsnr.nii.gz  \
  dryrun ../FmapCorrect/angle_at_max.py  \
        --nosd \
        -l $maxang_dir/angles.txt \
        -i $maxang_dir/${sub}_tsnr-3depi222all4d.nii.gz  \
        -m $prep_dir/${sub}/func/${sub}_task-rest_acq-p13_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz \
        -o __SKIPFILE
