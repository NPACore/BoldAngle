3dMVM \
  -prefix tsnr_lme.nii.gz \
  -qVars Angle\
  -qVarCenters 0\
  -wsVars Angle \
  -bsVars 1 \
  -num_glt 1 \
  -gltLabel 1 BestAngle  -gltCode 1 'Angle : 1'  \
  -mask mni_brainmask.nii.gz \
  -dataTable \
Subj	Angle	InputFile \
1	0	../Data/tsnr/sub-1_task-rest0_tsnr.nii.gz   \
1	6	../Data/tsnr/sub-1_task-rest6_tsnr.nii.gz   \
1	13	../Data/tsnr/sub-1_task-rest13_tsnr.nii.gz  \
1	20	../Data/tsnr/sub-1_task-rest20_tsnr.nii.gz  \
1	-6	../Data/tsnr/sub-1_task-restn6_tsnr.nii.gz  \
1	-13	../Data/tsnr/sub-1_task-restn13_tsnr.nii.gz \
1	-19	../Data/tsnr/sub-1_task-restn19_tsnr.nii.gz \
1	-26	../Data/tsnr/sub-1_task-restn26_tsnr.nii.gz \
1	-33	../Data/tsnr/sub-1_task-restn33_tsnr.nii.gz \
1	-39	../Data/tsnr/sub-1_task-restn39_tsnr.nii.gz \
2	0  	../Data/tsnr/sub-2_task-rest0_tsnr.nii.gz   \
2	6  	../Data/tsnr/sub-2_task-rest6_tsnr.nii.gz   \
2	13 	../Data/tsnr/sub-2_task-rest13_tsnr.nii.gz  \
2	20 	../Data/tsnr/sub-2_task-rest20_tsnr.nii.gz  \
2	-6 	../Data/tsnr/sub-2_task-restn6_tsnr.nii.gz  \
2	-13	../Data/tsnr/sub-2_task-restn13_tsnr.nii.gz \
2	-19	../Data/tsnr/sub-2_task-restn19_tsnr.nii.gz \
2	-26	../Data/tsnr/sub-2_task-restn26_tsnr.nii.gz \
2	-33	../Data/tsnr/sub-2_task-restn33_tsnr.nii.gz \
2	-39	../Data/tsnr/sub-2_task-restn39_tsnr.nii.gz \
