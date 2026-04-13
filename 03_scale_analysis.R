### Scale Analysis
### Dimension descriptives, histograms, correlation heatmap,
### factor analysis, parallel analysis, reliability

if (!exists("itemdata")) source("01_data_preparation.R")

library(ggplot2)
library(ggrepel)
library(moments)
library(Hmisc)
library(psych)
library(nFactors)

### ── Dimension descriptive statistics ─────────────────────────────────────────

dimensionstatistics <- (dimensiondata
  %>% group_by(dimid)
  %>% summarise(
    N = n(), M = mean(score), SD = sd(score),
    Skew = skewness(score), Kurtosis = kurtosis(score),
    MIN = min(score), MAX = max(score),
    .groups = "drop"
  )
)

cat("Dimension statistics:\n")
print(as.data.frame(dimensionstatistics), row.names = FALSE)

### ── Dimension histograms ─────────────────────────────────────────────────────

for (currentdim in dimensions) {
  currentdimname <- unique(iteminfo$dimname[iteminfo$dimid == currentdim])

  currentdimvalues <- (dimensiondata
    %>% dplyr::filter(dimid == currentdim)
    %>% group_by(score)
    %>% summarise(N = n(), .groups = "drop")
    %>% mutate(rel = N / sum(N))
  )

  p <- ggplot(data = currentdimvalues) +
    geom_bar(stat = "identity", aes(x = score, y = N), fill = "#161d9e") +
    theme_bw() +
    labs(x = "Sum Score", y = "Frequency") +
    ggtitle(currentdimname)

  p %>% ggsave(filename = file.path(outputpath, "dimstatistics",
                                    paste0("hist-", currentdim, ".png")))
}

cat("Dimension histograms saved.\n")

### ── Correlation heatmap ──────────────────────────────────────────────────────

### create a lookup table with one row per dimension (avoids many-to-many join)
dimlookup <- iteminfo %>% select(dimid, dimname) %>% distinct()

dimensiondatamatrix <- (dimensiondata
  %>% pivot_wider(names_from = dimid, values_from = score)
  %>% select(-userID)
)

corrmatrix <- rcorr(as.matrix(dimensiondatamatrix))
corrdata <- (as.data.frame(corrmatrix$r)
  %>% tibble::rownames_to_column("dim1")
  %>% pivot_longer(cols = -dim1, names_to = "dim2", values_to = "corr")
  %>% left_join(dimlookup, by = c("dim1" = "dimid"))
  %>% rename(Dimension1 = dimname)
  %>% left_join(dimlookup, by = c("dim2" = "dimid"))
  %>% rename(Dimension2 = dimname)
)

corrplot <- ggplot(corrdata, aes(x = Dimension1, y = Dimension2, fill = corr)) +
  geom_tile() +
  geom_text(aes(label = sprintf("%.2f", corr)), size = 3.5) +
  scale_fill_gradient2(low = "blue", high = "red", mid = "white",
                       midpoint = 0, limit = c(-1, 1), space = "Lab",
                       name = "Pearson\nCorrelation") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, size = 12, hjust = 1),
        axis.title = element_blank()) +
  ggtitle("Scale Intercorrelations") +
  coord_fixed()

corrplot %>% ggsave(filename = file.path(outputpath, "dimstatistics", "dimcorrelation.png"))

cat("Correlation heatmap saved.\n")

### ── Factor analysis ──────────────────────────────────────────────────────────

allitemdata <- (itemdata
  %>% select(userID, itemid, value)
  %>% pivot_wider(names_from = itemid, values_from = value)
  %>% select(-userID)
)

numberOfFactors <- 5

### principal components
fit <- principal(allitemdata, numberOfFactors, rotate = "varimax")
print(fit)

### parallel analysis / scree
ev <- eigen(cor(allitemdata))
ap <- parallel(subject = nrow(allitemdata), var = ncol(allitemdata), rep = 100, cent = .05)
nS <- nScree(x = ev$values, aparallel = ap$eigen$qevpea)
png(file.path(outputpath, "dimstatistics", "scree.png"))
plotnScree(nS)
dev.off()

### factor loadings plot
fca <- fa(allitemdata, nfactors = numberOfFactors)
fcaloadings <- fca$loadings

fcal <- (as.data.frame(unclass(fcaloadings))
  %>% tibble::rownames_to_column("itemid")
  %>% pivot_longer(cols = -itemid, names_to = "factor", values_to = "value")
  %>% left_join(iteminfo, by = "itemid")
)

### automatically determine which factor maps to which dimension
### (by highest mean absolute loading)
factor_dim_map <- (fcal
  %>% group_by(factor, dimid)
  %>% summarise(mean_abs_loading = mean(abs(value)), .groups = "drop")
  %>% group_by(factor)
  %>% slice_max(mean_abs_loading, n = 1)
  %>% select(factor, dimid)
  %>% rename(mapped_dimid = dimid)
)

fcal <- (fcal
  %>% left_join(factor_dim_map, by = "factor")
  %>% mutate(showlabel = (dimid == mapped_dimid))
)

### create readable x-axis labels: map factor IDs to dimension names
factor_labels <- factor_dim_map %>%
  left_join(dimlookup, by = c("mapped_dimid" = "dimid"))
factor_label_vec <- setNames(factor_labels$dimname, factor_labels$factor)

ggloadings <- ggplot(data = fcal, aes(x = factor, y = value, colour = dimname)) +
  geom_point() +
  theme_bw() +
  scale_x_discrete(labels = factor_label_vec) +
  labs(x = "Factor", y = "Factor Loading", colour = "Dimension") +
  ggtitle("Exploratory Factor Analysis: Factor Loadings") +
  geom_label_repel(aes(label = ifelse(showlabel, itemid, "")),
                   max.overlaps = 20, size = 3)

