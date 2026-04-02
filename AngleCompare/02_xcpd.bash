#!/usr/bin/env bash
#
# runs xcpd ontop of fmriprep. see 01_preproc_fmriprep.bash
# Mar 5 - init (?)
# 20260402WF - for all fmriprep puts (reset dataset regexp; disable $f =~ bids-3depi)
# 
# NB. TR header for 3depis needs to be corrected.
#     TR@.06s*200 volumes < 100s
#     ../3depi_iso/03_reset_tr.bash (and get_tr.R)

set -euo pipefail
export FDTHRES=${FDTHRES:-0.3}
export USEBANDPASS=${USEBANDPASS:-yes}
export INPUT_TYPE=${INPUT_TYPE:-nifti}
XCPDVER=0.12.0
PREPVER=25.2.3
datadir="$(cd "$(dirname "$0")/../Data"; pwd)"
prepdir=$datadir/preproc/fmriprep-$PREPVER
export FS_LICENSE=$PWD/fs_license.txt TEMPLATEFLOW_HOME=$HOME/.templateflow

[[ "${USEBANDPASS:-}" == "no" ]] && bandpass_yesno="--disable-bandpass-filter" || bandpass_yesno=""

# run each "sub" separately
# ls -d ../Data/preproc/bids-*/fmriprep*[0-9]/sub-*/
#  ../Data/preproc/bids-3depi2x2x2/fmriprep-25.2.3/sub-1iso3d
#  ../Data/preproc/bids-3depi/fmriprep-25.2.3/sub-1
#  ../Data/preproc/bids-a10/fmriprep-25.2.3/sub-1
#  ../Data/preproc/bids-a10/fmriprep-25.2.3/sub-2
for f in $PWD/../Data/preproc/bids-*/fmriprep-$PREPVER/sub-*/; do
  prepdir=${f//\/sub-.*/}
  ! [[ $f =~ bids-?([^/]*) ]] && echo "no dataset version from bids-* name for '$f'" && continue
  #! [[ $f =~ bids-3depi ]] && echo "no dataset version from bids-ep3d name for '$f'" && continue
  dataset=${BASH_REMATCH}
  xcpddir="$datadir/preproc/$dataset/xcpd-ver-${XCPDVER}_prep-${PREPVER}_type-${INPUT_TYPE}_fd-${FDTHRES}_bp-$USEBANDPASS"
  WORK=$(dirname $xcpddir)/work-$(basename $xcpddir)

  dryrun mkdir -p $xcpddir $WORK


  ! [[ $f =~ (sub-[^-/]+)[/_] ]] && echo "file does not have subj: '$f'" && continue
  subj=${BASH_REMATCH[1]} 
  #[[ $task =~ anglechange ]] && echo "not running on $task, explicit skip" && continue
  example_output=$(find "$xcpddir/$subj"/func/ -iname "*pearsoncorrelation_relmat.tsv" -print -quit 2>/dev/null|| :)
  [ -n "$example_output" ] && [ -r "$example_output" ] && echo "# already ran on $example_output; skipping" && continue
  pgrep -af "podman .*xcp_d.*$subj" && echo "# already running $subj" && continue
  echo "# $(date) $dataset / $subj :: $f"

  # 20260402 - dervies need a description. can go back and edit, but dont block from running
  test -r "$prepdir/dataset_description.json" ||
     echo '{"Name": "Example dataset", "BIDSVersion": "1.0.2"}' > "$_"

  dryrun podman run \
      -v $FS_LICENSE:$FS_LICENSE:ro \
      -v $TEMPLATEFLOW_HOME:$TEMPLATEFLOW_HOME \
      -v $WORK:$WORK \
      \
      -v "$prepdir":$prepdir \
      -v "$xcpddir":"$xcpddir" \
      \
      --env FS_LICENSE \
      --env TEMPLATEFLOW_HOME \
      \
      docker.io/pennlinc/xcp_d:$XCPDVER \
       --input-type 'fmriprep' \
       --mode abcd \
       --motion-filter-type none \
       --nthreads 2 \
       `#--task_id $task` \
       -w $WORK \
       --despike \
       --head_radius 40 \
       --smoothing 4 \
       -p 36P \
       --mode none \
       --input-type fmriprep \
       --file-format "$INPUT_TYPE" `# nifti, not cifit` \
       --output-type censored `# vs 'interpolated', ignored if fd=0?` \
       --abcc-qc n \
       --linc-qc n \
       --combine-runs y \
       --warp-surfaces-native2std n \
       --min-coverage 0.5 \
       --min-time 100 `# after FD, min time needed in seconds` \
       --motion-filter-type none \
       --create-matrices all \
       --fd-thresh "$FDTHRES"  \
       $bandpass_yesno \
       $prepdir  $xcpddir participant \
       --participant-label "$subj" #&
done
