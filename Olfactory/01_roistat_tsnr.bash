3dROIstats -nzmean -nomeanout -mask ./atlas-AonPirFTTubV4_res-func.nii.gz\
	../Data/tsnr/sub-*task-rest*_tsnr.nii.gz \
	../Data/tsnr/3depi2x2x2/sub-1iso3d_task-rest_*_tsnr.nii.gz |
	sed -E 's/^File/subj\ttask/;s/restn/rest-/;
	s/.*sub-([^_]+)_task-rest([^_]+)_tsnr.nii.gz/\1\t\2/;
	s/.*sub-([^_]+)_task-rest_acq-([^_]+)_tsnr.nii.gz/\1\t\2/;
	s/n([0-9][0-9])/-\1/;
	s/p([0-9][0-9])/\1/;
	' |
	tee atlas-AonPirFTTubV4_tsnr.tsv
