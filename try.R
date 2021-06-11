simulate_data <- function(n_patients = 500, n_visits = 4, n_arms = 2) {
  structure <- tibble(patient = as.character(seq_len(n_patients))) %>%
    mutate(arm = as.character(rep(seq_len(n_arms), each = n_patients / n_arms))) %>%
    mutate(covariate1 = rnorm(n()), covariate2 = rnorm(n())) %>%
    expand_grid(visit = as.character(seq_len(n_visits))) %>%
    mutate(group = paste0(arm, visit))
  x <- model.matrix(~ covariate1 + covariate2 + group, data = structure) %>%
    as.matrix()
  beta <- rnorm(ncol(x), 10)
  covariance <- NULL
  while (is.null(covariance) || max(abs(covariance)) > 100) {
    rho <- rlkjcorr(n = 1, K = n_visits, eta = 1)
    sigma <- rcauchy(n = n_visits, location = 0, scale = 1)
    covariance <- diag(sigma) %*% rho %*% diag(sigma)
  }
  data <- structure %>%
    mutate(x_beta = as.numeric(x %*% beta)) %>%
    group_by(patient) %>%
    mutate(response = MASS::mvrnorm(n = 1L, mu = x_beta, Sigma = covariance)) %>%
    ungroup() %>%
    select(response, arm, patient, visit, covariate1, covariate2, group)
  list(
    data = data,
    y = data$response,
    x = x,
    n_arms = n_arms,
    n_beta = length(beta),
    n_observations = n_patients * n_visits,
    n_patients = n_patients,
    n_visits = n_visits,
    s_beta = 10,
    s_sigma = 5,
    .join_data = list(
      beta = beta,
      sigma = sigma,
      rho = rho
    )
  )
}

library(cmdstanr)
library(tidyverse)
library(trialr)
data <- simulate_data()
data$.join_data <- NULL
model <- cmdstan_model("model.stan")
fit <- model$sample(data = data, init = 1)
out <- fit$summary()
max(out$rhat, na.rm = TRUE)
out$variable
