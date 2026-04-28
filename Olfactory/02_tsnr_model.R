#!/usr/bin/env Rscript
pacman::p_load(dplyr, tidyr, ggplot2, ggbrain)
angle_vals <- round(read.table('FmapCorrect/angle.txt')$V1, 0)
# c(-40, -33, -27, -20, -13, -7, 0, 7, 13, 20)
# 3depi subset is:
#angle_val <- c(-40, -33, -13, 13, 20)
cleanup_angle <- function(d) d|>
    mutate(input=gsub('.*_|.tsv','',input),
           volume=as.numeric(gsub('[^0-9]','',volume)),
           # truncated 39.9, now want to round up
           angle=case_when(angle==-39~-40,
                           angle==-26~-27,
                           angle==-19~-20,
                           angle==-6~-7,
                           angle==6~7,
                           angle==-4020~angle_vals[volume+1],
                           T~angle)) |> select(-volume)

d <- readr::read_tsv(Sys.glob('Olfactory/atlas-AonPirFTTubV4_*.tsv'),
                     id='input') |>
    rename(volume=`Sub-brick`,
           AON=NZMean_1, PirF=NZMean_2, PirT=NZMean_3, Tub=NZMean_4,
           V4=NZMean_5, angle=task) |>
    cleanup_angle()

m <- lm(AON~angle, data=d|>filter(input=='tsnr'))
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


p_data_dseg <- readr::read_tsv(Sys.glob('Olfactory/atlas-dseg_*.tsv'), id='input') |>
    rename(volume=`Sub-brick`, angle=task,
           CSF=NZMean_3, GM=NZMean_1, WM=NZMean_2) |>
    cleanup_angle() |>
    gather('roi','measure', -c(subj,angle,input)) |>
    mutate(subj=as.factor(subj), epi3d=grepl('3d',subj)) |>
    group_by(subj, input) |>
    mutate(tmax=max(measure),
           ratmax = measure/tmax) #|> filter(!roi %in% c('PirF'))


p_data <- d |>
    gather('roi','measure', -c(subj,angle,input)) |>
    mutate(subj=as.factor(subj), epi3d=grepl('3d',subj)) |>
    group_by(subj, input) |>
    mutate(tmax=max(measure),
           ratmax = measure/tmax) |>
    rbind(p_data_dseg) |>
    mutate(input=case_when(input=='n40p20'~'Single Volume Magnitude',T~input))

###
angle_model <- p_data |>
    group_by(input, roi) |>
    group_modify(~broom::tidy(lm(measure~angle,.)))

p_model_data <- angle_model |>
    pivot_wider(id_cols = c("input","roi"),names_from="term", values_from = -c("input","roi","term"))|>
    mutate(label=glue::glue("m={round(estimate_angle,2)}\nt={round(statistic_angle,2)}"),
           angle=20,
           pred=20*estimate_angle+`estimate_(Intercept)`) |>
    inner_join(p_data|>filter(angle==20,subj=='1'))|>
    mutate(ratmax=pred/tmax)
###

# colors for ggbrain's outline. values set by 3dcalc in 00_get_atlas.bash
# dseg add 10 locally below
roi_label_color <- data.frame(value=c(             5,    1,    4, 1+10,2+10,3+10),
                              label=factor(c('V4','AON','Tub','GM','WM','CSF'), levels=c('V4','AON','Tub','GM','WM','CSF')),
                              color=scales::hue_pal()(6))
                              #color=c(scales::hue_pal()(3), RColorBrewer::brewer.pal(3,"Set3"))
                              #color=c("7fc97f", "#beaed4", "#fdc086", "#ffff89", "#386cb0", "#f0027f"))
roi_to_plot <- roi_label_color$label

p <-p_data |>
    filter(roi %in% roi_to_plot) |>
    mutate(roi = factor(roi, roi_to_plot)) |>
    ggplot() +
    aes(x=angle,y=ratmax, color=roi, group=roi, shape=subj) +
    geom_point(alpha=.25) +
    geom_smooth(method='lm', alpha=.10) +
    scale_shape_manual(values=c(19,21,17)) + # filled circle, open circle, triangle; sub1 is circle
    scale_color_manual(values=roi_label_color$color) +
    facet_grid(input~.) +
    theme_minimal() +
    #ggrepel::geom_label_repel(data=p_model_data|>
    #                              filter(roi %in% roi_to_plot,
    #                                     `p.value_(Intercept)`<.01),
    #                          #color='black',
    #                          hjust=1,
    #                          nudge_x=10,
    #                          segment.size=.2,
    #                          size=2,
    #                          aes(label=label)) +
    #ggrepel::geom_label_repel(data=p_data|>filter(tsnr_ratmax==1),
    #                          color='black',
    #                          segment.size=.2,
    #                          aes(label=glue::glue("{subj} {roi} {round(tsnr,1)} @ {angle}"))) +
    labs(title="Relative Mangitude and tSNR at acquistion angles", y="value/max(session)", x="Acq. Angle", shape="Session", color="Region")
p

ggsave(p, file='atlas-AonPirFTTub_lm.png', width=5, height=3)
#pacman::p_load(gganimate)
#anim <- ggplot(p_data) +
#    aes(x=angle,y=tsnr_ratmean, color=roi, group=seq_along(angle), shape=subj) +
#    geom_point() +
#    theme_bw() +
#    #transition_states(angle, transition_length=2, state_length=1)
#    transition_reveal(angle)
#anim_save("/tmp/ex.gif", animate(anim, fps=5, randerer = gifski_renderer()))

