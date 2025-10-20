#!/usr/bin/env bash
set -euo pipefail
export FDTHRES=${FDTHRES:-0.3}
export USEBANDPASS=${USEBANDPASS:-yes}
export INPUT_TYPE=${INPUT_TYPE:-nifti}
XCPDVER=0.12.0
PREPVER=25.2.3
datadir="$(cd "$(dirname "$0")/../Data"; pwd)"
prepdir=$datadir/preproc/fmriprep-$PREPVER
xcpddir="$datadir/preproc/xcpd/ver-${XCPDVER}_prep-${PREPVER}_type-${INPUT_TYPE}_fd-${FDTHRES}_bp-$USEBANDPASS"
   WORK=$datadir/preproc/xpcd/work/$(basename $xcpddir)

dryrun mkdir -p $xcpddir $WORK

export FS_LICENSE=$PWD/fs_license.txt TEMPLATEFLOW_HOME=$HOME/.templateflow

[[ "${USEBANDPASS:-}" == "no" ]] && bandpass_yesno="--disable-bandpass-filter" || bandpass_yesno=""

for f in ../Data/preproc/fmriprep-$PREPVER/sub-cm20230803/func/; do
  ! [[ $f =~ (sub-[^-/]+)[/_] ]] && echo "file does not have subj: '$f'" && continue
  subj=${BASH_REMATCH[1]} 
  #[[ $task =~ anglechange ]] && echo "not running on $task, explicit skip" && continue
  example_output=$(find "$xcpddir/$subj"/func/ -iname "*pearsoncorrelation_relmat.tsv" -print -quit || :)
  #[ -n "$example_output" ] && [ -r "$example_output" ] && echo "already ran on $example_output; skipping" && continue
  pgrep -af "podman .*xcp_d.*$subj" && echo "# already running $subj" && continue
  echo "# $(date) $subj"

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
