#!/usr/bin/env bash
set -euo pipefail
DATA=$(cd $(dirname $0)/../Data; pwd) # need data root so symlinks are valid across all
for bidsdir in bids_versions/*/; do
  lab=$(basename $bidsdir)
  dryrun mkdir -p out/$lab work/$lab
  dryrun podman run \
    -v $DATA:$DATA \
    -v $PWD:$PWD \
    --entrypoint sdcflows \
    nipreps/fmriprep:25.2.3 \
      --work $PWD/work/$lab \
      $PWD/bids_versions/$lab  $PWD/out/$lab participant
done
