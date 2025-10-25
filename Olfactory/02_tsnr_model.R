#!/usr/bin/env Rscript
pacman::p_load(dplyr, tidyr, ggplot2)
d <- read.table('../Olfactory/atlas-AonPirFTTub_tsnr.tsv', header=T) |>
    select(-Sub.brick) |>
    rename(AON=NZMean_1, PirF=NZMean_2, PirT=NZMean_3, Tub=NZMean_4, angle=task)

m <- lm(AON~angle, data=d)
summary(m)

# Call:
# lm(formula = AON ~ angle, data = d)
# 
# Residuals:
#     Min      1Q  Median      3Q     Max 
# -1.7272 -0.5726 -0.1299  0.6548  1.9855 
# 
# Coefficients:
#             Estimate Std. Error t value Pr(>|t|)    
# (Intercept) 24.73174    0.23742 104.167  < 2e-16 ***
# angle       -0.08858    0.01125  -7.876 3.06e-07 ***
# ---
# Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1
# 
# Residual standard error: 0.9431 on 18 degrees of freedom
# Multiple R-squared:  0.7751,	Adjusted R-squared:  0.7626 
# F-statistic: 62.04 on 1 and 18 DF,  p-value: 3.057e-07

p <- d |>
    gather('roi','tsnr', -c(subj,angle)) |>
    mutate(subj=as.factor(subj)) |>
    ggplot() +
    aes(x=angle,y=tsnr, color=roi, group=roi, shape=subj) +
    geom_point() +
    geom_smooth(method='lm') +
    theme_minimal()
ggsave(p, file='atlas-AonPirFTTub_lm.png', width=5, height=3)
