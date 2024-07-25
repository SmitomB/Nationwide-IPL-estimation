# Title: Random forest model for total phosphorus prediction

# Description----
# Here we provide the codes to develop the regression random forest model for total phosphorus prediction.

# Loading pacakages----
my_packages <- c("tidyverse", "rgeos", "rgdal", "sp", "raster", "lubridate",
                 "ncdf4", "quantregForest", "rstatix", "elevatr", "caret", "pdp")
lapply(my_packages,library, character.only = T)

# Loading data----
TP.df1 <- readRDS("Datafiles/TP.predictors.RDS")

# Preparing the training data----
## Training data
### Making log transformation
TP.df1$avgTP_mugL <- log(TP.df1$avgTP_mugL)
Train.TP.df1 <- TP.df1

### summary of the training data
plot(density(Train.TP.df1$avgTP_mugL)) # histogram

summary(Train.TP.df1$avgTP_mugL) # summary

quantile(Train.TP.df1$avgTP_mugL, probs = c(0.1, 0.25, 0.5, 0.75, 0.9)) # Quantiles


## Response variable and Predictors
pred.vars <- c("avgTP_mugL", "EcoRegion",
               "DEPTH", "Water_cover", "AvgSummPrec_mm", "AvgSummTemp_C",
               "Dev_cover", "Barren_cover", "For_cover",
               "Shrub_cover", "Herb_cover", "Cult_cover",
               "Wetland_cover", "Aream2", "ws_lake_arearatio")

# Hyperparameter tuning----
## Different mtry values
mtry.vec <- seq(3,12,1)

## to store the models and model performance
TP.rf.mod.lst <- list()
TP.rf.mod.per <- data.frame()

## Defining function
VarExp <- function(mod,obs)
{
  RSS = t(obs-mod)%*%(obs-mod); SYY = t(obs)%*%(obs)-length(obs)*mean(obs)^2 
  return(paste(signif(1-RSS/SYY,3)))
}

## Developing different models
for (i in 1:length(mtry.vec)){
  
  # Setting seed
  set.seed(326+i)
  
  # training model
  TP.rf.mod.lst[[i]] <- randomForest(
    formula = avgTP_mugL ~ .,
    data = Train.TP.df1[,pred.vars],
    mtry = mtry.vec[i],
    ntree = 1000,
    importance = T,
    nodesize = 10
  )
  
  # Temporary dataframe
  tmp.rf.mod <- data.frame(predicted = TP.rf.mod.lst[[i]]$predicted,y = TP.rf.mod.lst[[i]]$y)
  
  # Coefficient of determination
  tmp.R2 <- VarExp(tmp.rf.mod$predicted, tmp.rf.mod$y) 
  
  # Corelation coefficient
  tmp.r2 <- cor(tmp.rf.mod$predicted, tmp.rf.mod$y)
  
  # MSE
  tmp.mse <- mean((tmp.rf.mod$y - tmp.rf.mod$predicted)^2)
  
  # RMSE
  tmp.rmse <- sqrt(mean((tmp.rf.mod$y - tmp.rf.mod$predicted)^2))
  
  TP.rf.mod.per <- rbind(TP.rf.mod.per,
                         data.frame(mtry = mtry.vec[i],
                                    R2 = tmp.R2,
                                    r2 = tmp.r2,
                                    mse = tmp.mse,
                                    rmse = tmp.rmse))
}

TP.rf.mod.per

#Note: We select 1000 trees and mtry value of 5 for the TP RF model.

# Final model----
set.seed(329)

## Developing the model
TP.rf.mod1 <- randomForest(
  formula = avgTP_mugL ~ .,
  data = Train.TP.df1[,pred.vars],
  mtry = 5,
  ntree = 1000,
  importance = T,
  do.trace = 100,
  nodesize = 10
)

TP.rf.mod1

## Same model for quantile regression
set.seed(329)
TP.rf.mod2 <- quantregForest( Train.TP.df1[,pred.vars[which(pred.vars != "avgTP_mugL")]],
                              Train.TP.df1[, "avgTP_mugL"],
                              keep.inbag = T,
                              ntree = 1000,
                              mtry = 5,
                              importance = T,
                              do.trace = 100,
                              nodesize = 10)

