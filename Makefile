
all: posts server

server:
	hugo server

posts:
	Rscript content/render-content.R
  