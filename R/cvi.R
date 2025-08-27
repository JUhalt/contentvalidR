#' Content Validity Index (CVI): I-CVI, S-CVI/Ave, and modified kappa
#'
#' @description
#' Expects a binary matrix: rows = judges, cols = items (1 = relevant, 0 = not).
#' I-CVI = proportion of judges rating an item as relevant.
#' Modified kappa uses chance agreement \eqn{P_c} from a binomial model with \eqn{p = 0.5}:
#' \deqn{P_c = \sum_{i=A}^{N} \binom{N}{i} 0.5^{N},}
#' where \eqn{A} is the number of 1s for the item.
#'   k* = (I-CVI - Pc) / (1 - Pc), with k* set to NA when Pc == 1.
#'
#' @param binary matrix/data.frame (judges x items) of 0/1.
#'
#' @returns list with:
#'   - item_level: data.frame (item, A, N, I_CVI, Pc, kappa_mod)
#'   - scale_level: data.frame (S_CVI_Ave)
#'
#' @examples
#' M <- matrix(sample(0:1, 6*8, replace=TRUE, prob=c(.3,.7)), nrow=6)
#' cvi(M)
#' @export
cvi <- function(binary) {
  X <- as.matrix(binary)
  if (!all(X %in% c(0,1))) stop("binary must contain only 0/1 values")
  N <- nrow(X)
  A <- colSums(X)
  I_CVI <- A / N
  # chance agreement tail probability at p=0.5
  Pc <- vapply(A, function(a) sum(dbinom(a:N, size = N, prob = 0.5)), numeric(1))
  kappa_mod <- (I_CVI - Pc) / (1 - Pc)
  kappa_mod[Pc >= 1] <- NA_real_
  item_level <- data.frame(
    item = colnames(X) %||% paste0("Item", seq_len(ncol(X))),
    A = A, N = N, I_CVI = I_CVI, Pc = Pc, kappa_mod = kappa_mod,
    row.names = NULL
  )
  scale_level <- data.frame(S_CVI_Ave = mean(I_CVI), row.names = NULL)
  list(item_level = item_level, scale_level = scale_level)
}
