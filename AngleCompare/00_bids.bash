#!/usr/bin/env bash
#
# pilot to bids for fmriprep, sdcflows, etc
#
# 20251017WF - init
export PATH="/opt/ni_tools/lncdtools:/opt/ni_tools/afni:/opt/ni_tools/fsl:$PATH"

## 2025
dcmdir="../Data/2025-10-20/"
bids="$(cd $(dirname "$0")/../Data/; pwd)/bids-phantom"
sub=sub-20251020

mknii $bids/$sub/fmap/${sub}_acq-largeFOV_magnitude.nii.gz $dcmdir/GRE_FIELDMAP_LARGEFOV_0002
mknii $bids/$sub/fmap/${sub}_acq-largeFOV_phasediff.nii.gz $dcmdir/GRE_FIELDMAP_LARGEFOV_0003

mknii $bids/$sub/func/${sub}_task-n40p20_acq-dec_bold.nii.gz $dcmdir/A_EP2D_BOLD_ANG_N40P20_2MM_ASCEND_DECANG_0006
mknii $bids/$sub/func/${sub}_task-n40p20_acq-inc_bold.nii.gz $dcmdir/A_EP2D_BOLD_ANG_N40P20_2MM_ASCEND_INCANG_0004
mknii $bids/$sub/func/${sub}_task-n40p20_acq-mid_bold.nii.gz $dcmdir/A_EP2D_BOLD_ANG_N40P20_2MM_ASCEND_MIDANG_0005

add-intended-for -fmap '*acq-largeFOV*phasediff*.json' -for '*task-n40p20*.nii.gz' $bids/$sub
add-intended-for -fmap '*acq-largeFOV*magnitude*.json' -for '*task-n40p20*.nii.gz' $bids/$sub

mknii $bids/$sub/func/${sub}_task-c20_sbref.nii.gz $dcmdir/BOLD_REST_AP_T_C20_SBREF_0007
mknii $bids/$sub/func/${sub}_task-c20_bold.nii.gz $dcmdir/BOLD_REST_AP_T_C20_0008

mknii $bids/$sub/fmap/${sub}_acq-c20_dir-AP_epi.nii.gz $dcmdir/SPINECHOFIELDMAP_AP_0010
mknii $bids/$sub/fmap/${sub}_acq-c20_dir-PA_epi.nii.gz $dcmdir/SPINECHOFIELDMAP_PA_0011

