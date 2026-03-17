#!/usr/bin/env Rscript
# pulled from ./03a_tsnr_cmp.R. adding 3dEPI tsnr
# 20260315 - NB. no SDC on at lead 3dEPI (fmriprep didn't find spinechos)

pacman::p_load(dplyr, tidyr, oro.nifti, ggplot2, stringr)
mni_mask <- readNIfTI('mni_brainmask.nii.gz')@.Data
read_mask_na <- function(niifile){
    n <- readNIfTI(niifile)@.Data
    n[mni_mask==0] <- NA
    return(n)
}
cor_vec <- function(x,y) cor(as.vector(x),as.vector(y), use='pairwise.complete.obs')

imfiles <- list(
             mni='MNI_T1w.nii.gz',
             bmask='mni_brainmask.nii.gz',
              b0='./maxangle_mni/sub-1_space-MNI152NLin2009cAsym_fmap.nii.gz',
        # TODO: warp ../FmapCorrect/wf/human-largefov-3depi/sub-1/sdc/unwarp/EF_UD_fmap.nii.gz to MNI
        #b0_ep3d='./maxangle_mni/3depi/sub-1_space-MNI152NLin2009cAsym_fmap.nii.gz',
    n40p20inc_wf='./maxangle_mni/sub-1_a10_space-MNI_maxangle.nii.gz',
 maxtsnr_angle_ep_full='./maxangle_mni/sub-1_angleatmax-tsnr.nii.gz',
maxtsnr_angle_ep='./maxangle_mni/sub-1_select-n40n33n13p13p20_angleatmax-tsnr.nii.gz',
    maxtsnr_ep3d='maxangle_mni/3depi/sub-1_res-upsample_angleatmax-tsnr.nii.gz')

imfiles |> c('3dinfo -ad3 -n4 -iname ', args=_) |>
    paste0(collapse=" ") |> system(intern=T) |>
    read.table(text=_, col.names = c("dx","dy","dz","nx","ny","nz","nt","fname")) ->
    imdim
#  dx dy dz nx ny nz nt                                                      fname
#   2  2  2 77 95 82  1                                             MNI_T1w.nii.gz
#   2  2  2 77 95 82  1 ./maxangle_mni/sub-1_space-MNI152NLin2009cAsym_fmap.nii.gz
#   2  2  2 77 95 82  1         ./maxangle_mni/sub-1_a10_space-MNI_maxangle.nii.gz
#   2  2  2 77 95 82  1                ./maxangle_mni/sub-1_angleatmax-tsnr.nii.gz

mni <- readNIfTI('MNI_T1w.nii.gz')@.Data

# b0 from
# EF_UD from  FSL's fugue (via hallquist pipeline) using 'acq-largefov'
# /home/recontwix/data/BOLDSliceAngle/FmapCorrect/wf/human-largefov/sub-1/sdc/EF_UD_fmap.nii.gz
# moved to mni
b0 <- read_mask_na('./maxangle_mni/sub-1_space-MNI152NLin2009cAsym_fmap.nii.gz')@.Data

# atscanmax from sub-1_task-n40p20_acq-inc_bold.nii.gz
# ../FmapCorrect/01b_proc-10a.sh
#    ./angle_at_max.py -i wf/human-largefov/sub-1/epi_undistorted_masked.nii.gz -m wf/human-largefov/sub-1/mean_epi_brain.nii.gz -o wf/human-largefov/sub-1/angles_at_max.nii.gz
# ./02c_mni_warp.bash warp to mni
atscanmax <- read_mask_na('./maxangle_mni/sub-1_a10_space-MNI_maxangle.nii.gz')

cor_vec(b0, atscanmax) # [1] -0.2962406
cor_vec(b0, read_mask_na(imfiles$maxtsnr_ep3d))  # .0027

maxtsnr_angle_ep <- read_mask_na(imfiles$maxtsnr_angle_ep)
#tsnr_range <- read_mask_na('./maxangle_mni/tsnr-range.nii.gz')
maxtsnr_ep3d <- read_mask_na(imfiles$maxtsnr_ep3d)
cor_vec(maxtsnr_ep3d,maxtsnr_angle_ep) # .0479

# TODO: replace with subset at nifti
# using angles in ./maxangle_mni/3depi/angles.txt; ignore where 3d is 0 (mask value) or NA (no coverage)
ep2d_at_sub <- abs(as.vector(maxtsnr_angle_ep) - c(-39.90, -33.24,-13.28,13.34,20.0)) < 1 &
    !is.na(as.vector(maxtsnr_ep3d)) & as.vector(maxtsnr_ep3d) != 0
