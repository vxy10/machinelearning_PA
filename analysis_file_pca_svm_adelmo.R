library(caret)
library(tree)
library(rpart)
library(e1071)

setwd("C:/Users/Vivek/Desktop/coursera/PML_docs")

data_train<-read.csv('pml-training.csv')
data_test<-read.csv('pml-testing.csv')



ind_na = is.na(data_train[1,])
data_train2 <- as.data.frame(data_train[,ind_na==FALSE])
data_test2 <- as.data.frame(data_test[,ind_na==FALSE])

features<-names(data_train2)
roll_ind<-grep("_roll_",features,fixed = TRUE)
pitch_ind<-grep("_pitch_",features,fixed = TRUE)
picth_ind<-grep("_picth_",features,fixed = TRUE)
yaw_ind<-grep("_yaw_",features,fixed = TRUE)

# roll_arm, pitch_arm, yaw_arm
#roll_ind<-grep("roll_arm",features,fixed = TRUE)
#pitch_ind<-grep("pitch_arm",features,fixed = TRUE)
#yaw_aind<-grep("yaw_arm",features,fixed = TRUE)

data_train2 <- as.data.frame( data_train2[, -c( roll_ind, pitch_ind, yaw_ind, picth_ind ) ] )
data_train3 <- data_train2[,-c(1,3,4,5,6,7)]


data_usr<- split(data_train3,data_train3$user_name)
AllData<- data_usr$adelmo

ind_all_predictors<- 2:53
ind_bad_predictors<- ind_all_predictors[apply(AllData[,2:53],2,sd)==0]
if (length(ind_bad_predictors)!=0) {

  ind_predictors <-ind_all_predictors[-ind_bad_predictors]
  AllData<- AllData[,-ind_bad_predictors]
}
predictors<-names(AllData)
predictors<-predictors[2:(dim(AllData)[2]-1)]

ind_all <- sample(1:dim(AllData)[1])
num_model <- round(length(ind_all)*.8)
indModel <- ind_all[1:(num_model)]

data_training <- AllData[indModel,]
data_CV       <- AllData[-indModel,]



preProc<-preProcess(data_training[predictors],method = "pca",thresh=0.99)
predictors_PC<- predict(preProc,data_training[predictors])
AllData_PC <- cbind(predictors_PC,classe = data_training[,dim(data_training)[2]])

predictors_PC_cv<- predict(preProc,data_CV[predictors])
AllData_PC_cv   <- cbind(predictors_PC_cv,classe = data_CV[,dim(data_training)[2]])

inTrain <- createDataPartition(y=AllData_PC$classe, p = .5,list = FALSE)
num_train = length(inTrain)
trainData<- AllData_PC[inTrain,]
testData <- AllData_PC[-inTrain,]

len_data<- dim(AllData_PC)[2]


## algorithm selection
svm_model <- svm(classe ~ ., data = trainData)
pred_svm <- predict(svm_model, testData[,-len_data])
confusionMatrix(pred_svm,testData[,"classe"])

rpart_model <- rpart(classe ~ ., data = trainData)
pred_rpart <- predict(rpart_model, testData[,-len_data],type = "class")
confusionMatrix(pred_rpart,testData[,"classe"])

tree_model <- tree(classe ~ ., data = trainData)
pred_tree <- predict(tree_model, testData[,-len_data],type = "class")
confusionMatrix(pred_tree,testData[,"classe"])

SvmFit_all <- list() 
ConfMat_all <- list() 

num_fits = 41
for (j in 1:num_fits) {
  indModel <- sample(indModel,replace = TRUE)
  indTrain <- ind_all[1:(num_train)]
  indTest <- ind_all[1:(num_train)]
  
  inTrain <- createDataPartition(y=AllData_PC$classe, p = .7,list = FALSE)
  trainData<- AllData_PC[inTrain,]
  testData <- AllData_PC[-inTrain,]
  
  svm_model <- svm(classe ~ ., data = trainData)
  pred_svm <- predict(svm_model, testData[,-dim(testData)[2]])
  ConfMat_all[[j]]=confusionMatrix(pred_svm,testData[,"classe"])
  SvmFit_all[[j]] <-svm_model
}

mat_ind <- c("A","B","C","D","E")


mat_pred <- as.data.frame(matrix(nrow = dim(AllData_PC_cv)[1], ncol = num_fits))
for (j in 1:num_fits){
  pred_svm <- predict(SvmFit_all[[j]], AllData_PC_cv[,-len_data])
  mat_pred[,j] <- pred_svm
}

mat_cons <- as.data.frame(matrix(nrow = dim(AllData_PC_cv)[1], ncol = 5))
for (j in 1:5) {
  a<- mat_pred == mat_ind[j]
  mat_cons[,j] <- apply(a, 1, sum)  
}
mn_exp <- (apply(mat_cons, 1,which.max))

confusionMatrix(mat_ind[mn_exp],AllData_PC_cv[,len_data])


exam_data<- data_test2[data_test2$user_name == "adelmo",]
predictors_PC_exam<- predict(preProc,exam_data[predictors])
mat_pred_exam <- as.data.frame(matrix(nrow = dim(exam_data)[1], ncol = num_fits))
for (j in 1:num_fits){
  pred_svm <- predict(SvmFit_all[[j]], predictors_PC_exam)
  mat_pred_exam[,j] <- pred_svm
}
