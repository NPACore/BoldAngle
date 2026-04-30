#!/usr/bin/env Rscript

# visualize changes to tsnr over acq angle
# tsnr files from ./02_tsnr.bash


# 20251023WF - init

pacman::p_load(dplyr, tidyr, oro.nifti, ggplot2, stringr)
#pacman::p_install(ggExtra) # dont shadow any other functions
tsnr_fname <- Sys.glob('../Data/tsnr/sub-[12]_task-rest*_tsnr.nii.gz')
angle_from_taskname <- function(n) str_extract(n, '(?<=task-rest)[^/_-]+') |> gsub(pat='n',rep='-') |> as.numeric()
mni_mask <- oro.nifti::readNIfTI('mni_brainmask.nii.gz')@.Data
tsnr_3ds <- lapply(tsnr_fname, function(f){
    nii <- oro.nifti::readNIfTI(f)@.Data
    nii[mni_mask==0]<-0
    return(nii)
})

### tsnr

# globals tsnr_3ds and tsrn_fname
# could just use tsnr_fname and load data, but caching those in tsnr_3ds for other use
dim_mean_df <- function(fi, xyi) 
    data.frame(angle=angle_from_taskname(tsnr_fname[fi]),
               subj=str_extract(tsnr_fname[fi],'sub-[^/_-]+'),
               tsnr_mean=apply(tsnr_3ds[[fi]],xyi,
                               \(d) median(d[d!=0])),
               nnz=apply(tsnr_3ds[[fi]],xyi,
                               \(d) length(which(d!=0))),
               dim=c('x','y','z')[xyi],
               source='tsnr',
               i=1:dim(tsnr_3ds[[fi]])[xyi])

# dims = 77 95 82
# c(77*95, 95*82, 77*82) [1] 7315 7790 6314 -- probably more useful to know mask dims
nnz_lims <- c(4000, 3000, 3000)
pdata <- lapply(1:3,
       \(di) lapply(seq_along(tsnr_fname), dim_mean_df, xyi=di) |>
             bind_rows()|>
             filter(nnz>nnz_lims[di])) |>
    bind_rows()

angles_for_line <- c(20, -13, -39)
# where interesting things happen -- lines swap
Y_IDX <- c(21,45,63)
Z_IDX <- c(25,60, 65)
pdata_nox <- pdata |> filter(dim!='x')
tsnr_plane <- ggplot(pdata_nox) +
    aes(x=i, y=tsnr_mean,
        color=angle,
        shape=subj,
        linetype=subj,
        #size=nnz,
        group=as.factor(paste(subj,angle))) +
    # annotate interesting planes
    geom_vline(data=rbind(data.frame(x=Y_IDX, dim='y'),
                          data.frame(x=Z_IDX, dim='z')),
               aes(xintercept=x,
                   group=NULL,linetype=NULL,
                   shape=NULL,color=NULL),
               color='red')+
    #geom_point(alpha=.2) +
    geom_smooth(data=pdata_nox|>filter(angle %in% angles_for_line),
                method = 'gam',
                se=FALSE) +
    scale_color_gradient2(high='red',mid='green',low='blue', breaks=round(unique(pdata_nox$angle))) +
    facet_grid(dim~.) +
    theme_minimal() +
    labs(title='Average tSNR by cross section',
         x='voxel index',
         y='Median tSRN  (brain masked)')

ggsave(tsnr_plane, file="images/tsnr_per_plane.png")


## magnitude of disortoin corrected quick 10 angle epi sequence
# TODO: use mni version?
sdc_a10_files <- Sys.glob('../FmapCorrect/wf/human-largefov/sub-[12]/epi_undistorted_masked.nii.gz')
sdc_a10 <- lapply(sdc_a10_files, \(f) oro.nifti::readNIfTI(f)@.Data)
a10_angle <- read.table('../FmapCorrect/angle.txt')$V1
angle_is <- c(1,5,10) # a10_angle[angle_is]  -39.90 -13.28  20.00
a10_slice_mean_df <- function(si, ai, xyi) {
    m3d <- sdc_a10[[si]][,,,ai]
    data.frame(angle=a10_angle[ai],
               subj=str_extract(sdc_a10_files[si],'sub-[^/_-]+'),
               tsnr_mean=apply(m3d, xyi, \(d) median(d[d!=0])),
               nnz=apply(m3d,xyi, \(d) length(which(d!=0))),
               source='shortepi',
               dim=c('x','y','z')[xyi],
               i=1:dim(m3d)[xyi])
}
a10_pdata <- lapply(1:3,
  \(xyi) lapply(1:2,
    \(si) lapply(angle_is,
       \(ai) a10_slice_mean_df(si,ai, xyi) |>
             bind_rows())|>
      bind_rows())) |>
    bind_rows()
