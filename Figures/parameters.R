#!/usr/bin/env Rscript
# expect to run from repo root (pwd one above Figures/)
seq_params <- read.csv('seq_params.csv',sep=",")
#pacman::p_install('mmtable2')
#p_seq_params <- mmtable2::mmtable(seq_params)
#print(p_seq_params)

#library(kableExtra)
#seq_params|>
# mutate(across(everything(), \(x) ifelse(is.na(x), '',x))) |>
# kable() |>
# kable_styling(position="center", font_size=25, full_width=T) |>
# as_image(file='Figures/parameters.png', width=7, height=5, density=300)

library(gridExtra)
seqtheme <- ttheme_default(core=list(fg_params=list(hjust=0,x=0)),
                      rowhead=list(fg_params=list(hjust=1, x=0.95, fontface="bold")))
grid::grid.newpage()
seq_params_fmt <- seq_params|>
    select(-seq) |>
   mutate(across(everything(),\(x) ifelse(is.na(x),"",x)|>gsub(';','\n',x=_)))
rownames(seq_params_fmt) <- seq_params$seq
png("Figures/parameters.png", width=5.5, height=3, units="in", res=300)
tableGrob(seq_params_fmt, theme=seqtheme) |> grid::grid.draw()
dev.off()
