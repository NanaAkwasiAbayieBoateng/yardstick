#' Calculate sensitivity, specificity and predictive values
#'
#' These functions calculate the sensitivity, specificity or
#'  predictive values of a measurement system compared to a
#'  reference results (the truth or a gold standard). The
#'  measurement and "truth" data must have the same two possible
#'  outcomes and one of the outcomes must be thought of as a
#'  "positive" results or the "event".
#'
#' The sensitivity is defined as the proportion of positive
#'  results out of the number of samples which were actually
#'  positive. When there are no positive results, sensitivity is not
#'  defined and a value of `NA` is returned. Similarly, when
#'  there are no negative results, specificity is not defined and a
#'  value of `NA` is returned. Similar statements are true for
#'  predictive values. 
#'
#' The positive predictive value is defined as the percent of
#'  predicted positives that are actually positive while the
#'  negative predictive value is defined as the percent of negative
#'  positives that are actually negative.
#'
#' TODO mention prob interpretations
#'
#' Suppose a 2x2 table with notation
#'
#' \tabular{rcc}{ \tab Reference \tab \cr Predicted \tab Event \tab No Event
#' \cr Event \tab A \tab B \cr No Event \tab C \tab D \cr }
#'
#' The formulas used here are: \deqn{Sensitivity = A/(A+C)} \deqn{Specificity =
#' D/(B+D)} \deqn{Prevalence = (A+C)/(A+B+C+D)} \deqn{PPV = (sensitivity *
#' Prevalence)/((sensitivity*Prevalence) + ((1-specificity)*(1-Prevalence)))}
#' \deqn{NPV = (specificity * (1-Prevalence))/(((1-sensitivity)*Prevalence) +
#' ((specificity)*(1-Prevalence)))}
#'
#' See the references for discussions of the statistics.
#'
#' @aliases sens sens.default sens.table sens.matrix spec
#'  spec.default spec.table spec.matrix ppv ppv.default ppv.table
#'  ppv.matrix npv npv.default npv.table npv.matrix
#' @param data For the default functions, a factor containing the
#'  discrete measurements. For the `table` or `matrix`
#'  functions, a table or matrix object, respectively.
#' @param truth A single character value containing the column
#'  name of `data` that contains the true classes (in a factor).
#' @param estimate A single character value containing the column
#'  name of `data` that contains the predicted classes (in a factor).
#' @param prevalence A numeric value for the rate of the
#'  "positive" class of the data.
#' @param na.rm A logical value indicating whether `NA`
#'  values should be stripped before the computation proceeds
#' @param ... Not currently used.
#' @return A number between 0 and 1 (or NA).
#' @author Max Kuhn
#' @seealso [conf_mat()]
#' @references Altman, D.G., Bland, J.M. (1994) ``Diagnostic tests 1:
#'  sensitivity and specificity,'' *British Medical Journal*,
#'  vol 308, 1552.
#'
#'   Altman, D.G., Bland, J.M. (1994) ``Diagnostic tests 2:
#'  predictive values,'' *British Medical Journal*, vol 309,
#'  102.
#' @keywords manip
#' @examples
#'
#'
#' @export sens
sens <- function(data, ...)
  UseMethod("sens")

#' @export
#' @rdname sens
sens.data.frame  <-
  function(data, truth = NULL, estimate = NULL, na.rm = TRUE, ...) {
    check_call_vars(match.call(expand.dots = TRUE))
    xtab <- vec2table(
      truth = get_col(data, truth),
      estimate = get_col(data, estimate),
      na.rm = na.rm,
      two_class = TRUE,
      dnn = c("Prediction", "Truth"),
      ...
    )
    sens.table(xtab, ...)
  }

#' @rdname sens
#' @export
"sens.table" <-
  function(data, ...) {
    ## "truth" in columns, predictions in rows
    check_table(data)
    
    positive <- pos_val(data)
    numer <- sum(data[positive, positive])
    denom <- sum(data[, positive])
    sens <- ifelse(denom > 0, numer / denom, NA)
    sens
  }

#' @rdname sens
"sens.matrix" <-
  function(data, ...) {
    data <- as.table(data)
    sens.table(data)
  }


