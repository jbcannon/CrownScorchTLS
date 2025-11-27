#' tree_005.laz Example segmented longleaf pine LAS tree
#'
#' A small LAS object representing a segmented longleaf pine tree after crown scorch,
#' from Cannon et al. (2025). Complete data from article can be found at
#' https://github.com/jbcannon/CrownScorchTLS-data
#'
#' @name tree_005.laz
#' @format External .laz file representing a LAS tree
#' @source Cannon, J., et al. 2025. [https://doi.org/10.1186/s42408-025-00420-0]
#' @examples
#' las_file <- system.file("extdata", "tree_005.laz", package = "CrownScorchTLS")
#' las <- readLAS(las_file)

#' RF_scorch_int.RDS Default random forest model for predicting crown scorch
#'
#' This `randomForest` model was trained on segmented longleaf pine trees collected
#' using a RIEGL vz400i terrestrial lidar scanner, following Cannon et al. (2025).
#' Users may train custom models for other species or instrumentation.
#' @name RF_scorch_int.RDS
#' @format A `randomForest` object saved as an `.RDS` file
#' @source Cannon, J., et al. 2025. [https://doi.org/10.1186/s42408-025-00420-0]
#' @examples
#' model_file <- system.file("extdata", "RF_scorch_int.RDS", package = "CrownScorchTLS")
#' model.RF <- readRDS(model_file)
#' print(model.RF)
