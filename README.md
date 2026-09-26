# Homework 2 — PCA for Image Compression

Static results website: https://MichaelLeeCodes.github.io/hw2-pca-results/

## Contents

- `R/compress_image.R` :the rank-k PCA image compression function.
- `R/analysis.R` :script that runs the function on all four images and generates every plot used on the website.
- `data/` :the four input images provided for the assignment, as CSV matrices.
- `index.html`, `styles.css`, `images/` — the static website (published via GitHub Pages).
- `shiny_app/` — the interactive Shiny app (upload an image, pick k, compare original vs. compressed), deployed at
  https://michaelleecodes.shinyapps.io/pca-image-compressor/. The app mockup/design writeup is at
  https://michaelleecodes.github.io/hw2-app-mockup/.

## Regenerating the plots

```r
source("R/analysis.R")
```

This reads each CSV in `data/`, computes the rank 1–10 approximations, the full error-vs-k curve, and the
first eigenvector/PC score, and writes the resulting PNGs into `images/`.
