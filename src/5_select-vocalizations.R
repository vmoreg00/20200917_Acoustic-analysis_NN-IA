# Creation date: DD-MM-YYYY
# Author: Víctor Moreno-González <vmorg@unileon.es>
# Last commit: --
# To do:
# Description
rm(list = ls())
setwd("/mnt/sdb1/MisDocumentos/004-INVESTIGACION/TESIS/20200917_Acoustic-analysis_NN-IA")

library(tuneR)
library(seewave)
library(warbleR)
library(coRvidSound)
library(crayon)

# Load DataBase data ==========================================================
source("../00_CarrionCrow_DB/launchDB.R")
files = EXPAND(cc, "files")
syls <- SELECT(cc, "syllables")
dbDisconnect(cc); detach(db); rm(db)

# List resnet selection tables ================================================
if(file.exists("results/resnet_selections/00_Selections.RDa")){
  load("results/resnet_selections/00_Selections.RDa")
}
lf <- list.files("results/resnet_selections", pattern = "csv$", full.names = T)

# Selection ===================================================================
for(f in lf){
  # Read resnet selection table f
  cat("Reading selections from", unlist(strsplit(f, split = "/"))[3], "...\n")
  automatic_detec <- read.csv(f, stringsAsFactors = F)
  # Look for file location and ID
  archivo <- unique(automatic_detec$Archivo_original)
  if(!file.exists(archivo)){
    fid <- as.numeric(strsplit(archivo, split = c("/|\\."))[[1]][3])
    archivo <- paste0(files$location[files$fileID == fid], ".wav")
    if(archivo == ".wav"){
      cat("\tW: NO FILE FOUND!!!\n")
      next
    }
  } else {
    fid <- files$fileID[files$location == unlist(strsplit(archivo, "\\."))[1]]
  }
  if(! fid %in% 37:99){
    next
  }
  if(archivo %in% unique(vocs$file) | fid %in% c(127, 163, 180, 182, 185, 196,
                                                 198, 199)){
    cat("\tSKIPPING (already parsed)\n")
    next
  }
  # Filter for crow selections
  automatic_detec <- automatic_detec[automatic_detec$Sonido == "crow",]
  cat("\tFound", nrow(automatic_detec), "crow sounds by ResNet50v2\n")
  if(nrow(automatic_detec) == 0){
    cat("\tEMPTY!\n")
    next
  }
  # Look for previously selected vocalizations
  sss <- syls[syls$fileID == fid,]
  if(nrow(sss) > 0){
    cat(bold(red("\nWARNING: Some previous vocalizations are located in this file")))
    cat("\n\tFrom", min(sss$start), "to", max(sss$end))
  }
  # Selections
  cat("\n\tParsing file", archivo, "\n")
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
    # Curation
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
  }; rm(i); close(pb) 
  t2 <- as.numeric(Sys.time())
  st <- round(t2 - t1)
  cat("\tDONE! (", st, " s", ")\n", sep = "")
}; rm(t1, t2, st, pb, archivo, f, automatic_detec, lml, lf, fid, sss)

### Move this line to end !!
save(vocs, file = "results/resnet_selections/00_Selections.RDa")

# Fix selections ==============================================================
# Remove unnecesary columns 
vocs <- vocs[, -c(5,6)]

# Remove overlapping selections
vocs <- vocs[order(vocs$file, vocs$start.in.file),]
ovlp <- c()
for(f in unique(vocs$file)){
  idx = which(vocs$file == f)
  if(length(idx) == 1){
    next
  }
  for(i in 2:length(idx)){
    if(vocs$start.in.file[idx[i]] < vocs$end.in.file[idx[i-1]]){
      ovlp <- c(ovlp, idx[i])
    }
  }
}; rm(f, idx, i)
print(paste("Found", length(ovlp), "overlapping selections"))
vocs <- vocs[-ovlp,]; rm(ovlp)
vocs <- vocs[order(vocs$ID),]

# Save ========================================================================
write.table(vocs, file = "results/resnet_selections/00_Selections.tsv",
            sep = ",", quote = F, col.names = T, row.names = F, dec = ".")

# 