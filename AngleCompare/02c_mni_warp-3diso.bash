#!/usr/bin/env bash
set -euo pipefail
# warp B0 map to mni to visualize with tsnr
# 20260402 copy from 02c_mni_warp.bash (20251027WF -init)

#export ROOT=$(cd -L $PWD/..; pwd -P)
export ROOT=/home/boldsliceangle/BOLDSliceAngle/ # 20260402 - symlinks and docker issue

syn() { podman run -v $ROOT:$ROOT --entrypoint=antsRegistrationSyNQuick.sh  docker.io/nipreps/fmriprep "$@"; }
apply() { podman run -v $ROOT:$ROOT --entrypoint=antsApplyTransforms  docker.io/nipreps/fmriprep "$@"; }
export -f syn apply

# ../Data/preproc/bids-3depi2x2x2/fmriprep-25.2.3/sub-1iso3d/anat/
t1="$ROOT/Data/bids-3depi2x2x2/sub-1iso3d/anat/sub-1iso3d_T1w.nii.gz"
prepdir="$ROOT/Data/preproc/bids-3depi2x2x2/fmriprep-25.2.3/sub-1iso3d"
fmapdir="$ROOT/FmapCorrect/wf/human-largefov-3depi2x2x2/sub-1iso3d"
t1mask="$prepdir/anat/sub-1iso3d_desc-brain_mask.nii.gz"
t12mni="$prepdir/anat/sub-1iso3d_from-T1w_to-MNI152NLin2009cAsym_mode-image_xfm.h5"

epi_fmap="$fmapdir/sdc/unwarp/EF_UD_fmap.nii.gz"
epi2t1="$prepdir/func/sub-1iso3d_task-n40p20_from-boldref_to-T1w_mode-image_desc-coreg_xfm.txt"
mniref="$prepdir/func/sub-1iso3d_task-n40p20_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz"

out=$ROOT/AngleCompare/maxangle_mni/

# check we have everything
for f in $t1 $prepdir $fmapdir $t1mask $t12mni $epi_fmap $epi2t1 $mniref; do
 ! test -r $f && echo "$f doesn't exist!?" && exit 1
done

## "largeFOV" fieldmap created with hallquist prelude wrapper
# warp to mni to compare with tsnr

mh_fmap_in_mni=$out/sub-1_ses-iso3d_space-MNI152NLin2009cAsym_fmap.nii.gz 
mkdir -p $(dirname $mh_fmap_in_mni)
! test -r $mh_fmap_in_mni &&
  dryrun niinote $_ \
   apply -d 3 -e 3 \
     -i $epi_fmap \
     -r $mniref \
     -t $t12mni\
     -o $mh_fmap_in_mni &&
  dryrun 3drefit -space MNI $mh_fmap_in_mni

t1bet=$out/sub-1_ses-iso3d_desc-brain_T1w.nii.gz
test -r $t1bet ||
    dryrun 3dcalc \
	-t $t1 \
	-m $t1mask \
	-expr 't*m' -prefix $_

## max angle selection at scan time, to compare with selection at tsnr
a10mean="$fmapdir/mean_epi_brain.nii.gz"
a10_max="$fmapdir/angles_at_max.nii.gz"
a10_lin=$out/ses-iso3d_from-largefov-to-t1w_0GenericAffine.mat
! test -r $a10_lin &&
  dryrun syn -f $t1bet -m $a10mean -o ${a10_lin/0GenericAffine.mat/} -t r

mni_maxangle=$out/sub-1_ses-iso3d_a10_space-MNI_maxangle.nii.gz 
test -r $mni_maxangle ||
 dryrun niinote $mni_maxangle \
  apply -d 3 -e 3 \
     -i $a10_max \
     -r $mniref \
     -t $t12mni\
     -t $a10_lin \
     -n NearestNeighbor \
     -o $mni_maxangle &&
  dryrun 3drefit -space MNI $mni_maxangle
