#!/usr/bin/env python3
#
# Run batch file in Windows command terminal
# MultiTiltRemote dicomfolder angle.txt
#
import os, sys

SERVER="moonc@10.48.88.13"
ID_FILE="gyrus2"
REMOTE_SYNC="~/sshremote/BOLDSliceAngle"

dcmfolder=sys.argv[1]
anglefile=sys.argv[2]
rslcdcmfolder=f"Reslice_{dcmfolder}"

# TODO: can system calls be concatted?
os.system(f"""
echo scp -rpi {ID_FILE} {dcmfolder} {anglefile} {SERVER}:{REMOTE_SYNC}/ """)

# remote run
os.system(f"""
echo ssh -i {ID_FILE} {SERVER} "~/data/BOLDSliceAngle/FmapCorrect/proc_multitilt.bash ${REMOTE_SYNC}" """) 

# fetch remote results
os.system(f"""
echo scp -rpi {ID_FILE} {SERVER}:{REMOTE_SYNC}/{rslcdcmfolder} .""")

# cleanup on remote
#ssh -i gyrus2 %server% "cd ~/sshremote/BOLDSliceAngle; chmod -R 775 *; rm -rf %dcmfolder%; rm -rf %rslcdcmfolder%; rm %anglefile%; rm -rf Analyzer;" 
