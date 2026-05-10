source('../msa_funcs.R')

image_fnames <- list(
  msa_1='AngleCompare/maxangle_mni/sub-1_angleatmax-n40p20_subset5.nii.gz',
  msa_2='AngleCompare/maxangle_mni/sub-2_angleatmax-n40p20_subset5.nii.gz',
  b0_1='AngleCompare/maxangle_mni/sub-1_space-MNI152NLin2009cAsym_fmapDirect.nii.gz',
  b0_2='AngleCompare/maxangle_mni/sub-2_space-MNI152NLin2009cAsym_fmapDirect.nii.gz',
  roi = './Olfactory/atlas-AonPirFTTubV4_res-func.nii.gz'
)

t1 <- readNifti( "Data/preproc/bids-3depi2x2x2/fmriprep-25.2.3/sub-1iso3d/anat/sub-1iso3d_space-MNI152NLin2009cAsym_res-task_desc-preproc_T1w.nii.gz")
t1_crop <- t1; t1_crop[t1<150] <- 0

b0_caps_quant <- seq(0.4,1,by=.02)
b0_1_nifti <- read_and_crop(image_fnames$b0_1)
b0_1_caps <- quantile(abs(b0_1_nifti),na.rm=T, b0_caps_quant)

b0_2_nifti <- read_and_crop(image_fnames$b0_2)
b0_2_caps <- quantile(abs(b0_2_nifti),na.rm=T, b0_caps_quant)

b0_1_nifti_p <- asNifti(b0_1_nifti,b0_1_nifti)
b0_1_nifti_p[b0_1_nifti>400] <- 400
b0_1_nifti_p[b0_1_nifti<-400] <- -400

b0_empty_df <- data.frame(cor=NA,nmatch=NA,nV4=NA,nTub=NA,nV4match=NA,nAONmatch=NA,nTubmatch=NA, n=NA)

matching_in <- function(i,roi_v, one, two) {
   i_roi <- i & (roi_3d[i]==roi_v)
   sum(one[i_roi]==two[i_roi],na.rm=T)/length(which(i_roi))
   #cor(one[i_roi],two[i_roi],na.rm=T)/length(which(i_roi))
}
roi_size <- function(i, roi_v){
  length(which(roi_3d[i]==roi_v))
}

msa_tsnr_by_b0_quant <- rbind(
  lapply(seq_along(b0_caps_quant), \(i) {
    above_i <- abs(b0_1_nifti)>=b0_1_caps[i]
    cat(i, length(which(above_i)),"\n")
    if (length(which(above_i))==0L) return(b0_empty_df)
    tsnr_at_cap<-all_vecs$tsnr_1[above_i]
    data.frame(cor=cor(tsnr_at_cap, all_vecs$msa_1[above_i], use='pairwise.complete.obs'),
               nmatch=length(which(tsnr_at_cap == all_vecs$msa_1[above_i])),
               nV4=roi_size(above_i,5),
               nAON=roi_size(above_i,1),
               nTub=roi_size(above_i,4),
               nV4match=matching_in(above_i,5,all_vecs$msa_1,all_vecs$tsnr_1),
               nAONmatch=matching_in(above_i,3,all_vecs$msa_1,all_vecs$tsnr_1),
               nTubmatch=matching_in(above_i,4,all_vecs$msa_1,all_vecs$tsnr_1),
               n=length(which(!is.na(tsnr_at_cap))))}) |>
  bind_rows() |>
  mutate(thres=b0_1_caps,
         quant= b0_caps_quant,
         sess="sub-1"),
 # kludge: copy paste for sub_2
  lapply(seq_along(b0_caps_quant), \(i) {
    above_i <- abs(b0_2_nifti)>=b0_2_caps[i]
    cat(i, length(which(above_i)),"\n")
    if (length(which(above_i))==0L) return(b0_empty_df)
    tsnr_at_cap<-all_vecs$tsnr_2[above_i]
    data.frame(cor=cor(tsnr_at_cap, all_vecs$msa_2[above_i], use='pairwise.complete.obs'),
               nmatch=length(which(tsnr_at_cap == all_vecs$msa_2[above_i])),
               nV4=length(which(roi_3d[above_i]==5)),
               nAON=length(which(roi_3d[above_i]==1)),
               nTub=length(which(roi_3d[above_i]==4)),
               nV4match=matching_in(above_i,5,all_vecs$msa_2,all_vecs$tsnr_2),
               nAONmatch=matching_in(above_i,3,all_vecs$msa_2,all_vecs$tsnr_2),
               nTubmatch=matching_in(above_i,4,all_vecs$msa_2,all_vecs$tsnr_2),
               n=length(which(!is.na(tsnr_at_cap))))}) |> bind_rows() |>
  mutate(thres=b0_2_caps,
         quant= b0_caps_quant,
         sess="sub-2"))

