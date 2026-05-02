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

# diverging color scheme. here to use for consistancy elsewhere
angle_colors_div <- scales::pal_div_gradient(low="red",mid="green",high="blue")(scales::rescale(msa_angles))
# c("#FF0000", "#EA7200", "#D29E00", "#ABC900", "#65EF00", "#4FE947", "#78B785", "#7C85B2", "#6A57D6", "#0000FF")
# also see: scales::show_col(angle_colors_div)

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
    gsub('^n','-', txt) |> gsub('^p','',x=_) |>as.numeric()

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
