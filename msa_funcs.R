#!/usr/bin/env Rscript
# generic functions for consistant MSA angle
# pulled from figures.org for use in AngleCompare/03a_tsnr_3depi.R

harmonize_angle <- function(angle){
  case_when(
            angle==-39~-40,
            angle==-26~-27,
            angle==-19~-20,
            angle==-6~-7,
            angle==6~7,
            T~angle)
}

# we expect 10 angles
msa_angles <- c(-40, -33, -27, -20, -13, -7, 0, 7, 13, 20)
msa_angles5 <- c(-40, -33, -13, 13, 20)

# diverging color scheme. here to use for consistancy elsewhere
angle_colors_div <- scales::pal_div_gradient(low="red",mid="green",high="blue")(scales::rescale(msa_angles))
names(angle_colors_div) <- msa_angles
# c("#FF0000", "#EA7200", "#D29E00", "#ABC900", "#65EF00", "#4FE947", "#78B785", "#7C85B2", "#6A57D6", "#0000FF")
# also see: scales::show_col(angle_colors_div)

# colors for the 3 sessions sub-1 sub-2 sub-3d1
sub_colors <- c("#F781BF","#FF7F00","#983EA3")
names(sub_colors) <- c("1","2","3d1")

acq_colors <- list(msa="#F8766D", tsnr="#00BFC4")

# command & parameters to try to get to a high quality gif image
# used by Figures/b0_thres_animate.R Figures/montage_nifit.R Olfactory/02_tsnr_model.R
cmd_convert_base <- 'convert -background white -alpha remove -layers OptimizePlus -density 300 -quality 100 -loop 0'

# stylize x/y for cor mat like below, but with markdown for color too
relabel_datasets_axis_md <- function(x) {
  color <- case_when(
      grepl('tsnr',x)&grepl('msa',x) ~ NA,
      grepl('msa', x) ~ acq_colors$msa,
      grepl('tsnr',x) ~ acq_colors$tsnr,
      T ~ NA)
  x <- ifelse(is.na(color),
              x,
              gsub('^',paste0("<span style='color:",color, "'>"), x) |>
              gsub('$','</span>', x=_))
  gsub('(b|snr|msa)','\\U\\1',x, perl=T)|>
          gsub('(.*_3d1)','<b>\\1</b>',x=_) |>
          gsub('_([^<\\)]*)', '_\\1', x=_)
}
# stylize x/y ticks add subscript and bold: msa_1 to MSA["1"]; MSA_3d1 bold(MSA_["3d1"])
relabel_datasets_axis <- function(x)
  parse(text=gsub('(b|snr|msa)','\\U\\1',x, perl=T)|>
          gsub('(.*_3d1)','bold(\\1)',x=_) |>
          gsub('_([^\\)]*)', '["\\1"]', x=_))


# 3D nifti file into vector. useful for between-volume correlation
niifile_vec <- function(img, mask=NULL, na.zero=TRUE){
  m<-RNifti::readNifti(img)
  # remove stuff outside the brain if given a mask
  if(!is.null(mask)) m[mask==0]<-NA;
  # already masked area might inflate correlation if treated as 0
  if(na.zero) m[m==0] <- NA;
  as.vector(m)
}

#' @examples
#' n_neg_text_to_num(c('n40','20','p13'))
n_neg_text_to_num <- function(txt)
    gsub('^[Nn]','-', txt) |> gsub('^p','',x=_) |>as.numeric()

#' @examples
#' rest_subj_angle(list("25.2.3/sub-2/func/sub-2_task-restn6_space-MNI152NLin2009cAsym_desc-mean_bold.nii.gz", "sub-1iso3d/func/sub-1iso3d_task-rest_acq-n13_space-MNI152NLin2009cAsym_desc-mean_bold.nii.gz"))
rest_subj_angle <- function(niilist){
 niilist |>
  stringr::str_extract('sub-([^/_]*)[/_].*rest.*?([np]?[0-9]+)_',
                       group=1:2)|>
  as.data.frame() |>
  transmute(id=V1,
            angle=n_neg_text_to_num(V2)) |>
  mutate(angle = harmonize_angle(angle))
}


# copied from b0
read_and_crop <- function(f) { x <- readNifti(f); x[t1_crop<=0] <- NA; x }
mk_tsnr_diff_df <- function(tsnr_in){
  # tsnr_in 4d 5angle tsnr
  tsnr_a5_min <- apply(tsnr_in,c(1:3),min,na.rm=T)
  tsnr_a5_max <- apply(tsnr_in,c(1:3),max,na.rm=T)
  tsnr_a5_dif <- (tsnr_a5_max - tsnr_a5_min)

  tsnr_a5_minA <- apply(tsnr_in,c(1:3),\(x) which.min(x)|>argm_angle())
  tsnr_a5_maxA <- apply(tsnr_in,c(1:3),\(x) which.max(x)|>argm_angle())
  tsnr_a5_difA <- tsnr_a5_maxA - tsnr_a5_minA

  #tsnr_a5d <- tsnr_a5_dif |> asNifti(tsnr)
  #tsnr_a5d[!is.finite(tsnr_a5d)|tsnr_a5_min<0|t1_crop<5] <- NA
  #  tsnr_a5d_oob <- tsnr_a5d
  #  tsnr_a5d_oob[tsnr_a5d>30] <- 30
  #  tsnr_a5d_oob_roi <- tsnr_a5d_oob
  #  tsnr_a5d_oob_roi[!roi_3d %in% c(1,4,5) ] <- NA

  data.frame(
      tsnr=as.vector(tsnr),
      minmaxdiff=as.vector(tsnr_a5_dif),
      max=as.vector(tsnr_a5_max),
      angledif = as.vector(tsnr_a5_difA))
}
