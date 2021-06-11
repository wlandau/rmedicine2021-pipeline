#!/bin/bash
rm -rf .RData logs
module load R
nohup Rscript -e 'rmarkdown::render("report.Rmd")' &
rm -f .RData