## full rest
a10_rest_f <- Sys.glob('../Data/preproc/fmriprep-25.2.3/sub-*/func/sub-*_task-rest*_space-MNI152NLin2009cAsym_desc-mean_bold.nii.gz')
a10_rest_mean_df <- function(f, xyi) {
    m3d <- oro.nifti::readNIfTI(f)@.Data
    data.frame(angle=angle_from_taskname(f),
               subj=str_extract(f,'sub-[^/_-]+'),
               tsnr_mean=apply(m3d, xyi, \(d) median(d[d!=0])),
               nnz=apply(m3d,xyi, \(d) length(which(d!=0))),
               source='rest',
               dim=c('x','y','z')[xyi],
               i=1:dim(m3d)[xyi])
}
a10_rest_pdata <- lapply(1:3,
       \(di) lapply(a10_rest_f |> grepv(pat="task-rest(n39|n13|20)"),
                    a10_rest_mean_df, xyi=di) |>
             bind_rows()|>
             filter(nnz>nnz_lims[di])) |>
    bind_rows()


a10_plane <- rbind(a10_pdata,
                   a10_rest_pdata,
                   pdata |> filter(angle %in% angles_for_line)) |>
    ggplot() +
    aes(x=i, y=tsnr_mean,
        color=angle,
        shape=subj,
        linetype=subj,
        #size=nnz,
        group=as.factor(paste(subj,angle))) +
    # annotate interesting planes
    #geom_point(alpha=.2) +
    geom_smooth(method = 'gam',
                se=FALSE) +
    scale_color_gradient2(high='red',mid='green',low='blue',
                          limits=c(-40,20),
                          breaks=unique(a10_rest_pdata$angle)) +
    facet_wrap(source~dim, scales="free") +
    theme_minimal() +
    labs(title='EPI magnituded by cross section',
         x='voxel index',
         y='Median magnitude  (brain masked)')

ggsave(file="images/a10_plane.png", a10_plane)



subj1_idx <- which(grepl('sub-1', tsnr_fname))
alltsnr_sub1 <- as.matrix(unlist(tsnr_3ds[subj1_idx]))
dim(alltsnr_sub1) <- c(dim(tsnr_3ds[[1]]),length(subj1_idx))

# make sure we put the matrix back together correctly
stopifnot(all(alltsnr_sub1[,,,subj1_idx[2]] == tsnr_3ds[[subj1_idx[2]]]))

anglemax3d <- apply(alltsnr_sub1,1:3,which.max)
anglemax3d[alltsnr_sub1[,,,1]==0] <- NA

angles <- angle_from_taskname(tsnr_fname[subj1_idx])
anglemax3d <- angles[anglemax3d] 
dim(anglemax3d) <- dim(alltsnr_sub1)[1:3]

# TODO: plot best angle at each pos

## volumetric plots
rslice_ys <- function(data)
    lapply(Y_IDX,
           \(y) reshape2::melt(data[,y,],
                               varnames=c("x","z"),
                               value.name='tsnr') |>
                mutate(y=y)) |>
        bind_rows()

rslice_zs <- function(data)
    lapply(Z_IDX,
           \(z) reshape2::melt(data[,,z],
                               varnames=c("x","y"),
                               value.name='tsnr') |>
                mutate(z=z)) |>
        bind_rows()


tsnr_angle_y <- rslice_ys(anglemax3d) |>
  ggplot(aes(x = x, y = z, fill = tsnr)) +
  scale_fill_gradient2(high='red',mid='green',low='blue',na.value='#FFFFFF00') +
  facet_grid(y~.) +
  geom_raster() +
  theme_minimal() +
  guides(fill="none")
tsnr_angle_z <- rslice_zs(anglemax3d) |>
  ggplot(aes(x = x, y = y, fill = tsnr)) +
  scale_fill_gradient2(high='red',mid='green',low='blue',na.value='#FFFFFF00') +
  facet_grid(z~.) +
  geom_raster() +
    theme_minimal() +
  labs(fill='Angle of\nmax tSNR')

###

b0 <- oro.nifti::readNIfTI('./maxangle_mni/sub-1_space-MNI152NLin2009cAsym_fmap.nii.gz')@.Data
b0[mni_mask==0]<-NA

# full mni brain for underaly/reference
# see 02_masks.bash for MNI_T1w.nii.gz
mni <- oro.nifti::readNIfTI('MNI_T1w.nii.gz')@.Data


#cowplot::plot_grid(ncol=3,)
oob <- abs(b0)>200 & !is.na(b0)
b0_pdata <- b0; b0_pdata[oob] <- sign(b0[oob])*200

p_b0_y <- rslice_ys(b0_pdata) |>
  ggplot(aes(x = x, y = z, fill = tsnr)) +
  scale_fill_gradient(high='red',low='blue', limits=c(-200,200),na.value="#FFFFFF00") +
  facet_grid(y~.) +
  geom_raster() +
  theme_minimal() +
  guides(fill="none")

p_b0_z <- rslice_zs(b0_pdata) |>
  ggplot(aes(x = x, y = y, fill = tsnr)) +
  scale_fill_gradient(high='red',low='blue', limits=c(-200,200),na.value="#FFFFFF00",breaks=c(-200,0,200)) +
  facet_grid(z~.) +
  geom_raster() +
  theme_minimal() # + guides(fill="none")

