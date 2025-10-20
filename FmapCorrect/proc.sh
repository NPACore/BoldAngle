#!/usr/bin/env bash
set -xeuo pipefail
export PATH="$PATH:/opt/ni_tools/afni:/opt/ni_tools/fsl:/opt/ni_tools/fmri_processing_scripts:/opt/ni_tools/lncdtools"
export MRI_STDDIR=NA # preproc scripts look for MNI dir. dont need for distortion correction
# reslice and sdc with fsl

# 20251015WF - init

out=wf
mkdir -p $out

dicom_epi=../Data/ICTR-MOON_TEST_20230803_152316_668000/DICOM/A_EP2D_BOLD_ANG_N40P20_2MM_ASCEND_0003/
dicom_mag=../Data/ICTR-MOON_TEST_20230803_152316_668000/DICOM/GRE_FIELDMAP_0010/
dicom_phasediff=../Data/ICTR-MOON_TEST_20230803_152316_668000/DICOM/GRE_FIELDMAP_0011/

epi=$out/epi_angles.nii.gz
resliced=$out/resliced.nii.gz

test -r $epi ||
time niinote $epi \
 dcm2niix -o $out/ -f epi_angles \
  -z y \
  $dicom_epi 
# 3drefit -relabel_all_str "$(cat ../angle.txt | tr '\n' ' ')" $epi

if ! test -r $out/mean_epi_brain.nii.gz; then
    3dTstat  -prefix $out/mean_epi.nii.gz -mean $resliced
    bet $out/mean_epi.nii.gz $out/mean_epi_brain.nii.gz
fi

test -r $resliced || 
time niinote  $resliced \
   mcflirt \
   `# -refvol n/2 #middle what we want to see? should maybe use mag?`  \
   -out $resliced \
   -in  $epi


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
