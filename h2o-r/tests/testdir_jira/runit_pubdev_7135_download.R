setwd(normalizePath(dirname(R.utils::commandArgs(asValues=TRUE)$"f")))
source("../../scripts/h2o-r-test-setup.R")



test.pubdev_7135 <- function() {

  # Test saving and loading of GLM model
  Log.info("Importing prostate.csv...")
  prostate.hex = h2o.uploadFile(normalizePath(locate('smalldata/logreg/prostate.csv')))
  prostate.hex[,2] = as.factor(prostate.hex[,2])
  iris.hex = h2o.uploadFile(normalizePath(locate('smalldata/iris/iris.csv')))

  # Build GLM, RandomForest, GBM, Naive Bayes, and Deep Learning models
  Log.info("Build GLM model")
  prostate.glm = h2o.glm(y = "CAPSULE", x = c("AGE","RACE","PSA","DCAPS"), training_frame = prostate.hex, family = "binomial", nfolds = 0, alpha = 0.5)
  Log.info("Build GBM model")
  prostate.gbm = h2o.gbm(y = 2, x = 3:9, training_frame = prostate.hex, nfolds = 5, distribution = "multinomial")
  Log.info("Build Speedy Random Forest Model")
  iris.srf = h2o.randomForest(x = c(2,3,4), y = 5, training_frame = iris.hex, ntree = 10)
  Log.info("Build BigData Random Forest Model")
  iris.drf = h2o.randomForest(x = c(2,3,4), y = 5, training_frame = iris.hex, ntree = 10, nfolds = 5)
  Log.info("Build Naive Bayes Model")
  iris.nb = h2o.naiveBayes(y = 5, x = 1:4, training_frame = iris.hex)
  Log.info("Build Deep Learning model")
  iris.dl = h2o.deeplearning(y = 5, x= 1:4, training_frame = iris.hex)

  # Predict on models and save results in R
  Log.info("Scoring on models and saving predictions to R")

  pred_df <- function(object, newdata) {
    h2o_pred = h2o.predict(object, newdata)
    as.data.frame(h2o_pred)
  }
  glm.pred = pred_df(object = prostate.glm, newdata = prostate.hex)
  gbm.pred = pred_df(object = prostate.gbm, newdata = prostate.hex)
  srf.pred = pred_df(object =     iris.srf, newdata = iris.hex)
  drf.pred = pred_df(object =     iris.drf, newdata = iris.hex)
   nb.pred = pred_df(object =      iris.nb, newdata = iris.hex)
   dl.pred = pred_df(object =      iris.dl, newdata = iris.hex)

  # Save models to disk
  Log.info("Saving models to disk")
  dir1 = sandboxMakeSubDir(dirname="tmp")
  prostate.glm.path = h2o.download_model(model = prostate.glm, path = dir1)
  prostate.gbm.path = h2o.download_model(model = prostate.gbm, path = dir1)
      iris.srf.path = h2o.download_model(model =     iris.srf, path = dir1)
      iris.drf.path = h2o.download_model(model =     iris.drf, path = dir1)
       iris.nb.path = h2o.download_model(model =      iris.nb, path = dir1)
       iris.dl.path = h2o.download_model(model =      iris.dl, path = dir1)

  # All keys removed to test that cross validation models are actually being loaded
  h2o.removeAll()

  # Proving we can move files from one directory to another and not affect the load of the model
  dir2 = sandboxRenameSubDir(dir1,"tmp2")
  Log.info(paste("Moving models from", dir1, "to", dir2))

  model_paths = c(prostate.glm.path, prostate.gbm.path, iris.srf.path, iris.drf.path, iris.nb.path, iris.dl.path)
  new_model_paths = {}
  for (path in model_paths) {
    new_path = paste(dir2,basename(path),sep = .Platform$file.sep)
    new_model_paths = append(new_model_paths, new_path)
  }

  # Check to make sure predictions made on loaded model is the same as glm.pred
  prostate.hex = h2o.importFile(normalizePath(locate('smalldata/logreg/prostate.csv')))
      iris.hex = h2o.importFile(normalizePath(locate('smalldata/iris/iris.csv')))

  Log.info(paste("Model saved in", dir2))

  reloaded_models = {}
  for(path in new_model_paths) {
    Log.info(paste("Loading model from",path,sep=" "))
    model_obj = h2o.loadModel(path)
    reloaded_models = append(x = reloaded_models, values = model_obj)
  }

  Log.info("Running Predictions for Loaded Models")
  glm2 = reloaded_models[[1]]
  gbm2 = reloaded_models[[2]]
  srf2 = reloaded_models[[3]]
  drf2 = reloaded_models[[4]]
   nb2 = reloaded_models[[5]]
   dl2 = reloaded_models[[6]]

  glm.pred2 = pred_df(object = glm2, newdata = prostate.hex)
  gbm.pred2 = pred_df(object = gbm2, newdata = prostate.hex)
  srf.pred2 = pred_df(object = srf2, newdata = iris.hex)
  drf.pred2 = pred_df(object = drf2, newdata = iris.hex)
   nb.pred2 = pred_df(object =  nb2, newdata = iris.hex)
   dl.pred2 = pred_df(object =  dl2, newdata = iris.hex)

## Check to make sure scores are the same
  expect_equal(nrow(glm.pred), 380)
  expect_equal(nrow(gbm.pred), 380)
  expect_equal(nrow(drf.pred), 150)
  expect_equal(nrow( nb.pred), 150)
  expect_equal(nrow( dl.pred), 150)
  expect_equal(nrow(srf.pred), 150)
  expect_equal(glm.pred, glm.pred2)
  expect_equal(gbm.pred, gbm.pred2)
  expect_equal(drf.pred, drf.pred2)
  expect_equal( nb.pred,  nb.pred2)
  expect_equal( dl.pred,  dl.pred2)
  expect_equal(srf.pred, srf.pred2)

}

doTest("PUBDEV-7135 Test: Download binary Model", test.pubdev_7135)
