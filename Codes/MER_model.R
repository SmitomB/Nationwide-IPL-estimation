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