# Title: Randomforest model for bottom temperature prediction

# Description----
# Here we provide the codes to develop the regression random forest model for bottom temperature prediction.

# Loading pacakages----
my_packages <- c("tidyverse", "rgeos", "rgdal", "sp", "raster", "lubridate",
                 "ncdf4", "quantregForest", "rstatix", "elevatr", "caret", "pdp")
lapply(my_packages,library, character.only = T)

# Loading data----
BT.df1 <- readRDS("Datafiles/BT.predictors.RDS")


# Preparing the training data----
## Training data
Train.BT.df1 <- BT.df1

### summary of the training data
plot(density(Train.BT.df1$TEMPERATURE)) # histogram

summary(Train.BT.df1$TEMPERATURE) # summary

quantile(Train.BT.df1$TEMPERATURE, probs = c(0.1, 0.25, 0.5, 0.75, 0.9)) # Quantiles


## Response variable and Predictors
pred.vars <- c("TEMPERATURE", "DEPTH", "Aream2","AvgSummTemp_C", "EcoRegion")
pred.vars1 <- c("DEPTH", "Aream2","AvgSummTemp_C", "EcoRegion")


# Hyperparameter tuning----
## Different mtry values
mtry.vec <- c(2,3,4)

## to store the models and model performance
BT.rf.mod.lst <- list()
BT.rf.mod.per <- data.frame()

## Defining function
VarExp <- function(mod,obs)
{
  RSS = t(obs-mod)%*%(obs-mod); SYY = t(obs)%*%(obs)-length(obs)*mean(obs)^2 
  return(paste(signif(1-RSS/SYY,3)))
}

## Developing different models
for (i in 1:length(mtry.vec)){
  
  # Setting seed
  set.seed(123+i)
  
  # training model
  BT.rf.mod.lst[[i]] <- randomForest(
    formula = TEMPERATURE ~ DEPTH + Aream2 + AvgSummTemp_C + EcoRegion,
    data = Train.BT.df1[,pred.vars],
    mtry = mtry.vec[i],
    ntree = 1000,
    importance = T,
    nodesize = 10
  )
  
  # Temporary dataframe
  tmp.rf.mod <- data.frame(predicted = BT.rf.mod.lst[[i]]$predicted,y = BT.rf.mod.lst[[i]]$y)
  
  # Coefficient of determination
  tmp.R2 <- VarExp(tmp.rf.mod$predicted, tmp.rf.mod$y) 
  
  # Corelation coefficient
  tmp.r2 <- cor(tmp.rf.mod$predicted, tmp.rf.mod$y)
  
  # MSE
  tmp.mse <- mean((tmp.rf.mod$y - tmp.rf.mod$predicted)^2)
  
  # RMSE
  tmp.rmse <- sqrt(mean((tmp.rf.mod$y - tmp.rf.mod$predicted)^2))
  
  BT.rf.mod.per <- rbind(BT.rf.mod.per,
                         data.frame(mtry = mtry.vec[i],
                                    R2 = tmp.R2,
                                    r2 = tmp.r2,
                                    mse = tmp.mse,
                                    rmse = tmp.rmse))
}

BT.rf.mod.per

#Note: We select 1000 trees and mtry value of 3 for the BT RF model.

# Final model----
set.seed(125)

# Developing the model again
BT.rf.mod1 <- randomForest(
  formula = TEMPERATURE ~ DEPTH + Aream2 + AvgSummTemp_C + EcoRegion,
  data = Train.BT.df1[,pred.vars],
  mtry = 3,
  ntree = 1000,
  importance = T,
  do.trace = 100,
  nodesize = 10
)

BT.rf.mod1

# Cross-validation----
## number of folds
k <- 4

## set seed
set.seed(600)

## Create k-fold cross-validation indices
folds <- createFolds(Train.BT.df1$TEMPERATURE, k = k, list = TRUE, returnTrain = TRUE)

## Model predictions
pred_list_mtry <- list()
pred_list_fold <- list()


## k-fold cross-validation each mtry
for (j in 1:length(mtry.vec)){
  for (i in 1:k){
    tmp.Train.indices <- folds[[i]]
    
    # Train and test data
    tmp.Train.df <- Train.BT.df1[tmp.Train.indices,]
    tmp.Test.df <- Train.BT.df1[-tmp.Train.indices,]
    
    # Modeling training
    tmp.rf.mod <- randomForest(
      formula = TEMPERATURE ~ DEPTH + Aream2 + AvgSummTemp_C + EcoRegion,
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
BT.mod.holdouts.lst <- list()


## Loop to pull all the predicted data in the holdout folds for a given mtry value
for (j in 1:length(mtry.vec)){
  
  # temporary data frame
  BT.mod.holdouts.mtry <- data.frame()
  
  for (i in 1:k){
    # Adding to the data frame
    BT.mod.holdouts.mtry <- rbind(BT.mod.holdouts.mtry,
                                  pred_list_mtry[[j]][[i]]$holdout.fold.df )
  }
  
  BT.mod.holdouts.lst[[j]] <- BT.mod.holdouts.mtry
}

### check
#### for mtry == 3
VarExp(BT.mod.holdouts.lst[[2]]$predicted,
       BT.mod.holdouts.lst[[2]]$TEMPERATURE)

# Model performance----
## Training phase
### Coefficient of determination
Train.BT.df.per <- cbind(Train.BT.df1, pred.BT_C = BT.rf.mod1$predicted)
VarExp(Train.BT.df.per$pred.BT_C , Train.BT.df.per$TEMPERATURE ) 

### RMSE
sqrt(mean((Train.BT.df.per$pred.BT_C - Train.BT.df.per$TEMPERATURE)^2))

## Cross-validation
### dataframe to store cross-validation results
BT.rf.mod.per.CV <- data.frame()

# model perfomance
for (j in 1:length(mtry.vec)){
  
  # temp. dataframe
  tmp.df <- BT.mod.holdouts.lst[[j]]
  
  # Performance metrics
  ## Coefficient of determination
  
  tmp.R2 <- VarExp(tmp.df$predicted , tmp.df$TEMPERATURE ) 
  
  ## Correlation coefficient
  tmp.cor <- cor(tmp.df$predicted , tmp.df$TEMPERATURE)
  
  ## MSE
  tmp.mse <- mean((tmp.df$predicted  - tmp.df$TEMPERATURE)^2) 
  
  # RMSE
  tmp.rmse <- sqrt(mean((tmp.df$TEMPERATURE - tmp.df$predicted)^2)) 
  
  tmp.per.df <- data.frame(mtry = mtry.vec[j],
                           R2 = tmp.R2,
                           r = tmp.cor,
                           mse = tmp.mse,
                           rmse = tmp.rmse)
  
  BT.rf.mod.per.CV <- rbind(BT.rf.mod.per.CV,
                            tmp.per.df)
}

BT.rf.mod.per.CV
