##
# want to show angle of acquisition with un-relsliced data. raw tsnr (resliced). roi. and value at angle
##

# read in niftis
t1 <- readNifti( "Data/preproc/bids-3depi2x2x2/fmriprep-25.2.3/sub-1iso3d/anat/sub-1iso3d_space-MNI152NLin2009cAsym_res-task_desc-preproc_T1w.nii.gz")
t1_crop <- t1; t1_crop[t1<150] <- 0

a10 <- readNifti("Data/bids-a10/sub-1/func/sub-1_task-n40p20_acq-inc_bold.nii.gz")
#a10[a10 < quantile(a10,.8)] <- NA

roi_mask <- readNifti("Olfactory/atlas-AonPirFTTubV4_res-func.nii.gz")
#roi_mask[!roi_mask %in% roi_label_color$value] <- NA

# 20260427 changed colors based on just what we will plot. remove PirF, PirT
#          see roi_label_color above
#roi_labels <- data.frame(value=1:5, label=c("AON","PirF","PirT","Tub","V4"),
#                         color=scales::hue_pal()(5))
#                         #color=RColorBrewer::brewer.pal("Pastel1",n=4))


# ls Data/tsnr/sub-1_task-rest*tsnr.nii.gz
#   sub-1_task-rest0_tsnr.nii.gz
#   sub-1_task-rest13_tsnr.nii.gz
#   sub-1_task-rest20_tsnr.nii.gz
#   sub-1_task-rest6_tsnr.nii.gz
#   sub-1_task-restn13_tsnr.nii.gz
#   sub-1_task-restn19_tsnr.nii.gz
#   sub-1_task-restn26_tsnr.nii.gz
#   sub-1_task-restn33_tsnr.nii.gz
#   sub-1_task-restn39_tsnr.nii.gz
#   sub-1_task-restn6_tsnr.nii.gz
tsnr_nii <- lapply(c("n39", "n33","n26","n19", "n13", "n6", "0", "6", "13", "20"),
                   \(x){ tsnr <- readNifti(glue::glue("Data/tsnr/sub-1_task-rest{x}_tsnr.nii.gz")); tsnr[t1_crop==0]<-NA; return(tsnr) })


show_slices <- c("x=21")#, "z=10")
a10_at_angle <- function(i) {
  img <- asNifti(a10[,,,i],a10)
  ggbrain(bg_color="white", text="black") +
    images(list(underlay = img)) +
    slices(show_slices) +
    geom_brain("underlay") +
    render() +
    labs(title=paste0("Quick EPI ɸ",angle_vals[i]))
}
tsnr_at_angle <- function(i) {
  this_angle <- angle_vals[i]; print(this_angle)
}
plot_at_angle <- function(p,i) {
  this_angle <- angle_vals[i]; print(this_angle)
  p_angle<-p +
      ggrepel::geom_label_repel(data= ~subset(., subj=='1' & angle==this_angle),
                                segment.size=1,
                                aes(label=glue::glue("{round(measure,1)}"))) +
      geom_vline(data=data.frame(angle=this_angle,
                                 roi=NA,input=c("tsnr","Single Volume Magnitude")),
                 aes(xintercept=angle),
                 color='yellow')
      # + labs(title= glue::glue("tSNR at acquisition angle {this_angle}"))
  return(p_angle)
}

tsnr_at_angle <- function(i) {

  roi_colors <- roi_label_color$color; names(roi_colors) <- roi_label_color$label
  tsnr_img <- tsnr_nii[[i]]
  # force limit, doesn't work below in ggbrain fill
  limits <-c(5,100)
  tsnr_img[tsnr_img>max(limits)] <- max(limits)
  tsnr_img[tsnr_img<min(limits)] <- min(limits)

  ggbrain(bg_color="white", text_color="black") +
    images(list(underlay=t1_crop, tsnr=tsnr_img)) +
    images(list(atlas=roi_mask), labels=roi_label_color) +
    slices(c("x=38", "y=-3")) +
    geom_brain("underlay")+
    geom_brain("tsnr",
               fill_scale=scale_fill_distiller("tSNR", palette="Spectral",
                                               limits=limits),
               limits=limits)+
    geom_outline("atlas",
                 outline_scale = scale_fill_manual("Name", values=roi_colors),
                 mapping=aes(outline=label), show_legend = FALSE)+
    render()

}

angle_frames <- function(i, prefix="/tmp/XXXX_") {
   require(patchwork)
   fname <- glue::glue("{prefix}{sprintf('%02d',i)}.png")
   #a_plots <- cowplot::plot_grid(cowplot::plot_grid(a10_at_angle(i),
   #                                             tsnr_at_angle(i),ncol=2),
   #                          plot_at_angle(p,i),
   #                          nrow=2)
   a_plots <- (a10_at_angle(i) | tsnr_at_angle(i)) / plot_at_angle(p,i)
   ggsave(fname, a_plots, height=9.8, width=10.5)
   return(fname)
}
input_images<-lapply(seq_along(angle_vals), angle_frames)
#gifski::gifski(unlist(input_images), gif_file="tSNR_angle.gif")
system("ffmpeg -y -f image2 -r 2 -i /tmp/XXXX_%02d.png -vcodec libx264 -crf 22 tSNR_angle.mp4")
