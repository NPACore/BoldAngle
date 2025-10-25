#!/usr/bin/env Rscript
pacman::p_load(dplyr, tidyr, readr, ggseg)
# remotes::install_github("LCBC-UiO/ggsegGlasser")
xcpd_dir <- '../Data/preproc/xcpd/ver-0.12.0_prep-25.2.3_type-nifti_fd-0.3_bp-yes/' # /sub-cm20230803

#' read in xcpd atlas correlation tsv files
#' @param flist list of tsv files, likely from Sys.glob
#' @return long dataframe with task part of fname in 'fname'.
#'         row per task x roi-roi r value
long_r <- function(flist) {
  d <- readr::read_delim(flist, delim="\t", id='fname')
  # reshape longer: from col per roi to cols like: fname,node,Node2,r
  all_cor <- d |>
    gather("Node2","r", -Node, -fname) |>
    mutate(fname=gsub('.*task-([^-_/]+).*','\\1',fname)) |>
    filter(Node!=Node2)
}
rm_dup_node <- function(d) {
 d|>
   mutate(Node1=pmin(Node,Node2), Node2=pmax(Node,Node2))|>
   rename(Node=Node1) |>
   group_by(fname) |>
   filter(!duplicated(paste0(Node,Node2))
   ungroup()

 #d |> filter(
 # ! rbind(Node,Node2) |>
 #   apply(2,sort) |> t() |>
 #   duplicated()
 #)
}

cormats <- Sys.glob(paste0(xcpd_dir,'sub-*/func/sub-*_task-*Glasser_stat-pearsoncorrelation_relmat.tsv'))
all_cor_glasser <- long_r(cormats)

cor_glasser_norep <- all_cor_glasser |> group_by(fname) |> rm_dup_node()
#glasser_aov_all <- aov(data=cor_glasser_norep, r ~ Node + fname)
#glasser_aov <- aov(data=cor_glasser_norep, r ~ fname)
ggplot(cor_glasser_norep) + aes(y=r,x=fname) + geom_boxplot()


# make r_mean, r_sd, r_median
by_roi <- all_cor_glasser |>
  group_by(fname, Node) |>
  summarise(across(r,lst(mean,sd,med=median)))

glasser_node_smry <- by_roi |>
  group_by(Node) |>
 summarise(across(c(r_med,r_mean,r_sd), lst(change=\(x) max(x) - min(x))),
           across(r_med, lst(min,max)),
           node_min_med=fname[which.min(r_med)],
           node_max_med=fname[which.max(r_med)]
           ) |>
 arrange(-r_med_change)

glasser_node_smry |>
    mutate(across(where(is.numeric), ~round(.,3))) |>
    rename_with(\(x) gsub('_change','Δ',x))|>
    head(n=10) |>
    knitr::kable()

## plotting

# match glasser ggset atlas names:
# Left_* to lh_L_*, Right_* to rh_R_*
change_glasser_pdata <- glasser_node_smry |>
    mutate(label=gsub('Left','lh_L', Node),
           label=gsub('Right','rh_R', label))

p_delta_r <-
 ggplot(change_glasser_pdata) +
 theme_void() +
 aes(fill=r_med_change) +
 ggseg::geom_brain(atlas=ggsegGlasser::glasser) +
 scale_fill_gradient(low="firebrick",high="yellow") +
 labs(fill="Max-Min\nMedian ⍴\nacross ∡\nf.ea ROI")
 #labs(fill=expression("↾"["∈∡"]*rho["ROI"] - rho["ROI"]))

p_max <-
 ggplot(change_glasser_pdata) +
 theme_void() +
 aes(fill=node_max_med) +
 ggseg::geom_brain(atlas=ggsegGlasser::glasser) + #position = ggseg::position_brain(hemi ~ side))
 labs(fill="∡ of max\nmed ⍴")

p <- cowplot::plot_grid(p_delta_r, p_max, nrow=2, labels="Per Glasser ROI Median ROI-ROI Correlations by Angle")
ggsave(p, file="glasser_roiroi_medmax.png")

##  HPC
all_cor_hpc <- 
    Sys.glob(paste0(xcpd_dir,'sub-*/func/sub-*_task-*seg-HCP_stat-pearsoncorrelation_relmat.tsv')) |>
    long_r()
 ggplot(all_cor_hpc) +
     aes(x=fname,
         y=r,
         group=paste(Node,Node2),
         color=Node) +
     geom_point() +
     geom_line() +
     theme_minimal()
    
