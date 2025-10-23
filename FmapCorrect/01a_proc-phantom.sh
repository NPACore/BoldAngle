#!/usr/bin/env bash
set -xeuo pipefail
export PATH="$PATH:/opt/ni_tools/afni:/opt/ni_tools/fsl:/opt/ni_tools/fmri_processing_scripts:/opt/ni_tools/lncdtools"
export MRI_STDDIR=NA # preproc scripts look for MNI dir. dont need for distortion correction
# reslice and sdc with fsl

# 20251015WF - init on 20230803 human phantom
# 20251020WF - adapt for bullet phantom

out=wf/phantom20251020
mkdir -p $out

dicom_epi="../Data/2025-10-20/DICOM/A_EP2D_BOLD_ANG_N40P20_2MM_ASCEND_INCANG_0004/"
dicom_mag="../Data/2025-10-20/DICOM/GRE_FIELDMAP_LARGEFOV_0002/"
dicom_phasediff="../Data/2025-10-20/DICOM/GRE_FIELDMAP_LARGEFOV_0003/"

epi=$out/epi_angles.nii.gz
resliced=$out/resliced.nii.gz

test -r $epi ||
time niinote $epi \
 dcm2niix -o $out/ -f epi_angles \
  -z y \
  $dicom_epi 

#3drefit -relabel_all_str "$(cat angle.txt | tr '\n' ' ')" $epi

test -r $resliced || 
time niinote  $resliced \
   mcflirt \
   `# -refvol n/2 #middle what we want to see? should maybe use mag?`  \
   -out $resliced \
   -in  $epi


if ! test -r $out/mean_epi_brain.nii.gz; then
    3dTstat  -prefix $out/mean_epi.nii.gz -mean $resliced
    bet $out/mean_epi.nii.gz $out/mean_epi_brain.nii.gz
fi


fmap_unwarp_field=$out/sdc/unwarp/EF_UD_warp.nii.gz
test -r $fmap_unwarp_field ||
  ./sdc.sh "$out/mean_epi_brain.nii.gz" "$dicom_mag" "$dicom_phasediff" $(jq '.EchoTime' $out/epi_angles.json)


# are these two steps needed? ref can be 4d? no need to convert?
#inweight="-inweight $out/sdc/unwarp/EF_UD_fmap_sigloss" # $(pwd)/unwarp/EF_UD_fmap_sigloss.nii.gz
#convertwarp --ref=$out/mean_epi.nii.gz \
#	    --warp1=$fmap_unwarp_field  \
#	    --relout \
#	    --out=$out/undistort
ref=$out/mean_epi_brain.nii.gz
niinote $out/epi_undistored.nii.gz \
	applywarp --in=$resliced \
	--out=$out/epi_undistored_masked.nii.gz \
	`#--warp=$out/undistort` \
	--warp=$fmap_unwarp_field \
	--ref=$ref --rel \
	--mask=$out/sdc/unwarp/EF_UD_fmap_mag_brain_mask.nii.gz \
	--interp=spline
