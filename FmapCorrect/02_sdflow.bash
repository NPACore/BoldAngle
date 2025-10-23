#!/usr/bin/env bash
bids=$(cd $(dirname $0)/../Data/bids-phantom/; pwd)
out=$(cd $(dirname $0);pwd)/wf/phantom20251020/flow/
dryrun mkdir -p $out/work
dryrun podman run \
    -v $bids:$bids \
    -v $out:$out \
    --entrypoint sdcflows \
    nipreps/fmriprep:25.2.3 \
      --work $out/work \
      $bids $out participant
