# R Seminar: Big Five Personality Test - Item Analysis

Workshop materials for an introductory R seminar aimed at psychology students and researchers. The seminar covers data handling, descriptive statistics, item analysis, visualization, factor analysis, and reliability analysis using the [IPIP Big Five Factor Markers](https://openpsychometrics.org/tests/IPIP-BFFM/) dataset.

## Data

This project uses the [Big Five Personality Test](https://www.kaggle.com/datasets/tunguz/big-five-personality-test) dataset from Kaggle (~1M responses to the 50-item IPIP Big Five questionnaire).

## Setup

1. **Install R** (>= 4.0) from [r-project.org](https://www.r-project.org/)
2. **Download the data** from [Kaggle](https://www.kaggle.com/datasets/tunguz/big-five-personality-test) and place `data-final.csv` into the `src_data/` folder
3. **Install packages** by running `setup.R`:
   ```r
   source("setup.R")
   ```

Alternatively, download the data via the Kaggle CLI:
```bash
kaggle datasets download -d tunguz/big-five-personality-test -p src_data/ --unzip
```

## Scripts

The scripts are meant to be run in order. Each script sources its dependencies automatically.

| Script | Topic | Content |
|--------|-------|---------|
| `0.intro.R` | Quick Start | Load data, basic file I/O |
| `1.files.R` | File Handling | Read/write CSV, Excel (.xlsx), SPSS (.sav) |
| `2.datascience.R` | Data Wrangling | tidyr, dplyr, item recoding, descriptive statistics, item-total correlations |
| `3.ggplot.R` | Visualization | Histograms, correlation heatmaps, item difficulty-discrimination plots |
| `4.psych.R` | Psychometrics | Factor analysis, parallel analysis, reliability (Cronbach's alpha, split-half) |
| `5.anova.R` | Group Comparisons | *(planned)* |

## Big Five Dimensions

| Code | Dimension | Items |
|------|-----------|-------|
| EXT | Extraversion | EXT1-EXT10 |
| EST | Emotional Stability | EST1-EST10 |
| AGR | Agreeableness | AGR1-AGR10 |
| CSN | Conscientiousness | CSN1-CSN10 |
| OPN | Openness | OPN1-OPN10 |

Negatively keyed items are recoded in `2.datascience.R`.

## Required R Packages

openxlsx, haven, tidyr, dplyr, moments, ggplot2, Hmisc, scales, ggrepel, psych, nFactors

## License

The IPIP items are in the public domain ([ipip.ori.org](https://ipip.ori.org/)). The Kaggle dataset was collected by [Open Psychometrics](https://openpsychometrics.org/).