p_mni_y <- rslice_ys(mni) |>
  ggplot(aes(x = x, y = z, fill = tsnr)) +
  scale_fill_gradient(high='gray62',low='grey8') +
  facet_grid(y~.) +
  geom_raster() +
  theme_minimal() +
  guides(fill="none")
p_mni_z <- rslice_zs(mni) |>
  ggplot(aes(x = x, y = y, fill = tsnr)) +
  scale_fill_gradient(high='gray62',low='grey8') +
  facet_grid(z~.) +
  geom_raster() +
  theme_minimal() +
  guides(fill="none")

no_facet <- theme(strip.background = element_blank(),
                 strip.text.y = element_blank())
#no_y <- scale_y_discrete(labels = NULL, breaks = NULL)
p_anat <- cowplot::plot_grid(ncol=3,
  tsnr_angle_y + theme_void() + no_facet,
  p_b0_y + theme_void() + no_facet,
  p_mni_y + theme_void(),
  tsnr_angle_z + theme_void() + no_facet +
                 theme(legend.position = "none"),
  p_b0_z + theme_void() + no_facet +
           theme(legend.position = c(.4,.3),
                 legend.direction = "horizontal") + labs(fill='B0'),
  p_mni_z + theme_void())
ggsave(p_anat,file='images/anat_tsnr_b0_mni.png')

mktitle <- function(title)  cowplot::ggdraw() +
  cowplot::draw_label(title, fontface = 'bold', x = 0, hjust = 0)
  #+theme(plot.margin = margin(0, 0, 0, 7))

p_fig3 <- cowplot::plot_grid(ncol=2,
                             rel_heights = c(0.1, 1),
                             mktitle("  A. In-plane tSNR"),
                             mktitle("B. Angle Map at Max. ΔB0. Anatomy "),
                             tsnr_plane+labs(title=NULL),
                             p_anat)

ggsave(p_fig3,
       file='images/fig3_tsnr_b0_mni.png',
       width=8.39,height=7.56)



### cor between tsnr angle at max and scan time calculation (epi mag) 
atscanmax <- oro.nifti::readNIfTI('./maxangle_mni/sub-1_a10_space-MNI_maxangle.nii.gz')@.Data
tsnr_angle2 <- oro.nifti::readNIfTI('./maxangle_mni/sub-1_angleatmax-tsnr.nii.gz')@.Data
atscanmax[mni_mask==0]<-NA

# done in R vs done in pyhton
cor(as.vector(tsnr_angle2),as.vector(anglemax3d), use='pairwise.complete.obs') 
# [1] .9998497

cor(as.vector(anglemax3d),as.vector(atscanmax), use='pairwise.complete.obs') 
# [1] -0.1023047
cor(as.vector(anglemax3d),as.vector(b0), use='pairwise.complete.obs') 
# [1] 0.1538157
cor(as.vector(atscanmax),as.vector(b0), use='pairwise.complete.obs') 
# [1] -0.2962406

angle_cut <- function(x) cut(as.vector(x),breaks=c(-Inf,-7,7, Inf)) |> as.numeric()
cor(angle_cut(atscanmax), angle_cut(anglemax3d), use='pairwise.complete.obs')
# [1] 0.1096362

# okay what about only where it matters
tsnr_range <- oro.nifti::readNIfTI('./maxangle_mni/tsnr-range.nii.gz')@.Data
asvec_cor <- function(x,y) cor(as.vector(x), as.vector(y),  use='pairwise.complete.obs')
asvec_cor(atscanmax[tsnr_range>20], anglemax3d[tsnr_range>20])
# [1] 0.1411983

# dist for epi is mostly -40 and 20 with 0 getting afew. for tsnr most voxels get assigned angle 6 and 20?!
cbind(
    rle(sort(round(atscanmax[tsnr_range>20] ))) |> with(data.frame(epi=values,nepivox=lengths)) ,
    rle(sort(round(anglemax3d[tsnr_range>20]))) |> with(data.frame(tsnr=values,ntsnrvox=lengths))) |>
    knitr::kable()

p_best_angle_dist <- rbind(
  data.frame(from="a10epi",angle=atscanmax[TRUE]),
  data.frame(from="tsnr",  angle=anglemax3d[TRUE])) |>
    ggplot() + aes(x=angle, fill=from) +
    geom_histogram(position='dodge') +
   theme_minimal() +
   labs(title='Distribution of best angle assignments')
ggsave(p_best_angle_dist,file="images/max_angle_distribution.png",
       width=5.99, height=3.32)


angle_max <- data.frame(
    tsnr=as.vector(anglemax3d), 
    epi=as.vector(atscanmax),
    b0=as.vector(b0))
p_angle <- ggplot(angle_max) +
    aes(x=b0, y=epi, color=b0) +
    geom_jitter() +
    theme_minimal()
#ggsave(p_angle,file="max_angle_corr.png")