# subsetting whole angle dataset was better than building tsnr (.066)
cor_vec(maxtsnr_ep3d[ep2d_at_sub],maxtsnr_angle_ep[ep2d_at_sub]) # .049
hist(round(as.vector(maxtsnr_angle_ep)[ep2d_at_sub]))
hist(maxtsnr_ep3d[ep2d_at_sub])
d3d2 <- data.frame(d3=as.factor(maxtsnr_ep3d[ep2d_at_sub]),
           d2=as.factor(round(maxtsnr_angle_ep[ep2d_at_sub]))) |>
    group_by(d3,d2) |>
    tally()

ggplot(d3d2) + aes(x=d3,y=d2, fill=n) +
    geom_tile(hjust=0, vjust=0) +
    scale_fill_gradient(limits=c(900,3000), oob=scales::squish) +
    theme_bw() +
    title('EPI tSNR best angle: 3D vs 2D', x='3D', y='2D')

## plotting to browser
#pacman::p_install('httpgd'); httpgd::hgd()
# ssh -NfL 33039:localhost:33039 mrrc-ptx
# http://127.0.0.1:33039/live?token=aCWwTvgI
pacman::p_load('ggbrain')

base_plot <- ggbrain(bg_color = "white", text_color = "black") +
  images(c(underlay = imfiles$mni, mask=imfiles$bmask)) +
  slices(c("z = 20%", "z = 80%", "x = 40%", "y = 40%")) +
  geom_brain(definition = "underlay")

## 3d epi best angle
base_plot +
 images(c(overlay=imfiles$maxtsnr_ep3d)) +
 geom_brain(definition="overlay[mask>0]",
            fill_scale=ggplot2::scale_fill_viridis_c("best angle")) +
 render() +
 patchwork::plot_annotation(title="tSNR best angle 3D EPI (upsample)")

## ep2d but max angle only considered those that we collected in 3d epi
base_plot +
 images(c(overlay=imfiles$maxtsnr_angle_ep)) +
 geom_brain(definition="overlay[mask>0]",
            fill_scale=ggplot2::scale_fill_viridis_c("best angle")) +
 render() +
 patchwork::plot_annotation(title="tSNR best angle 2D EPI (subset matching 3D)")

## full ep2d: includes all original angles
base_plot +
 images(c(overlay=imfiles$maxtsnr_angle_ep_full)) +
 geom_brain(definition="overlay",
            fill_scale=ggplot2::scale_fill_viridis_c("best angle"), limits=c(-40,20)) +
 render() +
 patchwork::plot_annotation(title="tSNR best angle 2D EPI (full range)")

## EF_UD file from FSL's FUGUE
base_plot +
 images(c(overlay=imfiles$b0)) +
 geom_brain(definition="overlay[mask > 0]",
            fill_scale=ggplot2::scale_fill_continuous("B0", palette=c("#ff0000","#00ff00","#0000ff"))) +
 render() +
 patchwork::plot_annotation(title="B0 EF_UD via FSL's FUGUE")

## TODO: b0 from 3depi session. need MNI warp
tsnrfiles <- list(
    ep3d_n33 = '../Data/tsnr/3depi/sub-1_task-n33_acq-3d_tsnr.nii.gz',
    ep3d_p13 = '../Data/tsnr/3depi/sub-1_task-13_acq-3d_tsnr.nii.gz',
    ep2d_n33= '../Data/tsnr/sub-1_task-restn33_tsnr.nii.gz',
    ep2d_p13= '../Data/tsnr/sub-1_task-rest13_tsnr.nii.gz'
)
## individual tsnr maps
ggbrain(bg_color = "white", text_color = "black") +
 images(c(underlay=tsnrfiles$ep3d_n33)) +
 slices(c("z = 20%", "z = 80%", "x = 40%", "y = 40%")) +
 geom_brain(definition="underlay",
            fill_scale=ggplot2::scale_fill_continuous("tsnr", palette=c("#ffffff","#ff0000"))) +
 render() +
 patchwork::plot_annotation(title="ep3d tSNR @ -33")
## ep3d 13

ggbrain(bg_color = "white", text_color = "black") +
 images(c(underlay=tsnrfiles$ep3d_p13)) +
 slices(c("z = 20%", "z = 80%", "x = 40%", "y = 40%")) +
 geom_brain(definition="underlay",
            fill_scale=ggplot2::scale_fill_continuous("tsnr", palette=c("#ffffff","#ff0000"))) +
 render() +
 patchwork::plot_annotation(title="ep3d tSNR @ 13")
