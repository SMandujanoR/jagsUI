context("Test model fit with autojags()")

set_up_input <- function(){
  data(longley)
  jags_data <<- list(gnp=longley$GNP, employed=longley$Employed, 
             n=length(longley$Employed))
  model_file <<- tempfile()
  writeLines("
  model{
  #Likelihood
  for (i in 1:n){ 
  employed[i] ~ dnorm(mu[i], tau)     
  mu[i] <- alpha + beta*gnp[i]
  }
  #Priors
  alpha ~ dnorm(0, 0.00001)
  beta ~ dnorm(0, 0.00001)
  sigma ~ dunif(0,1000)
  tau <- pow(sigma,-2)
  }", con=model_file)
  params <<- c('alpha','beta','sigma','mu')
  n_chains <<- 3; n_iter <<- 10; n_warmup <<- 20; n_adapt <<- 100
}

test_that("autojags() returns correct output structure",{

  skip_on_cran()
  set_up_input()
 
  set.seed(123)
  out <- autojags(jags_data, NULL, params, model_file, n_chains, n_adapt,
              n_iter, n_warmup, n.thin=1,quiet=T)
  
  expect_true(is.list(out))
  expect_true(inherits(out, "jagsUI"))
  expect_equal(names(out), c("sims.list","mean","sd","q2.5","q25","q50",
                             "q75","q97.5","Rhat","n.eff","overlap0","f",
                             "pD","DIC","summary","samples","model",
                             "parameters", "modfile","mcmc.info","run.info"))
  expect_equal(as.character(unlist(sapply(out, function(x) class(x)[1]))),
               c(rep("list",12),rep("numeric",2),"matrix","mcmc.list",
                 "jags",rep("character",2),"list","list"))
  expect_equal(length(out$sims.list), 5)
  expect_equal(names(out$sims.list),c(params,'deviance'))
  actual_iter <- out$mcmc.info$n.iter
  expect_equal(length(out$sims.list$alpha), n_iter*n_chains)
  expect_equal(dim(out$sims.list$mu), c(n_iter*n_chains, 16))
  expect_equal(length(out$mean$mu), 16)
  expect_equal(length(out$mean),5)
  expect_equal(dim(out$summary), c(20,11))
  expect_equal(out$mcmc.info$n.draws, 30)
  expect_equal(out$mcmc.info$n.burnin, 440)
  expect_equal(out$mcmc.info$n.iter, 450)
})

test_that("autojags() summary values are correct",{

  skip_on_cran()
  set_up_input()
  
  set.seed(123)
  out <- autojags(jags_data, NULL, params, model_file, n_chains, n_adapt,
              n_iter, n_warmup, n.thin=1,quiet=T)

  match_out <- readRDS('autojags_out1.Rds')
  expect_equal(out$summary, match_out, tol=1e-3)

  #Check that setting seed works
  set.seed(123)
  out2 <- autojags(jags_data, NULL, params, model_file, n_chains, n_adapt,
              n_iter, n_warmup, n.thin=1,quiet=T)
  expect_equal(out$summary, out2$summary)

  #Check that output is not fixed
  out3 <- autojags(jags_data, NULL, params, model_file, n_chains, n_adapt,
              n_iter, n_warmup, n.thin=1,quiet=T)
  expect_true(any(out$summary!=out3$summary))

})

test_that("autojags() in parallel produces identical results", {

  skip_on_cran()
  #skip_on_travis()
  set_up_input()
  n_cores <- max(2, min(parallel::detectCores()-1, n_chains))
  
  set.seed(789)
  out_ref <- autojags(jags_data, NULL, params, model_file, n_chains, n_adapt,
              n_iter, n_warmup, n.thin=1,quiet=T, parallel=FALSE)

  set.seed(789)
  out <- autojags(jags_data, NULL, params, model_file, n_chains, n_adapt,
              n_iter, n_warmup, n.thin=1,quiet=T, 
              parallel=TRUE, n.cores=n_cores)

  expect_equal(out$summary, out_ref$summary)

})

test_that("autojags() running loudly gives identical results", {

  skip_on_cran()
  set_up_input()
  n_cores <- max(2, min(parallel::detectCores()-1, n_chains))

  set.seed(123)
  printed <- capture_output(
    out <- autojags(jags_data, NULL, params, model_file, n_chains, n_adapt,
    n_iter, n_warmup, n.thin=1,quiet=F))

  match_out <- readRDS('autojags_out1.Rds')
  expect_equal(out$summary, match_out, tol=1e-3)

  set.seed(123)
  printed <- capture_output(
    out <- autojags(jags_data, NULL, params, model_file, n_chains, n_adapt,
    n_iter, n_warmup, n.thin=1,parallel=T,quiet=F))

  expect_equal(out$summary, match_out, tol=1e-3)

})

test_that("Saving all iterations in autojags works", {

  skip_on_cran()
  set_up_input()
 
  set.seed(123)
  out <- autojags(jags_data, NULL, params, model_file, n_chains, n_adapt,
              n_iter, n_warmup, save.all.iter=T, n.thin=1,quiet=T)
  expect_equal(nrow(out$samples[[1]]), 20)
  expect_equal(out$mcmc.info$n.draws, 60)
  expect_equal(out$mcmc.info$n.burnin, 20)
  expect_equal(out$mcmc.info$n.iter, 40)
})

test_that("autojags respects max iterations", {

  skip_on_cran()
  set_up_input()
 
  set.seed(123)
  printed <- capture_output(
    out <- autojags(jags_data, NULL, params, model_file, n_chains, n_adapt,
              n_iter, n_warmup, n.thin=1, max.iter=150, quiet=F))
  expect_equal(out$mcmc.info$n.burnin,140)
  expect_equal(out$mcmc.info$n.iter,150)
})
