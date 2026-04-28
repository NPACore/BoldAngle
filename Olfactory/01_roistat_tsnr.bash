#!/usr/bin/env bash
cleanup_names(){
sed -E 's/^File/subj\ttask/;s/restn/rest-/;
	s/.*sub-([^_]+)_task-rest([^_]+)_tsnr.nii.gz/\1\t\2/;
	s/.*sub-([^_]+)_task-rest_acq-([^_]+)_tsnr.nii.gz/\1\t\2/;
	s/.*sub-([^_]+)_task-(n40p20).*.nii.gz/\1\t\2/;
	s/n([0-9][0-9])/-\1/;
	s/p([0-9][0-9])/\1/;'
}
tsnr_files=(../Data/tsnr/sub-*task-rest*_tsnr.nii.gz ../Data/tsnr/3depi2x2x2/sub-1iso3d_task-rest_*_tsnr.nii.gz)

atlas_mask=./atlas-AonPirFTTubV4_res-func.nii.gz
dseg=../Data/preproc/bids-a10/fmriprep-25.2.3/sub-1/anat/sub-1_space-MNI152NLin2009cAsym_res-task_dseg.nii.gz

3dROIstats -nzmean -nomeanout -mask $atlas_mask "${tsnr_files[@]}" |
	cleanup_names | tee atlas-AonPirFTTubV4_tsnr.tsv

# 20260427 - added res-task but not sure what made that :gulp: WM GM and CSF
3dROIstats -nzmean -nomeanout -mask $dseg "${tsnr_files[@]}" |
  cleanup_names | tee atlas-dseg_tsnr.tsv

# 20260427 - also add same for n40p20 acqusistion (now magnitude instead of tSNR)
angle_files=(
../Data/preproc/bids-3depi2x2x2/fmriprep-25.2.3/sub-1iso3d/func/sub-1iso3d_task-n40p20_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz
../Data/preproc/bids-a10/fmriprep-25.2.3/sub-1/func/sub-1_task-n40p20_acq-inc_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz
../Data/preproc/bids-a10/fmriprep-25.2.3/sub-2/func/sub-2_task-n40p20_acq-inc_run-2_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz)

3dROIstats -nzmean -nomeanout -mask $atlas_mask "${angle_files[@]}" |
	cleanup_names | tee atlas-AonPirFTTubV4_n40p20.tsv

3dROIstats -nzmean -nomeanout -mask $dseg "${angle_files[@]}" |
  cleanup_names | tee atlas-dseg_n40p20.tsv
