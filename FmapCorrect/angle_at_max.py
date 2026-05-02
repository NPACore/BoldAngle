#!/usr/bin/env python3
# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "nibabel",
# ]
# ///
import argparse
import os
import sys

import nibabel as nib
import numpy as np

parser = argparse.ArgumentParser(
    description="Report max normalized intensity per voxel"
)
parser.add_argument("-i", "--input", nargs='+', type=str, required=True, help="Path to epi file.")
parser.add_argument("-m", "--mask", type=str, required=True, help="Path to mask file.")
parser.add_argument(
    "-o", "--output", type=str, required=False, help="Path to save file."
)
parser.add_argument(
    "-n",
    "--normed_out",
    type=str,
    required=False,
    help="Where to save SD normed file.",
    default=None,
)
parser.add_argument(
    "-l",
    "--labelfile",
    type=str,
    required=False,
    help="File containing label values (float)",
    default="angle.txt",
)
parser.add_argument(
    "--nosd",
    required=False,
    help="Do not norm by standard devatoin",
    action="store_true",
    default=False,
)
args = parser.parse_args()

mask = nib.load(args.mask)
ep_brain = np.where(np.asanyarray(mask.dataobj) > 0, 1, np.nan)

ep_eg = nib.load(args.input[0]) # assume all have same header info!
ep4d_data = np.squeeze(np.stack([nib.load(i).dataobj for i in args.input], axis=3))

if args.nosd:
    sd = np.ones(ep4d_data.shape)
else:
    sd = np.std(
        ep4d_data, axis=(0, 1, 2), where=np.isfinite(ep_brain[..., np.newaxis])
    )
mx = np.argmax(ep4d_data / sd, axis=3)

if args.output:
    an = np.loadtxt(args.labelfile, dtype=float)
    angle_3d = an[mx] * ep_brain

    out = nib.Nifti1Image(angle_3d, ep_eg.affine, ep_eg.header)
    nib.save(out, args.output)

    # maintain provenance
    notes = f'AFNI_NIFTI_TYPE_WARN=NO 3dNotes -h "{" ".join(sys.argv)}" "{args.output}"'
    os.system(notes)

if args.normed_out:
    vis = ep4d_data / sd
    nib.save(nib.Nifti1Image(vis, ep_eg.affine, ep_eg.header), args.normed_out)
    notes = f'AFNI_NIFTI_TYPE_WARN=NO 3dNotes -h "{" ".join(sys.argv)}" "{args.normed_out}"'
    os.system(notes)
