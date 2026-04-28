#!/usr/bin/env bash

# datatable like:
# Subj	Angle	InputFile
# 1	0	../Data/tsnr/sub-1_task-rest0_tsnr.nii.gz
skip-exist tsnr_mvm.nii.gz \
 3dMVM \
  -prefix tsnr_mvm.nii.gz \
  -qVars Angle\
  -qVarCenters 0\
  -wsVars Angle \
  -bsVars 1 \
  -num_glt 1 \
  -gltLabel 1 BestAngle  -gltCode 1 'Angle : 1'  \
  -mask mni_brainmask.nii.gz \
  -dataTable @2depi_datatable.txt

skip-exist tsnr_lme.nii.gz \
 3dLMEr \
  -overwrite \
  -model  'Angle+(1|Subj)' \
  -SS_type 3 \
  -jobs 32 \
  -gltCode Angle 'Angle : 1' \
  -qVars Angle \
  -qVarCenters 0 \
  -mask mni_brainmask.nii.gz \
  -prefix tsnr_lme.nii.gz \
  -dataTable @2depi_datatable.txt


# datatable like:
# Subj	Angle	InputFile
# 2d	13	../Data/tsnr/sub-1_task-rest13_tsnr.nii.gz
# 3d	13	../Data/tsnr/3depi2x2x2/sub-1iso3d_task-rest_acq-p13_tsnr.nii.gz
skip-exist tsnr_3dV2d_lme.nii.gz \
 3dLMEr \
  -overwrite \
  -model  'Subj*Angle+(1|Subj)' \
  -SS_type 3 \
  -jobs 32 \
  -gltCode Angle 'Angle : 1' \
  -qVars Angle \
  -qVarCenters 0 \
  -mask mni_brainmask.nii.gz \
  -prefix __SKIPFILE \
  -dataTable @3d-v-2d_datatable.txt