for f in $bids/$sub/func/*json; do
  [[ $f =~ task-([^_-]*) ]] || continue
  grep TaskName $f ||
    sed -i "1s;^{;{\n\"TaskName\": \"${BASH_REMATCH[1]}\",;" $f
done

exit
## 20230803

dcmdir=../Data/ICTR-MOON_TEST_20230803_152316_668000/DICOM
#ls ../Data/ICTR-MOON_TEST_20230803_152316_668000/DICOM |   perl -F_ -slane 'push @a, {p=>$_,s=>$F[$#f]}; END{print join("\n", map {$_->{p}} (sort {$a->{s} <=> $b->{s}} @a));}'

bids="$(cd $(dirname "$0")/../Data/; pwd)/bids"
sub=sub-cm20230803
mknii $bids/$sub/anat/${sub}_T1w.nii.gz $dcmdir/T1MPRAGE_0002

mknii $bids/$sub/func/${sub}_task-anglechange_epi.nii.gz $dcmdir/A_EP2D_BOLD_ANG_N40P20_2MM_INTLEAV_0004

# -8 -- bad dimensions? 
#   2: [ERR] Bold scans must be 4 dimensional. (code: 54 - BOLD_NOT_4D)    
#      ./sub-cm20230803/func/sub-cm20230803_task-n08_bold.nii.gz                                           
#              Evidence: header field "dim" = 3,104,104,72
# mknii $bids/$sub/func/${sub}_task-n08_epi.nii.gz       $dcmdir/BOLD_REST_AP_T_C-8_4_SBREF_0005
# mknii $bids/$sub/func/${sub}_task-n08_epi.nii.gz       $dcmdir/BOLD_REST_AP_T_C-8_4_0006
# mknii $bids/$sub/fmap/${sub}_acq-n08_dir-AP_epi.nii.gz $dcmdir/SPINECHOFIELDMAP_AP_0008
# mknii $bids/$sub/fmap/${sub}_acq-n08_dir-PA_epi.nii.gz $dcmdir/SPINECHOFIELDMAP_PA_0009
# mknii $bids/$sub/fmap/${sub}_acq-n08_magnitude.nii.gz  $dcmdir/GRE_FIELDMAP_0010
# mknii $bids/$sub/fmap/${sub}_acq-n08_phasediff.nii.gz  $dcmdir/GRE_FIELDMAP_0011
# add-intended-for -fmap '*acq-n08*phasediff*.json' -for '*task-n08*.nii.gz' ../Data/bids/sub-cm20230803/
# add-intended-for -fmap '*acq-n08*mag*.json' -for '*task-n08*.nii.gz' ../Data/bids/sub-cm20230803/

# -45
mknii $bids/$sub/func/${sub}_task-n45_sbref.nii.gz     $dcmdir/BOLD_REST_AP_T_C-45_SBREF_0012
mknii $bids/$sub/func/${sub}_task-n45_epi.nii.gz       $dcmdir/BOLD_REST_AP_T_C-45_0013
mknii $bids/$sub/fmap/${sub}_acq-n45_dir-AP_epi.nii.gz $dcmdir/SPINECHOFIELDMAP_AP_0015
mknii $bids/$sub/fmap/${sub}_acq-n45_dir-PA_epi.nii.gz $dcmdir/SPINECHOFIELDMAP_PA_0016
mknii $bids/$sub/fmap/${sub}_acq-n45_magnitude.nii.gz  $dcmdir/GRE_FIELDMAP_0017
mknii $bids/$sub/fmap/${sub}_acq-n45_phasediff.nii.gz  $dcmdir/GRE_FIELDMAP_0018
add-intended-for -fmap '*acq-n45*phasediff*.json' -for '*task-n45*.nii.gz' ../Data/bids/sub-cm20230803/
add-intended-for -fmap '*acq-n45*mag*.json' -for '*task-n45*.nii.gz' ../Data/bids/sub-cm20230803/

# 0
mknii $bids/$sub/func/${sub}_task-p00_sbref.nii.gz     $dcmdir/BOLD_REST_AP_T_C0_SBREF_0019
mknii $bids/$sub/func/${sub}_task-p00_epi.nii.gz       $dcmdir/BOLD_REST_AP_T_C0_0020
mknii $bids/$sub/fmap/${sub}_acq-p00_dir-AP_epi.nii.gz $dcmdir/SPINECHOFIELDMAP_AP_0022
mknii $bids/$sub/fmap/${sub}_acq-p00_dir-PA_epi.nii.gz $dcmdir/SPINECHOFIELDMAP_PA_0023
mknii $bids/$sub/fmap/${sub}_acq-p00_magnitude.nii.gz  $dcmdir/GRE_FIELDMAP_0024
mknii $bids/$sub/fmap/${sub}_acq-p00_phasediff.nii.gz  $dcmdir/GRE_FIELDMAP_0025
add-intended-for -fmap '*acq-p00*phasediff*.json' -for '*task-p00*.nii.gz' ../Data/bids/sub-cm20230803/
add-intended-for -fmap '*acq-p00*mag*.json' -for '*task-p00*.nii.gz' ../Data/bids/sub-cm20230803/

## -40
mknii $bids/$sub/func/${sub}_task-n40_sbref.nii.gz     $dcmdir/BOLD_REST_AP_T_C-40_SBREF_0027
mknii $bids/$sub/func/${sub}_task-n40_epi.nii.gz       $dcmdir/BOLD_REST_AP_T_C-40_0028
mknii $bids/$sub/fmap/${sub}_acq-n40_dir-AP_epi.nii.gz $dcmdir/SPINECHOFIELDMAP_AP_0031
mknii $bids/$sub/fmap/${sub}_acq-n40_dir-PA_epi.nii.gz $dcmdir/SPINECHOFIELDMAP_PA_0032
mknii $bids/$sub/fmap/${sub}_acq-n40_magnitude.nii.gz  $dcmdir/GRE_FIELDMAP_0033
mknii $bids/$sub/fmap/${sub}_acq-n40_phasediff.nii.gz  $dcmdir/GRE_FIELDMAP_0034
add-intended-for -fmap '*acq-n40*phasediff*.json' -for '*task-n40*.nii.gz' ../Data/bids/sub-cm20230803/
add-intended-for -fmap '*acq-n40*mag*.json' -for '*task-n40*.nii.gz' ../Data/bids/sub-cm20230803/

# TaskName into func/_bold
for f in $bids/$sub/func/*json; do
  [[ $f =~ task-([^_-]*) ]] || continue
  grep TaskName $f ||
    sed -i "1s;^{;{\n\"TaskName\": \"${BASH_REMATCH[1]}\",;" $f
done
