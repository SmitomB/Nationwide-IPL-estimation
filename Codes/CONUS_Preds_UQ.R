# Title: Uncertainty Quantification during nationwide prediction

# Description----
# Here we provide the codes to quantify the uncertainty in the nationwide IPL predictions

# Loading pacakages----
my_packages <- c("tidyverse", "rgeos", "rgdal", "sp", "raster", "lubridate",
                 "ncdf4", "quantregForest", "rstatix", "elevatr", "caret", "pdp")
lapply(my_packages,library, character.only = T)

# Loading data----
lakes.sp.df <- readRDS("Datafiles/lakes.sp.df.RDS")


# Bottom temperature prediction----
## Loading the BT RF model
BT.rf.mod2 <- readRDS("Datafiles/BTRF_model.RDS")

## New dataframe for the BT model run
lakes.sp.BT.df <- lakes.sp.df

## number of lakes
Nlakes <- nrow(lakes.sp.df) # 5899 lakes

## Renaming the area column
lakes.sp.BT.df <- lakes.sp.BT.df %>%
  rename(.,
         Aream2 = Area_m2)

## predictors for the BT model
BT.predvars0 <- c("lagoslakei" ,"DEPTH", "Aream2", "AvgSummTemp_C", "EcoRegion")
BT.predvars1 <- c("DEPTH", "Aream2", "AvgSummTemp_C", "EcoRegion")

## Making ecoregion factors
lakes.sp.BT.df$EcoRegion <- as.factor(lakes.sp.BT.df$EcoRegion)

## Predictng the mean value and sd
lakes.sp.BT.df <- lakes.sp.BT.df %>% mutate(mean.pred.BT = predict(BT.rf.mod2, newdata = lakes.sp.BT.df[,BT.predvars1], what = mean),
                                            sd.pred.BT = predict(BT.rf.mod2, newdata = lakes.sp.BT.df[,BT.predvars1], what = sd))

## Predicting the 90% prediction interval
lakes.sp.BT.dfUQ <- predict(BT.rf.mod2, newdata = lakes.sp.BT.df[,BT.predvars1], what = c(0.05, 0.5, 0.95))
colnames(lakes.sp.BT.dfUQ) <- c("pred.BT.5", "pred.BT.50", "pred.BT.95")

lakes.sp.BT.df <- cbind(lakes.sp.BT.df,lakes.sp.BT.dfUQ )


## Generating 1000 predictions
set.seed(225)
n_samples <- 1000
lakes.sp.BT.df1000 <- predict(BT.rf.mod2, newdata = lakes.sp.BT.df[,BT.predvars1], what = function(x) sample(x, n_samples, replace = T))

lakes.sp.BT.df1000 <- cbind(lakes.sp.BT.df[,c("lagoslakei", "mean.pred.BT", "pred.BT.5", "pred.BT.50", "pred.BT.95")] ,lakes.sp.BT.df1000) # 5899 rows


# Total phosphorus prediction----
## Loading the TP RF model
TP.rf.mod2 <- readRDS("Datafiles/TPRF_model.RDS")

## New dataframe for the BT model run
lakes.sp.TP.df <- lakes.sp.df

## Renaming the area column
lakes.sp.TP.df <- lakes.sp.TP.df %>%
  rename(.,
         Aream2 = Area_m2)

## predictors for the BT model
TP.predvars0 <- c("avgTP_mugL", "EcoRegion",
                  "DEPTH", "Water_cover", "AvgSummPrec_mm", "AvgSummTemp_C",
                  "Dev_cover", "Barren_cover", "For_cover",
                  "Shrub_cover", "Herb_cover", "Cult_cover",
                  "Wetland_cover", "Aream2", "ws_lake_arearatio")


TP.predvars1 <- c("EcoRegion",
                  "DEPTH", "Water_cover", "AvgSummPrec_mm", "AvgSummTemp_C",
                  "Dev_cover", "Barren_cover", "For_cover",
                  "Shrub_cover", "Herb_cover", "Cult_cover",
                  "Wetland_cover", "Aream2", "ws_lake_arearatio")

## Making ecoregion factors
lakes.sp.TP.df$EcoRegion <- as.factor(lakes.sp.TP.df$EcoRegion)

## Predictng the mean value and sd
lakes.sp.TP.df <- lakes.sp.TP.df %>% mutate(mean.ln.pred.TP = predict(TP.rf.mod2, newdata = lakes.sp.TP.df[,TP.predvars1], what = mean),
                                            sd.ln.pred.TP = predict(TP.rf.mod2, newdata = lakes.sp.TP.df[,TP.predvars1], what = sd))

## Predicting the 90% prediction interval
lakes.sp.TP.dfUQ <- predict(TP.rf.mod2, newdata = lakes.sp.TP.df[,TP.predvars1], what = c(0.05, 0.5, 0.95))
colnames(lakes.sp.TP.dfUQ) <- c("ln.pred.TP.5", "ln.pred.TP.50", "ln.pred.TP.95")