#' @export
spec <-  function(data, ...)
  UseMethod("spec")


#' @export
#' @rdname sens
spec.data.frame  <-
  function(data, truth = NULL, estimate = NULL, na.rm = TRUE, ...) {
    check_call_vars(match.call(expand.dots = TRUE))
    xtab <- vec2table(
      truth = get_col(data, truth),
      estimate = get_col(data, estimate),
      na.rm = na.rm,
      two_class = TRUE,
      dnn = c("Prediction", "Truth"),
      ...
    )
    
    spec.table(xtab, ...)
  }


#' @export
"spec.table" <-
  function(data, negative = rownames(data)[-1], ...) {
    ## "truth" in columns, predictions in rows
    check_table(data)
    
    negative <- neg_val(data)
    
    numer <- sum(data[negative, negative])
    denom <- sum(data[, negative])
    spec <- ifelse(denom > 0, numer / denom, NA)
    spec
  }

"spec.matrix" <-
  function(data, negative = rownames(data)[-1], ...) {
    data <- as.table(data)
    spec.table(data)
  }

#' @rdname sens
#' @export
ppv <- function(data, ...)
  UseMethod("ppv")

#' @export
ppv.data.frame  <-
  function(data, truth = NULL, estimate = NULL, 
           na.rm = TRUE, prevalence = NULL, ...) {
    check_call_vars(match.call(expand.dots = TRUE))
    xtab <- vec2table(
      truth = get_col(data, truth),
      estimate = get_col(data, estimate),
      na.rm = na.rm,
      two_class = TRUE,
      dnn = c("Prediction", "Truth"),
      ...
    )
    lev <- if (getOption("yardstick.event_first"))
      colnames(xtab)[1]
    else
      colnames(xtab)[2]
    
    ppv.table(xtab, prevalence = prevalence, ...)
  }

#' @rdname sens
#' @export
"ppv.table" <-
  function(data, prevalence = NULL, ...) {
    ## "truth" in columns, predictions in rows
    check_table(data)
    
    positive <- pos_val(data)
    negative <- neg_val(data)
    
    if (is.null(prevalence))
      prevalence <- sum(data[, positive]) / sum(data)
    
    sens <- sensitivity(data, positive)
    spec <- specificity(data, negative)
    (sens * prevalence) / ((sens * prevalence) + ((1 - spec) * (1 - prevalence)))
    
  }

#' @rdname sens
#' @export
"ppv.matrix" <-
  function(data, prevalence = NULL, ...) {
    data <- as.table(data)
    ppv.table(data, prevalence = prevalence)
  }

#' @rdname sens
#' @export
npv <- function(data, ...)
  UseMethod("npv")

#' @export
npv.data.frame  <-
  function(data, truth = NULL, estimate = NULL, 
           na.rm = TRUE, prevalence = NULL, ...) {
    check_call_vars(match.call(expand.dots = TRUE))
    xtab <- vec2table(
      truth = get_col(data, truth),
      estimate = get_col(data, estimate),
      na.rm = na.rm,
      two_class = TRUE,
      dnn = c("Prediction", "Truth"),
      ...
    )
    lev <- if (getOption("yardstick.event_first"))
      colnames(xtab)[2]
    else
      colnames(xtab)[1]
    
    npv.table(xtab, prevalence = prevalence, ...)
  }

#' @rdname sens
#' @export
"npv.table" <-
  function(data, prevalence = NULL, ...) {
    ## "truth" in columns, predictions in rows
    check_table(data)
    
    positive <- pos_val(data)
    negative <- neg_val(data)
    
    if (is.null(prevalence))
      prevalence <- sum(data[, positive]) / sum(data)
    
    sens <- sensitivity(data, positive)
    spec <- specificity(data, negative)
    (spec * (1 - prevalence)) / (((1 - sens) * prevalence) + ((spec) * (1 - prevalence)))
    
  }

#' @rdname sens
#' @export
"npv.matrix" <-
  function(data, prevalence = NULL, ...) {
    data <- as.table(data)
    npv.table(data, prevalence = prevalence)
  }
