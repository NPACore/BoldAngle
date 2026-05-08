#!/usr/bin/env bash
# warp B0 map to mni to visualize with tsnr
# 20251027WF -init

export ROOT=$(cd $(dirname $0 || echo ~/BOLDSliceAngle/Olfactory )/..; pwd)


syn() { podman run -v $ROOT:$ROOT --entrypoint=antsRegistrationSyNQuick.sh  docker.io/nipreps/fmriprep "$@"; }
apply() { podman run -v $ROOT:$ROOT --entrypoint=antsApplyTransforms  docker.io/nipreps/fmriprep "$@"; }
export -f syn apply

oflac_warp_main(){
atlas="$ROOT/Olfactory/atlas-AonPirFTTubV4_res-func.nii.gz"
sub=sub-1
#for sub in sub-1 sub-2 sub-1iso3d sub-1e3d; do

  bidsname=bids-a10; acq=acq-inc_; sdcname=human-largefov; bsub=$sub
  #[[ $sub =~ 1iso3d ]] && bidsname=bids-3depi2x2x2 && acq="" && sdcname=human-largefov-3depi2x2x2
  #[[ $sub =~ 1e3d ]] && bidsname=bids-3depi && acq="acq-inc_" && sdcname=human-largefov-3depi && bsub=sub-1
  
  t1="$ROOT/Data/$bidsname/$bsub/anat/${bsub}_T1w.nii.gz"
  t1mask="$ROOT/Data/preproc/$bidsname/fmriprep-25.2.3/$bsub/anat/${bsub}_desc-brain_mask.nii.gz"
  t12mni="$ROOT/Data/preproc/$bidsname/fmriprep-25.2.3/$bsub/anat/${bsub}_from-T1w_to-MNI152NLin2009cAsym_mode-image_xfm.h5"
  mni2t1="$ROOT/Data/preproc/$bidsname/fmriprep-25.2.3/$bsub/anat/sub-1_from-MNI152NLin2009cAsym_to-T1w_mode-image_xfm.h5" 

  #epi_fmap="$ROOT/FmapCorrect/wf/$sdcname/$bsub/sdc/unwarp/EF_UD_fmap.nii.gz"
  epi="$ROOT/FmapCorrect/wf/human-largefov/sub-1/resliced.nii.gz"
  epi2t1="$ROOT/Data/preproc/$bidsname/fmriprep-25.2.3/$bsub/func/${bsub}_task-n40p20_${acq}from-boldref_to-T1w_mode-image_desc-coreg_xfm.txt"
  mniref="$ROOT/Data/preproc/$bidsname/fmriprep-25.2.3/$bsub/func/${bsub}_task-n40p20_${acq}space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz"
  mniref="/home/boldsliceangle/BOLDSliceAngle/Data/preproc/bids-a10/fmriprep-25.2.3/sub-1/func/sub-1_task-rest0_space-MNI152NLin2009cAsym_desc-mean_bold.nii.gz"
  epi2t1="/home/boldsliceangle/BOLDSliceAngle/Data/preproc/bids-a10/fmriprep-25.2.3/sub-1/func/sub-1_task-rest0_from-boldref_to-T1w_mode-image_desc-coreg_xfm.txt"

  a10mean="$ROOT/FmapCorrect/wf/$sdcname/$bsub/mean_epi_brain.nii.gz"
  a10_max="$ROOT/FmapCorrect/wf/$sdcname/${bsub}/angles_at_max.nii.gz"


  # check we have everything
  for f in $t1 $t1mask $mni2t1 $epi $epi2t1 $mniref $a10mean $a10_max; do
   ! test -r $f && echo "ERROR $sub: '$f' doesn't exist!?" && continue
  done
  
  #mni_in_native="$ROOT/Olfactory/mni_$sub.nii.gz" #$(basename $atlas .nii.gz)_space-${sub}.nii.gz"
  mni_in_native="$ROOT/Olfactory/$(basename $atlas .nii.gz)_space-${sub}.nii.gz"
  
  #mkdir -p $(dirname $mni_in_native)
  skip-exist $mni_in_native \
    niinote __SKIPFILE \
     apply -d 3 -e 3 \
        `#-i $mniref` \
       -i $atlas \
       -t [$epi2t1,1] \
       -t $mni2t1 \
       -r $a10mean \
       -n NearestNeighbor \
       -v \
       -o __SKIPFILE
    #3drefit -space MNI $mni_in_native
#done
}

eval "$(iffmain oflac_warp_main)"
