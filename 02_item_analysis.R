### Item Analysis
### Descriptive item statistics, item-total correlations, item histograms,
### difficulty-discrimination plots

if (!exists("itemdata")) source("01_data_preparation.R")

library(ggplot2)
library(ggrepel)
library(scales)

### ── Item statistics ──────────────────────────────────────────────────────────

itemstatistics <- (itemdata
  %>% left_join(iteminfo, by = "itemid")
  %>% group_by(userID, dimid)
  %>% mutate(dimvalue = sum(value))
  %>% ungroup()
  %>% group_by(itemid)
  %>% summarise(
    N = n(),
    M = mean(value),
    SD = sd(value),
    MIN = min(value),
    MAX = max(value),
    TotCorr = cor(value, dimvalue - value),
    .groups = "drop"
  )
  %>% mutate(P = M / MAX)
)

cat("Item statistics computed.\n")
print(as.data.frame(itemstatistics), row.names = FALSE)

### ── Item histograms ──────────────────────────────────────────────────────────

itemhistvalues <- (itemdata
  %>% group_by(itemid, value)
  %>% summarise(N = n(), .groups = "drop_last")
  %>% mutate(rel = N / sum(N))
  %>% ungroup()
)

for (currentitemid in unique(itemdata$itemid)) {
  currentitemvalues <- itemhistvalues %>% dplyr::filter(itemid == currentitemid)
  itemcontent <- iteminfo[iteminfo$itemid == currentitemid, ]$text

  currentitemplot <- ggplot(data = currentitemvalues) +
    geom_bar(stat = "identity", aes(x = value, y = rel), fill = "#161d9e") +
    theme_bw() +
    labs(x = "Response", y = "Relative Frequency") +
    scale_y_continuous(labels = function(x) paste0(x * 100, "%")) +
    scale_x_continuous(breaks = 1:5, labels = c(
      "1\nDisagree", "2", "3\nNeutral", "4", "5\nAgree")) +
    ggtitle(paste0(currentitemid, ": ", itemcontent))

  currentitemplot %>% ggsave(
    filename = file.path(outputpath, "itemstatistics", paste0("hist-", currentitemid, ".png")))
}

cat("Item histograms saved.\n")

### ── Difficulty-discrimination plots (per dimension) ──────────────────────────

### quadratic regression helper for P-TotCorr curve
quadY <- function(a, xvalues) {
  a * xvalues^2 + (-a) * xvalues
}

quadReg <- function(x, y, amin, amax, h) {
  possibleas <- seq(amin, amax, h)
  errors <- sapply(possibleas, function(a) {
    paraby <- a * x^2 + (-a) * x
    mean((y - paraby)^2)
  })
  possibleas[which.min(errors)]
}

for (currentdim in dimensions) {
  currentdimname <- unique(iteminfo$dimname[iteminfo$dimid == currentdim])

  currentdimitemdata <- (itemstatistics
    %>% left_join(iteminfo, by = "itemid")
    %>% dplyr::filter(dimid == currentdim)
    %>% select(itemid, P, TotCorr, dimname)
  )

  paraLine <- data.frame(x = seq(0, 1, 0.01))
  paraLine$y <- quadY(
    quadReg(currentdimitemdata$P, currentdimitemdata$TotCorr, -4, -0.01, 0.01),
    paraLine$x)

  currentdimplot <- ggplot(data = currentdimitemdata, aes(x = P, y = TotCorr)) +
    geom_line(data = paraLine, aes(x = x, y = y), color = "green") +
    geom_point(size = 2) +
    theme_bw() +
    labs(x = "Item Difficulty (P)", y = "Corrected Item-Total Correlation") +
    ggtitle(paste0(currentdimname, " (", currentdim, ")")) +
    geom_label_repel(aes(label = itemid), size = 3)

  currentdimplot %>% ggsave(
    filename = file.path(outputpath, "itemstatistics", paste0("totCorr-", currentdim, ".png")))
  currentdimplot %>% ggsave(
    filename = file.path(outputpath, "itemstatistics", paste0("totCorr-", currentdim, ".pdf")))
}

cat("Difficulty-discrimination plots saved.\n")
