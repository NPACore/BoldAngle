#!/usr/bin/env bash
#
# USAGE:
#     $0 epi.dcm/ gremag.dcm/ grephase.dcm/
#
# distortion correct and pick best angle by magnitude mutli-tilt/sliceangle EPI acquisition
#
#   1. dcm2nii
#   2. reslice (mcflirt)
#   3. B0 unwarp / susptability distortion correct (sdc.sh)
#   4. get max mag at each angle (angle_at_max.py)
#   5. write back to dicom (tomaroberts/nii2dcm)
#
# output written to 
#    ${TMPDIR:-wf}/${TMPPREFIX:-$(date +%F)_XXX}
# modify global environment TMPDIR/TMPPREFIX for deterministic file output
# maybe needed for scp back from scan console
#
##END SYNOPSYS
#
# 20251015WF - init as 01_proc.sh
# 20251022WF - 01b_proc-10a.sh
# 20251106WF - generalize to own script to be run by .bat over ssh on scan console

set -euo pipefail
export PATH="$PATH:/opt/ni_tools/afni:/opt/ni_tools/fsl:/opt/ni_tools/fmri_processing_scripts:/opt/ni_tools/lncdtools"
export MRI_STDDIR=NA # preproc scripts look for MNI dir. dont need for distortion correction

if [[ $# -ne 3 || "$*" =~ ^-h ]]; then 
  sed -n "s:\$0:$0:; 1,/##END SYN/ s/# //p" "$0"
  exit 1
fi

# where does this script live. need to find it's sibling 'sdc.sh' 
scriptdir=$(cd "$(dirname "$(readlink -f "$0")")";pwd -L)

## always exactly 3 arguments
dicom_epi=${1?-multi tilt epi dcm folder}   #../Data/ICTR-MOON_TEST_20230803_152316_668000/DICOM/A_EP2D_BOLD_ANG_N40P20_2MM_ASCEND_0003/
dicom_mag=${2?-GRE fmap mag folder}         #../Data/ICTR-MOON_TEST_20230803_152316_668000/DICOM/GRE_FIELDMAP_0010/
dicom_phasediff=${3?-GRE fmap phase folder} #../Data/ICTR-MOON_TEST_20230803_152316_668000/DICOM/GRE_FIELDMAP_0011/

## sanity checks
! test -d "$dicom_epi" &&
	echo "epi dicom dir '$dicom_epi' is not a directory" 2>&1 && exit 1
! test -d "$dicom_mag" &&
	echo "GRE mag dicom dir '$dicom_mag' is not a directory" 2>&1 && exit 1
! test -d "$dicom_phasediff" &&
	echo "GRE phase dicom dir '$dicom_phasediff' is not a directory" 2>&1 && exit 1

n_mag=$(ls "$dicom_mag" |wc -l)
n_phase=$(ls "$dicom_phasediff"|wc -l)
if [ $n_mag -le $n_phase ]; then
  echo "$n_mag mag files <= $n_phase phase files. expect mag to be at least 2x phase. '$dicom_mag' <= '$dicom_phasediff'"  2>&1
  exit 1
fi

## do pipeline
out=$(mktemp -d ${TMPDIR:-wf}/${TMPPREFIX:-$(date +%F)_XXX})
mkdir -p $out

echo "## Reading in raw data"
epi=$out/epi_angles.nii.gz
resliced=$out/resliced.nii.gz

resliced=$out/resliced.nii.gz                # 4D aligned
undistort=$out/epi_undistorted_masked.nii.gz # 4D SDC w/o skull
best_angle=$out/best_angle.nii.gz            # 3D collapsed - tilt of highest mag

time niinote $epi \
 dcm2niix -o $out/ -f epi_angles `# $(basename $epi .nii.gz)` \
  -z y \
  $dicom_epi 


echo "## Reslicing"
zero_i=6 # tilt angle=0.03 on volume 7/10
time niinote $resliced \
 mcflirt \
 -refvol $zero_i `#-reffile $mag` \
 -out $resliced \
 -in  $epi \
 -mats 

# see expected angles against those derived from the rigid alignmnet
# this is unlikely to be seen when running, but will error here if the angles don't match
echo "### tilt angle reslice vs expected"
$scriptdir/affine2tilt.py $resliced.mat/ # $scriptdir/angle.txt


echo "## brain extraction/skull strip"
3dTstat -overwrite  -prefix $out/mean_epi.nii.gz -mean $resliced
brain=$out/mean_epi_brain.nii.gz 
niinote $brain \
  bet $out/mean_epi.nii.gz $brain


echo "## suspetibality distortion correction; unwarping w/GRE est. fieldmap"
fmap_unwarp_field=$out/sdc/unwarp/EF_UD_warp.nii.gz
EchoTime=$(jq '.EchoTime' ${epi/.nii.gz/.json})
time $scriptdir/sdc.sh "$brain" "$dicom_mag" "$dicom_phasediff" $EchoTime 


niinote $undistort \
  applywarp --in=$resliced \
    --out=$undistort \
    `#--warp=$out/undistort` \
    --warp=$fmap_unwarp_field \
    --ref=$brain --rel \
    --mask=$out/sdc/unwarp/EF_UD_fmap_mag_brain_mask.nii.gz \
    --interp=spline 

echo "## best tilt by magnitutde at each voxel"
uv run --script ./angle_at_max.py \
	-i $undistort \
	-m $brain \
	-o $best_angle

echo "## write back to dicom"
# uv tool install git+https://github.com/WillForan/nii2dcm # @numpy-bump @mkdir
dcmref=$(find $dicom_epi -iname '*.0001.*' -type f -size +1k -print -quit)
if [ -z "$dcmref" -o ! -r "$dcmref" ]; then
  echo "ERROR: could not find reference dicom file .0001 in $dicom_epi" 
  dcmref=()
else
  dcmref=(-r "$dcmref")
fi
uv tool run nii2dcm  -d MR "${dcmref[@]}" $best_angle $out/dcm-best-tilt

echo -e "nifti out:\t$best_angle\ndcm dir:\t$out/dcm-best-tilt"
