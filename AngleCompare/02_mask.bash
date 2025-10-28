#!/usr/bin/env bash

# fmriprep includes some skull and brainstem. source of noise
# mask with mni brain
test -r mni_brainmask.nii.gz ||
    3dresample \
      -inset ~/.templateflow/tpl-MNI152NLin2009cAsym/tpl-MNI152NLin2009cAsym_res-02_desc-brain_mask.nii.gz \
      -master ../Data/tsnr/sub-1_task-rest0_tsnr.nii.gz \
      -prefix mni_brainmask.nii.gz

test -r mni_GM-0.7.nii.gz ||
    3dresample \
      -inset '3dcalc( -a ~/.templateflow/tpl-MNI152NLin2009cAsym/tpl-MNI152NLin2009cAsym_res-01_label-GM_probseg.nii.gz -expr step(a-.7) )' \
      -master ../Data/tsnr/sub-1_task-rest0_tsnr.nii.gz \
      -prefix mni_GM-0.7.nii.gz

test -r MNI_T1w.nii.gz ||
 3dresample \
    -inset ~/.templateflow/tpl-MNI152NLin2009cAsym/tpl-MNI152NLin2009cAsym_res-01_T1w.nii.gz \
    -master ../Figures/tsnr/sub-1_space-MNI152NLin2009cAsym_fmap.nii.gz \
    -prefix MNI_T1w.nii.gz
