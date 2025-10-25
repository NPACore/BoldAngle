#!/usr/bin/env bash

# fmriprep includes some skull and brainstem. source of noise
# mask with mni brain
3dresample -inset ~/.templateflow/tpl-MNI152NLin2009cAsym/tpl-MNI152NLin2009cAsym_res-02_desc-brain_mask.nii.gz \
	-master ../Data/tsnr/sub-1_task-rest0_tsnr.nii.gz \
	-prefix mni_brainmask.nii.gz
