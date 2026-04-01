#' Read controlled vocabularies (CV) in EAF/ETF file(s)
#'
#' @description
#' Reads the controlled vocabularies in ELAN (.eaf/.etf/.ecv) file(s)
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
#' @param ecv Whether to read linked external CVs as well (defaults to `TRUE`)
#' @param progress Whether to display a progress bar (defaults to `FALSE`)
#'
#' @return Data frame of the ELAN media metadata
#' @export
#'
#' @examples
#' eaf_file <- system.file("extdata", "example.eaf", package = "readelan", mustWork = TRUE)
#' read_cv(eaf_file, ecv = FALSE)
#'
#' # External CVs (.ecv files) can also be read
#' ecv_file <- system.file("extdata", "syntax.ecv", package = "readelan", mustWork = TRUE)
#' read_cv(ecv_file, ecv = FALSE)
#'
read_cv <- function(file,
                    full_path = FALSE,
                    ecv = TRUE,
                    progress = FALSE) {

  # Check input format
  stopifnot("`file` input needs to be EAF, ETF or ECV format (.eaf/.etf/.ecv)!" = all(tools::file_ext(file) %in% c("eaf", "etf", "ecv")))
  stopifnot("`file` does not exist!" = all(file.exists(file) | (startsWith(file, "http"))))
  stopifnot('`ecv` has to be one of TRUE or FALSE"!' = is.logical(ecv))

  # Define function to read a single file's CVs
  file_to_cv <- function(eaf, filename, url = NA) {

    # Read input as XML
    xml <- xml2::read_xml(eaf)

    # Find CV nodeset
    ns <- xml2::xml_children(xml2::xml_children(xml2::xml_find_all(xml, ".//CONTROLLED_VOCABULARY")))

    # Extract linguistic type data
    langtypes <- xml2::xml_find_all(xml, ".//LANGUAGE")

    # Make key/value vector from linguistic type data
    lang_vector <-
      mapply(
        function(id, lang) id = lang,
        xml2::xml_attr(langtypes, "LANG_ID"),
        xml2::xml_attr(langtypes, "LANG_LABEL")
      )

    # Iterate over all CVs
    list_cv <-
      lapply(
        ns,
        function(x) {
          parent <- xml2::xml_parent(x)
          c(filename = NA,
            url = url,
            cv_id = xml2::xml_attr(xml2::xml_parent(parent), "CV_ID"),
            cve_id = xml2::xml_attr(parent, "CVE_ID"),
            lang_ref = xml2::xml_attr(x, "LANG_REF"),
            language = NA,
            value = xml2::xml_text(x))
        }
      )

    # Bind together as a data frame
    df_cv <- as.data.frame(do.call(rbind, list_cv))

    # Check that lengths are not zero
    if (length(df_cv) > 0) {
      df_cv$filename <- filename

      if (length(lang_vector) > 0) {
        df_cv$language <- lang_vector[df_cv$lang_ref]
      }

    }

    df_cv

  }

  # Initiate progress bar if selected
  if (progress) {
    pb <- utils::txtProgressBar(min = 0,
                                max = length(file),
                                initial = 1,
                                char = "=",
                                style = 3)
  }

  # Iterate over all input files to read CVs
  all_cvs <-
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

             # Current file
             eaf <- file[i]

             # Read CVs of current file
             cvs <- file_to_cv(eaf, fname)

             # Read external CVs if selected
             if (ecv) {

               # Find URLs to external CVs
               ecv_urls <- xml2::xml_attr(xml2::xml_find_all(xml2::read_xml(eaf), ".//EXTERNAL_REF[@TYPE='ecv']"), "VALUE")

               # Iterate over URLs to read external CVs
               ecvs <-
                 lapply(
                   ecv_urls,
                   function(x) file_to_cv(x, fname, url = x)
                 )

               # Bind external CVs together
               external <- do.call(rbind, ecvs)

               # Bind together with internal CVs
               cvs <- do.call(rbind, list(cvs, external))
             }

             # Check that length is not zero
             if (length(cvs) > 0) {
               cvs
             } else {
                 data.frame()
               }

             }

           )

  # Bind data frames together
  do.call(rbind, all_cvs)

}
