#!/usr/bin/env Rscript
# expect to run from repo root (pwd one above Figures/)
library(kableExtra)
seq_params <- read.csv('seq_params.csv')
#pacman::p_install('mmtable2')
#p_seq_params <- mmtable2::mmtable(seq_params)
#print(p_seq_params)
seq_params|>
 mutate(across(everything(), \(x) ifelse(is.na(x), '',x))) |>
 kable() |>
 kable_styling(position="center") |>
 as_image(file='Figures/parameters.png', width=600, height=200)
