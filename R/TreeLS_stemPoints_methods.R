# ===============================================================================
#
# Developers:
#
# Tiago de Conto - tdc.florestal@gmail.com -  https://github.com/tiagodc/
#
# COPYRIGHT: Tiago de Conto, 2020
#
# This piece of software is open and free to use, redistribution and modifications
# should be done in accordance to the GNU General Public License >= 3
# Use this software as you wish, but no warranty is provided whatsoever. For any
# comments or questions on TreeLS, please contact the developer (prefereably through my github account)
#
# If publishing any work/study/research that used the tools in TreeLS,
# please don't forget to cite the proper sources!
#
# Enjoy!
#
# ===============================================================================
#' Stem points classification
#' @description Classify stem points of all trees in a \strong{normalized}
#' point cloud. Stem denoising methods are prefixed by \code{stm}.
#' This file includes code derived from the TreeLS package by Tiago de Conto
#' Original source: https://github.com/tiagodc/TreeLS
#' License: GPL-3
#' The code below is copied and adapted from TreeLS::stemPoints for the purpose
#' of maintaining CRAN compatibility. All modifications are clearly documented.
#' @param las \code{\link[lidR:LAS]{LAS}} object.
#' @param method stem denoising algorithm. Currently available: \code{\link{stm.hough}}, \code{\link{stm.eigen.knn}} and \code{\link{stm.eigen.voxel}}.
#' @return \code{\link[lidR:LAS]{LAS}} object.
#' @references
#' Carvalho, T. (2017). TreeLS: Tools for Terrestrial LiDAR in R.
#'   GitHub: https://github.com/tiagodc/TreeLS
#' @note This function includes code derived from TreeLS::stemPoints
#'   (GPL-3 license). See source for details.
#' @examples
#' ### single tree
#' file = system.file("extdata", "spruce.laz", package="TreeLS")
#' tls = readTLS(file) %>%
#'   tlsNormalize %>%
#'   stemPoints(stm.hough(h_base = c(.5,2)))
#' plot(tls, color='Stem')
#'
#' ### entire forest plot
#' file = system.file("extdata", "pine_plot.laz", package="TreeLS")
#' tls = readTLS(file) %>%
#'   tlsNormalize %>%
#'   tlsSample
#'
#' map = treeMap(tls, map.hough())
#' tls = treePoints(tls, map, trp.crop(circle=FALSE))
#' tls = stemPoints(tls, stm.hough(pixel_size = 0.03))
#' tlsPlot(tls)
#' @export
stemPoints = function(las, method = stm.hough()){

  if(!'TreeID' %in% colnames(las@data)){
    rg = as.double(apply(las@data[,1:2], 2, function(x) max(x) - min(x)))
    if(any(rg > 15))
      message("point cloud unlikely a single tree (XY extents too large)")
  }
  if(max(las$Z) < 0)
    stop('input Z coordinates are all negative')
  if(abs(min(las$Z)) > 0.5)
    warning('point cloud apparently not normalized')
  las = method(las)
  las@data[is.na(las$Stem)]$Stem = FALSE
  las@data$Stem <- as.logical(las@data$Stem)
  return(las)
}