ggloadings %>% ggsave(
  filename = file.path(outputpath, "dimstatistics", "fa_loadings.png"),
  width = 12, height = 6)

### factor loadings heatmap (items sorted by dimension)

### factor-to-dimension-name lookup for axis labels
factor_to_name <- factor_dim_map %>%
  left_join(dimlookup, by = c("mapped_dimid" = "dimid")) %>%
  select(factor, factor_label = dimname)

fcal_heatmap <- (as.data.frame(unclass(fcaloadings))
  %>% tibble::rownames_to_column("itemid")
  %>% left_join(iteminfo, by = "itemid")
  %>% pivot_longer(cols = starts_with("MR"), names_to = "factor", values_to = "loading")
  %>% left_join(factor_to_name, by = "factor")
  ### order items by dimension, then by index within dimension
  %>% mutate(index = as.numeric(index))
  %>% arrange(dimid, index)
  %>% mutate(itemid = factor(itemid, levels = rev(unique(itemid))))
  ### order factors by mapped dimension
  %>% mutate(factor_label = factor(factor_label,
    levels = unique(factor_label[order(factor)])))
)

ggheatmap <- ggplot(fcal_heatmap, aes(x = factor_label, y = itemid, fill = loading)) +
  geom_tile(colour = "white", linewidth = 0.3) +
  geom_text(aes(label = sprintf("%.2f", loading)),
            size = 2.2, colour = ifelse(abs(fcal_heatmap$loading) > 0.45, "white", "grey30")) +
  scale_fill_gradient2(low = "#2166ac", mid = "white", high = "#b2182b",
                       midpoint = 0, limit = c(-0.5, 0.85),
                       oob = scales::squish,
                       name = "Loading") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 7),
        panel.grid = element_blank()) +
  labs(x = "Factor", y = NULL) +
  ggtitle("Factor Loadings Heatmap")

ggheatmap %>% ggsave(
  filename = file.path(outputpath, "dimstatistics", "fa_heatmap.png"),
  width = 7, height = 12)

### factor loadings network diagram
library(qgraph)

### compute item correlation matrix for the network
item_corr <- cor(allitemdata)

### item groups and colors by dimension
### qgraph uses the `color` argument as per-group colors when `groups` is set,
### so the order must match the factor levels of `groups`
group_levels <- c("Extraversion", "Emotional Stability", "Agreeableness",
                  "Conscientiousness", "Openness")
group_colors <- c("#00BFC4", "#7CAE00", "#F8766D", "#C77CFF", "#FF61CC")

item_dimids <- iteminfo$dimid[match(colnames(item_corr), iteminfo$itemid)]
dim_labels <- setNames(iteminfo$dimname, iteminfo$dimid)
item_groups <- factor(dim_labels[item_dimids], levels = group_levels)

png(file.path(outputpath, "dimstatistics", "fa_network.png"),
    width = 1400, height = 1100, res = 150)
qgraph(item_corr,
       layout = "spring",
       color = group_colors,
       labels = colnames(item_corr),
       label.cex = 0.65,
       label.scale.equal = TRUE,
       minimum = 0.15,
       cut = 0.3,
       vsize = 5,
       esize = 3,
       borders = FALSE,
       title = "Item Correlation Network",
       title.cex = 1.3,
       groups = item_groups,
       legend = TRUE,
       legend.cex = 0.32,
       posCol = "#b2182b",
       negCol = "#2166ac",
       mar = c(2, 2, 4, 2))
dev.off()

cat("Factor analysis plots saved.\n")

### ── Reliability ──────────────────────────────────────────────────────────────

reltable <- data.frame(dimid = character(), Dimension = character(), N = numeric(),
                       Cronbach = numeric(), Cronbach_st = numeric(), SplitHalf = numeric())

for (currentdim in dimensions) {
  currentdimname <- unique(iteminfo$dimname[iteminfo$dimid == currentdim])

  currentitemdata <- (itemdata
    %>% left_join(iteminfo, by = "itemid")
    %>% dplyr::filter(dimid == currentdim)
    %>% select(userID, itemid, value)
    %>% pivot_wider(names_from = itemid, values_from = value)
    %>% select(-userID)
  )

  ca <- psych::alpha(currentitemdata)
  sh <- splitHalf(currentitemdata)

  reltable <- reltable %>% add_row(
    dimid = currentdim, Dimension = currentdimname, N = nrow(currentitemdata),
    Cronbach = ca$total$raw_alpha, Cronbach_st = ca$total$std.alpha,
    SplitHalf = sh$maxrb
  )
}

cat("\nReliability:\n")
print(as.data.frame(reltable), row.names = FALSE)

reltable_long <- reltable %>%
  pivot_longer(cols = c(Cronbach, Cronbach_st, SplitHalf), names_to = "Typ", values_to = "rel")

reliability_labels <- c(
  Cronbach = "Cronbach's \u03b1",
  Cronbach_st = "Cronbach's \u03b1 (std.)",
  SplitHalf = "Split-Half"
)

reltableplot <- ggplot(data = reltable_long, aes(x = Dimension, y = rel, colour = Typ)) +
  geom_point(size = 3) +
  theme_bw() +
  scale_y_continuous(breaks = seq(0.1, 1, 0.1), limits = c(0.1, 1)) +
  scale_colour_discrete(labels = reliability_labels) +
  labs(x = NULL, y = "Reliability Coefficient", colour = "Method") +
  ggtitle("Internal Consistency and Split-Half Reliability")

reltableplot %>% ggsave(
  filename = file.path(outputpath, "dimstatistics", "reliability.png"),
  width = 10, height = 5)

cat("Reliability plot saved.\n")