TP.rf.mod2

# Cross-validation----
## number of folds
k <- 4

## set seed
set.seed(150)

## Create k-fold cross-validation indices
folds <- createFolds(Train.TP.df1$avgTP_mugL , k = k, list = TRUE, returnTrain = TRUE)

## Model predictions
pred_list_mtry <- list()
pred_list_fold <- list()


## k-fold cross-validation each mtry
for (j in 1:length(mtry.vec)){
  for (i in 1:k){
    tmp.Train.indices <- folds[[i]]
    
    # Train and test data
    tmp.Train.df <- Train.TP.df1[tmp.Train.indices,]
    tmp.Test.df <- Train.TP.df1[-tmp.Train.indices,]
    
    # set seed
    set.seed(329)
    
    # Modeling training
    tmp.rf.mod <- randomForest(
      formula = avgTP_mugL ~ .,
      data = tmp.Train.df[,pred.vars],
      mtry = mtry.vec[j],
      ntree = 1000,
      importance = T,
      nodesize = 10
    )
    
    # Predicting on test test
    tmp.Test.df <- tmp.Test.df %>% mutate(predicted = predict(tmp.rf.mod, newdata = tmp.Test.df),
                                          Fold = rep(i, nrow(tmp.Test.df)))
    
    pred_list_fold[[i]] <- list(mtry = mtry.vec[j],
                                hodlout.fold = paste0("Fold",i),
                                holdout.fold.df = tmp.Test.df)
  }
  pred_list_mtry[[j]] <- pred_list_fold
  
}

## List to store model results for different mtry values
TP.mod.holdouts.lst <- list()


## Loop to pull all the predicted data in the holdout folds for a given mtry value
for (j in 1:length(mtry.vec)){
  
  # temporary data frame
  TP.mod.holdouts.mtry <- data.frame()
  
  for (i in 1:k){
    # Adding to the data frame
    TP.mod.holdouts.mtry <- rbind(TP.mod.holdouts.mtry,
                                  pred_list_mtry[[j]][[i]]$holdout.fold.df )
  }
  
  TP.mod.holdouts.lst[[j]] <- TP.mod.holdouts.mtry
}

### check
#### for mtry == 5
VarExp(TP.mod.holdouts.lst[[3]]$predicted,
       TP.mod.holdouts.lst[[3]]$avgTP_mugL )


# Model performance----
## Training phase
### Coefficient of determination
Train.TP.df.per <- cbind(Train.TP.df1, log.pred.avgTP_mugL = TP.rf.mod1$predicted)
VarExp(Train.TP.df.per$log.pred.avgTP_mugL , Train.TP.df.per$avgTP_mugL )

### RMSE
sqrt(mean((Train.TP.df.per$log.pred.avgTP_mugL - Train.TP.df.per$avgTP_mugL)^2))

## Cross-validation
### dataframe to store cross-validation results
TP.rf.mod.per.CV <- data.frame()

# model perfomance
for (j in 1:length(mtry.vec)){
  # temp. dataframe
  tmp.df <- TP.mod.holdouts.lst[[j]]
  
  # Performance metrics
  ## Coefficient of determination
  
  tmp.R2 <- VarExp(tmp.df$predicted , tmp.df$avgTP_mugL ) 
  
  ## Correlation coefficient
  tmp.cor <- cor(tmp.df$predicted , tmp.df$avgTP_mugL)
  
  ## MSE
  tmp.mse <- mean((tmp.df$predicted  - tmp.df$avgTP_mugL)^2) 
  
  # RMSE
  tmp.rmse <- sqrt(mean((tmp.df$avgTP_mugL - tmp.df$predicted)^2)) 
  
  tmp.per.df <- data.frame(mtry = mtry.vec[j],
                           R2 = tmp.R2,
                           r = tmp.cor,
                           mse = tmp.mse,
                           rmse = tmp.rmse)
  
  TP.rf.mod.per.CV <- rbind(TP.rf.mod.per.CV,
                            tmp.per.df)
}

TP.rf.mod.per.CV















