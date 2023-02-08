rm(list = ls())

library(ggplot2)

times <- read.csv2("results/timing/times.csv")

cor <- cor(times$w, times$s)

ggplot(times, aes(x = w, y = s)) +
  geom_smooth(method = "lm") +
  geom_point() +
  geom_text(aes(x = 120, y = 2500, label = paste("r =", round(cor, 2)))) +
  xlab("Number of crow windows") + ylab("Time spend (s)") +
  scale_y_continuous(expand = c(0,0, 0, 50)) +
  scale_x_continuous(expand = c(0,0, 0, 1)) +
  theme_classic()
ggsave("results/timing/time_windows_cor.png",
       width = 20, height = 10, units = "cm", dpi = 333)

mean(times$s); sd(times$s)
