# Scan Console 
*Multi-Tilt Remote Sync* moves DICOM folders to a more capable computer for processing with scripts (in [`../FmapCorrect/`](../FmapCorrect/)) on a more capabile environment. And then copies the results back as a new DICOM folder.

MR acquisitions are immediately available on Windows PC as dicom folders. 
Results need to be views on this computer.

## MTRS
The easiest and quickest solution to transfer, run, and resync is in `MTRS.bat`.
But this is limited and has a difficult UX/UI.

It will upload all files specified and call out to [`../FmapCorrect/00_MTRP`](../FmapCorrect/00_MTRP) on the server side to figure out what is what.


## Rust FLTK
Experiments for other programs doing that are in their own folders based on language.
These need to be compiled to windows binaries.

This can run [`../FmapCorrect/proc_multitilt.bash`](../FmapCorrect/proc_multitilt.bash) on remote directly (instead of using server side folder guessing).

