context("Test mcmc.list tools")

test_that('get_inds extracts indices',{
  params_raw <- c('beta[1]','beta[2]')  
  expect_equal(get_inds('beta',params_raw),matrix(c(1,2)))
  params_raw <- c('gamma[1,1]','gamma[2,1]','gamma[1,3]')
  expect_equal(get_inds('gamma',params_raw),
               matrix(c(1,1,2,1,1,3),ncol=2,byrow=T))
  params_raw <- c('kappa[1,1,1]','kappa[2,1,1]','kappa[1,3,1]')
  expect_equal(get_inds('kappa',params_raw),
               matrix(c(1,1,1,2,1,1,1,3,1),ncol=3,byrow=T))
  params_raw <- 'alpha'
  inds <- expect_warning(get_inds('alpha',params_raw)[1,1])
  expect_true(is.na(inds))
})

test_that('strip_params removes brackets and indices',{
  params_raw <- c('alpha','beta[1]','beta[2]','gamma[1,2]','kappa[1,2,3]')
  expect_equal(strip_params(params_raw),
               c('alpha','beta','beta','gamma','kappa'))
  expect_equal(strip_params(params_raw,unique=T),
               c('alpha','beta','gamma','kappa'))
})

test_that('which_params gets param col indices',{
  params_raw <- c('alpha','beta[1]','beta[2]','gamma[1,1]','gamma[3,1]')
  expect_equal(which_params('alpha',params_raw),1)
  expect_equal(which_params('beta',params_raw),c(2,3))
  expect_equal(which_params('gamma',params_raw),c(4,5))
  expect_null(which_params('kappa',params_raw))
})

test_that('param_names returns correct names',{
  samples <- readRDS('coda_samples.Rds')
  expect_equal(param_names(samples),
    c("alpha", "beta", "sigma", "mu[1]", "mu[2]", "mu[3]", "mu[4]",
    "mu[5]", "mu[6]", "mu[7]", "mu[8]", "mu[9]", "mu[10]", "mu[11]",
    "mu[12]", "mu[13]", "mu[14]", "mu[15]", "mu[16]", "kappa[1,1,1]",
    "kappa[2,1,1]", "kappa[1,2,1]", "kappa[2,2,1]", "kappa[1,1,2]",
    "kappa[2,1,2]", "kappa[1,2,2]", "kappa[2,2,2]", "deviance"))
  expect_equal(param_names(samples,simplify=T),
               c('alpha','beta','sigma','mu','kappa','deviance'))
})

test_that('match_param identifies correct set of params', {
  params_raw <- c('alpha','beta[1]','beta[2]','gamma[1,1]','gamma[3,1]')
  expect_equal(match_params('alpha', params_raw),'alpha')
  expect_equal(match_params('beta', params_raw), c('beta[1]','beta[2]'))
  expect_equal(match_params('gamma[1,1]', params_raw), 'gamma[1,1]')
  expect_true(is.null(match_params('fake',params_raw)))
  expect_equal(match_params(c('alpha','beta'),params_raw),
               c('alpha','beta[1]','beta[2]'))
  expect_equal(match_params(c('alpha','fake','beta'),params_raw),
               c('alpha','beta[1]','beta[2]'))
})

test_that('select_cols works correctly',{
  samples <- readRDS('coda_samples.Rds')
  expect_equal(dim(samples[[1]]),c(30,28))
  out <- select_cols(samples,1:3)
  expect_equal(class(out),'mcmc.list')
  expect_equal(length(out),length(samples))
  expect_equal(unlist(lapply(out,nrow)),unlist(lapply(samples,nrow)))
  expect_equal(colnames(out[[1]]),c('alpha','beta','sigma'))
  expect_equal(lapply(out,dim),list(c(30,3),c(30,3),c(30,3)))
  expect_equal(unlist(lapply(out,class)),rep('mcmc',3))
  expect_equal(attr(out[[1]],'mcpar'),c(1042,1100,2))
  out <- select_cols(samples,-c(1:3))
  expect_equal(dim(out[[1]]),c(30,25))
  expect_equal(colnames(out[[1]])[1],'mu[1]')
  out <- select_cols(samples,1)
  expect_equal(colnames(out[[1]]),'alpha')
  expect_equal(dim(out[[1]]),c(30,1))
})

test_that('remove_params drops correct params from list',{
  samples <- readRDS('coda_samples.Rds')
  expect_equal(remove_params(samples), param_names(samples))
  expect_equal(remove_params(samples, 'beta'), param_names(samples)[-2])
  expect_equal(remove_params(samples, c('mu','kappa')),
               c('alpha','beta','sigma','deviance'))
  expect_equal(remove_params(samples, param_names(samples, simplify=TRUE)),
               character(0))               
})

test_that('mcmc_to_mat converts properly',{
  samples <- readRDS('coda_samples.Rds')
  mat <- mcmc_to_mat(samples, 'alpha')
  expect_true(inherits(mat, 'matrix'))
  expect_equal(dim(mat),c(nrow(samples[[1]]),length(samples)))
  expect_equal(mat[,1],as.numeric(samples[[1]][,'alpha'])) 
  one_sample <- readRDS('one_sample.Rds')
  mat <- mcmc_to_mat(one_sample, 'alpha')
  expect_equal(dim(mat), c(1,3))
  only_alpha <- select_cols(one_sample, 'alpha')
  mat <- mcmc_to_mat(only_alpha, 'alpha')
  expect_equal(mat, matrix(c(52.03132,52.67406,51.04401),ncol=3), tol=1e-4)
})

test_that('comb_mcmc_list combines correctly',{
  comb_samples1 <- readRDS('comb_samples1.Rds')
  comb_samples2 <- readRDS('comb_samples2.Rds')
  comb_object <- comb_mcmc_list(comb_samples1,comb_samples2)
  expect_equal(nrow(comb_object[[1]]),20)
  expect_equal(length(comb_object),3)
  expect_equal(attr(comb_object[[1]],'mcpar'),c(1101,1120,1))
})

test_that('order_samples works correctly', {
  samples <- readRDS('coda_samples.Rds')
  new_order <- c('beta','mu','alpha')
  out <- order_samples(samples, new_order)
  expect_equal(class(out), 'mcmc.list')
  expect_equal(length(out),length(samples))
  expect_equal(lapply(out,class),lapply(samples,class))
  expect_equal(param_names(out),c('beta',paste0('mu[',1:16,']'),'alpha'))
  expect_equal(dim(out[[1]]), c(30,18))
  expect_equal(as.numeric(out[[1]][1,1:2]), 
               c(0.03690717, 59.78175), tol=1e-4)
  expect_equal(order_samples(samples, 'beta'),
               order_samples(samples, c('beta','fake')))
  result <- expect_message(order_samples('fake','beta'))
  expect_equal(result, 'fake')
  one_param <- select_cols(samples, 'alpha')
  expect_equal(order_samples(one_param,'alpha'),one_param)
  expect_equal(dim(order_samples(one_param, 'beta')[[1]]),c(30,0))
})

test_that('check_parameter works correctly',{
  samples <- readRDS('coda_samples.Rds')
  expect_error(check_parameter('alpha',samples),NA)
  expect_error(check_parameter('fake',samples))
})
