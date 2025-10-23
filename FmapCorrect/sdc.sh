#!/usr/bin/env bash
set -xeuo pipefail
export PATH="$PATH:/opt/ni_tools/afni:/opt/ni_tools/fsl:/opt/ni_tools/fmri_processing_scripts:/opt/ni_tools/lncdtools"
export MRI_STDDIR=NA # preproc scripts look for MNI dir. dont need for distortion correction

# ./sdc.bash "$out/mean_epi_brain.nii.gz" "$dicom_mag" "$dicom_phasediff" $(jq '.EchoTime' $out/epi_angles.json)
# from 'prepare_fieldmap'

epi_brain=${1:?EPI Brain} # $out/mean_epi_brain.nii.gz
out=$(dirname "$epi_brain")
dicom_mag=${2:?Magnitude folder. first of two. 2x the dicoms}
dicom_phasediff=${3:?Phasediff folder. first of two. 2x the dicoms}
epiTE=${4:?EPI TE in seconds} # .03s
unwarpdir=y
fugue_unwarpdir=$unwarpdir # BADBAD bug if 'x-' elsewhere, needs to be 'x' for fugue. have 'y' so shouldnt matter
echoSpacing=0.580009; #ms
GRAPPAAccel=1
dwelltime=$(echo "($echoSpacing/$GRAPPAAccel)/1000" | bc -l) # 0.000XXX sec

fmap_unwarp_field=$out/sdc/unwarp/EF_UD_warp.nii.gz

# initially had dicoms, but can also support nifti instead
ppd_args=(-magdir $dicom_mag -phasedir $dicom_phasediff  -mrpatt '*IMA')
test -f $dicom_mag && ppd_args=(-mag $dicom_mag -phase $dicom_phasediff -method gre.nii.gz )

preprocessDistortion \
	 -savedir $out/sdc \
	 ${ppd_args[@]} \
	 -fm_cfg $PWD/largefov_gre.fmcfg

# copy of func registration target
fslmaths $epi_brain   $out/sdc/unwarp/EF_D_mc_target	

cd $out/sdc/unwarp

    #change image orientation to LPI/RPI to match EPI (ease registration)
    #N.B. This needs to be run on the local copies, not in $fm_phasedir to avoid file collisions during parallel runs of preprocessFunctional
    #rel "fslreorient2std FM_UD_fmap FM_UD_fmap"
    #rel "fslreorient2std FM_UD_fmap_mag FM_UD_fmap_mag"
    #rel "fslreorient2std FM_UD_fmap_mag_brain FM_UD_fmap_mag_brain"

    ### STEP 2: Create and refine mask for fieldmap based on magnitude image.
    #rel "Creating masks" c
    # Create a binary mask of the non-zero voxels of the fieldmap magnitude image (which was skull-stripped above)
fslmaths FM_UD_fmap_mag_brain -bin FM_UD_fmap_mag_brain_mask -odt short

    #the steps below (up through re-creation of FM_UD_fmap_mag_brain_mask) appear to try to handle the case where
    #either the fmap_rads or fmap_mag images have already been masked elsewhere, and we want to recreate a reasonable mask.

    # abs the original fieldmap, binarize, then mask based on the 1/0 magnitude image, invert by *-1, + 1, binarize (to be safe).
    # The result, FM_UD_fmap_mag_brain_mask_inv, is the non-zero voxels of the *fieldmap* (not magnitude) inverted such that
    # brain-ish voxels are 0 and non-brain voxels are 1.
    # This may lead to a circumstance where there are brain voxels of interest that have value 0 in the fieldmap. (patchy holes)
fslmaths FM_UD_fmap -abs -bin -mas FM_UD_fmap_mag_brain_mask -mul -1 -add 1 -bin FM_UD_fmap_mag_brain_mask_inv

    # To handle the above scenario of 0-valued voxels in fieldmap, use cluster to obtain the largest cluster of non-zero
    # (non-brain) voxels in the above mask. The output of cluster is an integer-valued image with masks for each spatial cluster
FSLCLUSTER=fsl-cluster
command -v $FSLCLUSTER >&/dev/null || FSLCLUSTER=cluster
$FSLCLUSTER -i FM_UD_fmap_mag_brain_mask_inv -t 0.5 --no_table -o FM_UD_fmap_mag_brain_mask_idx

    # This will grab the largest spatial cluster (the max of the range, -R), which refers to the biggest non-brain cluster
    outsideIdx=$(fslstats FM_UD_fmap_mag_brain_mask_idx -R | awk '{print  $2}')

    # Now take the clusters image, zero everything below the max (where max contains the biggest non-brain cluster),
    # binarize the image, re-invert (*-1 + 1), binarize again, then mask by the skull-stripped magnitude image.
    # Overwrite the fieldmap magnitude brain mask with the result, which reflects the largest non-zero cluster

fslmaths FM_UD_fmap_mag_brain_mask_idx -thr $outsideIdx -bin -mul -1 -add 1 -bin -mas FM_UD_fmap_mag_brain_mask FM_UD_fmap_mag_brain_mask

### Refine Mask
## De-median the fieldmap (to avoid gross shifting)
# compute median of non-zero voxels in fieldmap, masking by the useful voxels (from mask steps above)
medVal=$(fslstats FM_UD_fmap -k FM_UD_fmap_mag_brain_mask -P 50 | sed 's/ //g') # 112.242508