msa_tsnr_b0_quant_roi <- msa_tsnr_by_b0_quant |>
  transmute(cor, sess, quant, n,
            across(c(nV4,nAON,nTub), \(x) x/max(x))) |>
  gather(roi,percent,-c(cor,sess,quant,n))

msa_tsnr_b0_quant_roi_match <- msa_tsnr_by_b0_quant  |>
    select(cor, sess, quant, nV4match, nAONmatch,nTubmatch) |>
    gather(roi,percent,-c(cor,sess,quant))|>
    mutate(roi=as.factor(gsub('^n|match$','',roi)))

p_b0_cor_quant <-  ggplot(msa_tsnr_by_b0_quant) +
      aes(x=quant,
          #y=nmatch/n,
          y=cor,
          size=n, fill=gsub('sub-','',sess)) +
      #geom_hline(data=tcor_max, aes(yintercept=cor), color="gray") +
      #geom_line(data=msa_tsnr_by_b0_quant|>filter(quant<.99),
      #          aes(y=nmatch/n, size=NULL),alpha=.1, size=1) +
      geom_point(shape=21) +
      #geom_point(data=msa_tsnr_b0_quant_roi,
      #           aes(fill=NULL,
      #               size=percent*max(n),
      #               color=roi),
      #           shape=21) +
#
      #geom_smooth(data=msa_tsnr_b0_quant_roi_match,
      #           aes(fill=NULL,
      #               #size=,
      #               linetype=sess,
      #               group=paste(roi,sess),
      #               y=percent,
      #               color=roi), size=1, alpha=0) +
      ##geom_line(data=msa_tsnr_b0_quant_roi,
      ##           aes(fill=NULL,
      ##               #size=,
      ##               linetype=sess,
      ##               group=paste(roi,sess),
      ##               y=percent,
      ##               color=roi), size=1, alpha=1) +
      see::theme_modern() +
      theme(plot.title=element_text(size=20, hjust=.5),
            legend.position='top', #c(.3,.8),
            legend.direction="horizontal",
            axis.title=element_text(size=15)) +
      scale_fill_manual(values=sub_colors)+
      scale_size_continuous(breaks=c(1000,20000), , labels=c("1%","100%")) +
    coord_cartesian(xlim=c(.6,1)) +
      guides(fill="none") +
      labs(title="", y=parse(text="'cor'(ɸ[tSNR], ɸ[MSA])"),
           x="ΔB0 Quantile Threshold",
           size="n Voxels",
           fill="Participant")

thres_oob <- function(nii, thres, oob=400) {
    b0_1_thres <- asNifti(b0_1_nifti , b0_1_nifti)
    b0_1_thres[abs(b0_1_thres) < thres] <- NA
    b0_1_thres[b0_1_thres > oob] <- oob
    b0_1_thres[b0_1_thres < -1*oob] <- -1*oob
    return(b0_1_thres)
}

