library("knitr")

# Get all source .Rmd files and all .md files
rmd_files <- list.files("./content", pattern = "\\.Rmd$", recursive = TRUE,
                        full.names = TRUE, ignore.case = TRUE)
force_knit <- FALSE

# Run through all files
for (f in rmd_files)  {
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
