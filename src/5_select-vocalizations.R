rm(list = ls())
setwd("/mnt/sdb1/MisDocumentos/004-INVESTIGACION/TESIS/20200917_Acoustic-analysis_NN-IA")

library(tuneR)
library(seewave)
library(warbleR)
library(coRvidSound)

if(file.exists("results/resnet_selections/00_Selections.RDa")){
  load("results/resnet_selections/00_Selections.RDa")
}
lf <- list.files("results/resnet_selections", pattern = "csv$", full.names = T)

for(f in lf){
  cat("Reading selections from", unlist(strsplit(f, split = "/"))[3], "...\n")
  automatic_detec <- read.csv(f, stringsAsFactors = F)
  if(unique(automatic_detec$Archivo_original) %in% unique(vocs$file)){
    cat("\tSKIPPING (already parsed)\n")
    next
  }
  
  automatic_detec <- automatic_detec[automatic_detec$Sonido == "crow",]
  cat("\tFound", nrow(automatic_detec), "crow sounds by ResNet50v2\n")
  if(nrow(automatic_detec) == 0){
    cat("\tEMPTY!\n")
    next
  }
  pb <- txtProgressBar(min = 0, max = nrow(automatic_detec), style = 3)
  for(i in 1:nrow(automatic_detec)){
    a <- readWave(filename = automatic_detec$Archivo_original[i],
                  from = automatic_detec$Segundo[i],
                  to = automatic_detec$Segundo[i] + 5,
                  units = "seconds")
    writeWave(a, "tmp-audio-clip.wav"); rm(a)
    lml <- long_manual_loc(wav.files = automatic_detec$Archivo_original[i],
                           from = automatic_detec$Segundo[i],
                           to = automatic_detec$Segundo[i] + 5,
                           show = 5, width = 12.5, windowlength = 32,
                           IDstart = ifelse(exists("vocs"), max(vocs$ID + 1), 1),
                           title = automatic_detec$Nombre_fragmento[i])
    if(nrow(lml) > 0){
      lml$label <- automatic_detec$Nombre_fragmento[i]
      lml <- sel_tailor2(lml, width = 12.5, windowlength = 15)
      if(!exists("vocs")){
        vocs <- lml
      } else {
        vocs <- rbind(vocs, lml)
      }
    }
    setTxtProgressBar(pb, i)
  }; rm(i)
  close(pb)
  cat("\tDONE!\n")
}

save(vocs, file = "results/resnet_selections/00_Selections.RDa")
