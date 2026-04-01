#' Read tier metadata in in EAF/ETF/ECV file(s)
#'
#' @description
#' Reads the tier metadata in ELAN file(s) (.eaf/.etf/.ecv)
#' from a single file or a vector of files as input.
#'
#' @details
#' If `full_path` is set to `FALSE` (default), the input file names
#' will be listed with their base names only, without the full path.
#'
#' If `progress` is set to `TRUE` (defaults to `FALSE`), a progress bar
#' is printed to the console to show the iteration across input files.
#'
#' @param file Path(s) to ELAN file(s) (.eaf/.etf/.ecv)
#' @param full_path Whether file names should include full path (defaults to `FALSE`)
#' @param progress Whether to display a progress bar (defaults to `FALSE`)
#'
#' @return Data frame of ELAN tier metadata
#' @export
#'
#' @examples
#' eaf_file <- system.file("extdata", "example.eaf", package = "readelan", mustWork = TRUE)
#' read_tiers(eaf_file)
#'
#' etf_file <- system.file("extdata", "CLP_annotation_v2-2.etf", package = "readelan", mustWork = TRUE)
#' read_tiers(etf_file)
#'
read_tiers <- function(file,
                       full_path = FALSE,
                       progress = FALSE) {

  # Check input format
  stopifnot("`file` input needs to be EAF, ETF or ECV format (.eaf/.etf/.ecv)!" = all(tools::file_ext(file) %in% c("eaf", "etf", "ecv")))
  stopifnot("`file` does not exist!" = all(file.exists(file) | (startsWith(file, "http"))))

  # Initiate progress bar if selected
  if (progress) {
    pb <- utils::txtProgressBar(min = 0,
                                max = length(file),
                                initial = 1,
                                char = "=",
                                style = 3)
  }

  # Iterate over all input files to read tiers
  all_eafs <-
    lapply(seq_along(file),
           function(i) {

             # Store file name based on input
             if (!full_path) {
               fname <- basename(file[i])
             } else {
               fname <- file[i]
             }

             # Update progress bar if used
             if (progress) {
               utils::setTxtProgressBar(pb, i)
             }

             # Read EAF as XML
             eaf <- xml2::read_xml(file[i])

             time_unit <- xml2::xml_attr(xml2::xml_find_first(eaf, ".//HEADER"), "TIME_UNITS")

             # Extract linguistic type data
             lingtype_nodes <- xml2::xml_find_all(eaf, ".//LINGUISTIC_TYPE")

             # Extract linguistic type data
             tier_nodes <- xml2::xml_find_all(eaf, ".//TIER")

             # Check that length is not zero
             if (length(lingtype_nodes) > 0) {

               # Iterate through tier types to extract data
               lingtypes <-
                 lapply(
                   lingtype_nodes,
                   function(x) {
                     c(filename = fname,
                       tier_type = xml2::xml_attr(x, "LINGUISTIC_TYPE_ID"),
                       constraint = xml2::xml_attr(x, "CONSTRAINTS"),
                       cv_ref = xml2::xml_attr(x, "CONTROLLED_VOCABULARY_REF"))
                   }
                 )

               # Bind rows together
               all_lingtypes <- do.call(rbind, lingtypes)
             }

             # Check that length is not zero
             if (length(tier_nodes) > 0) {

               # Iterate through annotations to extract hierarchical data (up/down)
               tiers <-
                 lapply(
                   tier_nodes,
                   function(x) {
                     c(filename = fname,
                       tier = xml2::xml_attr(x, "TIER_ID"),
                       tier_type = xml2::xml_attr(x, "LINGUISTIC_TYPE_REF"),
                       participant = xml2::xml_attr(x, "PARTICIPANT"),
                       annotator = xml2::xml_attr(x, "ANNOTATOR"),
                       parent_ref = xml2::xml_attr(x, "PARENT_REF"),
                       language_ref = xml2::xml_attr(x, "LANG_REF"))
                   }
                 )

               # Bind rows together
               all_tiers <- do.call(rbind, tiers)
             }

             # Check that both data frames exist and merge them
             if (all(exists("all_tiers"), exists("all_lingtypes"))) {
               merge(all_tiers,
                     all_lingtypes,
                     by.x = c("filename", "tier_type"),
                     by.y = c("filename", "tier_type"),
                     sort = FALSE)
             } else {
               data.frame()
             }

           }

    )

  # Bind data frames together
  do.call(rbind, all_eafs)

}
