#!/usr/bin/env bash
#
# 3depi dicom header TR reports slice not volume
#  use ./get_tr.R to calculate based on image time
#
# realized this after running fmriprep
# b/c xcpd wont run with not enough time (.06*200 < 100s)
#
# globals TR and INDIRS set for iso. 
# for non-iso version of data:
#  TR=1.425 INDIRS="../Data/preproc/bids-3depi/fmriprep-25.2.3/sub-1 ../Data/bids-3depi/" ./03_reset_tr.bash
TR=${TR:-2.14} # see get_tr.R
mapfile -t FILES < <(find \
  ${INDIRS:-../Data/bids-3depi2x2x2/ ../Data/preproc/bids-3depi2x2x2/fmriprep-25.2.3/sub-1iso3d/}\
  \( -iname '*task-*.nii.gz' -or -iname '*task-*.json' \) \
  -and -not -iname '*mask*' \
  -and -not -iname '*sbref*' \
  -and -not -iname '*boldref*' \
  -and -not -iname '*n40p20*' )
echo "# working on ${#FILES[@]} files"
for f in "${FILES[@]}"; do
  case $f in
    *nii.gz)
	    [[ $(3dinfo -nt $f) == 1 ]] && echo "# NOTE: only one timepoint in $f; skipping" && continue
	    curTR=$(3dinfo -tr $f)
	    [[ $curTR =~ ^$TR ]] && echo "# have $TR (as $curTR) in $f" && continue
	    echo "# curTR $curTR setting to $TR for $f"
	    dryrun 3drefit -TR $TR "$f";
	    ;;
    *json)
	    ! grep -q RepetitionTime $f && echo "# NOTE: no RepetitionTime in $f" && continue
	    curTR=$(jq -r .RepetitionTime $f)
	    [[ $curTR == "$TR" ]] && echo "# have $TR in $f" && continue
	    echo "# curTR $curTR setting to $TR for $f"
	    dryrun perl -pi -e "s/(\"RepetitionTime\":) [0-9.]+/\1 $TR/g" $f
	    ;;
    *) echo "#ERROR don't know what to do with $f (not nii.gz or json)"; continue;;
  esac
done

