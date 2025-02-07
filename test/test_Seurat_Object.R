##
rm(list=ls());

library(Seurat);
library(SeuratData);

## get the example data
data(pbmc3k)
pbmc <- LoadData("pbmc3k", type = "pbmc3k.final")
monocyte.de.markers <- FindMarkers(pbmc, ident.1 = "CD14+ Mono", 
                                   ident.2 = "FCGR3A+ Mono")

## single cell matrix
data      <- pbmc[["RNA"]]@scale.data
cellnames <- Idents(pbmc)
celln.u   <- unique(cellnames)

## the cell type 
cell.type <- as.character(celln.u[3])
## cell names by the cell type
cell.i    <- which(cellnames==cell.type) 
cell.n   <- names(cellnames)[cell.i]

## get umap data 
umap <- pbmc[["umap"]]@cell.embeddings;

## get the sub-data of the cell type
dat.s   <- data[,cell.i]
u.i     <- which(row.names(umap) %in% cell.n)
umap.s  <- umap[u.i,]
umap2.s <- data.frame(name=row.names(umap.s), umap.s)

###
### do cluster
###
library(scCorr)
set.seed(1234)
out   <- GCluster(umap2.s, wt=4, k=20)
clu.i <- out$membership
## sign the single cell into clusters
out.s <- data.frame(umap2.s, cluster=clu.i)

## 
indat <- out.s[,-1];
## merge clusters if the cluster size < 4 
## the merge was based on the smallest distance
out1  <- merge_cluster(indat, 4)
out2  <- mgGCluster(indat[,3], out1, rename=TRUE)

## final cluster result
clu.k <- out2$renamed
clu.u <- unique(clu.k)

## get final data set
out.d <- get_value(dat.s, clu.k)
colnames(out.d) <- paste0("clu", sort(clu.u))
write.table(out.d, "20231019_single_cell.txt", quote=F, sep="\t")

var.v <- apply(out.d, 1, var)
## the genes without expression
var.i <- which(var.v==0)
## remove no-informative 
out.d <- out.d[-var.i,]

out.f <- m2p(t(out.d))
## matrix for p value 
head(out.f$p[,1:3])
## matrix for correlation coefficient
head(out.f$cor[,1:3])



