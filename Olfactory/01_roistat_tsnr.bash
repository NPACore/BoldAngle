3dROIstats -nzmean -nomeanout -mask ./atlas-AonPirFTTub_res-func.nii.gz ../Data/tsnr/sub-*task-rest*_tsnr.nii.gz |
	sed -E 's/^File/subj\ttask/;s/restn/rest-/;s/.*sub-([^_]+)_task-rest([^_]+)_tsnr.nii.gz/\1\t\2/;' |
	tee atlas-AonPirFTTub_tsnr.tsv
