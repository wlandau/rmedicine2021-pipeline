data {
  int<lower=0> n_arms; // number of clinical trial study arms, e.g. treatment groups
  int<lower=0> n_beta; // number of model coefficients beta
  int<lower=0> n_observations; // number of observed data points (n_patients * n_visits)
  int<lower=0> n_patients; // number of patients/patients in the clinical trial
  int<lower=0> n_visits; // number of scheduled site visits / repeated measures per patient
  vector[n_observations] y; // observed clinical endpoint
  matrix[n_observations, n_beta] x; // model matrix
}
parameters {
  vector[n_beta] beta; // vector of model coefficients
  vector[n_visits] sigma; // standard deviations of the response at each visit
  cholesky_factor_corr[n_visits] rho; // Cholesky factor of the correlation matrix among visits within patients
}
model {
  int first_visit; // first visit/observation of the current patient
  int last_visit; // last visit/observation of the current patient
  vector[n_observations] mu = x * beta; // mean response
  for (patient in 1:n_patients) { // model each patient separately
    last_visit = patient * n_visits; // Find the last visit of the current patient.
    first_visit = last_visit - n_visits + 1; // Find the first visit of the current patient.
    // Each patient is multivariate normal with the same unstructured covariance:
    y[first_visit:last_visit] ~ multi_normal_cholesky(mu[first_visit:last_visit], diag_pre_multiply(sigma, rho));
  }
  beta ~ normal(0, 10); // independent fixed effects
  sigma ~ cauchy(0, 5); // diffuse prior on the visit-specific standard deviations
  rho ~ lkj_corr_cholesky(1); // LKJ prior on the correlations among visits
}
