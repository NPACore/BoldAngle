#!/usr/bin/env bash
# get sdcflow's prepared fieldmap [cf. hallquist/fsl pipeline]
# biggest difference: sdcflow is not brain masked, better for viz?
#
# also see ../B0compare/01_sdcflow.bash

# bids=bids-phantom/; lab=phantom20251020
bids=bids-a10/; lab=a10

bids=$(cd $(dirname $0)/../Data/$bids; pwd)
out=$(cd $(dirname $0);pwd)/wf/$lab/flow/
dryrun mkdir -p $out/work
dryrun podman run \
    -v $bids:$bids \
    -v $out:$out \
    --entrypoint sdcflows \
    nipreps/fmriprep:25.2.3 \
      --work $out/work \
      $bids $out participant