# subtract off the median from all fieldmap voxels within the relevant mask, then overwrite fmap
fslmaths FM_UD_fmap -sub $medVal -mas FM_UD_fmap_mag_brain_mask FM_UD_fmap

# From skull-stripped magnitude image, compute 98th pctile of nonzero voxels, divide by 2
almostHalfMax=$(fslstats FM_UD_fmap_mag_brain -P 98 | awk '{print $1/2.0}') # 563.5
fslmaths FM_UD_fmap_mag_brain -thr $almostHalfMax -bin FM_UD_fmap_mag_brain_mask50
fslmaths FM_UD_fmap_mag_brain_mask -ero FM_UD_fmap_mag_brain_mask_ero
fslmaths FM_UD_fmap_mag_brain_mask_ero -add FM_UD_fmap_mag_brain_mask50 -thr 0.5 -bin FM_UD_fmap_mag_brain_mask
fslmaths FM_UD_fmap -mas FM_UD_fmap_mag_brain_mask FM_UD_fmap
#Despiking edges of fieldmap image
fslmaths FM_UD_fmap_mag_brain_mask -ero FM_UD_fmap_mag_brain_mask_ero

fugue --loadfmap=FM_UD_fmap --savefmap=FM_UD_fmap_tmp_fmapfilt \
      --mask=FM_UD_fmap_mag_brain_mask --despike --despikethreshold=2.1

    fslmaths FM_UD_fmap -sub FM_UD_fmap_tmp_fmapfilt -mas FM_UD_fmap_mag_brain_mask_ero -add FM_UD_fmap_tmp_fmapfilt FM_UD_fmap
mkdir -p tmp/
    mv FM_UD_fmap_tmp_fmapfilt* FM_UD_fmap_mag_brain_mask_ero* FM_UD_fmap_mag_brain_mask50* FM_UD_fmap_mag_brain_mask_i* tmp/

    ### STEP 4: Demedian fieldmap (again)
    medVal=$(fslstats FM_UD_fmap -k FM_UD_fmap_mag_brain_mask -P 50 | sed 's/ //g' ) # -0.623573

    fslmaths FM_UD_fmap -sub $medVal -mas FM_UD_fmap_mag_brain_mask FM_UD_fmap
# get a sigloss estimate and make (-s) a siglossed estimate for forward warp
# to be Distorted (ref (after *mag) and refweight in EF_2_FM warp) and warped to epi (sigloss+*png)
sigloss -i FM_UD_fmap --te="$epiTE" -m FM_UD_fmap_mag_brain_mask -s FM_UD_fmap_sigloss
# make siglossed magnitude image for EPI -> fieldmap warp
fslmaths FM_UD_fmap_sigloss -mul FM_UD_fmap_mag_brain FM_UD_fmap_mag_brain_siglossed -odt float

    # Distort mag_brain_siglossed and fmap_sigloss based on FD_UD_fmap.
    # This uses the "forward warp" of the fieldmap to distort the sigloss and magnitude images
    # to match EPI. These are then used for the sigloss+mag png file.
    fugue -i FM_UD_fmap_mag_brain_siglossed \
           --loadfmap=FM_UD_fmap --mask=FM_UD_fmap_mag_brain_mask --dwell=$dwelltime \
           -w FM_D_fmap_mag_brain_siglossed --nokspace --unwarpdir=$fugue_unwarpdir

    fugue -i FM_UD_fmap_sigloss \
           --loadfmap=FM_UD_fmap --mask=FM_UD_fmap_mag_brain_mask --dwell=$dwelltime \
           -w FM_D_fmap_sigloss --nokspace --unwarpdir=$fugue_unwarpdir


# align target epi (is distorted) to mag fieldmap (with distortion applied)
# use distorted sigloss as a reference weight
# mc_target is distorted and has falloff in high sigloss areas (darkening)
# FM magnitude siglossed has been distorted and darkened similarly to improve coregistration
# In addition, weight the "good" voxels (low sigloss) more in the registration cost function
flirt -in EF_D_mc_target -ref FM_D_fmap_mag_brain_siglossed -omat func_to_fmap.mat -o grot -dof 6
# reverse  EF->FM  to get FM->EF (to put all fieldmap stuff in epi space)
convert_xfm -omat fmap_to_epi.mat -inverse func_to_fmap.mat
# needed for more than a picture? Yes

    for file in "FM_UD_fmap" "FM_UD_fmap_mag_brain" "FM_UD_fmap_mag_brain_mask" "FM_UD_fmap_sigloss"; do
	#creates "EF_UD_fmap" "EF_UD_fmap_mag_brain" "EF_UD_fmap_mag_brain_mask" "EF_UD_fmap_sigloss"
	flirt -in $file -ref EF_D_mc_target -init fmap_to_epi.mat -applyxfm -out ${file/FM_/EF_} -interp spline
    done

##STEP 9. UNWARP TARGET EPI (mc_target)
# epi: D -> UD (undistort mc_target)
# unwarp EF_D_mc_target to EF_UD_mc_target (for thumbnail, compare to original, and in convertwarp to build applywarp)
# and save unwarp-shiftmap then convert to unwarp warpfield
# -u is unwarp 
fugue --loadfmap=EF_UD_fmap --dwell=$dwelltime --mask=EF_UD_fmap_mag_brain_mask -i EF_D_mc_target -u EF_UD_mc_target --unwarpdir=$fugue_unwarpdir --saveshift=EF_UD_shift
convertwarp -s EF_UD_shift -o EF_UD_warp -r EF_D_mc_target --shiftdir=$unwarpdir --relout
