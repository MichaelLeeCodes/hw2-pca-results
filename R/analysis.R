# Generates all plots used on the results website:
#  - <image>_grid.png    original + rank 1..10 approximations
#  - <image>_error.png   Frobenius error vs k, for all k
#  - <image>_eigvec.png  first eigenvector (u1)
#  - <image>_pcscore.png first PC score (z1)
# and a summary CSV of k, error(k), and cumulative variance explained.

source("R/compress_image.R")

plot_image_matrix <- function(mat, title, zlim) {
  image(
    t(mat)[, nrow(mat):1],
    col = gray.colors(256, start = 0, end = 1),
    axes = FALSE, main = title, zlim = zlim
  )
}

analyze_image <- function(name, csv_path, out_dir, k_grid = 10) {
  x <- as.matrix(read.csv(csv_path))
  n <- nrow(x); p <- ncol(x)
  max_k <- min(n, p)
  zlim <- range(x)

  ## eigendecomposition (reused across k)
  V <- t(x) %*% x
  eig <- eigen(V, symmetric = TRUE)
  U <- eig$vectors
  Z <- x %*% U
  eigenvalues <- pmax(eig$values, 0)
  total_var <- sum(eigenvalues)

  ## 1. original + first 10 approximations
  png(file.path(out_dir, paste0(name, "_grid.png")), width = 1650, height = 750, res = 150)
  par(mfrow = c(3, 4), mar = c(1, 1, 2, 1))
  plot_image_matrix(x, "Original", zlim)
  for (k in 1:k_grid) {
    Uk <- U[, 1:k, drop = FALSE]
    Zk <- Z[, 1:k, drop = FALSE]
    approx <- Zk %*% t(Uk)
    plot_image_matrix(approx, paste0("k = ", k), zlim)
  }
  dev.off()

  ## 2. error vs k, for ALL possible k
  errors <- numeric(max_k)
  for (k in 1:max_k) {
    # sum of eigenvalues after the k-th one = squared Frobenius error
    resid_var <- if (k < length(eigenvalues)) sum(eigenvalues[(k + 1):length(eigenvalues)]) else 0
    errors[k] <- sqrt(resid_var)
  }
  cum_var_explained <- 1 - (errors^2) / total_var

  png(file.path(out_dir, paste0(name, "_error.png")), width = 900, height = 600, res = 150)
  par(mar = c(4, 4, 2, 1))
  plot(1:max_k, errors, type = "b", pch = 16, cex = 0.6,
       xlab = "k (rank of approximation)", ylab = "Frobenius error",
       main = paste0("Approximation error vs k (", name, ")"))
  dev.off()

  ## 3. first eigenvector and first PC score
  png(file.path(out_dir, paste0(name, "_eigvec.png")), width = 900, height = 500, res = 150)
  par(mar = c(4, 4, 2, 1))
  plot(U[, 1], type = "l", xlab = "Column index", ylab = expression(u[1]),
       main = paste0("First eigenvector u1 (", name, ")"))
  dev.off()

  png(file.path(out_dir, paste0(name, "_pcscore.png")), width = 900, height = 500, res = 150)
  par(mar = c(4, 4, 2, 1))
  plot(Z[, 1], type = "l", xlab = "Row index", ylab = expression(z[1]),
       main = paste0("First PC score z1 (", name, ")"))
  dev.off()

  ## summary table
  summary_df <- data.frame(k = 1:max_k, error = errors, cum_var_explained = cum_var_explained)
  write.csv(summary_df, file.path(out_dir, paste0(name, "_summary.csv")), row.names = FALSE)

  k95 <- which(cum_var_explained >= 0.95)[1]
  k99 <- which(cum_var_explained >= 0.99)[1]
  cat(sprintf("%s: dim=%dx%d, max_k=%d, k for 95%% var=%d, k for 99%% var=%d\n",
              name, n, p, max_k, k95, k99))

  invisible(summary_df)
}

dir.create("site/images", showWarnings = FALSE, recursive = TRUE)

images <- list(
  image1 = "data/image1.csv",
  image2 = "data/image2.csv",
  image3 = "data/image3.csv",
  image4 = "data/image4.csv"
)

for (nm in names(images)) {
  analyze_image(nm, images[[nm]], "site/images")
}
