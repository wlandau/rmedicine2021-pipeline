data {
  int<lower=0> n_arms; // number of clinical trial study arms, e.g. treatment groups
  int<lower=0> n_beta; // number of model coefficients beta
  int<lower=0> n_observations; // number of data points (n_patients * n_visits) including missing values
  int<lower=0> n_missing; // number of missing data points
  int<lower=0> n_patients; // number of patients/patients in the clinical trial
  int<lower=0> n_visits; // number of scheduled site visits / repeated measures per patient
  int<lower=0> s_beta; // prior standard deviation of the model coefficients.
  int<lower=0> s_sigma; // prior half-Cauchy scale for the visit-specific variances of the response
  int<lower=0> missing[n_observations]; // 0-1 vector to indicate which elements of y are missing values
  int<lower=0> count_missing[n_observations]; // index vector to map missing to an index in y_missing
  vector[n_observations] y; // clinical endpoint, including missing data points
  matrix[n_observations, n_beta] x; // model matrix
}
parameters {
  vector[n_beta] beta; // vector of model coefficients
  vector<lower=0>[n_visits] sigma; // standard deviations of the response at each visit
  cholesky_factor_corr[n_visits] lambda; // Cholesky factor of the correlation matrix among visits within patients
  vector[n_missing] y_missing; // missing values to impute
}
model {
  int first_visit; // first visit/observation of the current patient
  int last_visit; // last visit/observation of the current patient
  vector[n_observations] mu = x * beta; // mean response
  vector[n_observations] y_imputed; // data vector with imputed missing values
  matrix[n_visits, n_visits] sigma_lambda = diag_pre_multiply(sigma, lambda);
  for (observation in 1:n_observations){
    // Impute the missing data:
    y_imputed[observation] = missing[observation] == 1 ? y_missing[count_missing[observation]] : y[observation];
  }
  for (patient in 1:n_patients) { // model each patient separately
    last_visit = patient * n_visits; // Find the last visit of the current patient.
    first_visit = last_visit - n_visits + 1; // Find the first visit of the current patient.
    // Each patient is multivariate normal with the same unstructured covariance:
    y_imputed[first_visit:last_visit] ~ multi_normal_cholesky(mu[first_visit:last_visit], sigma_lambda);
  }
  beta ~ normal(0, s_beta); // independent fixed effects
  sigma ~ cauchy(0, s_sigma); // diffuse prior on the visit-specific standard deviations
  lambda ~ lkj_corr_cholesky(1); // LKJ prior on the correlations among visits
}
