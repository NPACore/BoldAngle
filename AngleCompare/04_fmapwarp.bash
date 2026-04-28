#!/usr/bin/env bash
export SKIP_QUIET=1

# want to compare spinecho derived fieldmaps for each angle
# 20260411WF - init


# make sure to not catch new derivs like "auto00000_space-152NLin2009cAsym_desc-preproc_fieldmap.nii.gz"
fmap_list=(../Data/preproc/bids-*/fmriprep-25.2.3/sub-*/fmap/*[0-9][0-9][0-9]_desc-preproc_fieldmap.nii.gz)
fmap_to_mni() {
 f=${1:?path to desc-preproc_fieldmap within fmriprep deriv tree}
 #grep -Po 'auto\d+' < <(jq .AnatomicalReference ${f/.nii.gz/.json})
 ! [[ $f =~ ^(.*)/fmap/.*fmapid-(auto[0-9]+) ]] && echo "ERROR: no fmap/.*autoid in '$f'" && return 1
 sesroot=${BASH_REMATCH[1]}
 autoid=${BASH_REMATCH[2]}
 # from-boldref_to-auto00002_mode-image_desc-fmap_xfm.txt
 boldxfm=($sesroot/func/*from-boldref_to-${autoid}_mode-image_desc-fmap_xfm.txt)
 ! test -r ${boldxfm[0]} && echo "ERROR: no boldxfm for '$f' like '${boldxfm[*]}'" && return 2
 # from-boldref_to-T1w_mode-image_desc-coreg_xfm.txt
 t1xfm=${boldxfm/_to-${autoid}_mode-image_desc-fmap_xfm/_to-T1w_mode-image_desc-coreg_xfm}
 ! test -r $t1xfm && echo "ERROR: no t1xfm for '$f' like '$t1xfm' (pair of '${boldxfm[*]}')" && return 3
 # ../Data/preproc/bids-3depi2x2x2/fmriprep-25.2.3/sub-1iso3d/anat/sub-1iso3d_desc-preproc_T1w.nii.gz
 t1ref=($sesroot/anat/*_desc-preproc_T1w.nii.gz)
 ! test -r ${t1ref[0]} && echo "ERROR: no t1ref for '$f' like '${t1ref[*]}'" && return 4

 t1out=${f/_desc-preproc/_space-T1w_desc-preproc}

 echo "# $t1out"
 skip-exist $t1out dryrun niinote $t1out \
    antsApplyTransforms -i "$f" -t "$t1xfm" -t "[$boldxfm,1]" -r "${t1ref[0]}" -o $t1out

 mniout=${t1out/space-T1w/space-MNI152NLin2009cAsym}
 mniout_res=${t1out/space-T1w/space-MNI152NLin2009cAsym_res-native}
 echo "# $mniout_res"
 if ! test -r "$mniout_res"; then
   # sub-1iso3d_space-MNI152NLin2009cAsym_desc-preproc_T1w.nii.gz
   mniref=${t1ref/_desc/_space-MNI152NLin2009cAsym_desc}
   ! test -r "$mniref" && echo "ERROR: no mniref for '$f' like '$mniref'" && return 5
   # sub-1iso3d_from-T1w_to-MNI152NLin2009cAsym_mode-image_xfm.h5
   mniwarp=${mniref/_space.*/from-T1w_to-MNI152NLin2009cAsym_mode-image_xfm.h5}
   ! test -r $warp && echo "ERROR: no mniwarp for '$f' like '$mniwarp'" && return 6
   dryrun niinote $mniout \
    antsApplyTransforms -i "$f" -t "$mniwarp" -t "$t1xfm" -t "[$boldxfm,1]" -r "${t1ref[0]}" -o $mniout
   dryrun 3drefit -space MNI $mniout

   # 20260413 - want 2x2x2 matching func res
   # ../Data/preproc/bids-3depi2x2x2/fmriprep-25.2.3/sub-1iso3d/func/sub-1iso3d_task-n40p20_space-MNI152NLin2009cAsym_boldref.nii.gz
   mniref_res=($sesroot/func/*MNI152*_boldref*.nii.gz)
   mniref_res=${mniref_res[0]}

   ! test -r "$mniref_res" && echo "ERROR: no mniref at res for '$f' like '$mniref_res'" && return 7
   dryrun 3dresample -prefix "$mniout_res" -inset "$mniout" -master "$mniref_res" 
 fi

}
fmap_to_mni_all(){
    export -f fmap_to_mni
    parallel -J10 -N1  -- fmap_to_mni {1} ::: "${fmap_list[@]}"
}
eval "$(iffmain fmap_to_mni_all)"



: <<ENDCOMMENT

 niinote /tmp/fmap_to_t1w.nii.gz antsApplyTransforms -i ../Data/preproc/bids-3depi2x2x2/fmriprep-25.2.3/sub-1iso3d/fmap/sub-1iso3d_acq-largefov_fmapid-auto00000_desc-preproc_fieldmap.nii.gz -t ../Data/preproc/bids-3depi2x2x2/fmriprep-25.2.3/sub-1iso3d/func/sub-1iso3d_task-n40p20_from-boldref_to-T1w_mode-image_desc-coreg_xfm.txt -t "[../Data/preproc/bids-3depi2x2x2/fmriprep-25.2.3/sub-1iso3d/func/sub-1iso3d_task-n40p20_from-boldref_to-auto00000_mode-image_desc-fmap_xfm.txt,1]" -r ../Data/preproc/bids-3depi2x2x2/fmriprep-25.2.3/sub-1iso3d/anat/sub-1iso3d_desc-preproc_T1w.nii.gz -o /tmp/fmap_to_t1w.nii.gz


niinote /tmp/fmap_to_mni.nii.gz antsApplyTransforms -i ../Data/preproc/bids-3depi2x2x2/fmriprep-25.2.3/sub-1iso3d/fmap/sub-1iso3d_acq-largefov_fmapid-auto00000_desc-preproc_fieldmap.nii.gz  -t ../Data/preproc/bids-3depi2x2x2/fmriprep-25.2.3/sub-1iso3d/anat/sub-1iso3d_from-T1w_to-MNI152NLin2009cAsym_mode-image_xfm.h5 -t ../Data/preproc/bids-3depi2x2x2/fmriprep-25.2.3/sub-1iso3d/func/sub-1iso3d_task-n40p20_from-boldref_to-T1w_mode-image_desc-coreg_xfm.txt -t "[../Data/preproc/bids-3depi2x2x2/fmriprep-25.2.3/sub-1iso3d/func/sub-1iso3d_task-n40p20_from-boldref_to-auto00000_mode-image_desc-fmap_xfm.txt,1]" -r ../Data/preproc/bids-3depi2x2x2/fmriprep-25.2.3/sub-1iso3d/anat/sub-1iso3d_space-MNI152NLin2009cAsym_desc-preproc_T1w.nii.gz -o /tmp/fmap_to_mni.nii.gz

jq . Data/preproc/bids-a10/fmriprep-25.2.3/sub-1/fmap/sub-1_acq-rest6_fmapid-auto00002_desc-preproc_fieldmap.json
{
  "AnatomicalReference": "sub-1_acq-rest6_fmapid-auto00002_desc-epi_fieldmap.nii.gz",
  "AssociatedCoefficients": [
    "sub-1_acq-rest6_fmapid-auto00002_desc-coeff_fieldmap.nii.gz"
  ],
  "B0FieldIdentifier": "auto_00002",
  "IntendedFor": [
    "func/sub-1_task-rest6_bold.nii.gz",
    "func/sub-1_task-rest6_sbref.nii.gz"
  ],
  "RawSources": [
    "/home/boldsliceangle/BOLDSliceAngle/Data/bids-a10/sub-1/fmap/sub-1_acq-rest6_dir-AP_epi.nii.gz",
    "/home/boldsliceangle/BOLDSliceAngle/Data/bids-a10/sub-1/fmap/sub-1_acq-rest6_dir-PA_epi.nii.gz"
  ],
  "Units": "Hz"
}
 jq . Data/preproc/bids-a10/fmriprep-25.2.3/sub-1/func/*auto000*2*.json
 {
   "Sources": [
     "bids:raw:sub-1/func/sub-1_task-rest6_sbref.nii.gz",
     "bids::sub-1/fmap/sub-1_acq-rest6_fmapid-auto00002_desc-epi_fieldmap.nii.gz"
   ]
 }

 jq . Data/preproc/bids-a10/fmriprep-25.2.3/sub-1/func/*auto000*2*.json
{
  "Sources": [
    "bids:raw:sub-1/func/sub-1_task-rest6_sbref.nii.gz",
    "bids::sub-1/fmap/sub-1_acq-rest6_fmapid-auto00002_desc-epi_fieldmap.nii.gz"
  ]
}
ENDCOMMENT
