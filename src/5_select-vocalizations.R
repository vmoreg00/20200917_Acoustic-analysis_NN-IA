rm(list = ls())
setwd("/mnt/sdb1/MisDocumentos/004-INVESTIGACION/TESIS/20200917_Acoustic-analysis_NN-IA")

library(tuneR)
library(seewave)
library(warbleR)
library(coRvidSound)
source("../00_CarrionCrow_DB/launchDB.R")
files = SELECT(cc, "files")
dbDisconnect(cc); detach(db); rm(db)

if(file.exists("results/resnet_selections/00_Selections.RDa")){
  load("results/resnet_selections/00_Selections.RDa")
}
lf <- list.files("results/resnet_selections", pattern = "csv$", full.names = T)

for(f in lf){
  cat("Reading selections from", unlist(strsplit(f, split = "/"))[3], "...\n")
  automatic_detec <- read.csv(f, stringsAsFactors = F)
  archivo <- unique(automatic_detec$Archivo_original)
  if(!file.exists(archivo)){
    fid <- as.numeric(strsplit(archivo, split = c("/|\\."))[[1]][3])
    archivo <- paste0(files$location[files$fileID == fid], ".wav")
    if(archivo == ".wav"){
      cat("\tW: NO FILE FOUND!!!\n")
      next
    }
    rm(fid)
  }
  if(archivo %in% unique(vocs$file)){
    cat("\tSKIPPING (already parsed)\n")
    next
  }
  
  automatic_detec <- automatic_detec[automatic_detec$Sonido == "crow",]
  cat("\tFound", nrow(automatic_detec), "crow sounds by ResNet50v2\n")
  if(nrow(automatic_detec) == 0){
    cat("\tEMPTY!\n")
    next
  }
  t1 <- as.numeric(Sys.time())
  pb <- txtProgressBar(min = 0, max = nrow(automatic_detec), style = 3)
  for(i in 1:nrow(automatic_detec)){
    a <- readWave(filename = archivo,
                  from = automatic_detec$Segundo[i],
                  to = automatic_detec$Segundo[i] + 5,
                  units = "seconds")
    a <- downsample(a, 16000)
    writeWave(a, "tmp-audio-clip.wav"); rm(a)
    lml <- long_manual_loc(wav.files = archivo,
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
  t2 <- as.numeric(Sys.time())
  st <- round(t2 - t1)
  cat("\tDONE! (", st, " s", ")\n", sep = "")
}; rm(t1, t2, st, pb, archivo, f, automatic_detec, lml, lf)

save(vocs, file = "results/resnet_selections/00_Selections.RDa")

vocs <- vocs[, -c(5,6)]
if(any(vocs$end.in.file < vocs$start.in.file)){
  idx <- which(vocs$end.in.file < vocs$start.in.file)
  for(i in idx){
    start <- vocs$start.in.file[i]
    vocs$start.in.file[i] <- vocs$end.in.file[i]
    vocs$end.in.file[i] <- start
  }
}; rm(idx, start, i)

write.table(vocs, file = "results/resnet_selections/00_Selections.tsv",
            sep = ",", quote = F, col.names = T, row.names = F, dec = ".")
