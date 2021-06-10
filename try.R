simulate_data <- function(n_subjects = 500, n_visits = 4, n_arms = 2) {
  structure <- tibble(subject = as.character(seq_len(n_subjects))) %>%
    mutate(arm = as.character(rep(seq_len(n_arms), each = n_subjects / n_arms))) %>%
    mutate(covariate1 = rnorm(n()), covariate2 = rnorm(n())) %>%
    expand_grid(visit = as.character(seq_len(n_visits))) %>%
    mutate(group = paste0(arm, visit))
  x <- model.matrix(~ 0 + covariate1 + covariate2 + group, data = structure) %>%
    as.matrix()
  beta <- rnorm(ncol(x), 10)
  sigma <- NULL
  while (is.null(sigma) || max(abs(sigma)) > 100) {
    sigma <- rInvWishart(1, df = n_visits, Sigma = diag(n_visits))[, , 1, drop = TRUE]
  }
  data <- structure %>%
    mutate(x_beta = as.numeric(x %*% beta)) %>%
    group_by(subject) %>%
    mutate(response = MASS::mvrnorm(n = 1L, mu = x_beta, Sigma = sigma)) %>%
    ungroup() %>%
    select(response, arm, subject, visit, covariate1, covariate2, group)
  list(
    data = data,
    y = data$response,
    x = x,
    beta = beta,
    sigma = sigma,
    n_arms = n_arms,
    n_beta = length(beta),
    n_observations = n_subjects * n_visits,
    n_subjects = n_subjects,
    n_visits = n_visits,
    prior_sigma = diag(n_visits)
  )
}

library(cmdstanr)
library(tidyverse)
library(CholWishart)
data <- simulate_data()
model <- cmdstan_model("model.stan")
fit <- model$sample(
  data = data,
  init = 1
)
