---
title: "Hierarchical Edge Bundles in R"
date: 2020-01-03
time: "20:00"
excerpt: "Introduction to an R implementation of Hierarchical Edge Bundles"
author: "Anders Ellern Bilgrau"
draft: false
toc: true
tags:
  - hierachical clustering
  - graphs
  - visualisation
images:
  - /network2.jpg
output: 
  html_document: 
    keep_md: yes
    number_sections: yes
    toc: yes
---



{{< figure src="/images/network2.jpg" alt="image" caption="Hierarchical edge bundling of a gene network. Blue indicate negative correlations, red indicate positive. The darker the color, the more strong the correlation." class="big" >}}


## Background

During the finalization of my PhD, I implemented the so-called *Hierarchical Edge Bundling* plotting method for a paper now [published in the Annals of Applied Statistics](https://projecteuclid.org/euclid.aoas/1536652979). 
Though the plot above sadly did not make the final cut, I admit due to an lack of added value, it appeared in the original submission and the thesis. 
Suffice it to say, I was still quite pleased with the method at the time, so I wrapped the methods into an **R**-package called [**HierachicalEdgeBundles**](https://github.com/AEBilgrau/HierarchicalEdgeBundles). 
The plan was then to do a very small paper on this topic but I never got around to it. This a poor attempt of rectifying that.

The plot above illustrates estimated correlations of selected genes within the disease called diffuse large B-cell lymphoma the method.


## What is hierarchical edge bundling?

Hierarchical edge bundling is a visualization technique for displaying the relations in a network that additionally submit to some hierarchical structure.
The method was originally suggested in 2006 in a [lovely paper by Danny Holten](https://ieeexplore.ieee.org/document/4015425).
In short, hierarchical edge bundling visualizes graphs (of nodes and edges) by guiding the edges along along a hierarchical tree of the nodes.
A bundling parameter then controls how tightly the edges follow this underlying tree. 
So what data fits into this technique?


### The data 

The typical data suitable for this visualization needs two basic properties:

1. The data can be represented as a graph (directed or undirected)
2. The data can be arranged hierarchically 

If the data does not adhere to one of these properties the lacking properties may often be constructed. 
Now, I say 'data' here. But by 'data' I mean the likely processed data that goes in to the plotting method, not necessarily the *collected* data. 

Let me illustrate by using the **R** package.


## Using the **HierarchicalEdgeBundles** package

### Installation

First things first. To install the package directly from the [repository on GitHub](https://github.com/AEBilgrau/HierarchicalEdgeBundles), we run:


```r
#install.packages("remotes")  # Uncomment if devtools is not installed
remotes::install_github("AEBilgrau/HierarchicalEdgeBundles")
```

Then we load the needed packages:


```r
library("HierarchicalEdgeBundles")
library("ape")
library("igraph")
```


### Toy data

To illustrate the package use, we use a typical go-to dataset in **R**. 
The `mtcars` dataset:


```r
data(mtcars)
head(mtcars, n = 10)
```

|                  | mpg  | cyl | disp  | hp  | drat |  wt   | qsec  | vs | am | gear | carb |
|:-----------------|:----:|:---:|:-----:|:---:|:----:|:-----:|:-----:|:--:|:--:|:----:|:----:|
|Mazda RX4         | 21.0 |  6  | 160.0 | 110 | 3.90 | 2.620 | 16.46 | 0  | 1  |  4   |  4   |
|Mazda RX4 Wag     | 21.0 |  6  | 160.0 | 110 | 3.90 | 2.875 | 17.02 | 0  | 1  |  4   |  4   |
|Datsun 710        | 22.8 |  4  | 108.0 | 93  | 3.85 | 2.320 | 18.61 | 1  | 1  |  4   |  1   |
|Hornet 4 Drive    | 21.4 |  6  | 258.0 | 110 | 3.08 | 3.215 | 19.44 | 1  | 0  |  3   |  1   |
|Hornet Sportabout | 18.7 |  8  | 360.0 | 175 | 3.15 | 3.440 | 17.02 | 0  | 0  |  3   |  2   |
|Valiant           | 18.1 |  6  | 225.0 | 105 | 2.76 | 3.460 | 20.22 | 1  | 0  |  3   |  1   |
|Duster 360        | 14.3 |  8  | 360.0 | 245 | 3.21 | 3.570 | 15.84 | 0  | 0  |  3   |  4   |
|Merc 240D         | 24.4 |  4  | 146.7 | 62  | 3.69 | 3.190 | 20.00 | 1  | 0  |  4   |  2   |
|Merc 230          | 22.8 |  4  | 140.8 | 95  | 3.92 | 3.150 | 22.90 | 1  | 0  |  4   |  2   |
|Merc 280          | 19.2 |  6  | 167.6 | 123 | 3.92 | 3.440 | 18.30 | 1  | 0  |  4   |  4   |

The `mtcars` contains data for various specs of 32 cars where only the `n = 10` first cars are shown above. Run `help("mtcars")` to read more about this dataset.


### Analysis of features

Suppose that we would like to examine features of these cars and how they relate to each other.
So it is natural to evaluate all pairs of features by some metric. 



```r
# Compute correlation matrix of features
car_cor <- cor(mtcars)
print(round(car_cor, 1))
```

```
##       mpg  cyl disp   hp drat   wt qsec   vs   am gear carb
## mpg   1.0 -0.9 -0.8 -0.8  0.7 -0.9  0.4  0.7  0.6  0.5 -0.6
## cyl  -0.9  1.0  0.9  0.8 -0.7  0.8 -0.6 -0.8 -0.5 -0.5  0.5
## disp -0.8  0.9  1.0  0.8 -0.7  0.9 -0.4 -0.7 -0.6 -0.6  0.4
## hp   -0.8  0.8  0.8  1.0 -0.4  0.7 -0.7 -0.7 -0.2 -0.1  0.7
## drat  0.7 -0.7 -0.7 -0.4  1.0 -0.7  0.1  0.4  0.7  0.7 -0.1
## wt   -0.9  0.8  0.9  0.7 -0.7  1.0 -0.2 -0.6 -0.7 -0.6  0.4
## qsec  0.4 -0.6 -0.4 -0.7  0.1 -0.2  1.0  0.7 -0.2 -0.2 -0.7
## vs    0.7 -0.8 -0.7 -0.7  0.4 -0.6  0.7  1.0  0.2  0.2 -0.6
## am    0.6 -0.5 -0.6 -0.2  0.7 -0.7 -0.2  0.2  1.0  0.8  0.1
## gear  0.5 -0.5 -0.6 -0.1  0.7 -0.6 -0.2  0.2  0.8  1.0  0.3
## carb -0.6  0.5  0.4  0.7 -0.1  0.4 -0.7 -0.6  0.1  0.3  1.0
```

Since `car_cor` is a symmetric matrix it can be represented by a complete edge-weighted graph were the weights are the correlations. Using the `igraph` package, we can display it as such easily:


```r
# Create igraph
car_graph <- graph_from_adjacency_matrix(
  car_cor, mode = "undirected", weighted = TRUE, diag = FALSE
)

# Function for mapping correlations to colors
make_colors <- function(wgt) {  
  cr <- colorRamp(c("tomato", "white", "seagreen"), space = "Lab")
  v <- cr((wgt + 1)/2) # map linearly to [0, 1]
  return(rgb(v[,1], v[,2], v[, 3], maxColorValue = 255))
}

# Tweaks for some pretty plotting 
E(car_graph)$width <- 4*abs(E(car_graph)$weight)
E(car_graph)$color <- make_colors(E(car_graph)$weight)
V(car_graph)$label.color <- "black"
V(car_graph)$size <- 8
V(car_graph)$color <- "white"

par(mar = c(0, 0, 0, 0))
plot(car_graph, layout = layout_in_circle(car_graph))
```

![plot of chunk car_dist_plot](/images/hierachical-edge-bundles.en/car_dist_plot-1.png)

This gives us the first of our two new ingredients --- a graph of the features.

Using `as.dist` and and the sample correlation matrix we we can compute a dissimilarity matrix:


```r
# Compute pairwise 'distances' (high absolute correlation features are 'close')
car_dist <- as.dist(1 - abs(car_cor))
print(round(car_dist, 1))
```

```
##      mpg cyl disp  hp drat  wt qsec  vs  am gear
## cyl  0.1                                        
## disp 0.2 0.1                                    
## hp   0.2 0.2  0.2                               
## drat 0.3 0.3  0.3 0.6                           
## wt   0.1 0.2  0.1 0.3  0.3                      
## qsec 0.6 0.4  0.6 0.3  0.9 0.8                  
## vs   0.3 0.2  0.3 0.3  0.6 0.4  0.3             
## am   0.4 0.5  0.4 0.8  0.3 0.3  0.8 0.8         
## gear 0.5 0.5  0.4 0.9  0.3 0.4  0.8 0.8 0.2     
## carb 0.4 0.5  0.6 0.3  0.9 0.6  0.3 0.4 0.9  0.7
```

These distances are measures of 'dissimilarity' or 'unrelatedness' between the car features.
Greater values corresponds to a greater dissimilarity of the features and vice versa.
We do not bother here to consider if the '1 minus the absolute Pearson correlation' measure is a particularly well-suited measure for this (it is perhaps not). Nonetheless, the intuition here is that strong correlations (negative or positive) are considered 'close' and near-zero correlations are considered distant. I.e. this gives a crude measure of dependence.

Using the dissimilarities we can, for example, use regular hierarchical clustering to arrive at the second ingredient needed:


```r
car_phylo <- as.phylo(hclust(car_dist, "ave"))
plot(car_phylo)
```

![plot of chunk hclust_plot](/images/hierachical-edge-bundles.en/hclust_plot-1.png)

A tree of the features.

We happily notice that features which a priori are connected indeed also are (strongly) correlated and cluster together; e.g. the number of *cyl*inders and *disp*lacement, the weight of the cars (*wt*) strongly reflects in other features, etc. This is also illustrated in the graph which we styled using our distance measure.

Notice that we've wrapped the tree from `hclust` in `as.phylo` from the **ape** package to convert it for later use. The reason is that the plotting method uses the internal nodes of the tree and those are (or at least were) not available in the tree object from `hclust`.

We are now ready to bundle the edges of the graph above.


```r
plotHEB(car_graph, car_phylo, beta = 0.8, type = "fan",
        e.cols = E(car_graph)$color, args.lines = list(lwd = 2))
```

![plot of chunk bundling](/images/hierachical-edge-bundles.en/bundling-1.png)

Or with a little less bundling and as the phylogram and the internal nodes of the underlying tree plotted as well:


```r
plotHEB(car_graph, car_phylo, beta = 0.7, type = "cladogram",
        e.cols = E(car_graph)$color, args.lines = list(lwd = 2))
```

![plot of chunk alt_bundle](/images/hierachical-edge-bundles.en/alt_bundle-1.png)

As can be noted in the documentation of the package, it is `plot.phylo` from **`ape`** that controls much of the plotting. This also explains the excessive white space in this layout as the entire tree would normally be drawn (as seen above).


## Final remarks

The hiearachical edge bundling plotting method certainly produces pretty graphics
and useful in the right contexts. For them to be truely useful they need a careful construction of coloring, linewidth, and layout, and unfortunately the number of available layouts (in R) are lacking at the moment.




## References

* Danny Holten (2006) [**"Hierarchical Edge Bundles: Visualization of Adjacency Relations in Hierarchical Data"**](https://ieeexplore.ieee.org/document/4015425), IEEE Transactions on Visualization and Computer Graphics, 12 (5): 741--748. https://ieeexplore.ieee.org/document/4015425

* Bilgrau, Anders Ellern; Brøndum, Rasmus Froberg; Eriksen, Poul Svante; Dybkær, Karen; Bøgsted, Martin. [Estimating a common covariance matrix for network meta-analysis of gene expression datasets in diffuse large B-cell lymphoma.](https://projecteuclid.org/euclid.aoas/1536652979) Ann. Appl. Stat. 12 (2018), no. 3, 1894--1913. doi:10.1214/18-AOAS1136. https://projecteuclid.org/euclid.aoas/1536652979
