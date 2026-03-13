#!/usr/bin/env bash
VER=25.2.3 # 20251017
#podman image ls
# docker.io/nipreps/fmriprep   25.2.3                   dd3791489f2a  2 hours ago    7.14 GB

datadir="$(cd "$(dirname "$0")/../Data"; pwd -P)"
#  BIDS=${BIDS:-$datadir/bids}
#  BIDS=${BIDS:-$datadir/bids-a10} # 20251022
  BIDS=${BIDS:-$datadir/bids-3depi} # 20260301

! test -d $BIDS && echo "ERROR: env BIDS ($BIDS) directory DNE" && exit 1
dataset=$(basename "$BIDS")
bidsdb=$datadir/db/$(basename $BIDS)

   OUT=$datadir/preproc/$dataset/fmriprep-$VER
 FSOUT=$datadir/preproc/$dataset/fs-fmriprep-$VER
  WORK=$datadir/preproc/$dataset/fmriprep-$VER-work

mkdir -p $OUT $FSOUT $WORK $bidsdb

export FS_LICENSE="$(cd $PWD; pwd -P)/fs_license.txt" TEMPLATEFLOW_HOME=$HOME/.templateflow

# doesn't matter here. but for large bids dataset, wouldn't want to regenerate
test -r $bidsdb/layout_index.sqlite ||
  dryrun uv run --with pybids \
    pybids layout $BIDS $bidsdb --no-validate --index-metadata

# grab templates and make avial to container. dont want to pull them every new run
test -s $TEMPLATEFLOW_HOME/tpl-MNI152NLin2009bAsym/tpl-MNI152NLin2009bAsym_res-1_T1w.nii.gz ||
  dryrun uv run --with templateflow \
   python -c "from templateflow.api import get; get(['MNI152NLin2009cAsym', 'MNI152NLin6Asym'])"

# quick check bids is valid
echo podman run -v $BIDS:$BIDS:ro --entrypoint bids-validator docker.io/nipreps/fmriprep:25.2.3 $BIDS



#for task in "-t task-n40p20" ""; do
for task in ""; do
    # don't use for phanom. no anat to align, no point. see sdcflow instead
    extra_opts=()
    [[ $BIDS =~ phatnom ]] && extra_opts=(--fs-no-reconall --output-spaces )
    # 20260301 - no slictiming for 3d epi acquisitions. but do for n40p20 multiangle epi
    [[ $BIDS =~ epi3d && ! "$task" =~ n40p20 ]] && extra_opts=(--ignore slicetiming)
    test -z "$(find $BIDS -type f,l -iname "${task/-t /*}*.nii.gz" -print -quit)" &&
	echo "No files like for task '${task/-t /}'" && continue

    dryrun podman \
    run \
    `# -u=$(id -u boldsliceangle):$(id -g boldsliceangle)` \
    -v $BIDS:$BIDS:ro \
    -v $FS_LICENSE:$FS_LICENSE:ro \
    \
    -v $OUT:$OUT:rw \
    -v $FSOUT:$FSOUT:rw \
    -v $WORK:$WORK:rw \
    -v $bidsdb:$bidsdb:rw \
    -v $TEMPLATEFLOW_HOME:$TEMPLATEFLOW_HOME:rw \
    --env FS_LICENSE \
    --env TEMPLATEFLOW_HOME \
    docker.io/nipreps/fmriprep:$VER \
    "$@" \
    --bids-database-dir $bidsdb \
    --fs-subjects-dir $FSOUT \
    -d $OUT `# reuse anat derives when they exist` \
    -w $WORK \
    "${extra_opts[@]}" \
    $BIDS $OUT participant
done