plot_b0_brain <- function(nii) {
outline <- nii
outline <- asNifti(ifelse(!is.na(nii),1,0),nii)
p_b0_brain <- ggbrain(bg_color="white", text="black") +
    images(list(underlay = t1_crop)) +
    images(list(b0 = nii)) +
    images(list(outline = outline)) +
    images(list(b0_full = b0_1_nifti)) +
    images(list(roi = roi_3d), labels=roi_label_color) +
    slices(c("x=-29","y=45"))+
    #slices(c("x=-29","x=28",brain_pos)) +
    geom_brain("underlay") +
    geom_brain("b0_full",alpha=.8, show_legend = F,
               fill_scale = scale_fill_gradient2(name="ΔB0 (Hz)",
                                                high='red',mid="#FFFFFF00",low='blue'))+

    geom_brain("b0",
               show_legend = TRUE,
               fill_scale = scale_fill_gradient2(name="ΔB0 (Hz)",
                                                high='red',mid="#FFFFFF00",low='blue'))+
    geom_outline("outline", outline="black") +
    geom_region_label_repel(image="roi",
                             label_column="label",
                             color='black', size=3, force=1.5,force_pull=0)
}


##

tsnr4d_1_fname <- "AngleCompare/maxangle_mni/sub-1_tsnr-n40n33n13p13p20.nii.gz"
tsnr_1a5 <- read_and_crop(tsnr4d_1_fname)
tsnr_diff_sub1 <- mk_tsnr_diff_df(tsnr_1a5)
b0_tsnr_diff <- tsnr_diff_sub1 |>
    mutate(b0=as.vector(b0_1_nifti), sess='1') |>
    filter(!is.na(tsnr))

ggplot(b0_tsnr_diff |>filter(minmaxdiff>0,b0))+
    aes(x=b0,
        y=minmaxdiff,
        #shape=as.factor(sign(angledif)),
        color=angledif) +
    geom_point() +
    geom_smooth(color='red',method='lm', aes(shape=NULL)) +
    scale_color_gradient2(low='purple',mid='white', high='green') +
    facet_grid(.~factor(sign(b0_1),levels=c(-1,1), labels=c("B0 < 0","B0 > 0")), scales='free') +
    scale_y_continuous(limits=c(0,40))+
    #scale_shape_manual(values=c(21,16)) +
    #scale_x_continuous(trans=abslogtrans)+
    theme_bw() +
    labs(x="ΔB0 (Hz)",
         y=lab_tsnr_range,
         color=parse(text="ɸ[max] - ɸ[min]"))


##
b0q_idxs <- which(b0_caps_quant %in% c(.62, .70,.80, .90, b0_caps_quant[27:28]))
idv_b0_pngs <- lapply(b0q_idxs, \(i) {
#i<-b0q_idxs[4]
outname <- sprintf("Figures/b0/brain_cor_qaunt_%2d.png",i)
q<-b0_caps_quant[i]
v<-b0_1_caps[i]
p<-(plot_b0_brain(thres_oob(b0_1_nifti_p, v, 400)) + render()) /
    p_b0_cor_quant + geom_vline(xintercept=q, color=ifelse(q==.9,'red','yellow'))
  ggsave(p, file=outname, width=6.5,height=6.5,dpi=300)
})
b0_gif_cmd <- paste0(collapse='', 'convert -loop 0', paste0(' -delay 70 ',idv_b0_pngs), ' Figures/b0/brain_cor_qaunt.gif')
system(b0_gif_cmd)




## not used. distirbution
p_tsnr_cor_dist  <-
  rbind(data.frame(tdif=as.vector(b0_1_nifti), sess='1'),
      data.frame(tdif=as.vector(b0_2_nifti), sess='2')) |>
  ggplot() +
  aes(x=tdif,fill=sess) +
  geom_density(alpha=.7) +
  #geom_vline(data=tcor_max, aes(xintercept=thres), color="gray") +
  scale_fill_manual(values=sub_colors) +
  coord_cartesian(xlim=c(-500,500)) +
  see::theme_modern() +
  labs(x="Δ B0", fill="Participant") +
  theme(legend.position=c(.8,1),
        legend.direction="horizontal",
        axis.title=element_text(size=15))
