#' Read annotations in EAF file(s)
#'
#' @description
#' Reads the annotations in ELAN annotation file(s) (.eaf)
#' from a single file or a vector of files as input.
#'
#' @details
#' Specific tiers or tier types can be targeted with a named list,
#' `tiers = list(tier = "tier1", tier_type = c("tier_type1", "tier_type2"))`,
#' or a custom XPath input, `xpath = ".//TIER[starts-with(@TIER_ID,'gloss')]"`.
#' A valid `tier` input will override any simultaneous `xpath` input.
#'
#' If `fill_times` is set to `TRUE` (default), the time slots of child
#' annotations will be filled with the values of their parent annotations.
#'
#' If `full_path` is set to `FALSE` (default), the input file names
#' will be listed with their base names only, without the full path.
#'
#' If `progress` is set to `TRUE` (defaults to `FALSE`), a progress bar
#' is printed to the console to show the iteration across input files.
#'
#' @param file Path(s) to ELAN annotation file(s) (.eaf)
#' @param tiers Specify tiers (TIER_ID or TIER_TYPE) to be read
#' @param xpath Specify a detailed XPath for tiers to be read
#' @param fill_times Fill empty time slots of child annotations (defaults to `TRUE`)
#' @param full_path Whether file names should include full path (defaults to `FALSE`)
#' @param progress Whether to display a progress bar (defaults to `FALSE`)
#'
#' @return Data frame of ELAN annotations
#' @export
#'
#' @examples
#' eaf_file <- system.file("extdata", "example.eaf", package = "readelan", mustWork = TRUE)
#' read_eaf(eaf_file)
#'
read_eaf <- function(file,
                     tiers,
                     xpath,
                     fill_times = TRUE,
                     full_path = FALSE,
                     progress = FALSE) {

  # Check input format
  stopifnot("`file` input needs to be EAF format (.eaf)!" = all(tools::file_ext(file) == "eaf"))
  stopifnot("`file` does not exist!" = all(file.exists(file) | (startsWith(file, "http"))))

  # Specify tiers to read if there is an input to `tiers` or `xpath`
  if (!missing(tiers) && length(names((tiers))) > 0) {
    names(tiers) <- gsub("^TIER_TYPE$", "LINGUISTIC_TYPE_REF", gsub("^TIER$", "TIER_ID", toupper(names(tiers))))
    keys <- toupper(rep(names(tiers), sapply(tiers, length)))
    vals <- unlist(tiers)
    tier_attrs <- paste0(".//TIER[", paste0("@", keys, "='", vals, "'", collapse = " or "), "]")
  } else if (!missing(xpath) && xpath != "") {
    tier_attrs <- xpath
  } else {
    tier_attrs <- ".//TIER"
  }

  # Initiate progress bar if selected
  if (progress) {
    pb <- utils::txtProgressBar(min = 0,
                                max = length(file),
                                initial = 1,
                                char = "=",
                                style = 3)
  }

  # Iterate over all input files to read annotations
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

             # Read all annotation nodes and get their and their parents' attributes
             annotation_nodes <- xml2::xml_children(xml2::xml_children(xml2::xml_find_all(eaf, tier_attrs)))

             time_unit <- xml2::xml_attr(xml2::xml_find_first(eaf, ".//HEADER"), "TIME_UNITS")

             # Check that annotations were present in the file
             if (length(annotation_nodes) > 0) {

               # Extract timeslot data
               timeslots <- xml2::xml_find_all(eaf, ".//TIME_SLOT")

               # Make key/value vector from timeslot data
               time_vector <-
                 mapply(
                   function(id, ms) id = ms,
                   xml2::xml_attr(timeslots, "TIME_SLOT_ID"),
                   as.numeric(xml2::xml_attr(timeslots, "TIME_VALUE"))
                 )

               # Extract linguistic type data
               lingtypes <- xml2::xml_find_all(eaf, ".//LINGUISTIC_TYPE")

               # Make key/value vector from linguistic type data
               type_vector <-
                 mapply(
                   function(id, cv) id = cv,
                   xml2::xml_attr(lingtypes, "LINGUISTIC_TYPE_ID"),
                   xml2::xml_attr(lingtypes, "CONTROLLED_VOCABULARY_REF")
                 )

               # Iterate through annotations to extract hierarchical data (up/down)
               annotations <-
                 lapply(
                   annotation_nodes,
                   function(x) {
                     parent <- xml2::xml_parent(xml2::xml_parent(x))
                     c(filename = fname,
                       a = xml2::xml_attr(x, "ANNOTATION_ID"),
                       time_1 = xml2::xml_attr(x, "TIME_SLOT_REF1"),
                       time_2 = xml2::xml_attr(x, "TIME_SLOT_REF2"),
                       annotation = xml2::xml_text(x),
                       tier = xml2::xml_attr(parent, "TIER_ID"),
                       tier_type = xml2::xml_attr(parent, "LINGUISTIC_TYPE_REF"),
                       participant = xml2::xml_attr(parent, "PARTICIPANT"),
                       annotator = xml2::xml_attr(parent, "ANNOTATOR"),
                       parent_ref = xml2::xml_attr(parent, "PARENT_REF"),
                       a_ref = xml2::xml_attr(x, "ANNOTATION_REF"),
                       language_ref = xml2::xml_attr(parent, "LANG_REF"),
                       cv_id = NA,
                       cve_ref = xml2::xml_attr(x, "CVE_REF"))
                   }
                 )

               # Combine annotations into a data frame
               all_annotations <- as.data.frame(do.call(rbind, annotations))

               # If `fill_times = TRUE` (default): fill child tier times from parents
               if (fill_times & anyNA(all_annotations$time_1)) {
                 # Subset parent tiers
                 parent_annotations <- all_annotations[which(!is.na(all_annotations$time_1)), ]

                 # Subset child tiers
                 child_annotations <- all_annotations[which(is.na(all_annotations$time_1)), ][-(3:4)]
                 child_annotations <- merge(child_annotations,
                                            parent_annotations[c(1:4, 6)],
                                            by.x = c("filename", "a_ref", "parent_ref"),
                                            by.y = c("filename", "a", "tier"),
                                            sort = FALSE)

                 # Recombine data
                 all_annotations <-
                   do.call(
                     rbind,
                     c(list(parent_annotations, child_annotations), make.row.names = FALSE))
               }

               # Add timestamp data from named vector
               all_annotations$start <- time_vector[all_annotations$time_1]
               all_annotations$end <- time_vector[all_annotations$time_2]
               all_annotations$duration <- all_annotations$end - all_annotations$start
               all_annotations$time_unit <- time_unit

               # Fill any CV IDs from the tier type data
               all_annotations$cv_id <- type_vector[all_annotations$tier_type]

               # Return all annotations as a data frame
               all_annotations

               }

             }

           )

  # Bind data frames together
  do.call(rbind, all_eafs)

}
