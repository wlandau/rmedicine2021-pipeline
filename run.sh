#!/bin/bash
rm -rf .RData logs
module load R
nohup Rscript -e 'renv::restore(); rmarkdown::render("report.Rmd")' &
rm -f .RData
