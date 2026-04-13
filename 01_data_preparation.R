### Data Preparation
### Load Big Five data, define item metadata, recode negatively keyed items

library(tidyr)
library(dplyr)

### load raw data
srcpath <- file.path(getwd(), "src_data")
alldata <- read.table(file.path(srcpath, "data-final.csv"),
                      stringsAsFactors = FALSE, sep = "\t", header = TRUE)

### use first 15000 cases for faster computation
currentdata <- head(alldata, 15000)

### item metadata
items <- read.table(file.path(srcpath, "items.txt"),
                    sep = "\t", quote = "", stringsAsFactors = FALSE)

iteminfo <- (items
  %>% rename(itemid = "V1", text = "V2")
  %>% mutate(itemidcopy = itemid)
  %>% separate(itemidcopy, into = c("dimid", "index"),
               sep = "(?<=[a-zA-Z])\\s*(?=[0-9])")
  %>% mutate(dimname = case_when(
    dimid == "EXT" ~ "Extraversion",
    dimid == "OPN" ~ "Openness",
    dimid == "EST" ~ "Emotional Stability",
    dimid == "AGR" ~ "Agreeableness",
    dimid == "CSN" ~ "Conscientiousness"
  ))
)

### reshape to long format (one row per person x item)
itemdata <- (currentdata
  %>% dplyr::select(1:50)
  %>% tibble::rowid_to_column("userID")
  %>% mutate(userID = paste0("user_", userID))
  %>% pivot_longer(cols = -userID, names_to = "itemid", values_to = "value")
  %>% mutate(value = as.numeric(value))
)

### recode negatively keyed items (5 - value)
itemdata <- (itemdata
  %>% mutate(value = ifelse(itemid %in% c("EXT2", "EXT4", "EXT6", "EXT8", "EXT10"), 5 - value, value))
  %>% mutate(value = ifelse(itemid %in% c("EST2", "EST4"), 5 - value, value))
  %>% mutate(value = ifelse(itemid %in% c("AGR1", "AGR3", "AGR5", "AGR7"), 5 - value, value))
  %>% mutate(value = ifelse(itemid %in% c("CSN2", "CSN4", "CSN6", "CSN8"), 5 - value, value))
  %>% mutate(value = ifelse(itemid %in% c("OPN2", "OPN4", "OPN6"), 5 - value, value))
)

### compute scale scores per person and dimension
dimensiondata <- (itemdata
  %>% left_join(iteminfo, by = "itemid")
  %>% group_by(userID, dimid)
  %>% summarise(score = sum(value), .groups = "drop")
)

### list of dimensions (used in later scripts)
dimensions <- sort(unique(dimensiondata$dimid))

### output directory
outputpath <- file.path(getwd(), "output_data")
dir.create(outputpath, showWarnings = FALSE)
dir.create(file.path(outputpath, "itemstatistics"), showWarnings = FALSE)
dir.create(file.path(outputpath, "dimstatistics"), showWarnings = FALSE)

cat("Data preparation complete.\n")
cat(paste0("  N = ", length(unique(itemdata$userID)), " participants\n"))
cat(paste0("  ", length(unique(itemdata$itemid)), " items across ",
           length(dimensions), " dimensions\n"))
