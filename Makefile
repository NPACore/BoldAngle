Figures/coderepo_qr.png:
	 qrencode --dpi 300 -o Figures/coderepo_qr.png https://github.com/NPACore/BoldAngle

Figures/parameters.png: seq_params.csv
	Figures/parameters.R