lakes.sp.TP.df <- cbind(lakes.sp.TP.df,lakes.sp.TP.dfUQ )


## Generating 1000 predictions (in log scale)
set.seed(225)
lakes.sp.ln.TP.df1000 <- predict(TP.rf.mod2, newdata = lakes.sp.TP.df[,TP.predvars1], what = function(x) sample(x, n_samples, replace = T))

lakes.sp.ln.TP.df1000 <- cbind(lakes.sp.TP.df[,c("lagoslakei","lon", "lat", "mean.ln.pred.TP", "ln.pred.TP.5", "ln.pred.TP.50", "ln.pred.TP.95")] ,lakes.sp.ln.TP.df1000)


## Generating 1000 predictions (in natural scale)
lakes.sp.TP.df1000 <- lakes.sp.ln.TP.df1000
lakes.sp.TP.df1000[,!colnames(lakes.sp.TP.df1000) %in% c("lagoslakei", "lon", "lat","mean.ln.pred.TP", "ln.pred.TP.5", "ln.pred.TP.50", "ln.pred.TP.95")] <- exp(lakes.sp.TP.df1000[,!colnames(lakes.sp.TP.df1000) %in% c("lagoslakei","lon", "lat", "mean.ln.pred.TP", "ln.pred.TP.5", "ln.pred.TP.50", "ln.pred.TP.95")])


# IPL calculation with uncertainty quantification----
## Loading the model
MLIPLmodel1 <- readRDS("Datafiles/MER_model.RDS")


## Number of lakes
N <- Nlakes

## Renaming the mean depth column
lakes.sp.df <- lakes.sp.df %>% rename(.,
                                      DEPTH_m = DEPTH)

## number of iterations
n <- n_samples

## Model fixed effects
MLIPLmodel1.fedf <- coef(summary(MLIPLmodel1)) %>% as.data.frame()

## Model random effects (across lake variation)
MLIPLmodel1.redf <- sqrt(as.numeric(VarCorr(MLIPLmodel1)[["lagoslakei"]]))

## Function to calculate the uncertainty in the model coefficients and residual error
modunc.func <- function(mod.fe = MLIPLmodel1.fedf, 
                        mod.grp.re = MLIPLmodel1.redf,
                        ndat){

  # estimates of the coefficients
  a0 <- mod.fe["(Intercept)","Estimate"]
  a1 <- mod.fe["log(Depth_m)","Estimate"]
  a2 <- mod.fe["log(Area_m2)","Estimate"]
  a3 <- mod.fe["log(TP_mgL)","Estimate"]
  a4 <- mod.fe["log(Temp_C)","Estimate"]
  
  # Degrees of freedom
  model.df <- 49 
  
  # Note: As we ignore the residual error in our calculations, we calculate the degree of freedom similar to the linear regression model.
  
  # standard deviation of random mixed effects
  model.rse <- mod.grp.re
  
  # Simulation of residual standard error
  rse.sim <- model.rse * sqrt(model.df/rchisq(1, df = model.df))
  
  # new responses
  ysim <- rnorm(nrow(ndat), a0 + a1*log(ndat$Depth_m) + a2*log(ndat$Area_m2) + a3*log(ndat$TP_mgL) + a4*log(ndat$Temp_C), sd = rse.sim)
  
  
  # New linear model
  temp.model <- lm(ysim ~ log(Depth_m) + log(Area_m2) + log(TP_mgL)+log(Temp_C), data = ndat)
  
  # Coefficients
  Coeffs <- coef(temp.model)
  
  return(list(Coeffs, rse.sim))
}


## Creating a list to store all different iterations of the TP and BT
Acoeff.list <- list()
for(i in 1:n){
  # i <- 2 # for test
  
  # input data
  temp.dat <- lakes.sp.df[,c("lagoslakei", "lat", "lon", "DEPTH_m", "Area_m2")] %>%
    rename(., 
           Depth_m = DEPTH_m)
  
  temp.dat <- merge(temp.dat, 
                    (lakes.sp.TP.df1000[,c("lagoslakei", as.character(i))]), 
                    by = "lagoslakei", 
                    sort = F)
  
  temp.dat <- merge(temp.dat, 
                    lakes.sp.BT.df1000[,c("lagoslakei", as.character(i))], 
                    by = "lagoslakei", 
                    sort = F)
  
  colnames(temp.dat) <- c("lagoslakei", "lat", "lon", "Depth_m", "Area_m2", "TP_mgL", "Temp_C")
  
  temp.dat$TP_mgL <- temp.dat$TP_mgL/1000
  
  set.seed(25*i)
  Coeff.res <- modunc.func(ndat = temp.dat)
  coeff.vec <- Coeff.res[[1]]
  sigma <- Coeff.res[[2]]
  
  set.seed(25*i)
  rse <- rnorm(1, mean = 0, sigma)
  Acoeff.list[[i]] <- list(Coeff = as.numeric(c(coeff.vec, rse )),
                           SD = sigma)
  # Progress update
  Sys.sleep(0.01)
  cat("\rFinished",i,"of",n)
}