#' Stem denoising algorithm: Hough Transform
#' @description This function is meant to be used inside \code{\link{stemPoints}}. It applies an adapted version of the Hough Transform for circle search. Mode details are given in the sections below.
#' This file includes code derived from the TreeLS package by Tiago de Conto
#' Original source: https://github.com/tiagodc/TreeLS
#' License: GPL-3
#' The code below is copied and adapted from TreeLS::stemPoints for the purpose
#' of maintaining CRAN compatibility. All modifications are clearly documented.
#' @param las \code{\link[lidR:LAS]{LAS}} object.
#' @param method stem denoising algorithm. Currently available: \code{\link{stm.hough}}, \code{\link{stm.eigen.knn}} and \code{\link{stm.eigen.voxel}}.
#' @return \code{\link[lidR:LAS]{LAS}} object.
#' @template param-h_step
#' @template param-max-d
#' @template param-hbase
#' @template param-pixel-size
#' @template param-min-density
#' @template param-min-votes
#' @references
#' Carvalho, T. (2017). TreeLS: Tools for Terrestrial LiDAR in R.
#'   GitHub: https://github.com/tiagodc/TreeLS
#' @note This function includes code derived from TreeLS::stemPoints
#'   (GPL-3 license). See source for details.
#' @section \code{LAS@data} Special Fields:
#'
#' Meaninful new fields in the output:
#'
#' \itemize{
#' \item \code{Stem}: \code{TRUE} for stem points
#' \item \code{Segment}: stem segment number (from bottom to top and nested with TreeID)
#' \item \code{Radius}: approximate radius of the point's stem segment estimated by the Hough Transform - always a multiple of the \code{pixel_size}
#' \item \code{Votes}: votes received by the stem segment's center through the Hough Transform
#' }#'
#' @template section-hough-transform
#' @template reference-olofsson
#' @template reference-thesis
#' @export
stm.hough = function(h_step=0.5, max_d=0.5, h_base = c(1,2.5), pixel_size=0.025, min_density=0.1, min_votes=3){

  if(length(h_base) != 2)
    stop('h_base must be a numeric vector of length 2')

  if(diff(h_base) <= 0)
    stop('h_base[2] must be larger than h_base[1]')

  params = list(
    h_step = h_step,
    max_d = max_d,
    pixel_size = pixel_size,
    min_density = min_density,
    min_votes = min_votes
  )

  for(i in names(params)){
    val = params[[i]]

    if(length(val) != 1)
      stop( paste(i, 'must be of length 1') )

    if(!is.numeric(val))
      stop( paste(i, 'must be Numeric') )

    if(val <= 0)
      stop( paste(i, 'must be positive') )
  }

  if(min_density > 1)
    stop('min_density must be between 0 and 1')

  func = function(las){

    if(min(las$Z) < 0)
      message("points with Z below 0 will be ignored")

    if(min(las$Z) > 5)
      message("point cloud doesn't look normalized (Z values too high) - check ?tlsNormalize")

    survey_points = if(!'Classification' %in% colnames(las@data)){
      las$Classification != 2
    } else{
      rep(TRUE, nrow(las@data))
    }

    if(!'TreeID' %in% colnames(las@data)){
      message('no TreeID field found with tree_points signature: performing single stem point classification')
      results = houghStemPoints(las2xyz(las)[survey_points,], h_base[1], h_base[2], h_step, max_d/2, pixel_size, min_density, min_votes)
    }else{
      message('performing point classification on multiple stems')
      survey_points = survey_points & las$TreeID > 0
      results = houghStemPlot(las2xyz(las)[survey_points,], las@data$TreeID[survey_points], h_base[1], h_base[2], h_step, max_d/2, pixel_size, min_density, min_votes)
    }

    las@data$Stem = FALSE
    las@data$Stem[survey_points] = results$Stem

    las@data$Segment = 0
    las@data$Segment[survey_points] = results$Segment

    las@data$Radius = 0
    las@data$Radius[survey_points] = results$Radius

    las@data$Votes = 0
    las@data$Votes[survey_points] = results$Votes

    las = cleanFields(las, c('Radius', 'Votes'))

    return(las)

  }

  attr(func, "stem_pts_mtd") <- TRUE

  return(func)

}

las2xyz = function(las){

  if(class(las)[1] != "LAS")
    stop("las must be a LAS object")

  las = as.matrix(las@data[,c('X','Y','Z')])
  return(las)
}

hasField = function(las, field_name){
  if(class(las)[1] == 'LAS') las = las@data
  return(any(colnames(las) == field_name))
}

cleanFields = function(las, field_names){
  is_las = class(las)[1] == 'LAS'
  for(i in field_names){
    temp = if(is_las) las@data[,i,with=F] else las[,i,with=F]
    temp = unlist(temp)
    temp[is.na(temp) | is.nan(temp) | is.infinite(temp) | is.null(temp)] = ifelse(is.logical(temp), F, 0)
    if(is_las) las@data[,i] = temp else las[,i] = temp
  }
  return(las)
}

