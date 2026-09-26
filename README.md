# Homework 2 — PCA for Image Compression

Static results website: https://MichaelLeeCodes.github.io/hw2-pca-results/

## Contents

- `R/compress_image.R` :the rank-k PCA image compression function.
- `R/analysis.R` :script that runs the function on all four images and generates every plot used on the website.
- `data/` :the input images as CSV matrices: `image1.csv`, `image2.csv`, `image4.csv` are the originals
  provided for the assignment. `image3.csv` (the original rabbit photo) is kept as provided but is no longer
  what's shown on the site — the "Image 3" section on the website was swapped to `image3_photo.csv`, a
  personal photo (grayscale, downsized to 400x300), just to see how the method handles a different kind of
  image.
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
