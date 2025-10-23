#!/usr/bin/env bash
set -euo pipefail
cd $(dirname $0)
FUNC=(../Data/bids/sub-cm20230803/func/sub-cm20230803_task-*_sbref.nii.gz)
FMAP=(../Data/bids/sub-cm20230803/fmap/sub-cm20230803_acq-*_phasediff.json)
for func in "${FUNC[@]}"; do
   ! [[ $func =~ task-([^/_-]+) ]] && echo "missing task in func $func" && continue
   task=${BASH_REMATCH[1]}
   for fmapjson in "${FMAP[@]}"; do
     ! [[ $fmapjson =~ acq-([^/_-]+) ]] && echo "missing acq (taskname) in dcmp $fmapjson" && continue
     fmap_acq=${BASH_REMATCH[1]}

     # make fake bids for sdcflow
     bids=bids_versions/$task-$fmap_acq
     echo "# $bids"
     test -r $bids/dataset_description.json || dryrun cp ../Data/bids/dataset_description.json $_

     # populate bids
     out=$bids/sub-cm20230803/
     dryrun mkdir -p $out/{func,fmap}
     # funcs
     ! test -r $out/func/$(basename $func) && dryrun ln -s $(readlink -f "$func") $out/func/
     ! test -r $out/func/$(basename $func .nii.gz).json && dryrun ln -s "$(readlink -f "${func/.nii.gz/.json}")" $out/func/

     # fmap
     # need to updated the indendedFor. so json should be copied that will get updated
     # image files can be symlinks
     new_fmap=$out/fmap/$(basename $fmapjson)
     for suffix in phasediff magnitude{1,2}; do
	fmap_json="$(readlink -f "${fmapjson/phasediff/$suffix}")"
	old_nii="${fmap_json/.json/.nii.gz}"
	new_nii=$out/fmap/"$(basename "${fmap_json}" .json).nii.gz"

        ! test -r "$new_nii" &&
	 dryrun ln -s "$old_nii" "$new_nii"

        test -r $new_fmap ||
 	 dryrun sed "/IntendedFor/ s/task-$fmap_acq/task-$task/g" $fmap_json | drytee "${new_nii/.nii.gz/.json}"
     done
   done
done
