data {
  int<lower=0> n_arms; // number of clinical trial study arms, e.g. treatment groups
  int<lower=0> n_beta; // number of model coefficients beta
  int<lower=0> n_observations; // number of observed data points (n_subjects * n_visits)
  int<lower=0> n_subjects; // number of patients/subjects in the clinical trial
  int<lower=0> n_visits; // number of scheduled site visits / repeated measures per subject
  vector[n_observations] y; // observed clinical endpoint
  matrix[n_observations, n_beta] x; // model matrix
  matrix[n_visits, n_visits] prior_sigma; // inverse Wishart scale matrix prior
}
parameters {
  vector[n_beta] beta; // vector of model coefficients
  vector[n_visits] sigma; // standard deviations of the response at each visit
  cholesky_factor_corr[n_visits] rho; // Cholesky factor of the correlation matrix among visits within subjects
}
model {
  int index_min;
  int index_max;
  vector[n_observations] mu = x * beta; // mean response
  for (subject in 1:n_subjects) {
    index_max = subject * n_visits;
    index_min = index_max - n_visits + 1;
    y[index_min:index_max] ~ multi_normal_cholesky(mu[index_min:index_max], diag_pre_multiply(sigma, rho));
  }
  beta ~ normal(0, 10);
  rho ~ lkj_corr_cholesky(1);
}
