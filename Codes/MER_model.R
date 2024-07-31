# Title: Mixed effects model for IPL flux estimation

# Description----
# Here we provide the codes to develop the regression model for IPL flux prediction.

# Loading pacakages----
my_packages <- c("tidyverse", "readxl", "leaps", "relaimpo", "psych", "lme4", "Hmisc", "merTools")
lapply(my_packages, library, character.only = T)

# Loading data----
dat <- readRDS("Datafiles/IPL_obs.RDS")

# Mixed-effects Regression (MER) Model----
## New data frame
dat.MLdf <- dat

## Model development
MLIPLmodel1 <- lmer(log(IPL_flux)~ 1 + log(Depth_m)+ log(Area_m2) +  log(TP_mgL) + log(Temp_C) + (1|lagoslakei), data = dat.MLdf)

## model summary
summary(MLIPLmodel1)


## Model performance
### Getting model predictions
dat.MLdf <- dat.MLdf %>% 
  mutate(pred.ln.IPL.re = predict(MLIPLmodel1, newdata = .), # with random effects
         pred.ln.IPL = predict(MLIPLmodel1, re.form = NA ,newdata = .), # without random effects
         ln.IPL = log(IPL_flux))

### Adding labels to the columns
label(dat.MLdf[["pred.ln.IPL.re"]]) <- c("Predicted log IPL flux with random effects")
label(dat.MLdf[["pred.ln.IPL"]]) <- c("Predicted log IPL flux without random effects")
label(dat.MLdf[["ln.IPL"]]) <- c("Observed log IPL flux")


### Coefficient of determination
#### Defining function
VarExp <- function(mod,obs)
{
  RSS = t(obs-mod)%*%(obs-mod); SYY = t(obs)%*%(obs)-length(obs)*mean(obs)^2 
  return(paste(signif(1-RSS/SYY,3)))
}

#### Estimating R sq.
VarExp(dat.MLdf$pred.ln.IPL, dat.MLdf$ln.IPL) # without random effects
VarExp(dat.MLdf$pred.ln.IPL.re, dat.MLdf$ln.IPL) # with random effects

### RMSE
sqrt(mean((dat.MLdf$ln.IPL - dat.MLdf$pred.ln.IPL)^2)) # without random effects
sqrt(mean((dat.MLdf$ln.IPL - dat.MLdf$pred.ln.IPL.re)^2)) # without random effects


## 10-fold cross-validation
### Redefining the obs dataset
dat.cvMLdf <- dat

### number of lakes per fold
lakes_p_folds <- length(unique(dat.cvMLdf$lagoslakei))/10

### splitting the dataset into 10 folds
train.lakes <- split(unique(dat.cvMLdf$lagoslakei), ceiling(seq_along(unique(dat.cvMLdf$lagoslakei))/lakes_p_folds))

### data frame to store test data
testdat.cvMLdf <- data.frame()

for(i in 1:length(train.lakes)){
  # training dataset
  train.df <- dat.cvMLdf[which(!dat.cvMLdf$lagoslakei %in% train.lakes[[i]]),]
  
  # testing dataset
  test.df <- dat.cvMLdf[which(dat.cvMLdf$lagoslakei %in% train.lakes[[i]]),]
  
  # developing a model
  # Multilevel linear regression model
  LMMmod.temp <- lmer(log(IPL_flux)~ 1 + log(Depth_m)+ log(Area_m2) +  log(TP_mgL) + log(Temp_C) + (1|lagoslakei), data = train.df)
  
  # Predicting the test data
  test.df <- test.df %>% 
    mutate(pred.ln.IPL = predict(LMMmod.temp, re.form = NA ,newdata = .), # without random effects
           ln.IPL = log(IPL_flux)) # observed data in log scale
  
  test.df <- test.df %>% mutate(Fold = rep(paste0("fold",i)))
  
  testdat.cvMLdf <- rbind(testdat.cvMLdf, test.df)
}

### Coefficient of determination
VarExp(testdat.cvMLdf$pred.ln.IPL, testdat.cvMLdf$ln.IPL) # without random effects

### RMSE calculation
sqrt(mean((testdat.cvMLdf$ln.IPL - testdat.cvMLdf$pred.ln.IPL)^2)) # without random effects











