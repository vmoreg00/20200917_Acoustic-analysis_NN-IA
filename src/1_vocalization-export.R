#' 2020-11-06
#' Víctor Moreno-González <vmorg@unileon.es>
#' @description: Extract vocalizations from carrion crow db and noises from
#' 20200824_CarrionCrow-SoundEvents-extractio folder. For vocalization,
#' data augmentation is performed.

# Setup =======================================================================
set.seed(123)
rm(list = ls())

setwd("/mnt/sdb1/MisDocumentos/004-INVESTIGACION/TESIS/20200917_Acoustic-analysis_NN-IA/")
source("/mnt/sdb1/MisDocumentos/004-INVESTIGACION/TESIS/00_CarrionCrow_DB/launchDB.R")

# Retrieve calls ==============================================================
## Retrieve syllables
calls <- EXPAND(cc, "syllables")
calls <- calls[order(calls$fileID, calls$start),]

## Asign call ID (construct calls)
calls$callID <- NA
callID <- 1
calls$callID[1] <- callID
for(s in 2:nrow(calls)){
  silence <- calls$start[s] - calls$end[s-1]
  if(silence >= 0 & silence <= 1 & calls$fileID[s] == calls$fileID[s-1]){
    calls$callID[s] <- callID
  } else {
    callID <- callID + 1
    calls$callID[s] <- callID
  }
};rm(callID, s, silence)

## Substract calls
calls <- calls[, c("vocID", "callID", "location", "start")]
calls <- aggregate(calls, by = list(callID = calls$callID), 
                   function(x){
                     x[1]
                   })[,-1]

# Call's data augmentation ====================================================
# Substract 0.5-2.45 s
calls_ss1 <- calls
calls_ss1$start <- calls_ss1$start - runif(n = nrow(calls), min = 0.5, max = 2.45)
calls_ss1$callID <- paste0(calls_ss1$callID, "_ss1")
# Substract 2.55-4.5
calls_ss2 <- calls
calls_ss2$start <- calls_ss2$start - runif(n = nrow(calls), min = 2.55, max = 4.5)
calls_ss2$callID <- paste0(calls_ss2$callID, "_ss2")
# Merge datasets
calls <- rbind(calls, calls_ss1, calls_ss2); rm(calls_ss1, calls_ss2)
calls$label <- "crow"
calls <- calls[,-1]

# Retrieve noises =============================================================
load("../20200824_CarrionCrow-SoundEvents-extraction/results/noise_selection.Rda")
c.vocs <- c.vocs[, c("ID", "file", "start.in.file", "end.in.file", "label")]

## Split long selections
c.vocs$duration <- c.vocs$end.in.file - c.vocs$start.in.file
c.vocs <- c.vocs[c.vocs$duration >= 5,]
table(c.vocs$label)
to.rm <- c()
for(i in 1:nrow(c.vocs)){
  if(c.vocs$duration[i] > 10){
    n <- c.vocs$duration[i] %/% 5
    c.vocs.new <- c.vocs[rep(i, n),]
    c.vocs.new$start.in.file <- c.vocs.new$start.in.file + seq(from = 0, by = 5, length.out = n)
    to.rm <- c(to.rm, i)
    c.vocs <- rbind(c.vocs, c.vocs.new)
  }
};rm(i, n, c.vocs.new)
c.vocs <- c.vocs[-to.rm,]
c.vocs$duration <- 5
## Check
table(c.vocs$label)
aggregate(c.vocs$duration, by = list(c.vocs$label), sum)
## Assign IDs
c.vocs$ID <- 1:nrow(c.vocs)
c.vocs <- c.vocs[, c("ID", "file", "start.in.file", "label")]
c.vocs$ID <- paste0("n_", c.vocs$ID)
colnames(c.vocs) <- colnames(calls)

# Merge datasets ==============================================================
calls_dataset <- rbind(calls, c.vocs)

# Fix some names
calls_dataset$location <- sapply(calls_dataset$location, function(x){
  if(! endsWith(x, "wav")){
    x = paste0(x, ".wav")
  }
  x
})

# Save data ===================================================================
if(!dir.exists("data")){
  dir.create("data")
}
write.csv(calls_dataset, file = "data/calls_dataset.csv", quote = F,
          row.names = F)
