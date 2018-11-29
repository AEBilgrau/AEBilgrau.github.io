
setwd("~/Rprog/AEBilgrau.github.io/_posts/") 

library("knitr")

# Set knit options (figure placement)
opts_knit$set(base.dir = normalizePath('../images'))

# Get all source Rmd files
rmd_files <- list.files("../_posts_src/", 
                        pattern = "\\.Rmd$", 
                        full.names = TRUE,
                        ignore.case = TRUE)


# Run through all files
for (f in rmd_files)  {
  f_noext <- tools::file_path_sans_ext(basename(f))
  dir.create(file.path("../images", f_noext), showWarnings = FALSE)
  opts_chunk$set(fig.path = file.path(file.path("/images", f_noext), paste0(f_noext,"-")))
  knitr::knit(f)
}




