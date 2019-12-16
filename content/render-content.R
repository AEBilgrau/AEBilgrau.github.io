library("knitr")

# Get all source .Rmd files and all .md files
# Need to be 're-run' to get new generated files (if any)

rmd_files <- function() {
  list.files("./content", pattern = "\\.Rmd$", recursive = TRUE,
             full.names = TRUE, ignore.case = TRUE)
}

force_knit <- TRUE

# Copy those with no danish version
comment <- "<!---Automatically generated from 'render-content.R'--->"
for (f in rmd_files()) {
  da_f <- gsub("\\.en\\.", ".da.", f)
  # Write if not existing or already generated
  if (!file.exists(da_f) || any(comment == readLines(da_f))) {
    if (file.exists(da_f)) {
      Sys.chmod(da_f, mode = "0777")
    }
    lns <- c(readLines(f), comment)
    writeLines(lns, con = da_f)
    Sys.chmod(da_f, mode = "0444")
  }
}

# Run through all files to knit
for (f in rmd_files())  {
  o <- gsub(".Rmd", ".md", f)
  
  if (file.exists(o) && !force_knit) {
    message("Found:    ", o)
    message("Skipping: ", f)
    next
  }
  # Create folder for the particular Rmd file
  f_noext <- tools::file_path_sans_ext(basename(f))
  img_dir <- file.path("./static/images", f_noext, "/")
  dir.create(img_dir, showWarnings = FALSE, recursive = TRUE)
  
  # Set newly created img_dir as figure path
  opts_chunk$set(fig.path = img_dir)

  knitr::knit(input = f, output = o)
  
  # Correcting image paths in markdown
  message("Correcting image paths ('./static/images/...' -> '/images/...')")
  writeLines(gsub("./static/images", "/images", readLines(o), fixed = TRUE),
             con = o)
}
