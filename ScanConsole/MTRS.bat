@echo off
REM/||(
MUTLI-TILT REMOTE PROCESSING

USAGE:
  MTR.bat epidcmdir/ gre_mag/ gre_phase/ angle.txt

  expects to be run from within session directory

SYNOPSIS:
 1. send data to station specific remote server location
 2. run reslicing, susptablity correction, and voxelwise best-tilt by magnitutde
 3. copy reconstructed dicom here
)


REM  PARAMS
REM  ------
REM * Identifier for this scan console
REM   Assume one scanner will never try to run more than one at a time
set THISCOMP=Prisma1
REM * Remote SSH user@server  
set SERVER=moonc@10.48.88.13
REM * Identity file for passwordless access to remote server
set ID_FILE=gyrus2

REM fixed location to use as staging area
set upload_area=~/sshremote/BOLDSliceAngle/%THISCOMP%

REM Server interaction
REM ------------------
REM send dicom folders and angle.txt to server; run pipeline; copy data back
REM best-dicom-folder is always the output
REM always start with rm just incase we failed before
ssh   -i %ID_FILE% %SERVER% "test -d '%upload_area%' && rm -r '%upload_area%'; mkdir -p '%upload_area%'"
scp -rpi %ID_FILE% %* %SERVER%:%upload_area%
ssh   -i %ID_FILE% %SERVER% "/home/recontwix/data/BOLDSliceAngle/FmapCorrect/proc_multitilt.bash %upload_area%" 
scp -rpi %ID_FILE% %SERVER%:%upload_area%/dcm-best-tilt besttilt
ssh -i %ID_FILE% %SERVER% "rm %upload_area%" 
