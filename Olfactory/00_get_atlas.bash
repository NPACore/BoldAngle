test -r Figure_4_sourcedata.zip ||
  wget https://github.com/zelanolab/primaryolfactorycortexparcellation/raw/refs/heads/master/sourcedata/Figure_4_sourcedata.zip
test -d zhou2019 ||
  unzip  -d zhou2019 -j Figure_4_sourcedata.zip  'Figure_4_sourcedata/unique_*1mm.nii.gz'

3dcalc -a zhou2019/unique_pos_LR_Aon_1mm.nii.gz \
	-b zhou2019/unique_pos_LR_PirF_1mm.nii.gz \
	-c zhou2019/unique_pos_LR_PirT_1mm.nii.gz \
	-d zhou2019/unique_pos_LR_Tub_1mm.nii.gz \
	-expr 'a+b*2+c*3+d*4' \
	-prefix atlas-AonPirFTTub.nii.gz
3dresample -inset  atlas-AonPirFTTub.nii.gz -master ../Data/tsnr/sub-1_task-rest0_tsnr.nii.gz -prefix atlas-AonPirFTTub_res-func.nii.gz
