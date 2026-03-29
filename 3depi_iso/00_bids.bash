#!/usr/bin/env bash
cd "$(dirname $0)"
dcmdirtab \
	-e '$conf{columns}->{subj} = sub($p){ return "1iso3d";}' \
	-d '../Data/2026.03.24-16.41.55/26.03.24-16:37:16-DST-1.3.12.2.1107.5.2.43.67078/*' |
	tee /tmp/3depi.tsv |
dcmtab_bids \
  'T1w;pname=T1MPRAGE,ndcm=192'\
  \
  'bold=n40p20;pname=a_ep2d_bold_ang_n40p20_2mm_ascend_incang,ndcm=10;' \
  'fmap/magnitude;pname=GRE_FieldMap_LargeFOV,ndcm=200;acq=largefov'\
  'fmap/phasediff;pname=GRE_FieldMap_LargeFOV,ndcm=100;acq=largefov'\
  \
  'fmap/epi;pname=SpinEchoFieldMap_AP.*-39.9,ndcm=1;dir=AP;acq=n40' \
  'fmap/epi;pname=SpinEchoFieldMap_PA.*-39.9,ndcm=1;dir=PA;acq=n40' \
  'bold=rest;ndcm=200,pname=a_ep3d_bold_fid_2mm_R2x2.-39.9;acq=n40' \
  \
  'fmap/epi;pname=SpinEchoFieldMap_AP.*C20,ndcm=1;dir=AP;acq=p20' \
  'fmap/epi;pname=SpinEchoFieldMap_PA.*C20,ndcm=1;dir=PA;acq=p20' \
  'bold=rest;ndcm=200,pname=a_ep3d_bold_fid_2mm_R2x2.20;acq=p20' \
  \
  'fmap/epi;pname=SpinEchoFieldMap_AP.*-33,ndcm=1;dir=AP;acq=n33' \
  'fmap/epi;pname=SpinEchoFieldMap_PA.*-33,ndcm=1;dir=PA;acq=n33' \
  'bold=rest;ndcm=200,pname=a_ep3d_bold_fid_2mm_R2x2.-33;acq=n33' \
  \
  'fmap/epi;pname=SpinEchoFieldMap_AP.*-13,ndcm=1;dir=AP;acq=n13' \
  'fmap/epi;pname=SpinEchoFieldMap_PA.*-13,ndcm=1;dir=PA;acq=n13' \
  'bold=rest;ndcm=200,pname=a_ep3d_bold_fid_2mm_R2x2.*-13;acq=n13' \
  \
  'fmap/epi;pname=SpinEchoFieldMap_AP.*C13,ndcm=1;dir=AP;acq=p13' \
  'fmap/epi;pname=SpinEchoFieldMap_PA.*C13,ndcm=1;dir=PA;acq=p13' \
  'bold=rest;ndcm=200,pname=a_ep3d_bold_fid_2mm_R2x2.13;acq=p13' \
  |
  parallel --colsep '\t' mknii ../Data/bids-3depi2x2x2/{1} {2}

add-intended-for -fmap '*acq-largefov*magnitude1.json' -for '*task-n40p20*.nii.gz' ../Data/bids-3depi2x2x2/sub-*
add-intended-for -fmap '*acq-largefov*phasediff.json' -for '*task-n40p20*.nii.gz' ../Data/bids-3depi2x2x2/sub-*
for task in {n40,p20,n33,n13,p13}; do
   add-intended-for -fmap "*acq-$task*.json" -for "*rest_acq-$task*.nii.gz" ../Data/bids-3depi2x2x2/sub-*
done
