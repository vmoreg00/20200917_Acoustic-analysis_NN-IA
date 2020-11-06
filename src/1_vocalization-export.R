set.seed(123)
rm(list = ls())

setwd("/mnt/sdb1/MisDocumentos/004-INVESTIGACION/TESIS/20200917_Acoustic-analysis_NN-IA/")
source("/mnt/sdb1/MisDocumentos/004-INVESTIGACION/TESIS/00_CarrionCrow_DB/launchDB.R")

## Calls
calls <- EXPAND(cc, "syllables")
calls <- calls[order(calls$fileID, calls$start),]
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
calls <- calls[, c("vocID", "callID", "location", "start")]
calls <- aggregate(calls, by = list(callID = calls$callID), function(x) x[1])[,-1]
calls$start <- calls$start - runif(n = nrow(calls), min = 0, max = 4.5)
calls$label <- "crow"
calls <- calls[,-1]

load("../20200824_CarrionCrow-SoundEvents-extraction/results/noise_selection.Rda")
c.vocs <- c.vocs[, c("ID", "file", "start.in.file", "end.in.file", "label")]
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
table(c.vocs$label)
aggregate(c.vocs$duration, by = list(c.vocs$label), sum)
c.vocs$ID <- 1:nrow(c.vocs)
c.vocs <- c.vocs[, c("ID", "file", "start.in.file", "label")]
c.vocs$ID <- paste0("n_", c.vocs$ID)
colnames(c.vocs) <- colnames(calls)

calls_dataset <- rbind(calls, c.vocs)
# Remove some noises (~1500)
calls_dataset <- calls_dataset[-sample(which(calls_dataset$label == "noise"),
                                       size = 1500),]
# Fix some names
calls_dataset$location <- sapply(calls_dataset$location, function(x){
  if(! endsWith(x, "wav")){
    x = paste0(x, ".wav")
  }
  x
})

# Save data
if(!dir.exists("data")){
  dir.create("data")
}
write.csv(calls_dataset, file = "data/calls_dataset.csv", quote = F,
          row.names = F)