### Developing a coefficient matrix
for(i in 1:n){
  Coeffmat <- lapply(Acoeff.list, '[[', "Coeff")
  Coeffmat <- as.data.frame(do.call(rbind, Coeffmat)) %>% as.matrix()
}
colnames(Coeffmat) <- paste0("a", seq(0,5))

### Storing the coefficient matrix for each waterbody
for (i in 1:N){
  Acoeff.list[[i]] <- list(Amat = Coeffmat)
  
  # Progress update
  Sys.sleep(0.01)
  cat("\rFinished",i,"of",N)
}


## Calculating IPL flux for each combination of TP, BT, and coefficients
### List for predictor matrices
X.list <- list()

### predictor matrices for each waterbody
for (i in 1:N){
  
  # lake id
  l.id <- as.numeric(lakes.sp.df[i,"lagoslakei"])
  
  ## predictor matrix
  Xvals <- data.frame(fe.intercept = rep(1, n), ## Fixed effects intercept
                      
                      ## log (depth)
                      ln.z = rep(log(as.numeric(lakes.sp.df[which(lakes.sp.df$lagoslakei==l.id),"DEPTH_m"])), n),
                      
                      ## log(area)
                      ln.A = rep(log(as.numeric(lakes.sp.df[which(lakes.sp.df$lagoslakei==l.id),"Area_m2"])), n),
                      
                      
                      ## log(TP) with TP in mg/L units
                      ln.TP = log(as.numeric(lakes.sp.TP.df1000[which(lakes.sp.TP.df1000$lagoslakei== l.id), as.character(1:n)]/1000)),
                      
                      ## log(BT)
                      ln.T = log(as.numeric(lakes.sp.BT.df1000[which(lakes.sp.BT.df1000$lagoslakei== l.id), as.character(1:n)])),
                      
                      re.intercept =  rep(1, n) ## Random effect intercept
                      
  ) %>% t %>% as.matrix()
  
  ## Adding to the list
  X.list[[i]]<- list(lagoslakei = l.id, Xmat = Xvals)
  
  # Progress update
  Sys.sleep(0.01)
  cat("\rFinished",i,"of",N)
}

## Summary of IPL flux predictions
### Log-scale calculation
lnIPLFlux.df <- data.frame()

#### IPL flux estimates in each lake
for(i in 1:N){
  IPLFlux.temp.mat <- Acoeff.list[[i]]$Amat%*%X.list[[i]]$Xmat
  
  IPLFlux.temp.vec <- c(X.list[[i]]$lagoslakei, # lake id
                        mean(as.vector(diag(IPLFlux.temp.mat))), # mean
                        median(as.vector(diag(IPLFlux.temp.mat))), # median
                        sqrt(var(as.vector(diag(IPLFlux.temp.mat)))),  # sd
                        as.numeric(quantile(as.vector(diag(IPLFlux.temp.mat)),probs = c(0.05))), # 5 percentile
                        as.numeric(quantile(as.vector(diag(IPLFlux.temp.mat)),probs = c(0.95)))) # 95 percentile
  
  ## Adding to the data frome
  lnIPLFlux.df <- rbind(lnIPLFlux.df, IPLFlux.temp.vec)
  
  # Progress update
  Sys.sleep(0.01)
  cat("\rFinished",i,"of",N)
}

#### Renaming the columns
colnames(lnIPLFlux.df)<- c("lagoslakei", "mean.ln.pred.IPL", "median.ln.pred.IPL", "sd.ln.pred.IPL", "ln.pred.IPL.5", "ln.pred.IPL.95")

### Natural scale calculation
IPLFlux.df <- data.frame()

#### IPL flux estimates in each lake
for(i in 1:N){
  IPLFlux.temp.mat <- exp(Acoeff.list[[i]]$Amat%*%X.list[[i]]$Xmat)
  
  IPLFlux.temp.vec <- c(X.list[[i]]$lagoslakei, # lake id
                        mean(as.vector(diag(IPLFlux.temp.mat))), # mean
                        median(as.vector(diag(IPLFlux.temp.mat))), # median
                        sqrt(var(as.vector(diag(IPLFlux.temp.mat)))),  # sd
                        as.numeric(quantile(as.vector(diag(IPLFlux.temp.mat)),probs = c(0.05))), # 5 percentile
                        as.numeric(quantile(as.vector(diag(IPLFlux.temp.mat)),probs = c(0.95)))) # 95 percentile
  
  ## Adding to the data frome
  IPLFlux.df <- rbind(IPLFlux.df, IPLFlux.temp.vec)
  
  # Progress update
  Sys.sleep(0.01)
  cat("\rFinished",i,"of",N)
}

#### Renaming the columns
colnames(IPLFlux.df)<- c("lagoslakei", "mean.pred.IPL", "median.pred.IPL", "sd.pred.IPL", "pred.IPL.5", "pred.IPL.95")












































































