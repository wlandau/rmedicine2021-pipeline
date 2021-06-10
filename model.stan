data {
  int<lower=0> n_arms; // number of clinical trial study arms, e.g. treatment groups
  int<lower=0> n_beta; // number of model coefficients beta
  int<lower=0> n_observations; // number of observed data points (n_subjects * n_visits)
  int<lower=0> n_subjects; // number of patients/subjects in the clinical trial
  int<lower=0> n_visits; // number of scheduled site visits / repeated measures per subject
  real y[n_observations]; // observed clinical endpoint
  matrix[n_observations, n_beta] x; // model matrix
  matrix[n_visits, n_visits] prior_sigma; // inverse Wishart scale matrix prior
}
parameters {
  vector[n_beta] beta; // vector of model coefficients
  // block-diagonal residual covariance for correlated visits within each subject:
  matrix[n_visits, n_visits] sigma;
}
model {
  int index_subject;
  int index_min;
  int index_max;
  vector[n_observations] mu = x * beta; // mean response
  real y_subject[n_subjects];
  real mu_subject[n_subjects];
  for (subject in 1:n_subjects) {
    index_max = subject * n_visits;
    index_min = index_max - n_visits + 1;
    index_subject = 1;
    for (index in index_min:index_max) {
      y_subject[index_subject] = y[index];
      mu_subject[index_subject] = mu[index];
      index_subject += 1;
    }
    y_subject ~ normal(mu_subject, 1);
  }
  y ~ normal(x * beta, 1);
  beta ~ normal(0, 1);
  sigma ~ inv_wishart(n_visits, prior_sigma);
}
