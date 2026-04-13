### Setup script: install required packages and download data
### Run this once before running the seminar scripts

cat("=== R Seminar Setup ===\n\n")

### 1. Install required packages
required_packages <- c(
  "openxlsx",   # Excel read/write
  "haven",      # SPSS read/write
  "tidyr",      # data reshaping
  "dplyr",      # data manipulation
  "tibble",     # modern data frames
  "moments",    # skewness, kurtosis
  "ggplot2",    # plotting
  "Hmisc",      # correlation matrices
  "scales",     # axis formatting
  "ggrepel",    # non-overlapping labels
  "psych",      # factor analysis, reliability
  "nFactors",   # parallel analysis
  "qgraph"      # network visualization
)

cat("Checking and installing required packages...\n")
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat(paste0("  Installing ", pkg, "...\n"))
    install.packages(pkg, repos = "https://cloud.r-project.org")
  } else {
    cat(paste0("  ", pkg, " already installed.\n"))
  }
}

### 2. Check for data file
srcpath <- file.path(getwd(), "src_data")
datafile <- file.path(srcpath, "data-final.csv")

if (!dir.exists(srcpath)) {
  dir.create(srcpath)
}

if (!file.exists(datafile)) {
  cat("\n")
  cat("=== DATA DOWNLOAD REQUIRED ===\n")
  cat("The dataset 'data-final.csv' was not found in src_data/.\n\n")
  cat("Please download it from Kaggle:\n")
  cat("  https://www.kaggle.com/datasets/tunguz/big-five-personality-test\n\n")
  cat("Option 1 - Manual download:\n")
  cat("  1. Download the dataset from the Kaggle link above\n")
  cat("  2. Unzip and place 'data-final.csv' into the src_data/ folder\n\n")
  cat("Option 2 - Kaggle CLI (requires kaggle package: pip install kaggle):\n")
  cat("  Run in terminal:\n")
  cat("    kaggle datasets download -d tunguz/big-five-personality-test -p src_data/ --unzip\n\n")
} else {
  cat(paste0("\nData file found: ", datafile, "\n"))
  cat(paste0("  Size: ", round(file.size(datafile) / 1024 / 1024, 1), " MB\n"))
}

cat("\nSetup complete!\n")
