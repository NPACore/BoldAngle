#!/usr/bin/env python3
import numpy as np
import nibabel as nib
an = np.loadtxt('angle.txt', dtype=int)
ep = nib.load('wf/epi_undistored.nii.gz')
mask = nib.load('./wf/mean_epi_brain.nii.gz')
ep_brain = np.where(np.asanyarray(mask.dataobj)>0,1, np.nan)
sd = np.std(ep.dataobj, axis=(0,1,2), where=np.isfinite(ep_brain[...,np.newaxis]))
mx = np.argmax(ep.dataobj/sd, axis=3)
angle_3d = an[mx] * ep_brain

out = nib.Nifti1Image(angle_3d, ep.affine, ep.header)
nib.save(out, "wf/angle_at_max.nii.gz")

vis = ep.dataobj * sd;
nib.save(nib.Nifti1Image(vis, ep.affine,ep.header), "wf/ep_undist_sdnorm.nii.gz")
