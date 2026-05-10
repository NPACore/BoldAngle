Figures/coderepo_qr.png:
	 qrencode --dpi 300 -o Figures/coderepo_qr.png https://github.com/NPACore/BoldAngle

Figures/tSNR_angle.gif: Olfactory/02_tsnr_model.R
	./Olfactory/02_tsnr_model.R

Figures/parameters.png: seq_params.csv ./Figures/parameters.R
	./Figures/parameters.R

./Figures/b0/brain_cor_qaunt.gif: ./Figures/b0_thres_animate.R
	./Figures/b0_thres_animate.R
