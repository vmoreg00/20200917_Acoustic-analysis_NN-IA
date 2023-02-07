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
library(crayon)
devtools::load_all("../src/coRvidSound")

# Load DataBase data ==========================================================
devtools::load_all("../00_CarrionCrow_DB")
cc <- db_load()
files <- expand_ccdb(cc, "files")
syls <- select_ccdb(cc, "syllables")
dbDisconnect(cc); rm(cc)

# List resnet selection tables ================================================
if(file.exists("results/resnet_selections/00_Selections.RDa")){
  load("results/resnet_selections/00_Selections.RDa")
}
lf <- list.files("results/resnet_selections", pattern = "csv$", full.names = T)
lf_ids <- sapply(strsplit(lf, "_"), function(x){
  as.numeric(gsub(".csv$", "", x[length(x)]))
  })
# Selection ===================================================================
#### Temporal code
crowIDs <- c(60, 61, 69, 76, 86, 100)
#### END of temporal code
for(cid in sort(unique(files$crowID))){
  #### Temporal code
  if(! cid %in% crowIDs){
    next
  }
  #### END of temporal code
  cat("==================== PARSING CROW", cid, "====================\n")
  # Get files that correspond to crowID
  lf2 <- lf[which(lf_ids %in% files$fileID[files$crowID == cid])]
  if(length(lf2) == 0) next
  for(f in lf2){
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
    if(archivo %in% unique(vocs$file) | fid %in% c(127, 163, 180, 182, 185, 196,
                                                   198, 199, 206, 210, 461, 481,
                                                   690, 701)){
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
      if(nrow(sss) > 0){
        if(automatic_detec$Segundo[i] > min(sss$start) &
           automatic_detec$Segundo[i] < max(sss$start)){
          setTxtProgressBar(pb, i)
          next
        }
      }
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
        if(nrow(lml) > 0){
          if(!exists("vocs")){
            vocs <- lml
          } else {
            vocs <- rbind(vocs, lml)
          }
        }
      }
      setTxtProgressBar(pb, i)
    }; rm(i); close(pb)
    t2 <- as.numeric(Sys.time())
    st <- round(t2 - t1)
    cat("\tDONE! (", st, " s", ")\n", sep = "")
    # save changes after every file is done!!!
    save(vocs, file = "results/resnet_selections/00_Selections.RDa")
  }; rm(t1, t2, st, pb, archivo, f, automatic_detec, lml, fid, sss)
}; rm(lf, cid, lf_ids)
### Move this line to end !!
save(vocs, file = "results/resnet_selections/00_Selections.RDa")

# Fix selections ==============================================================
# Remove unnecessary columns
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
vocs <- vocs[order(vocs$ID, vocs$start.in.file),]

# Save ========================================================================
write.table(vocs, file = "results/resnet_selections/00_Selections.tsv",
            sep = ",", quote = F, col.names = T, row.names = F, dec = ".")

backup_ccdb("../00_CarrionCrow_DB/inst/ccdb/CarrionCrow_DB.sqlite")
backup_ccdb("../00_CarrionCrow_DB/data/CarrionCrow_DB.sqlite")

# Insert data into Carrion Crow DB
devtools::load_all("../00_CarrionCrow_DB/")
cc <- db_load()

## Adapt annotation
vocs$vocID <- NA
for(l in unique(vocs$label)){
  ss <- which(vocs$label == l)
  vocs$vocID[ss] <- paste0(vocs$label[ss], "_", 1:length(ss))
}; rm(l, ss)
vocs$fileID <- as.numeric(sapply(strsplit(vocs$vocID, "_"), function(x) x[1]))
vocs$context <- NA; vocs$callID <- NA

vocs <- vocs %>%
  dplyr::select(c(vocID, fileID, start = start.in.file, end = end.in.file, 
                  bottomFreq = bottom.freq, topFreq = top.freq, context, callID))
nms <- colnames(vocs)
vocs$vocID <- paste0("'", vocs$vocID, "'")
for(e in 1:nrow(vocs)){
  if(any(is.na(vocs[e,]))){
    vocs[e, which(is.na(vocs[e,]))] <- "NULL"
  }
  dbExecute(cc,
            paste0("INSERT INTO syllables (", paste(nms, collapse = ", "), ") ",
                   "VALUES (", paste(vocs[e,], collapse = ", "), ");")
  )
  if(e %% 1000 == 0){
    cat(e, "/", nrow(vocs), "\n")
  }
}; rm(e, nms)
.identify_calls(cc)

## Export annotation to raven selection tables
if(!dir.exists("results/manual_selections")){
  dir.create("results/manual_selections")
}
syllables_to_raven(cc, path = "results/manual_selections/")

# lf <- list.files("results/manual_selections/", pattern = ".txt$")
# sel_f <- sample(unique(syls$fileID), size = 50) %>% sort()
# 
# for(i in sel_f){
#   lf_i <- lf[which(startsWith(lf, paste0(i, "_")))]
#   if(length(grep("_19_", lf_i)) == 1){
#     file.copy(from = paste0("results/manual_selections/", lf_i),
#               to = "/media/msi/TOSHIBA EXT/SELECTIONS/")
#   }
# }; rm(i, lf_i)
