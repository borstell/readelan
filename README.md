
<!-- README.md is generated from README.Rmd. Please edit that file -->

# readelan <img src="man/figures/logo.png" align="right" height="139" alt="" />

<!-- badges: start -->

[![CRAN
status](https://www.r-pkg.org/badges/version/readelan)](https://CRAN.R-project.org/package=readelan)
[![R-CMD-check](https://github.com/borstell/readelan/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/borstell/readelan/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The goal of `{readelan}` is to access the data (i.e., annotations) and
metadata (e.g., tier types/structure, linked media and controlled
vocabularies) in [ELAN](https://archive.mpi.nl/tla/elan) annotation
files (`.eaf`), template files (`.etf`) and external controlled
vocabulary files (`.ecv`) directly in R.

The `{readelan}` package is a fast yet lightweight package with only one
dependency outside of core packages, namely
[`{xml2}`](https://xml2.r-lib.org). The `{xml2}` package is central to
access the inner structure of ELAN files, which are all fundamentally
XML files.

## Installation

You can download the official release version of `{readelan}` from CRAN:

``` r
install.packages("readelan")
```

Alternatively, you can install the development version like so:

``` r
pak::pak("borstell/readelan")
```

## Basic use

### Reading annotations

The most obvious use of `{readelan}` is to be able to read annotations
directly from an `.eaf` file:

``` r
library(readelan)

eaf_file <- system.file("extdata", 
                        "example.eaf", 
                        package = "readelan")

read_eaf(eaf_file)
#>      filename  a time_1 time_2 annotation   tier  tier_type participant
#> 1 example.eaf a1    ts1    ts2          I  words default-lt        s001
#> 2 example.eaf a2    ts3    ts4       like  words default-lt        s001
#> 3 example.eaf a3    ts5    ts6       cats  words default-lt        s001
#> 4 example.eaf a4    ts1    ts2    pronoun    pos        pos        s001
#> 5 example.eaf a7    ts1    ts2    subject syntax     syntax        s001
#> 6 example.eaf a5    ts3    ts4       verb    pos        pos        s001
#> 7 example.eaf a8    ts3    ts4  predicate syntax     syntax        s001
#> 8 example.eaf a6    ts5    ts6       noun    pos        pos        s001
#> 9 example.eaf a9    ts5    ts6     object syntax     syntax        s001
#>   annotator parent_ref a_ref language_ref  cv_id
#> 1       ABC       <NA>  <NA>         <NA>   <NA>
#> 2       ABC       <NA>  <NA>         <NA>   <NA>
#> 3       ABC       <NA>  <NA>         <NA>   <NA>
#> 4       DEF      words    a1          eng    pos
#> 5       GHI      words    a1          eng syntax
#> 6       DEF      words    a2          eng    pos
#> 7       GHI      words    a2          eng syntax
#> 8       DEF      words    a3          eng    pos
#> 9       GHI      words    a3          eng syntax
#>                                      cve_ref start  end duration    time_unit
#> 1                                       <NA>   490 1590     1100 milliseconds
#> 2                                       <NA>  2010 3670     1660 milliseconds
#> 3                                       <NA>  4370 5980     1610 milliseconds
#> 4 cveid_89b2ac38-7313-4737-aa5f-19e1231ccb18   490 1590     1100 milliseconds
#> 5 cveid_4990ed36-c1d1-40c6-800e-2bd264d9a89b   490 1590     1100 milliseconds
#> 6 cveid_d5558ab7-11c3-47d5-9a0f-403724b0e0b7  2010 3670     1660 milliseconds
#> 7 cveid_de8c8f23-6b49-42da-9bd4-5b8b59d8b1da  2010 3670     1660 milliseconds
#> 8 cveid_f2eec815-c427-4b61-84eb-cd1e1601c9b4  4370 5980     1610 milliseconds
#> 9 cveid_f37323ed-9b7e-48d9-bbd6-b9105186ed02  4370 5980     1610 milliseconds
```

The `tiers` and `xpath` arguments in `read_eaf()` allow the user to
specify tiers of interest already on reading the files, which simplifies
and speeds up the process in cases where there are many tiers but only
some of which are necessary to import:

``` r
library(readelan)

eaf_file <- system.file("extdata", 
                        "example.eaf", 
                        package = "readelan")

read_eaf(eaf_file, tiers = list(tier = "words"))
#>      filename  a time_1 time_2 annotation  tier  tier_type participant
#> 1 example.eaf a1    ts1    ts2          I words default-lt        s001
#> 2 example.eaf a2    ts3    ts4       like words default-lt        s001
#> 3 example.eaf a3    ts5    ts6       cats words default-lt        s001
#>   annotator parent_ref a_ref language_ref cv_id cve_ref start  end duration
#> 1       ABC       <NA>  <NA>         <NA>  <NA>    <NA>   490 1590     1100
#> 2       ABC       <NA>  <NA>         <NA>  <NA>    <NA>  2010 3670     1660
#> 3       ABC       <NA>  <NA>         <NA>  <NA>    <NA>  4370 5980     1610
#>      time_unit
#> 1 milliseconds
#> 2 milliseconds
#> 3 milliseconds
```

### Reading controlled vocabularies (CVs)

Some ELAN files may contain [controlled
vocabularies](https://www.mpi.nl/tools/elan/docs/manual/index.html#Sec_Controlled_Vocabularies.html),
which are pre-defined sets of labels that can be used as annotation
values. The function `read_cv()` can extract all CVs from a file –
whether a regular annotation file (`.eaf`), a template file (`.etf`) or
an external CV file (`.ecv`):

``` r
library(readelan)

eaf_file <- system.file("extdata", 
                        "example.eaf", 
                        package = "readelan")

dplyr::glimpse(read_cv(eaf_file))
#> Rows: 12
#> Columns: 7
#> $ filename <chr> "example.eaf", "example.eaf", "example.eaf", "example.eaf", "…
#> $ url      <chr> NA, NA, NA, NA, NA, NA, "./inst/extdata/syntax.ecv", "./inst/…
#> $ cv_id    <chr> "pos", "pos", "pos", "pos", "pos", "pos", "syntax", "syntax",…
#> $ cve_id   <chr> "cveid_89b2ac38-7313-4737-aa5f-19e1231ccb18", "cveid_89b2ac38…
#> $ lang_ref <chr> "eng", "fin", "eng", "fin", "eng", "fin", "eng", "fin", "eng"…
#> $ language <chr> "English (eng)", "Finnish (fin)", "English (eng)", "Finnish (…
#> $ value    <chr> "pronoun", "pronomini", "verb", "verbi", "noun", "substantiiv…

etf_file <- system.file("extdata", 
                        "CLP_annotation_v2-2.etf", 
                        package = "readelan")

dplyr::glimpse(read_cv(etf_file))
#> Rows: 92
#> Columns: 7
#> $ filename <chr> "CLP_annotation_v2-2.etf", "CLP_annotation_v2-2.etf", "CLP_an…
#> $ url      <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ cv_id    <chr> "CLP scene", "CLP scene", "CLP scene", "CLP scene", "CLP scen…
#> $ cve_id   <chr> "cveid_be1d709d-9158-4278-a220-620d2df5ceef", "cveid_321f1558…
#> $ lang_ref <chr> "und", "und", "und", "und", "und", "und", "und", "und", "und"…
#> $ language <chr> "undetermined (und)", "undetermined (und)", "undetermined (un…
#> $ value    <chr> "1a", "1b", "1c", "2a", "2b", "2c", "2d", "3a", "3b", "3c", "…

ecv_file <- system.file("extdata", 
                        "syntax.ecv", 
                        package = "readelan")

dplyr::glimpse(read_cv(ecv_file))
#> Rows: 6
#> Columns: 7
#> $ filename <chr> "syntax.ecv", "syntax.ecv", "syntax.ecv", "syntax.ecv", "synt…
#> $ url      <chr> NA, NA, NA, NA, NA, NA
#> $ cv_id    <chr> "syntax", "syntax", "syntax", "syntax", "syntax", "syntax"
#> $ cve_id   <chr> "cveid_4990ed36-c1d1-40c6-800e-2bd264d9a89b", "cveid_4990ed36…
#> $ lang_ref <chr> "eng", "fin", "eng", "fin", "eng", "fin"
#> $ language <chr> "English (eng)", "Finnish (fin)", "English (eng)", "Finnish (…
#> $ value    <chr> "subject", "subjekti", "predicate", "predikaatti", "object", …
```

### Reading tier metadata

To access information about tiers in an annotation file (`.eaf`) or
template file (`.etf`), the `read_tiers()` function can be used:

``` r
library(readelan)

eaf_file <- system.file("extdata", 
                        "example.eaf", 
                        package = "readelan")

dplyr::glimpse(read_tiers(eaf_file))
#> Rows: 3
#> Columns: 9
#> $ filename     <chr> "example.eaf", "example.eaf", "example.eaf"
#> $ tier_type    <chr> "default-lt", "pos", "syntax"
#> $ tier         <chr> "words", "pos", "syntax"
#> $ participant  <chr> "s001", "s001", "s001"
#> $ annotator    <chr> "ABC", "DEF", "GHI"
#> $ parent_ref   <chr> NA, "words", "words"
#> $ language_ref <chr> NA, "eng", "eng"
#> $ constraint   <chr> NA, "Symbolic_Association", "Symbolic_Association"
#> $ cv_ref       <chr> NA, "pos", "syntax"

etf_file <- system.file("extdata", 
                        "CLP_annotation_v2-2.etf", 
                        package = "readelan")

dplyr::glimpse(read_tiers(etf_file))
#> Rows: 14
#> Columns: 9
#> $ filename     <chr> "CLP_annotation_v2-2.etf", "CLP_annotation_v2-2.etf", "CL…
#> $ tier_type    <chr> "CLP main", "CLP congruence", "CLP event", "CLP interacti…
#> $ tier         <chr> "CLP handshape", "CLP congruence", "CLP event", "CLP inte…
#> $ participant  <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA
#> $ annotator    <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA
#> $ parent_ref   <chr> NA, "CLP handshape", "CLP handshape", "CLP handshape", "C…
#> $ language_ref <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA
#> $ constraint   <chr> NA, "Symbolic_Association", "Symbolic_Association", "Symb…
#> $ cv_ref       <chr> "CLP handshape", "CLP congruence", "CLP event", "CLP inte…
```

### Reading media metadata

To access information about linked media file in an annotation file
(`.eaf`), the `read_media()` function can be used:

``` r
library(readelan)

eaf_file <- system.file("extdata", 
                        "example.eaf", 
                        package = "readelan")

read_media(eaf_file)
#>      filename item          attribute                             value
#> 1 example.eaf    1          MEDIA_URL file:///Users/user01/video_01.mp4
#> 2 example.eaf    1          MIME_TYPE                         video/mp4
#> 3 example.eaf    1 RELATIVE_MEDIA_URL                    ./video_01.mp4
#> 4 example.eaf    2          MEDIA_URL file:///Users/user01/video_02.mp4
#> 5 example.eaf    2          MIME_TYPE                         video/mp4
#> 6 example.eaf    2 RELATIVE_MEDIA_URL                    ./video_02.mp4
#> 7 example.eaf    3          MEDIA_URL file:///Users/user01/audio_02.mp3
#> 8 example.eaf    3          MIME_TYPE                           audio/*
#> 9 example.eaf    3 RELATIVE_MEDIA_URL                    ./audio_02.mp3
```

### Iterating over multiple files

The `read_` functions all allow for either a single file or a vector of
files to be used as `file` input. With multiple files, the function will
iterate over them, and return a single data frame:

``` r
library(readelan)

eaf_file2 <- system.file("extdata", 
                         "example_no_annotations.eaf", 
                         package = "readelan")

dplyr::glimpse(read_eaf(c(eaf_file, eaf_file2)))
#> Rows: 9
#> Columns: 18
#> $ filename     <chr> "example.eaf", "example.eaf", "example.eaf", "example.eaf…
#> $ a            <chr> "a1", "a2", "a3", "a4", "a7", "a5", "a8", "a6", "a9"
#> $ time_1       <chr> "ts1", "ts3", "ts5", "ts1", "ts1", "ts3", "ts3", "ts5", "…
#> $ time_2       <chr> "ts2", "ts4", "ts6", "ts2", "ts2", "ts4", "ts4", "ts6", "…
#> $ annotation   <chr> "I", "like", "cats", "pronoun", "subject", "verb", "predi…
#> $ tier         <chr> "words", "words", "words", "pos", "syntax", "pos", "synta…
#> $ tier_type    <chr> "default-lt", "default-lt", "default-lt", "pos", "syntax"…
#> $ participant  <chr> "s001", "s001", "s001", "s001", "s001", "s001", "s001", "…
#> $ annotator    <chr> "ABC", "ABC", "ABC", "DEF", "GHI", "DEF", "GHI", "DEF", "…
#> $ parent_ref   <chr> NA, NA, NA, "words", "words", "words", "words", "words", …
#> $ a_ref        <chr> NA, NA, NA, "a1", "a1", "a2", "a2", "a3", "a3"
#> $ language_ref <chr> NA, NA, NA, "eng", "eng", "eng", "eng", "eng", "eng"
#> $ cv_id        <chr> NA, NA, NA, "pos", "syntax", "pos", "syntax", "pos", "syn…
#> $ cve_ref      <chr> NA, NA, NA, "cveid_89b2ac38-7313-4737-aa5f-19e1231ccb18",…
#> $ start        <dbl> 490, 2010, 4370, 490, 490, 2010, 2010, 4370, 4370
#> $ end          <dbl> 1590, 3670, 5980, 1590, 1590, 3670, 3670, 5980, 5980
#> $ duration     <dbl> 1100, 1660, 1610, 1100, 1100, 1660, 1660, 1610, 1610
#> $ time_unit    <chr> "milliseconds", "milliseconds", "milliseconds", "millisec…
```

**Note:** In this case, the resulting data frame is the same as in the
first example, since the second `.eaf` file does not contain any
annotations.

When iterating over a large number of files, setting the `progress`
argument to `TRUE` can be advisable, in order to get visual information
of the progress.

## Similar packages

There are other packages that also contain functions to read ELAN
annotation files, e.g.,
[`{act}`](https://cran.r-project.org/package=act) and
[`{phonfieldwork}`](https://cran.r-project.org/package=phonfieldwork).
However, the goal of `{readelan}` is to be a lightweight package
dedicated to ELAN files (including `.etf` and `.ecv` files), and which
is also fast. Benchmarking against these other packages indicate that
`{readelan}` is fast option.

``` r
eaf_file <- system.file("extdata", 
                        "example.eaf", 
                        package = "readelan")

microbenchmark::microbenchmark(
  readelan::read_eaf(eaf_file),
  phonfieldwork::eaf_to_df(eaf_file),
  act::import_eaf(eaf_file),
  times = 100
)
#> Unit: milliseconds
#>                                expr       min        lq      mean    median
#>        readelan::read_eaf(eaf_file)  3.618799  3.865444  4.408088  3.995882
#>  phonfieldwork::eaf_to_df(eaf_file) 12.486772 13.317079 19.673537 14.361861
#>           act::import_eaf(eaf_file) 57.919321 63.422488 76.427128 66.256699
#>         uq        max neval cld
#>   4.406987   8.940138   100  a 
#>  16.249869 471.515270   100  a 
#>  69.478613 800.792237   100   b
```

Additionally, since `{readelan}`’s `read_eaf()` function can inherently
iterate over many files, and specify target tiers or tier types using
the `tiers` or `xpath` arguments, it becomes much faster to read larger
sets of annotation files for which only specific tiers are of interest
to import.
