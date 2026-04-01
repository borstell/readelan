#' Read media metadata in EAF file(s)
#'
#' @description
#' Reads the media metadata in ELAN (.eaf) file(s)
#' from a single file or a vector of files as input.
#'
#' @details
#' If `full_path` is set to `FALSE` (default), the input file names
#' will be listed with their base names only, without the full path.
#'
#' If `progress` is set to `TRUE` (defaults to `FALSE`), a progress bar
#' is printed to the console to show the iteration across input files.
#'
#' @param file Path(s) to ELAN annotation file(s) (.eaf)
#' @param full_path Whether file names should include full path (defaults to `FALSE`)
#' @param progress Whether to display a progress bar (defaults to `FALSE`)
#'
#' @return Data frame of ELAN media metadata
#' @export
#'
#' @examples
#' eaf_file <- system.file("extdata", "example.eaf", package = "readelan", mustWork = TRUE)
#' read_media(eaf_file)
#'
read_media <- function(file,
                       full_path = FALSE,
                       progress = FALSE) {
  # Check input format
  stopifnot("`file` input needs to be EAF format (.eaf)!" = all(tools::file_ext(file) == "eaf"))
  stopifnot("`file` does not exist!" = all(file.exists(file) | (startsWith(file, "http"))))

  # Initiate progress bar if selected
  if (progress) {
    pb <- utils::txtProgressBar(min = 0,
                                max = length(file),
                                initial = 1,
                                char = "=",
                                style = 3)
  }

  # Iterate over all input files to read media metadata
  all_media <-
    lapply(seq_along(file),
           function(i) {

             # Store file name based on input
             if (!full_path) {
               fname <- basename(file[i])
             } else {
               fname <- file[i]
             }

             # Read EAF as XML
             eaf <- xml2::read_xml(file[i])

             urls <- xml2::xml_attrs(xml2::xml_find_all(xml2::xml_children(eaf), ".//MEDIA_DESCRIPTOR"))

             media_df <-
               lapply(
                 seq_along(urls),
                 function(j) {
                   df <- utils::stack(as.list(urls[[j]]))
                   colnames(df) <- c("value", "attribute")
                   df$item <- j
                   df$filename <- fname
                   df[4:1]
                 }
               )

             # Update progress bar if used
             if (progress) {
               utils::setTxtProgressBar(pb, i)
             }

             # Return all annotations as a data frame
             do.call(rbind, media_df)

           }

    )

  # Bind data frames together
  do.call(rbind, all_media)
}
