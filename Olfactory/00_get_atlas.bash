ref=../Data/tsnr/sub-1_task-rest0_tsnr.nii.gz
test -r Figure_4_sourcedata.zip ||
  wget https://github.com/zelanolab/primaryolfactorycortexparcellation/raw/refs/heads/master/sourcedata/Figure_4_sourcedata.zip
test -d zhou2019 ||
  unzip  -d zhou2019 -j Figure_4_sourcedata.zip  'Figure_4_sourcedata/unique_*1mm.nii.gz'

if ! test -r atlas-AonPirFTTub.nii.gz; then
  3dcalc -a zhou2019/unique_pos_LR_Aon_1mm.nii.gz \
	 -b zhou2019/unique_pos_LR_PirF_1mm.nii.gz \
	 -c zhou2019/unique_pos_LR_PirT_1mm.nii.gz \
	 -d zhou2019/unique_pos_LR_Tub_1mm.nii.gz \
	 -expr 'a+b*2+c*3+d*4' \
	 -prefix atlas-AonPirFTTub.nii.gz
  3dresample -inset  atlas-AonPirFTTub.nii.gz -master $ref  -prefix atlas-AonPirFTTub_res-func.nii.gz
fi

! test -d "../Olfactory/Glasser2016/" &&
  wget -O Glasser2016-MMP1.0_MNI.zip "https://neurovault.org/collections/1549/download"  && 
  unzip -jd Glasser2016 Glaser2016-MMP1.0_MNI.zip

test -r atlas-glasser2016_res-func.nii.gz ||
  3dresample \
     -inset "../Olfactory/Glasser2016/MMP_in_MNI_corr.nii.gz" \
     -master $ref \
     -prefix $_

v4=6,206 # V4 lh and rh combined to roi #5
skip-exist atlas-AonPirFTTubV4_res-func.nii.gz \
  3dcalc  -a atlas-AonPirFTTub_res-func.nii.gz \
  	-g atlas-glasser2016_res-func.nii.gz \
  	-expr "a+amongst(g,$v4)*5" \
  	-overwrite \
  	-prefix __SKIPFILE
