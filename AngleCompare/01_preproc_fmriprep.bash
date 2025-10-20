#!/usr/bin/env bash
VER=25.2.3

# 20251017
#podman image ls
# docker.io/nipreps/fmriprep   25.2.3                   dd3791489f2a  2 hours ago    7.14 GB
datadir="$(cd "$(dirname "$0")/../Data"; pwd)"
   OUT=$datadir/preproc/fmriprep-$VER
 FSOUT=$datadir/preproc/fs-fmriprep-$VER
  WORK=$datadir/preproc/fmriprep-$VER-work
  BIDS=$datadir/bids
bidsdb=$datadir/bids-db

mkdir -p $OUT $FSOUT $WORK $bidsdb

export FS_LICENSE=$PWD/fs_license.txt TEMPLATEFLOW_HOME=$HOME/.templateflow

# doesn't matter here. but for large bids dataset, wouldn't want to regenerate
: uv run --with pybids \
    pybids layout $BIDS $bidsdb --no-validate --index-metadata

# grab templates and make avial to container. dont want to pull them every new run
: uv run --with templateflow \
   python -c "from templateflow.api import get; get(['MNI152NLin2009cAsym', 'MNI152NLin6Asym'])"

# quick check bids is valid
: podman run -v $BIDS:$BIDS:ro --entrypoint bids-validator docker.io/nipreps/fmriprep:25.2.3 $BIDS

dryrun podman \
  run \
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
  --bids-database-dir $bidsdb \
  --fs-subjects-dir $FSOUT \
  -w $WORK \
  "$@" \
  $BIDS $OUT participant
