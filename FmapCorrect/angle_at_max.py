#!/usr/bin/env python3
import argparse
import numpy as np
import nibabel as nib

parser = argparse.ArgumentParser(description="Report max normalized intensity per voxel")
parser.add_argument('-i', '--input', type=str, required=True, help="Path to epi file.")
parser.add_argument('-m', '--mask', type=str, required=True, help="Path to mask file.")
parser.add_argument('-o', '--output', type=str, required=True, help="Path to save file.")
parser.add_argument('-n', '--normed_out', type=str, required=False, help="Where to save SD normed file.", default=None)
parser.add_argument('-l', '--labelfile', type=str, required=False, help="File containing label values (float)", default="angle.txt")
args = parser.parse_args()

ep = nib.load(args.input)
mask = nib.load(args.mask)

ep_brain = np.where(np.asanyarray(mask.dataobj)>0,1, np.nan)
sd = np.std(ep.dataobj, axis=(0,1,2), where=np.isfinite(ep_brain[...,np.newaxis]))
mx = np.argmax(ep.dataobj/sd, axis=3)

an = np.loadtxt(args.labelfile, dtype=float)
angle_3d = an[mx] * ep_brain

out = nib.Nifti1Image(angle_3d, ep.affine, ep.header)
nib.save(out, args.output)

if args.normed_out:
    vis = ep.dataobj * sd;
    nib.save(nib.Nifti1Image(vis, ep.affine,ep.header), args.normed_out)
