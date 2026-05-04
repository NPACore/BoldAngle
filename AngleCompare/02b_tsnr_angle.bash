#!/usr/bin/env bash
# calc best angle based on tsnr
#
mksd(){
  output=${1:?sd output name needed}; shift; #maxangle_mni/${sub}_select-n40n33n13p13p20_angleatmax-sd.nii.gz
  mapfile -t inputs < <(ls $@) # prefix*res*{n40,n39,n33,n13,[^n]13,[^n]20}_sd.nii.gz
  ! [[ ${#inputs[@]} -eq 5 ]] && echo "ERROR not exactly 5 ${inputs[*]}" && exit 1
  concat4d=$(dirname "$output")/.sd-concat-for-$(basename "$output")
  skip-exist $concat4d 3dTcat -prefix __SKIPFILE "${inputs[@]}"
  skip-exist  $output \
    ./FmapCorrect/angle_at_max.py  \
        --nosd \
        -l ./maxangle_mni/3depi/angles.txt \
        -i $concat4d  \
        -m mni_brainmask.nii.gz \
        -o __SKIPFILE
}
mkmxtsnr(){
  out=$1; shift # ./maxangle_mni/sub-1_angleatmax-tsnr.nii.gz
  tsnr_4d=${out/-tsnr.nii.gz/-all4d.nii.gz}
  [[ $out == $tsnr_4d || ! $out =~ -tsnr.nii.gz$ || $# -lt 5 ]] &&
      echo "BAD USAGE: $out should be -tsnr.nii.gz; '$*' should be >4" && return 1

  angle_lookup=$PWD/maxangle_mni_angless$#.txt
  ! test -r $angle_lookup && echo "ERROR: wrong number of inputs? have $# expect 5 or 10. not $angle_lookup file" && return 2

  skip-exist $tsnr_4d \
    3dTcat -prefix __SKIPFILE $@


  skip-exist $out \
    ../FmapCorrect/angle_at_max.py  \
          --nosd \
          -l $angle_lookup \
          -i $tsnr_4d \
          -m mni_brainmask.nii.gz \
          -o $out
}

## 20260503 - xcpd tsnr. created functions above
#  02_tsnr.bash makes e.g. ../Data/tsnr/a10/sub-2_task-restn6_xcpd_tsnr.nii.gz
#  from home/boldsliceangle/BOLDSliceAngle/Data/preproc/bids-a10/xcpd-ver-0.12.0_prep-25.2.3_type-nifti_fd-0.3_bp-yes/sub-2/func/sub-2_task-rest20_space-MNI152NLin2009cAsym_desc-denoisedSmoothed_bold.nii.gz

file_in_order(){
 i=0
 for f in $@; do
   [ ! -r $f ] && continue
   echo $f
   let i++
 done
 [ $i -ne 5 -a $i -ne 10 ] && echo "WARNING: have $i/$# readable files in '$*'" >&2
}

#
# cf. ../FmapCorrect/angle.txt
a10txt=./maxangle_mni_angless10.txt
a5txt=./maxangle_mni_angless5.txt
test -r $a10txt || printf "%s\n" -40 -33 -27 -20 -13 -7 0 7 13 20 | tee $a10txt
test -r $a5txt || printf "%s\n" -40 -33 -13 13 20 | tee $a5txt
mkdir -p maxangle_mni/xcpd
for prefix in ../Data/tsnr/a10/sub-{1,2} ../Data/tsnr/3depi2x2x2/sub-1iso3d; do
  sub=$(basename $prefix)
  # mksd maxangle_mni/${sub}_select-n40n33n13p13p20_angleatmax-sd.nii.gz $prefix/*xcpd*res*{n40,n39,n33,n13,[^n]13,[^n]20}_sd.nii.gz
  mkmxtsnr ./maxangle_mni/xcpd/${sub}_anglemax-tsnr.nii.gz $(file_in_order $prefix*{n40,n39,n33,n27,n26,n20,n13,n6,n7,[^n0-9]0,[^n]6,[^n]7,[^n]13,[^n]20}*xcpd_tsnr.nii.gz)
  mkmxtsnr ./maxangle_mni/xcpd/${sub}_select-n40n33n13p13p20_anglemax-tsnr.nii.gz $(file_in_order $prefix*{n40,n39,n33,n13,[^n]13,[^n]20}*_xcpd_tsnr.nii.gz)

done

exit
# 20260430 - also do sd
for prefix in ../Data/tsnr/a10/sub-{1,2} ../Data/tsnr/3depi2x2x2/sub-1iso3d; do
  sub=$(basename $prefix)
  concat4d=./maxangle_mni/${sub}_sd-n40n33n13p13p20.nii.gz 

  # need to make sure we dont grab neg versions of positive
  mapfile -t inputs < <(ls $prefix*res*{n40,n39,n33,n13,[^n]13,[^n]20}_sd.nii.gz)
  ! [[ ${#inputs[@]} -eq 5 ]] && echo "ERROR not exactly 5 ${inputs[*]}" && exit 1
  skip-exist $concat4d \
   dryrun 3dTcat -prefix __SKIPFILE "${inputs[@]}"
  skip-exist maxangle_mni/${sub}_select-n40n33n13p13p20_angleatmax-sd.nii.gz \
    dryrun ../FmapCorrect/angle_at_max.py  \
        --nosd \
        -l ./maxangle_mni/3depi/angles.txt \
        -i $concat4d  \
        -m mni_brainmask.nii.gz \
        -o __SKIPFILE
done
exit

# 20260328 - 3depi iso in own folder
# ../3depi_iso/02b_tsnr_angle.bash

# 20260312-  for 3depi
mkdir -p ./maxangle_mni/3depi/
skip-exist ./maxangle_mni/3depi/sub-1_tsnr-3depiall4d.nii.gz \
  dryrun 3dTcat -prefix __SKIPFILE \
     ../Data/tsnr/3depi/sub-1_task-{n40,n33,n13,13,20}_acq-3d_tsnr.nii.gz
dryrun printf "%s\n" -40 -33 -13 13 20 | drytee ./maxangle_mni/3depi/angles.txt
skip-exist ./maxangle_mni/3depi/sub-1_angleatmax-tsnr.nii.gz  \
  dryrun ../FmapCorrect/angle_at_max.py  \
        --nosd \
        -l ./maxangle_mni/3depi/angles.txt \
        -i ./maxangle_mni/3depi/sub-1_tsnr-3depiall4d.nii.gz  \
        -m ../Data/preproc/bids-3depi/fmriprep-25.2.3/sub-1/func/sub-1_task-13_acq-3d_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz \
        -o __SKIPFILE

## 20260316 3depi is 2x2x !!3!!
skip-exist ./maxangle_mni/3depi/sub-1_res-upsample_angleatmax-tsnr.nii.gz \
  3dresample -prefix __SKIPFILE -master ../maxangle_mni/sub-1_angleatmax-tsnr.nii.gz  -inset ./maxangle_mni/3depi/sub-1_angleatmax-tsnr.nii.gz

# and has fewer angles so make epi2d version with same angles
# -40 -33 -13 13 20
skip-exist ./maxangle_mni/sub-1_tsnr-n40n33n13p13p20.nii.gz \
 3dTcat -prefix __SKIPFILE \
        ../Data/tsnr/sub-1_task-restn39_tsnr.nii.gz \
        ../Data/tsnr/sub-1_task-restn33_tsnr.nii.gz \
        ../Data/tsnr/sub-1_task-restn13_tsnr.nii.gz \
        ../Data/tsnr/sub-1_task-rest13_tsnr.nii.gz \
        ../Data/tsnr/sub-1_task-rest20_tsnr.nii.gz
skip-exist maxangle_mni/sub-1_select-n40n33n13p13p20_angleatmax-tsnr.nii.gz \
    ../FmapCorrect/angle_at_max.py  \
        --nosd \
        -l ./maxangle_mni/3depi/angles.txt \
        -i ./maxangle_mni/sub-1_tsnr-n40n33n13p13p20.nii.gz  \
        -m mni_brainmask.nii.gz \
        -o __SKIPFILE
        #-m ../Data/preproc/fmriprep-25.2.3/sub-1/func/sub-1_task-rest0_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz  \

## 20260405 but for oct 2025 scan
# subset of angles
skip-exist ./maxangle_mni/sub-2_select-n40n33n13p13p20_tsnr-all4d.nii.gz \
 dryrun 3dTcat -prefix __SKIPFILE \
        ../Data/tsnr/sub-2_task-rest{n39,n33,n13,13,20}_tsnr.nii.gz

skip-exist ./maxangle_mni/sub-2_select-n40n33n13p13p20_angleatmax-tsnr.nii.gz \
  dryrun ../FmapCorrect/angle_at_max.py  \
        --nosd \
	-i ./maxangle_mni/sub-2_select-n40n33n13p13p20_tsnr-all4d.nii.gz \
        -l ./maxangle_mni/3depi/angles.txt  \
        -m ../Data/preproc/bids-a10/fmriprep-25.2.3/sub-2/func/sub-2_task-rest0_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz  \
        -o __SKIPFILE

# -39.90 -33.24 -26.59 -19.93 -13.28 -6.62 0.03 6.69 13.34 20.00
#    -40 -33                  -13                    13    20
#     0    1                   4                     8     9
skip-exist ./maxangle_mni/sub-2_task-n40p20_acq-incSUBSET_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz \
  3dTcat -prefix __SKIPFILE ../Data/preproc/bids-a10/fmriprep-25.2.3/sub-2/func/sub-2_task-n40p20_acq-inc_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz'[0,1,4,8,9]'
skip-exist ./maxangle_mni/sub-2_angleatmax-n40p20_subset5.nii.gz \
  dryrun ../FmapCorrect/angle_at_max.py  \
        --nosd \
        -l ./maxangle_mni/3depi/angles.txt  \
        -i ./maxangle_mni/sub-2_task-n40p20_acq-incSUBSET_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz \
        -m ../Data/preproc/bids-a10/fmriprep-25.2.3/sub-2/func/sub-2_task-n40p20_acq-inc_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz  \
        -o __SKIPFILE
# for sub1 too
skip-exist ./maxangle_mni/sub-1_task-n40p20_acq-incSUBSET_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz \
  3dTcat -prefix __SKIPFILE ../Data/preproc/bids-a10/fmriprep-25.2.3/sub-1/func/sub-1_task-n40p20_acq-inc_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz'[0,1,4,8,9]'
skip-exist ./maxangle_mni/sub-1_angleatmax-n40p20_subset5.nii.gz \
  dryrun ../FmapCorrect/angle_at_max.py  \
        --nosd \
        -l ./maxangle_mni/3depi/angles.txt  \
        -i ./maxangle_mni/sub-1_task-n40p20_acq-incSUBSET_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz \
        -m ../Data/preproc/bids-a10/fmriprep-25.2.3/sub-1/func/sub-1_task-n40p20_acq-inc_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz  \
        -o __SKIPFILE

# all angles
skip-exist ./maxangle_mni/sub-2_tsnr-all4d.nii.gz \
 dryrun 3dTcat -prefix __SKIPFILE \
        ../Data/tsnr/sub-2_task-rest{n39,n33,n26,n19,n13,n6,0,6,13,20}_tsnr.nii.gz

skip-exist ./maxangle_mni/sub-2_angleatmax-tsnr.nii.gz \
  dryrun ../FmapCorrect/angle_at_max.py  \
        --nosd \
        -l ../FmapCorrect/angle.txt \
        -i ./maxangle_mni/sub-2_tsnr-all4d.nii.gz  \
        -m ../Data/preproc/bids-a10/fmriprep-25.2.3/sub-2/func/sub-2_task-rest0_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz  \
        -o __SKIPFILE

skip-exist ./maxangle_mni/sub-2_angleatmax-n40p20.nii.gz \
  dryrun ../FmapCorrect/angle_at_max.py  \
        --nosd \
        -l ../FmapCorrect/angle.txt \
        -i ../Data/preproc/bids-a10/fmriprep-25.2.3/sub-2/func/sub-2_task-n40p20_acq-inc_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz \
        -m ../Data/preproc/bids-a10/fmriprep-25.2.3/sub-2/func/sub-2_task-n40p20_acq-inc_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz  \
        -o __SKIPFILE

# Oct 27 2025
test -r ./maxangle_mni/sub-1_tsnr-all4d.nii.gz ||
 dryrun 3dTcat -prefix ./maxangle_mni/sub-1_tsnr-all4d.nii.gz \
        ../Data/tsnr/sub-1_task-restn39_tsnr.nii.gz \
        ../Data/tsnr/sub-1_task-restn33_tsnr.nii.gz \
        ../Data/tsnr/sub-1_task-restn26_tsnr.nii.gz \
        ../Data/tsnr/sub-1_task-restn19_tsnr.nii.gz \
        ../Data/tsnr/sub-1_task-restn13_tsnr.nii.gz \
        ../Data/tsnr/sub-1_task-restn6_tsnr.nii.gz \
        ../Data/tsnr/sub-1_task-rest0_tsnr.nii.gz \
        ../Data/tsnr/sub-1_task-rest6_tsnr.nii.gz\
        ../Data/tsnr/sub-1_task-rest13_tsnr.nii.gz \
        ../Data/tsnr/sub-1_task-rest20_tsnr.nii.gz

test -r ./maxangle_mni/sub-1_angleatmax-tsnr.nii.gz  ||
  dryrun ../FmapCorrect/angle_at_max.py  \
        --nosd \
        -l ../FmapCorrect/angle.txt \
        -i ./maxangle_mni/sub-1_tsnr-all4d.nii.gz  \
        -m ../Data/preproc/fmriprep-25.2.3/sub-1/func/sub-1_task-rest0_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz  \
        -o ./maxangle_mni/sub-1_angleatmax-tsnr.nii.gz 

test -r maxangle_mni/tsnr-min.nii.gz ||
 dryrun 3dTstat \
  -prefix maxangle_mni/tsnr-min.nii.gz \
  -min ./maxangle_mni/sub-1_tsnr-all4d.nii.gz 
test -r maxangle_mni/tsnr-max.nii.gz ||
 dryrun 3dTstat \
  -prefix maxangle_mni/tsnr-max.nii.gz \
  -max ./maxangle_mni/sub-1_tsnr-all4d.nii.gz 

skip-exist maxangle_mni/tsnr-range.nii.gz \
dryrun 3dcalc -n maxangle_mni/tsnr-min.nii.gz\
       -x maxangle_mni/tsnr-max.nii.gz\
       -expr 'x-n' \
       -prefix maxangle_mni/tsnr-range.nii.gz
