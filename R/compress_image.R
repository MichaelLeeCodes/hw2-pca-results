# PCA-based image compression
#
# compress_image(x, k) computes the rank-k PCA approximation of a matrix x
# following the identity X = Z U' where U holds the eigenvectors of X'X
# and Z = X U holds the PC scores.

compress_image <- function(x, k) {
  x <- as.matrix(x)
  p <- ncol(x)

  if (k < 1 || k > p) {
    stop("k must be between 1 and ncol(x)")
  }

  V <- t(x) %*% x            # p x p cross product
  eig <- eigen(V, symmetric = TRUE)
  U <- eig$vectors           # p x p eigenvectors
  Z <- x %*% U                # n x p PC scores

  Uk <- U[, 1:k, drop = FALSE]
  Zk <- Z[, 1:k, drop = FALSE]

  approx <- Zk %*% t(Uk)     # rank-k approximation of x
  error <- norm(x - approx, type = "F")  # Frobenius norm of the residual

  list(approx = approx, error = error, U = U, Z = Z)
}
