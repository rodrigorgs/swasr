library(lattice)
library(igraph)
source("~/svn/swasr/src/rodrigo.R")
source("~/svn/swasr/opt/pli-R-v0.0.3-2007-07-25/discexp.R")
source("~/svn/swasr/opt/pli-R-v0.0.3-2007-07-25/disclnorm.R")
source("~/svn/swasr/opt/pli-R-v0.0.3-2007-07-25/discpowerexp.R")
source("~/svn/swasr/opt/pli-R-v0.0.3-2007-07-25/discweib.R")
source("~/svn/swasr/opt/pli-R-v0.0.3-2007-07-25/exp.R")
source("~/svn/swasr/opt/pli-R-v0.0.3-2007-07-25/lnorm.R")
source("~/svn/swasr/opt/pli-R-v0.0.3-2007-07-25/pareto.R")
source("~/svn/swasr/opt/pli-R-v0.0.3-2007-07-25/poisson.R")
source("~/svn/swasr/opt/pli-R-v0.0.3-2007-07-25/powerexp-exponential-integral.R")
source("~/svn/swasr/opt/pli-R-v0.0.3-2007-07-25/powerexp.R")
source("~/svn/swasr/opt/pli-R-v0.0.3-2007-07-25/power-law-test.R")
source("~/svn/swasr/opt/pli-R-v0.0.3-2007-07-25/weibull.R")
source("~/svn/swasr/opt/pli-R-v0.0.3-2007-07-25/yule.R")
source("~/svn/swasr/opt/pli-R-v0.0.3-2007-07-25/zeta.R")

# OBS.: conflita com os arquivos anteriores
source("/home/rodrigo/svn/swasr/opt/pli-R-v0.0.3-2007-07-25/plfit.R")


# ks.test para o caso discreto
ks.test2 <- function (x, y, ..., alternative = c("two.sided", "less", "greater"), 
    exact = NULL) 
{
    pkolmogorov1x <- function(x, n) {
        if (x <= 0) 
            return(0)
        if (x >= 1) 
            return(1)
        j <- seq.int(from = 0, to = floor(n * (1 - x)))
        1 - x * sum(exp(lchoose(n, j) + (n - j) * log(1 - x - 
            j/n) + (j - 1) * log(x + j/n)))
    }
    alternative <- match.arg(alternative)
    DNAME <- deparse(substitute(x))
    x <- x[!is.na(x)]
    n <- length(x)
    if (n < 1) 
        stop("not enough 'x' data")
    PVAL <- NULL
    if (is.numeric(y)) {
        DNAME <- paste(DNAME, "and", deparse(substitute(y)))
        y <- y[!is.na(y)]
        n.x <- as.double(n)
        n.y <- length(y)
        if (n.y < 1) 
            stop("not enough 'y' data")
        if (is.null(exact)) 
            exact <- (n.x * n.y < 10000)
        METHOD <- "Two-sample Kolmogorov-Smirnov test"
        TIES <- FALSE
        n <- n.x * n.y/(n.x + n.y)
        w <- c(x, y)
        z <- cumsum(ifelse(order(w) <= n.x, 1/n.x, -1/n.y))
        if (length(unique(w)) < (n.x + n.y)) {
            warning("cannot compute correct p-values with ties")
            z <- z[c(which(diff(sort(w)) != 0), n.x + n.y)]
            TIES <- TRUE
        }
        STATISTIC <- switch(alternative, two.sided = max(abs(z)), 
            greater = max(z), less = -min(z))
        nm_alternative <- switch(alternative, two.sided = "two-sided", 
            less = "the CDF of x lies below that of y", greater = "the CDF of x lies above that of y")
        if (exact && (alternative == "two.sided") && !TIES) 
            PVAL <- 1 - .C("psmirnov2x", p = as.double(STATISTIC), 
                as.integer(n.x), as.integer(n.y), PACKAGE = "stats")$p
    }
    else {
        if (is.character(y)) 
            y <- get(y, mode = "function")
        if (mode(y) != "function") 
            stop("'y' must be numeric or a string naming a valid function")
        if (is.null(exact)) 
            exact <- (n < 100)
        METHOD <- "One-sample Kolmogorov-Smirnov test"
        TIES <- FALSE
        if (length(unique(x)) < n) {
            warning("cannot compute correct p-values with ties")
            TIES <- TRUE
        }
        # x <- y(sort(x), ...) - (0:(n - 1))/n http://tolstoy.newcastle.edu.au/R/devel/01b/0037.html
        x <- sort(x)
        untied <- c(x[1:n-1] != x[2:n], TRUE)
        x <- y(x, ...) - (0 : (n-1)) / n
        x <- x[untied]
        ####################################### 
        STATISTIC <- switch(alternative, two.sided = max(c(x, 
            1/n - x)), greater = max(1/n - x), less = max(x))
        if (exact && !TIES) {
            PVAL <- if (alternative == "two.sided") 
                1 - .C("pkolmogorov2x", p = as.double(STATISTIC), 
                  as.integer(n), PACKAGE = "stats")$p
            else 1 - pkolmogorov1x(STATISTIC, n)
        }
        nm_alternative <- switch(alternative, two.sided = "two-sided", 
            less = "the CDF of x lies below the null hypothesis", 
            greater = "the CDF of x lies above the null hypothesis")
    }
    names(STATISTIC) <- switch(alternative, two.sided = "D", 
        greater = "D^+", less = "D^-")
    pkstwo <- function(x, tol = 1e-06) {
        if (is.numeric(x)) 
            x <- as.vector(x)
        else stop("argument 'x' must be numeric")
        p <- rep(0, length(x))
        p[is.na(x)] <- NA
        IND <- which(!is.na(x) & (x > 0))
        if (length(IND) > 0) {
            p[IND] <- .C("pkstwo", as.integer(length(x[IND])), 
                p = as.double(x[IND]), as.double(tol), PACKAGE = "stats")$p
        }
        return(p)
    }
    if (is.null(PVAL)) {
        PVAL <- ifelse(alternative == "two.sided", 1 - pkstwo(sqrt(n) * 
            STATISTIC), exp(-2 * n * STATISTIC^2))
    }
    RVAL <- list(statistic = STATISTIC, p.value = PVAL, alternative = nm_alternative, 
        method = METHOD, data.name = DNAME)
    class(RVAL) <- "htest"
    return(RVAL)
}

