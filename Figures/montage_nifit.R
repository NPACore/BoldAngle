#/uer/bin/env Rscript
pacman::p_load('RNifti')
draw_sag <- function(img, ti=1, values=NULL) {

  out <- sprintf("sag/%s_%02d.png", deparse(substitute(img)), ti)
  #if(file.exists(out)) return(out)

  # mid-sagittal slice
  mid <- round(dim(img)[1]/2)
  if(length(dim(img)) > 3) {
      sl <- img[mid,,,ti]
  } else {
      sl <- img[mid,,]
  }
  # left/right flip
  sl <- sl[nrow(sl):1,]


  png(out, width = ncol(sl), height = nrow(sl), bg = "black")
  par(mar = c(0,0,0,0))

  if(!is.null(values)){
    color <- scales::rescale(values) |>
        scales::pal_div_gradient(low="red",mid="green",high="blue")()
    breaks <- c(values-.5, max(values)+.5)
    image(sl, col = color, breaks=breaks, axes = FALSE, useRaster = TRUE)
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
sapply(seq_len(dim(aligned_undistored)[4]),\(ti) draw_sag(aligned_undistored, ti))

msa_argmax <- readNifti('../AngleCompare/maxangle_mni/sub-1_a10_space-MNI_maxangle.nii.gz')
mni_mask <- readNifti('../AngleCompare/mni_brainmask.nii.gz')
msa_argmax[mni_mask==0] <- NA
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
