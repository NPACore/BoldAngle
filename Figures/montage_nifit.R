#/uer/bin/env Rscript
# snapshots of nifti files for tool diagram ./MSA_max.svg
# 20260501 - init
pacman::p_load('RNifti')
draw_sag <- function(img, ti=1, values=NULL) {

  out <- sprintf("sag/%s_%02d.png", deparse(substitute(img)), ti)
  #if(file.exists(out)) return(out)

  # mid-sagittal slice
  mid <- round(dim(img)[1]/2)
  mid <- 66
  if(length(dim(img)) > 3) {
      sl <- img[mid,,,ti]
  } else {
      sl <- img[mid,,]
  }
  # left/right flip
  sl <- sl[nrow(sl):1,]


  png(out, width = ncol(sl), height = nrow(sl), bg = "black")
  par(mar = c(0,0,0,0))

  if(length(values) > 1 && length(values) < 20){
    # 10 angles
    color <- scales::rescale(values) |>
        scales::pal_div_gradient(low="red",mid="green",high="blue")()
    breaks <- c(values-.5, max(values)+.5)
    image(sl, col = color, breaks=breaks, axes = FALSE, useRaster = TRUE)
  } else if(length(values)==1){
    # heatmap
    image(sl, col = viridis::plasma(256), axes = FALSE, useRaster = TRUE)
  } else if(length(values)==256){
    # given colors heatmap
    image(sl, col = values, axes = FALSE, useRaster = TRUE)
  } else{
    color <- gray((0:255)/255)
    image(sl, col = color, axes = FALSE, useRaster = TRUE)
  }



  dev.off()

  return(out)
}

dir.create('sag/', showWarnings=F)

# multi-slice-angle before correction: sag/msa_01.png to sag/msa_10.png
msa <- readNifti('../Data/bids-a10/sub-1/func/sub-1_task-n40p20_acq-inc_bold.nii.gz')
sapply(seq_len(dim(msa)[4]),\(ti) draw_sag(msa, ti))

aligned_undistored <- readNifti('../FmapCorrect/wf/human-largefov/sub-1/epi_undistorted_masked.nii.gz')
# normalize color - drop bottom 20%
for (i in seq_len(dim(aligned_undistored)[4])) {
    x <- aligned_undistored[,,,i]
    x <- scales::rescale(x, to=c(0,1), from=quantile(x,c(.2,1)))
    x[x>1] <- 1
    x[x<0] <- 0
    aligned_undistored[,,,i] <- x
}
sapply(seq_len(dim(aligned_undistored)[4]),\(ti) draw_sag(aligned_undistored, ti))

# fieldmap. used to correct MSA
fieldmap <- readNifti('../FmapCorrect/wf/human-largefov/sub-1/sdc/unwarp/FM_UD_fmap.nii.gz')
fieldmap[fieldmap==0] <- NA
range(fieldmap,na.rm=T) # [1] -898.5629 1586.9850
draw_sag(fieldmap, 1)
fmap_heat <- fieldmap
draw_sag(fmap_heat, 1, viridis::turbo(256))

## arg max of MSA (already computed)
#msa_argmax <- readNifti('../AngleCompare/maxangle_mni/sub-1_a10_space-MNI_maxangle.nii.gz')
#mni_mask <- readNifti('../AngleCompare/mni_brainmask.nii.gz')
#msa_argmax[mni_mask==0] <- NA

msa_argmax <- readNifti('../FmapCorrect/wf/human-largefov/sub-1/angles_at_max.nii.gz')
msa_argmax[,,] <- round(msa_argmax[,,],0)
angles <- sort(unique(msa_argmax[!is.na(msa_argmax)]))
# [1] -40 -33 -27 -20 -13  -7   0   7  13  20
draw_sag(msa_argmax, 1, angles)

# create legend
color_mat <- scales::rescale(values) |>
    scales::pal_div_gradient(low="red",mid="green",high="blue")() |>
    as.matrix()
size <- max(dim(color_mat))
png("sag/key.png")
plot(c(0,.6), c(0, -size),
     type = "n", xlab = "", ylab = "", axes = FALSE)
rect(0, -row(colours) + 1,
     .2, -row(colours),
     col = as.vector(color_mat))
text(0.1, -row(colours) + 0.5, values, col = 'black')
dev.off()

# timeseires example
#rng <- apply(aligned_undistored,1:3,range)
#drng <- apply(rng, 2:4, diff)
#arrayInd(which.max(drng), dim(drng)) # 58 38 1
ts <- data.frame(ts=aligned_undistored[58,38,10,], angle=as.factor(angles), i=1:10)
library(ggplot2)
ggplot(ts) + aes(x=i,y=ts,color=angle) + geom_line(color="black",alpha=.2, size=1) + geom_point(size=4) + theme_void() + scale_color_manual(values=color_mat)
ggsave('sag/angle_ts.png', width=8, height=3)
