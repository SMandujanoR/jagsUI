\name{autojags}
\alias{autojags}


\title{Automatically run jagsUI analyses to convergence}
\description{
  The \code{autojags} function runs repeated updates of \code{jagsUI} models, 
  until a specified convergence level (based on the statistic Rhat) or a 
  maximum number of iterations is reached.
}

\usage{
autojags(data, inits, parameters.to.save, model.file,
  n.chains, n.adapt=1000, iter.increment=1000, n.burnin=0, n.thin=1,
  save.all.iter=FALSE, modules=c('glm'), factories=NULL, 
  parallel=FALSE, n.cores=NULL, DIC=TRUE, no.stats=NULL, 
  Rhat.limit=1.1, max.iter=100000, quiet=FALSE)}

\arguments{
  \item{data}{A named list of the data objects required by the model, or a 
    character vector containing the names of the data objects required by the 
    model.}
  \item{inits}{A list with \code{n.chains} elements; each element of the
    list is itself a list of starting values for the \code{BUGS} model,
    \emph{or} a function creating (possibly random) initial values. If inits is 
    \code{NULL}, \code{JAGS} will generate initial values for parameters.}
  \item{parameters.to.save}{Character vector of the names of the
    parameters in the model which should be monitored.}
  \item{model.file}{Path to file containing the model written in \code{BUGS} code}
  \item{n.chains}{Number of Markov chains to run.}
  \item{n.adapt}{Number of iterations to run in the \code{JAGS} adaptive phase.}
  \item{iter.increment}{Number of iterations per model auto-update. Set to 
    larger values when you suspect the model will take a long time to converge.}
  \item{n.burnin}{Number of iterations at the beginning of the chain to discard 
    (i.e., the burn-in). Does not include the adaptive phase iterations.}
  \item{n.thin}{Thinning rate. Must be a positive integer.}
  \item{save.all.iter}{Option to combine MCMC samples from all iterative updates 
    into final posterior (by default only the final iteration is included in 
    the posterior).}
  \item{modules}{List of JAGS modules to load before analysis. By default only 
    module 'glm' is loaded (in addition to 'basemod' and 'bugs').}
  \item{factories}{Optional character vector of factories to enable or disable, 
    in the format <factory> <type> <setting>. For example, to turn 
    \code{TemperedMix} on you would provide \code{'mix::TemperedMix sampler TRUE'} 
    (note spaces between parts). Make sure you have the corresponding modules 
    loaded as well.}
  \item{parallel}{If TRUE, run MCMC chains in parallel on multiple CPU cores}
  \item{n.cores}{If parallel=TRUE, specify the number of CPU cores used. 
    Defaults to total available cores or the number of chains, whichever is smaller.}
  \item{DIC}{If TRUE, report DIC and the estimated number of parameters (pD).}
  \item{no.stats}{Optional character vector of parameters that will be saved 
    only in $samples and not otherwise processed by jagsUI.}
  \item{Rhat.limit}{Set the desired cutoff point for convergence; when all Rhat 
    values are less than this value the model assumes convergence has been 
    reached and will stop auto-updating.}
  \item{max.iter}{Maximum number of total iterations allowed via auto-update 
    (including burn-in).}
  \item{quiet}{If TRUE, all text output in the console will be suppressed as 
    the function runs.}
}

\details{
Usage and output is otherwise identical to the \code{jags} function.
}

\author{ 
  Ken Kellner \email{contact@kenkellner.com}.
}
