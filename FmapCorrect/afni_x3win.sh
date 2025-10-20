AFNI_TIME_LOCK=YES \
afni \
   -com 'OPEN_WINDOW A.axialimage mont=1x2:50' -com 'SWITCH_UNDERLAY epi_angles.nii.gz'  \
   -com 'OPEN_WINDOW B.axialimage mont=1x2:50' -com 'SWITCH_UNDERLAY B.resliced.nii.gz'\
   -com 'OPEN_WINDOW C.axialimage mont=1x2:50' -com 'SWITCH_UNDERLAY C.epi_undistored.nii.gz'\
   -com 'OPEN_WINDOW A.coronalimage mont=1x2:30' -com 'OPEN_WINDOW A.sagittalimage mont=2x2:15'\
   -com 'OPEN_WINDOW B.coronalimage mont=1x2:30' -com 'OPEN_WINDOW B.sagittalimage mont=2x2:15'\
   -com 'OPEN_WINDOW C.coronalimage mont=1x2:30' -com 'OPEN_WINDOW C.sagittalimage mont=2x2:15' \
   -com 'A.axialgraph matrix=1' \
   -com 'B.axialgraph matrix=1' \
   -com 'C.axialgraph matrix=1' \
   -com 'SET_XHAIRS B.SINGLE' -com 'SET_XHAIRS C.SINGLE' \
   \
   -com 'OPEN_WINDOW D.sagittalimage mont=2x2:15' \
   -com 'SWITCH_UNDERLAY D.resliced.nii.gz'  \
   -com 'SWITCH_OVERLAY D.epi_undistored.nii.gz' 


   afni -com 'SWITCH_UNDERLAY epi_undistored' \
	-com 'SWITCH_OVERLAY angle_at_max' \
	-com 'OPEN_WINDOW axialgraph matrix=1' \
	-com 'SET_PBAR_ALL -35'
