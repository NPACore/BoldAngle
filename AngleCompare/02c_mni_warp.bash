#!/usr/bin/env bash
set -euo pipefail
# warp B0 map to mni to visualize with tsnr
# 20251027WF -init

export ROOT=$(cd $PWD/..; pwd)

syn() { podman run -v $ROOT:$ROOT --entrypoint=antsRegistrationSyNQuick.sh  docker.io/nipreps/fmriprep "$@"; }
apply() { podman run -v $ROOT:$ROOT --entrypoint=antsApplyTransforms  docker.io/nipreps/fmriprep "$@"; }
export -f syn apply


t1="$ROOT/Data/bids-a10/sub-1/anat/sub-1_T1w.nii.gz"
t1mask="$ROOT/Data/preproc/fmriprep-25.2.3/sub-1/anat/sub-1_desc-brain_mask.nii.gz"
t12mni="$ROOT/Data/preproc/fmriprep-25.2.3/sub-1/anat/sub-1_from-T1w_to-MNI152NLin2009cAsym_mode-image_xfm.h5"

epi_fmap="$ROOT/FmapCorrect/wf/human-largefov/sub-1/sdc/unwarp/EF_UD_fmap.nii.gz"
epi2t1="$ROOT/Data/preproc/fmriprep-25.2.3/sub-1/func/sub-1_task-n40p20_acq-inc_from-boldref_to-T1w_mode-image_desc-coreg_xfm.txt"
mniref="$ROOT/Data/preproc/fmriprep-25.2.3/sub-1/func/sub-1_task-n40p20_acq-inc_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz"

# not EPI warpped data -- not used (yet)
fmap_mag="$ROOT/FmapCorrect/wf/a10/flow/sdcflows/sub-1/fmap/sub-1_acq-largefov_fmapid-auto00000_desc-magnitude_fieldmap.nii.gz"
fmap="$ROOT/FmapCorrect/wf/human-largefov/sub-1/sdc/unwarp/FM_UD_fmap.nii.gz"


## "largeFOV" fieldmap created with hallquist prelude wrapper
# warp to mni to compare with tsnr

mh_fmap_in_mni=$PWD/maxangle_mni/sub-1_space-MNI152NLin2009cAsym_fmap.nii.gz 
mkdir -p $(dirname $mh_fmap_in_mni)
! test -r $mh_fmap_in_mni &&
  niinote $_ \
   apply -d 3 -e 3 \
     -i $epi_fmap \
     -r $mniref \
     -t $t12mni\
     -o $mh_fmap_in_mni &&
  3drefit -space MNI maxangle_mni/sub-1_space-MNI152NLin2009cAsym_fmap.nii.gz

t1bet=$PWD/maxangle_mni/sub-1_desc-brain_T1w.nii.gz
test -r $t1bet ||
    3dcalc \
	-t $t1 \
	-m $t1mask \
	-expr 't*m' -prefix $_

## max angle selection at scan time, to compare with selection at tsnr
a10mean="$ROOT/FmapCorrect/wf/human-largefov/sub-1/mean_epi_brain.nii.gz"
a10_max="$ROOT/FmapCorrect/wf/human-largefov/sub-1/angles_at_max.nii.gz"
a10_lin=$PWD/maxangle_mni/from-a10-to-t1w_0GenericAffine.mat
! test -r $a10_lin &&
  syn -f $t1bet -m $a10mean -o $PWD/maxangle_mni/from-a10-to-t1w_ -t r

mni_maxangle=$PWD/maxangle_mni/sub-1_a10_space-MNI_maxangle.nii.gz 
test -r $mni_maxangle ||
 niinote $mni_maxangle \
  apply -d 3 -e 3 \
     -i $a10_max \
     -r $mniref \
     -t $t12mni\
     -t $a10_lin \
     -n NearestNeighbor \
     -o $mni_maxangle &&
  3drefit -space MNI $mni_maxangle
