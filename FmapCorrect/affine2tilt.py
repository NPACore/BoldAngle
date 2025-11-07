#!/usr/bin/env python3
import numpy as np
def calc_rot(A):
    # chatgpt
    #M = A[:3,:3]
    #k = M[:,2]
    #k_hat = k / np.linalg.norm(k)
    #z = np.array([0.,0.,1.])
    #angle_rad = np.arctan2(np.linalg.norm(np.cross(k_hat, z)), np.dot(k_hat, z))
    #angle_deg = np.degrees(angle_rad)

    # https://stackoverflow.com/questions/11514063/extract-yaw-pitch-and-roll-from-a-rotationmatrix
    yaw = np.arctan2(A[1,0],A[0,0])
    pitch = np.arctan2(-A[2,0],np.sqrt(A[2,1]**2+A[2,2]**2))
    roll = np.arctan2(A[2,1],A[2,2])

    return [np.round(np.degrees(x),2) for x in (yaw,pitch,roll)]

if __name__ == "__main__":
    from glob import glob
    from os.path import basename
    import sys
    #matdir = '/home/recontwix/data/BOLDSliceAngle/FmapCorrect/wf/2025-11-06_gnl/resliced.nii.gz.mat/'
    matdir = sys.argv[1]
    if len(sys.argv) == 3:
        angle_file = sys.argv[2]
    else:
        angle_file = 'angle.txt'

    affine_mats = sorted(glob(f'{matdir}/*'))
    angles = np.loadtxt(angle_file)

    if (n_mats := len(affine_mats))  != (n_angle := len(angles)):
        raise Exception(f"exptected angles({n_angle} {angle_file}) and volumes ({n_mats} {matdir}) do not match")

    tilts = [ calc_rot(np.loadtxt(f))[2] for f in affine_mats]
    # ref volume is middle. might not be the actual AC-PC 0 deg
    # TODO: can we do this -- linearly adjust tilt?
    #       do we need to update the ref region before aligning?
    i0 = np.flatnonzero(np.round(angles,0)==0)[0] # == 6; 7/10 is AC/PC 0 deg
    offset0 = tilts - tilts[i0] - angles[i0]

    disp_array = [f"{basename(f)}\t{t:>6.2f}\t{a:>6.2f}\t{(-a-t):>5.2f}"
                  for a,f,t in zip(angles,affine_mats,offset0)]
    print("ind_00xx\taffine\texpect\t diff")
    print("\n".join(disp_array))
