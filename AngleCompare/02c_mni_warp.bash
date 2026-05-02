#!/usr/bin/env bash
set -euo pipefail
# warp B0 map to mni to visualize with tsnr
# 20251027WF -init

export ROOT=$(cd $PWD/..; pwd)

syn() { podman run -v $ROOT:$ROOT --entrypoint=antsRegistrationSyNQuick.sh  docker.io/nipreps/fmriprep "$@"; }
apply() { podman run -v $ROOT:$ROOT --entrypoint=antsApplyTransforms  docker.io/nipreps/fmriprep "$@"; }
export -f syn apply

for sub in sub-1 sub-2 sub-1iso3d sub-1e3d; do

  bidsname=bids-a10; acq=acq-inc_; sdcname=human-largefov; bsub=$sub
  [[ $sub =~ 1iso3d ]] && bidsname=bids-3depi2x2x2 && acq="" && sdcname=human-largefov-3depi2x2x2
  [[ $sub =~ 1e3d ]] && bidsname=bids-3depi && acq="acq-inc_" && sdcname=human-largefov-3depi && bsub=sub-1
  
  t1="$ROOT/Data/$bidsname/$bsub/anat/${bsub}_T1w.nii.gz"
  t1mask="$ROOT/Data/preproc/$bidsname/fmriprep-25.2.3/$bsub/anat/${bsub}_desc-brain_mask.nii.gz"
  t12mni="$ROOT/Data/preproc/$bidsname/fmriprep-25.2.3/$bsub/anat/${bsub}_from-T1w_to-MNI152NLin2009cAsym_mode-image_xfm.h5"
  
  epi_fmap="$ROOT/FmapCorrect/wf/$sdcname/$bsub/sdc/unwarp/EF_UD_fmap.nii.gz"
  epi2t1="$ROOT/Data/preproc/$bidsname/fmriprep-25.2.3/$bsub/func/${bsub}_task-n40p20_${acq}from-boldref_to-T1w_mode-image_desc-coreg_xfm.txt"
  mniref="$ROOT/Data/preproc/$bidsname/fmriprep-25.2.3/$bsub/func/${bsub}_task-n40p20_${acq}space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz"

  a10mean="$ROOT/FmapCorrect/wf/$sdcname/$bsub/mean_epi_brain.nii.gz"
  a10_max="$ROOT/FmapCorrect/wf/$sdcname/${bsub}/angles_at_max.nii.gz"


  # native fmap -> t1w or mni
  fmap_native="$ROOT/FmapCorrect/wf/$sdcname/$bsub/sdc/unwarp/FM_UD_fmap.nii.gz"
  fmap_magbrain="$ROOT/FmapCorrect/wf/$sdcname/$bsub/sdc/unwarp/FM_UD_fmap_mag_brain.nii.gz"
  
  # not EPI warpped data -- not used (yet)
  #fmap_mag=$ROOT/FmapCorrect/wf/a10/flow/sdcflows/$bsub/fmap/${bsub}_acq-largefov_fmapid-auto*_desc-magnitude_fieldmap.nii.gz
  #fmap="$ROOT/FmapCorrect/wf/$sdcname/$bsub/sdc/unwarp/FM_UD_fmap.nii.gz"
  
  # check we have everything
  for f in $t1 $t1mask $t12mni $epi_fmap $epi2t1 $mniref $a10mean $a10_max $fmap_native $fmap_magbrain; do
   ! test -r $f && echo "ERROR $sub: '$f' doesn't exist!?" && continue
  done
  
  ## "largeFOV" fieldmap created with hallquist prelude wrapper
  # warp to mni to compare with tsnr
  
  mh_fmap_in_mni=$PWD/maxangle_mni/${sub}_space-MNI152NLin2009cAsym_fmap.nii.gz 
  mkdir -p $(dirname $mh_fmap_in_mni)
  ! test -r $mh_fmap_in_mni &&
    niinote $_ \
     apply -d 3 -e 3 \
       -i $epi_fmap \
       -r $mniref \
       -t $t12mni\
       -o $mh_fmap_in_mni &&
    3drefit -space MNI $mh_fmap_in_mni
  
  t1bet=$PWD/maxangle_mni/${sub}_desc-brain_T1w.nii.gz
  test -r $t1bet ||
      3dcalc \
  	-t $t1 \
  	-m $t1mask \
  	-expr 't*m' -prefix $_
  
  ## max angle selection at scan time, to compare with selection at tsnr
  a10_lin=$PWD/maxangle_mni/${sub}_from-a10-to-t1w_0GenericAffine.mat
  ! test -r $a10_lin &&
   niinote ${a10_lin/_0GenericAffine.mat/_Warped.nii.gz} \
    syn -f $t1bet -m $a10mean -o $PWD/maxangle_mni/${sub}_from-a10-to-t1w_ -t r
  
  mni_maxangle=$PWD/maxangle_mni/${sub}_a10_space-MNI_maxangle.nii.gz 
  ! test -e $mni_maxangle &&
   niinote $mni_maxangle \
    apply -d 3 -e 3 \
       -i $a10_max \
       -r $mniref \
       -t $t12mni\
       -t $a10_lin \
       -n NearestNeighbor \
       -o $mni_maxangle &&
    3drefit -space MNI $mni_maxangle


  # 2026-04-03
  # iso 3depi n40 started at 0 instead!
  #/home/boldsliceangle/BOLDSliceAngle/FmapCorrect/wf/human-largefov-3depi2x2x2/sub-1iso3d/sdc/unwarp/FM_UD_fmap_mag_brain.nii.gz
  #/home/boldsliceangle/BOLDSliceAngle/FmapCorrect/wf/human-largefov-3depi2x2x2/sub-1iso3d/sdc/unwarp/FM_UD_fmap.nii.gz
  fmap2t1w=$PWD/maxangle_mni/${sub}_from-fmap-to-t1w_
  fm_mni=$PWD/maxangle_mni/${sub}_space-MNI152NLin2009cAsym_fmapDirect.nii.gz 
  skip-exist ${fmap2t1w}Warped.nii.gz \
    niinote __SKIPFILE \
	  syn -f $t1bet -m $fmap_magbrain -o $fmap2t1w -t r
  skip-exist $fm_mni \
    niinote __SKIPFILE \
     apply -d 3 -e 3 \
       -i $fmap_native \
       -r $mniref \
       -t $t12mni\
       -t ${fmap2t1w}0GenericAffine.mat \
       -o $fm_mni
  # same for mag
  skip-exist ${fm_mni/fmapDirect/fmapmag} \
    niinote __SKIPFILE \
     apply -d 3 -e 3 \
       -i $fmap_magbrain \
       -r $mniref \
       -t $t12mni\
       -t ${fmap2t1w}0GenericAffine.mat \
       -o __SKIPFILE 
  ! [[ $(3dinfo -space ${fm_mni}) =~ MNI ]] && 3drefit -space MNI ${fm_mni}
  ! [[ $(3dinfo -space ${fm_mni/fmapDirect/fmapmag}) =~ MNI ]] && 3drefit -space MNI ${fm_mni/fmapDirect/fmapmag}
done
