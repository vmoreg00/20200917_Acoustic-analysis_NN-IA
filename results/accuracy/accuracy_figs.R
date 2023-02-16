sss <- read.csv("/mnt/sdb1/MisDocumentos/004-INVESTIGACION/TESIS/20200917_Acoustic-analysis_NN-IA/results/ResNet50V2_historial_de_entrenamiento.csv")
library(ggplot2)
library(ggpubr)
library(png)

cm <- readPNG("/mnt/sdb1/MisDocumentos/004-INVESTIGACION/TESIS/20200917_Acoustic-analysis_NN-IA/results/accuracy/confusion_matrix.png")


ss1 <- reshape2::melt(sss, id.vars = "X",
                      measure.vars = c("accuracy", "val_accuracy"))
ss2 <- reshape2::melt(sss, id.vars = "X",
                      measure.vars = c("loss", "val_loss"))
ggarrange(
  ggarrange(
    ggplot(ss1, aes(x = X, y = value, color = variable)) +
      geom_line(lwd = 0.8) +
      scale_color_manual(name = "", values = RColorBrewer::brewer.pal(9, "Set1")[c(2,5)]) +
      scale_y_continuous(name = "Accuracy", limits = c(0,1), expand = c(0,0)) +
      scale_x_continuous(name = "epoch", expand = c(0,0)) +
      theme_classic() +
      theme(legend.position = "top",
            text = element_text(size = 12)),
    ggplot(ss2, aes(x = X, y = value, color = variable)) +
      geom_line(lwd = 0.8) +
      scale_color_manual(name = "", values = RColorBrewer::brewer.pal(9, "Set1")[c(1,3)]) +
      scale_y_log10(name = "Loss") +
      scale_x_continuous(name = "epoch", expand = c(0,0)) +
      theme_classic() +
      theme(legend.position = "top",
            text = element_text(size = 12)),
    nrow = 2, labels = "AUTO"),
  ggplot() + 
    background_image(img1) +
    theme(plot.margin = margin(t=-1, l=-0.5, r=-0.5, b=0, unit = "cm")),
  ncol = 2, labels = c("", "C"), widths = c(0.35,0.65))
ggsave("/mnt/sdb1/MisDocumentos/004-INVESTIGACION/TESIS/20200917_Acoustic-analysis_NN-IA/results/accuracy/accuracy.png",
       height = 11, width = 25, units = "cm", dpi = 333)

