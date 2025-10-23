#!/usr/bin/env bash
set -xeuo pipefail
export PATH="$PATH:/opt/ni_tools/afni:/opt/ni_tools/fsl:/opt/ni_tools/fmri_processing_scripts:/opt/ni_tools/lncdtools"
export MRI_STDDIR=NA # preproc scripts look for MNI dir. dont need for distortion correction

# reslice and sdc with fsl
# data from ../AngleCompare/00_bids.bash -> ../Data/bids-a10/sub-1/fmap/sub-1_acq-largefov_*

# 20251015WF - init on 20230803 human phantom
# 20251020WF - adapt for bullet phantom
# 20251022WF - adapt for 10x angle rest version
#              second subj has test/retest for largefov
#              now depends on ../AngleCompare/00_bids.bash

for sub in sub-{1,2}; do
  for run in "" _run-2; do
    epi="$PWD/../Data/bids-a10/$sub/func/${sub}_task-n40p20_acq-inc${run}_bold.nii.gz"

    mag="$PWD/../Data/bids-a10/$sub/fmap/${sub}_acq-largefov_magnitude1.nii.gz"
    phase="$PWD/../Data/bids-a10/$sub/fmap/${sub}_acq-largefov_phasediff.nii.gz"
    # run 2 doesn't have filedmap -- oops :(
    #mag="$PWD/../Data/bids-a10/$sub/fmap/${sub}_acq-largefov${run}_magnitude1.nii.gz"
    #phase="$PWD/../Data/bids-a10/$sub/fmap/${sub}_acq-largefov${run}_phasediff.nii.gz"
    ! [ -r $epi ] && echo "# no epi for sub '$sub' + run '$run': '$epi'" && continue

    out=$PWD/wf/human-largefov/$sub$run
    mkdir -p $out
    # preprocessDistortion adds sibling files to $phase. so link into output dir
    test -r $out/$(basename $mag) || ln -s $mag $_; mag=$_
    test -r $out/$(basename $phase) || ln -s $phase $_; phase=$_
    
    resliced=$out/resliced.nii.gz                # input
    undistort=$out/epi_undistorted_masked.nii.gz # output

    #3drefit -relabel_all_str "$(cat angle.txt | tr '\n' ' ')" $epi

    test -r $resliced || 
      time niinote  $resliced \
         mcflirt \
         `#-refvol $mag` \
         -out $resliced \
         -in  $epi

    # for reference, not used elsehwere in pipeline
    # also see ../B0compare/02_align.bash
    if ! test -r $out/resliced_volreg.nii.gz; then
      3dresample -inset $mag -master $epi -prefix $out/mag_res.nii.gz
      3dvolreg -overwrite -base $out/mag_res.nii.gz -dfile $out/resliced_mcmat.1D -prefix $out/resliced_volreg.nii.gz   $epi
    fi


    if ! test -r $out/mean_epi_brain.nii.gz; then
        3dTstat  -prefix $out/mean_epi.nii.gz -mean $resliced
        bet $out/mean_epi.nii.gz $out/mean_epi_brain.nii.gz
    fi


    fmap_unwarp_field=$out/sdc/unwarp/EF_UD_warp.nii.gz
    EchoTime=$(jq '.EchoTime' ${epi/.nii.gz/.json})
    test -r $fmap_unwarp_field ||
      ./sdc.sh "$out/mean_epi_brain.nii.gz" "$mag" "$phase" $EchoTime 


    # are these two steps needed? ref can be 4d? no need to convert?
    #inweight="-inweight $out/sdc/unwarp/EF_UD_fmap_sigloss" # $(pwd)/unwarp/EF_UD_fmap_sigloss.nii.gz
    #convertwarp --ref=$out/mean_epi.nii.gz \
    #      --warp1=$fmap_unwarp_field  \
    #      --relout \
    #      --out=$out/undistort
    ref=$out/mean_epi_brain.nii.gz
    test -r $undistort ||
     niinote $undistort \
      applywarp --in=$resliced \
      --out=$undistort \
      `#--warp=$out/undistort` \
      --warp=$fmap_unwarp_field \
      --ref=$ref --rel \
      --mask=$out/sdc/unwarp/EF_UD_fmap_mag_brain_mask.nii.gz \
      --interp=spline 
  done
done
