#!/usr/bin/env Rscript

# visualize changes to tsnr over acq angle
# tsnr files from ./02_tsnr.bash


# 20251023WF - init
pacman::p_load(dplyr, tidyr, oro.nifti, ggplot2, stringr)
pacman::p_install(ggExtra) # dont shadow any other functions
tsnr_fname <- Sys.glob('../Data/tsnr/sub-[12]_task-rest*_tsnr.nii.gz')
angle_from_taskname <- function(n) str_extract(n, '(?<=task-rest)[^/_-]+') |> gsub(pat='n',rep='-') |> as.numeric()
mni_mask <- oro.nifti::readNIfTI('mni_brainmask.nii.gz')@.Data
tsnr_3ds <- lapply(tsnr_fname, function(f){
    nii <- oro.nifti::readNIfTI(f)@.Data
    nii[mni_mask==0]<-0
    return(nii)
})


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
               i=1:dim(tsnr_3ds[[fi]])[xyi])

# dims = 77 95 82
# c(77*95, 95*82, 77*82) [1] 7315 7790 6314 -- probably more useful to know mask dims
nnz_lims <- c(4000, 3000, 3000)
pdata <- lapply(1:3,
       \(di) lapply(seq_along(tsnr_fname), dim_mean_df, xyi=di) |>
             bind_rows()|>
             filter(nnz>nnz_lims[di])) |>
    bind_rows()
#x <- lapply(seq_along(tsnr_fname), dim_mean_df, xyi=1) |> bind_rows()|> filter(nnz>4000)
#y <- lapply(seq_along(tsnr_fname), dim_mean_df, xyi=2) |> bind_rows() |> filter(nnz>3000)
#z <- lapply(seq_along(tsnr_fname), dim_mean_df, xyi=3) |> bind_rows() |> filter(nnz>3000)
#pdata<-rbind(x,y)

angles_for_line <- c(20, -13, -39)
tsnr_plane <- ggplot(pdata) +
    aes(x=i, y=tsnr_mean,
        color=angle,
        shape=subj,
        linetype=subj,
        #size=nnz,
        group=as.factor(paste(subj,angle))) +
    geom_point(alpha=.2) +
    geom_smooth(data=pdata|>filter(angle %in% angles_for_line),
                method = 'gam',
                se=FALSE) +
    scale_color_gradient2(high='red',mid='green',low='blue') +
    facet_grid(dim~.) +
    theme_minimal() +
    labs(title='Average tSNR by cross section',
         x='voxel index',
         y='Median tSRN  (brain masked)')
ggsave(tsnr_plane, 'tsnr_by_plane.png')

subj1_idx <- which(grepl('sub-1', tsnr_fname))
alltsnr_sub1 <- as.matrix(unlist(tsnr_3ds[subj1_idx]))
dim(alltsnr_sub1) <- c(dim(tsnr_3ds[[1]]),length(subj1_idx))

# make sure we put the matrix back together correctly
stopifnot(all(alltsnr[,,,subj1_idx[2]] == tsnr_3ds[[subj1_idx[2]]]))

anglemax3d <- apply(alltsnr_sub1,1:3,which.max)
anglemax3d[alltsnr_sub1[,,,1]==0] <- NA


# TODO: plot best angle at each pos

angles <- angle_from_taskname(tsnr_fname[subj1_idx])
anglemax3d <- angles[anglemax3d] 
dim(anglemax3d) <- dim(alltsnr_sub1)[1:3]
rslice_ys <- lapply(c(20,45,65),
                 \(y) reshape2::melt(tmp[,y,],
                                     varnames=c("x","z"),
                                     value.name='tsnr') |>
                      mutate(y=y)) |>
    bind_rows()

rslice_zs <- lapply(c(25,55, 65),
                 \(z) reshape2::melt(tmp[,,z],
                                     varnames=c("x","y"),
                                     value.name='tsnr') |>
                      mutate(z=z)) |>
    bind_rows()

cowplot::plot_grid(ncol=3,
 tsnr_plane,
 rslice_ys |>
  ggplot(aes(x = x, y = z, fill = tsnr)) +
  scale_fill_gradient2(high='red',mid='green',low='blue',na.value='#FFFFFF00') +
  facet_grid(y~.) +
  geom_raster() +
  theme_minimal() +
  guides(fill="none"),
 rslice_zs |>
  ggplot(aes(x = x, y = y, fill = tsnr)) +
  scale_fill_gradient2(high='red',mid='green',low='blue',na.value='#FFFFFF00') +
  facet_grid(z~.) +
  geom_raster() +
    theme_minimal() +
  labs(fill='Angle of\nmax tSNR') )



p<- rslice_zs |>
  ggplot(aes(x = x, y = y, fill = tsnr, color=tsnr)) +
  scale_fill_gradient2(high='red',mid='green',low='blue',na.value='#FFFFFF00') +
  facet_grid(z~.) +
  #geom_raster() +
    theme_minimal() +
  labs(fill='Angle of\nmax tSNR') + geom_point()
