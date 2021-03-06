#' @title  Construct a Multi Assay Experiment for ELMER analysis
#' @description 
#' This function will receive a gene expression and DNA methylation data objects 
#' and create a Multi Assay Experiment.
#' @param met A Summaerized Experiment, a matrix or path of rda file only containing the data.
#' @param exp A Summaerized Experiment, a matrix or path of rda file only containing the data. Rownames should be 
#' either Ensembl gene id (ensembl_gene_id) or gene symbol (external_gene_name)
#' @param genome Which is the default genome to make gene information. Options hg19 and hg38
#' @param colData A DataFrame or data.frame of the phenotype data for all participants
#' @param sampleMap  A DataFrame or data.frame of the matching samples and colnames
#'  of the gene expression and DNA methylation matrix. This should be used if your matrix
#'  have different columns names. 
#'  This object must have columns primary (sample ID) and colname (names of the columns of the matrix).
#' @param linearize.exp Take log2(exp + 1) in order to linearize relation between methylation and expression  
#' @param met.platform DNA methylation platform "450K" or "EPIC"
#' @param TCGA A logical. FALSE indicate data is not from TCGA (FALSE is default). 
#' TRUE indicates data is from TCGA and sample section will automatically filled in.
#' @param filter.probes A GRanges object contains the coordinate of probes which locate 
#'  within promoter regions or distal feature regions such as union enhancer from REMC and FANTOM5.
#'  See \code{\link{get.feature.probe}} function.
#' @param filter.genes List of genes ensemble ids to filter from object  
#' @param save If TRUE, MAE object will be saved into a file named as the argument save.file if this was set, otherwise as mae_genome_met.platform.rda.
#' @param save.filename Name of the rda file to save the object (must end in .rda)
#' @param met.na.cut Define the percentage of NA that the line should have to remove the probes for humanmethylation platforms.
#' @return A MultiAssayExperiment object
#' @export 
#' @importFrom MultiAssayExperiment MultiAssayExperiment 
#' @importFrom SummarizedExperiment SummarizedExperiment makeSummarizedExperimentFromDataFrame assay assay<-
#' @examples
#' # NON TCGA example: matrices has diffetrent column names
#' gene.exp <- S4Vectors::DataFrame(sample1.exp = c("ENSG00000141510"=2.3,"ENSG00000171862"=5.4),
#'                   sample2.exp = c("ENSG00000141510"=1.6,"ENSG00000171862"=2.3))
#' dna.met <- S4Vectors::DataFrame(sample1.met = c("cg14324200"=0.5,"cg23867494"=0.1),
#'                        sample2.met =  c("cg14324200"=0.3,"cg23867494"=0.9))
#' sample.info <- S4Vectors::DataFrame(primary =  c("sample1","sample2"), 
#'                                     sample.type = c("Normal", "Tumor"))
#' sampleMap <- S4Vectors::DataFrame(primary = c("sample1","sample1","sample2","sample2"), 
#'                                   colname = c("sample1.exp","sample1.met",
#'                                               "sample2.exp","sample2.met"))
#' mae <- createMAE(exp = gene.exp, 
#'                  met = dna.met, 
#'                  sampleMap = sampleMap, 
#'                  met.platform ="450K",
#'                  colData = sample.info, 
#'                  genome = "hg38") 
#' # You can also use sample Mapping and Sample information tables from a tsv file
#' # You can use the createTSVTemplates function to create the tsv files
#' readr::write_tsv(as.data.frame(sampleMap), path = "sampleMap.tsv")
#' readr::write_tsv(as.data.frame(sample.info), path = "sample.info.tsv")
#' mae <- createMAE(exp = gene.exp, 
#'                  met = dna.met, 
#'                  sampleMap = "sampleMap.tsv", 
#'                  met.platform ="450K",
#'                  colData = "sample.info.tsv", 
#'                  genome = "hg38") 
#' 
#' \dontrun{
#'    # TCGA example using TCGAbiolinks
#'    # Testing creating MultyAssayExperiment object
#'    # Load library
#'    library(TCGAbiolinks)
#'    library(SummarizedExperiment)
#'    
#'    samples <- c("TCGA-BA-4074", "TCGA-BA-4075", "TCGA-BA-4077", "TCGA-BA-5149",
#'                 "TCGA-UF-A7JK", "TCGA-UF-A7JS", "TCGA-UF-A7JT", "TCGA-UF-A7JV")
#'    
#'    #1) Get gene expression matrix
#'    query.exp <- GDCquery(project = "TCGA-HNSC", 
#'                          data.category = "Transcriptome Profiling", 
#'                          data.type = "Gene Expression Quantification", 
#'                          workflow.type = "HTSeq - FPKM-UQ",
#'                          barcode = samples)
#'    
#'    GDCdownload(query.exp)
#'    exp.hg38 <- GDCprepare(query = query.exp)
#'    
#'    
#'    # Aligned against Hg19
#'    query.exp.hg19 <- GDCquery(project = "TCGA-HNSC", 
#'                               data.category = "Gene expression",
#'                               data.type = "Gene expression quantification",
#'                               platform = "Illumina HiSeq", 
#'                               file.type  = "normalized_results",
#'                               experimental.strategy = "RNA-Seq",
#'                               barcode = samples,
#'                               legacy = TRUE)
#'    GDCdownload(query.exp.hg19)
#'    exp.hg19 <- GDCprepare(query.exp.hg19)
#'    
#'    # Our object needs to have emsembl gene id as rownames
#'    rownames(exp.hg19) <- values(exp.hg19)$ensembl_gene_id
#'    
#'    # DNA Methylation
#'    query.met <- GDCquery(project = "TCGA-HNSC",
#'                          legacy = TRUE,
#'                          data.category = "DNA methylation",
#'                          barcode = samples,
#'                          platform = "Illumina Human Methylation 450")
#'    
#'    GDCdownload(query.met)
#'    met <- GDCprepare(query = query.met)
#'    
#'    distal.enhancer <- get.feature.probe(genome = "hg19",platform = "450k")
#'    
#'    # Consisering it is TCGA and SE
#'    mae.hg19 <- createMAE(exp = exp.hg19, 
#'                          met =  met, 
#'                          TCGA = TRUE, 
#'                          genome = "hg19",  
#'                          filter.probes = distal.enhancer)
#'    values(getExp(mae.hg19))
#'    
#'    mae.hg38 <- createMAE(exp = exp.hg38, met = met, 
#'                         TCGA = TRUE, genome = "hg38",  
#'                         filter.probes = distal.enhancer)
#'    values(getExp(mae.hg38))
#'    
#'    # Consisering it is TCGA and not SE
#'    mae.hg19.test <- createMAE(exp = assay(exp.hg19), met =  assay(met), 
#'                               TCGA = TRUE, genome = "hg19",  
#'                               filter.probes = distal.enhancer)
#'    
#'    mae.hg38 <- createMAE(exp = assay(exp.hg38), met = assay(met), 
#'                          TCGA = TRUE, genome = "hg38",  
#'                          filter.probes = distal.enhancer)
#'    values(getExp(mae.hg38))
#'    
#'    # Consisering it is not TCGA and SE
#'    # DNA methylation and gene expression Objects should have same sample names in columns
#'    not.tcga.exp <- exp.hg19 
#'    colnames(not.tcga.exp) <- substr(colnames(not.tcga.exp),1,15)
#'    not.tcga.met <- met 
#'    colnames(not.tcga.met) <- substr(colnames(not.tcga.met),1,15)
#'    
#'    phenotype.data <- data.frame(row.names = colnames(not.tcga.exp), 
#'                                 samples = colnames(not.tcga.exp), 
#'                                 group = c(rep("group1",4),rep("group2",4)))
#'    distal.enhancer <- get.feature.probe(genome = "hg19",platform = "450k")
#'    mae.hg19 <- createMAE(exp = not.tcga.exp, 
#'                          met =  not.tcga.met, 
#'                          TCGA = FALSE, 
#'                          filter.probes = distal.enhancer,
#'                          genome = "hg19", 
#'                          colData = phenotype.data)
#' }
#' createMAE
createMAE <- function (exp, 
                       met, 
                       colData, 
                       sampleMap,
                       linearize.exp = FALSE,
                       filter.probes = NULL,
                       met.na.cut = 0.2,
                       filter.genes = NULL,
                       met.platform = "450K",
                       genome = NULL,
                       save = TRUE,
                       save.filename,
                       TCGA = FALSE) {
  
  if(missing(genome)) stop("Please specify the genome (hg38, hg19)")
  
  # Check if input are path to rda files
  if(is.character(exp)) exp <- get(load(exp))
  if(is.character(met)) met <- get(load(met))
  
  suppressMessages({
    
    if(!missing(colData)) { 
      if(is.character(colData)) { 
        colData <- as.data.frame(read_tsv(colData))
        rownames(colData) <- colData$primary
      }
    }
    if(!missing(sampleMap)) { 
      if(is.character(sampleMap)) sampleMap <- read_tsv(sampleMap)
    }
  })  
  
  # Expression data must have the ensembl_gene_id (Ensemble ID) and external_gene_name (Gene Symbol)
  required.cols <- c("external_gene_name", "ensembl_gene_id")
  # If my input is a data frame we will need to add metadata information for the ELMER analysis steps
  if(class(exp) != class(as(SummarizedExperiment(),"RangedSummarizedExperiment"))){
    exp <- makeSummarizedExperimentFromGeneMatrix(exp, genome)
  }
  # Add this here ?
  if(linearize.exp) assay(exp) <- log2(assay(exp) + 1)
  
  
  if(class(met) != class(as(SummarizedExperiment(),"RangedSummarizedExperiment"))){
    met <- makeSummarizedExperimentFromDNAMethylation(met, genome, met.platform)
  }
  met <- met[rowMeans(is.na(assay(met))) < met.na.cut, ]
  
  # Select the regions from DNA methylation that overlaps enhancer.
  if(!is.null(filter.probes)){
    if(is.character(filter.probes)){
      filter.probes <- get(load(filter.probes))
    }
  } 
  if(!is.null(filter.probes) & !is.null(met)){
    met <- met[rownames(met) %in% names(filter.probes),]
  }
  if(!is.null(filter.genes) & !is.null(exp)){
    exp <- exp[rownames(exp) %in% names(filter.genes),]
  } 
  
  # We will need to check if the fields that we need exists.
  # Otherwise we will need to create them
  if(class(exp) == class(as(SummarizedExperiment(),"RangedSummarizedExperiment"))){
    required.cols <- required.cols[!required.cols %in% colnames(values(exp))]
    if(length(required.cols) > 0) {
      gene.info <- TCGAbiolinks:::get.GRCh.bioMart(genome)
      colnames(gene.info)[grep("external_gene", colnames(gene.info))] <- "external_gene_name"
      if(all(grepl("ENSG",rownames(exp)))) {
        extra <- as.data.frame(gene.info[match(rownames(exp),gene.info$ensembl_gene_id),required.cols])
        colnames(extra) <- required.cols
        values(exp) <- cbind(values(exp),extra)
      } else {
        stop("Please the gene expression matrix should receive ENSEMBLE IDs")
      }
    }
  } 
  if(TCGA){
    message("Checking samples have both DNA methylation and Gene expression and they are in the same order...")
    # If it is not TCGA we will assure the sample has both DNA methylation and gene expression
    ID <- intersect(substr(colnames(met),1,16), substr(colnames(exp),1,16))
    
    # Get only samples with both DNA methylation and Gene expression
    met <- met[,match(ID,substr(colnames(met),1,16))]
    exp <- exp[,match(ID,substr(colnames(exp),1,16))]
    stopifnot(all(substr(colnames(exp),1,16) == substr(colnames(met),1,16)))
    stopifnot(ncol(exp) == ncol(met))
    
    # Get clinical information
    if(missing(colData)) {
      colData <- TCGAbiolinks:::colDataPrepare(c(colnames(met), colnames(exp)))
      # This will keep the same strategy the old ELMER version used:
      # Every type of tumor samples (starts with T) will be set to tumor and
      # every type of normal samples   (starts with N) will be set to normal 
      # See : https://github.com/lijingya/ELMER/blob/3e050462aa41c8f542530ccddc8fa607207faf88/R/Small.R#L8-L48
      colData$TN <- NA
      colData[grep("^N",colData$shortLetterCode),"TN"] <- "Normal" 
      colData[grep("^T",colData$shortLetterCode),"TN"] <- "Tumor" 
      
      colData$barcode <- NULL
      colData <- colData[!duplicated(colData),]      
      rownames(colData) <- colData$sample
    } 
    if(missing(sampleMap)) {
      sampleMap <- DataFrame(assay= c(rep("DNA methylation", length(colnames(met))), rep("Gene expression", length(colnames(exp)))),
                             primary = substr(c(colnames(met),colnames(exp)),1,16),
                             colname=c(colnames(met),colnames(exp)))
    }
    
    message("Creating MultiAssayExperiment")
    mae <- MultiAssayExperiment(experiments=list("DNA methylation" = met,
                                                 "Gene expression" = exp),
                                colData = colData,   
                                sampleMap = sampleMap,
                                metadata = list(TCGA= TRUE, genome = genome, met.platform = met.platform ))
  } else {
    
    if(missing(colData)){
      message <- paste("Please set colData argument. A data frame with samples", 
                       "information. All rownames should be colnames of DNA",
                       "methylation and gene expression. An example is showed",
                       "in MultiAssayExperiment documentation",
                       "(access it with ?MultiAssayExperiment)")
      stop(message)
    }
    
    if(missing(sampleMap)){
      # Check that we have the same number of samples
      message("Removing samples not found in both DNA methylation and gene expression (we are considering the names of the gene expression and DNA methylation columns to be the same) ")
      ID <- intersect(colnames(met), colnames(exp))
      met <- met[,match(ID,colnames(met))]
      exp <- exp[,match(ID,colnames(exp))]
      
      if(!all(colnames(exp) == colnames(met))) 
        stop("Error DNA methylation matrix and gene expression matrix are not in the same order")
      
      colData <- colData[match(ID,rownames(colData)),,drop = FALSE]
      sampleMap <- DataFrame(assay= c(rep("DNA methylation", length(colnames(met))), 
                                      rep("Gene expression", length(colnames(exp)))),
                             primary = c(colnames(met),colnames(exp)),
                             colname=c(colnames(met),colnames(exp)))
      mae <- MultiAssayExperiment(experiments=list("DNA methylation" = met,
                                                   "Gene expression" = exp),
                                  colData = colData,
                                  sampleMap = sampleMap,
                                  metadata = list(TCGA=FALSE, genome = genome, met.platform = met.platform ))
    } else {
      # Check that we have the same number of samples
      if(!all(c("primary","colname") %in% colnames(sampleMap))) 
        stop("sampleMap should have the following columns: primary (sample ID) and colname(DNA methylation and gene expression sample [same as the colnames of the matrix])")
      #if(!any(rownames(colData) %in% sampleMap$primary))
      #  stop("colData row names should be mapped to sampleMap primary column ")
      # Find which samples are DNA methylation and gene expression
      sampleMap.met <- sampleMap[sampleMap$colname %in% colnames(met),,drop = FALSE]
      sampleMap.exp <- sampleMap[sampleMap$colname %in% colnames(exp),,drop = FALSE]
      
      # Which ones have both DNA methylation and gene expresion?
      commun.samples <- intersect(sampleMap.met$primary,sampleMap.exp$primary)
      
      # Remove the one that does not have both data
      sampleMap.met <- sampleMap.met[match(sampleMap.met$primary,commun.samples),,drop = FALSE]
      sampleMap.exp <- sampleMap.exp[match(sampleMap.exp$primary,commun.samples),,drop = FALSE]
      
      # Ordering samples to be matched
      met <- met[,sampleMap.met$colname,drop = FALSE]
      exp <- exp[,sampleMap.exp$colname,drop = FALSE]
      
      if(!all(sampleMap.met$primary == sampleMap.exp$primary)) 
        stop("Error DNA methylation matrix and gene expression matrix are not in the same order")
      
      colData <- colData[match(commun.samples,rownames(colData)),,drop = FALSE]
      sampleMap <- DataFrame(assay= c(rep("DNA methylation", length(colnames(met))), 
                                      rep("Gene expression", length(colnames(exp)))),
                             primary = commun.samples,
                             colname=c(colnames(met),colnames(exp)))
      mae <- MultiAssayExperiment(experiments=list("DNA methylation" = met,
                                                   "Gene expression" = exp),
                                  colData = colData,
                                  sampleMap = sampleMap,
                                  metadata = list(TCGA=FALSE, genome = genome, met.platform = met.platform ))
    }
  }
  if(save) {
    if(missing(save.filename)) save.filename <- paste0("mae_",genome,"_",met.platform,".rda")
    save(mae, file = save.filename,compress = "xz")
    message("MAE saved as: ", save.filename)
  }
  return(mae)
}

makeSummarizedExperimentFromGeneMatrix <- function(exp, genome = genome){
  message("=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-")
  message("Creating a SummarizedExperiment from gene expression input")
  gene.info <- TCGAbiolinks:::get.GRCh.bioMart(genome)
  gene.info$chromosome_name <- paste0("chr",gene.info$chromosome_name)
  colnames(gene.info)[grep("external_gene", colnames(gene.info))] <- "external_gene_name"
  gene.info$strand[gene.info$strand == 1] <- "+"
  gene.info$strand[gene.info$strand == -1] <- "-"
  exp <- as.data.frame(exp)
  required.cols <- c("external_gene_name", "ensembl_gene_id")
  
  if(all(grepl("ENSG",rownames(exp)))) {
    exp$ensembl_gene_id <- rownames(exp)
    aux <- merge(exp, gene.info, by = "ensembl_gene_id", sort = FALSE)
    aux <- aux[!duplicated(aux$ensembl_gene_id),]
    rownames(aux) <- aux$ensembl_gene_id
    aux$entrezgene <- NULL
    exp <- makeSummarizedExperimentFromDataFrame(aux[,!grepl("external_gene_name|ensembl_gene_id",colnames(aux))],    
                                                 start.field="start_position",
                                                 end.field=c("end_position"))
    extra <- as.data.frame(gene.info[match(rownames(exp),gene.info$ensembl_gene_id),required.cols])
    colnames(extra) <- required.cols
    values(exp) <- cbind(values(exp),extra)
  } else {
    stop("Please the gene expression matrix should receive ENSEMBLE IDs (ENSG)")
  }
  return(exp)
}

#' @importFrom downloader download
#' @importFrom S4Vectors DataFrame
makeSummarizedExperimentFromDNAMethylation <- function(met, genome, met.platform) {
  message("=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-")
  message("Creating a SummarizedExperiment from DNA methylation input")
  
  # Instead of looking on the size, it is better to set it as a argument as the annotation is different
  annotation <-   getInfiniumAnnotation(met.platform, genome)
  rowRanges <- annotation[rownames(met),,drop=FALSE]
  
  # Remove masked probes, besed on the annotation
  rowRanges <- rowRanges[!rowRanges$MASK.mapping]
  
  colData <-  DataFrame(samples = colnames(met))
  met <- met[rownames(met) %in% names(rowRanges),,drop = FALSE]
  assay <- data.matrix(met)
  met <- SummarizedExperiment(assays=assay,
                              rowRanges=rowRanges,
                              colData=colData)
  return(met)
}

getInfiniumAnnotation <- function(plat = "450K", genome = "hg38"){
  if(tolower(genome) == "hg19" & toupper(plat) == "450K" ) return(getdata("hm450.manifest"))
  if(tolower(genome) == "hg19" & toupper(plat) == "EPIC" ) return(getdata("EPIC.manifest"))
  if(tolower(genome) == "hg38" & toupper(plat) == "450K" ) return(getdata("hm450.manifest.hg38"))
  if(tolower(genome) == "hg38" & toupper(plat) == "EPIC" ) return(getdata("EPIC.manifest.hg38"))
}

getdata <- function(...)
{
  e <- new.env()
  name <- data(..., package = "ELMER.data",envir = e)[1]
  e[[ls(envir = e)[1]]]
}

#' Create examples files for Sample mapping and information used in createMAE function
#' @description 
#' This function will receive the DNA methylation and gene expression matrix and will create
#' some examples of table for the argument colData and sampleMap used in ceeateMae function.
#' @param met DNA methylation matrix or Summarized Experiment
#' @param exp Gene expression matrix or Summarized Experiment
#' @examples 
#' gene.exp <- S4Vectors::DataFrame(sample1.exp = c("ENSG00000141510"=2.3,"ENSG00000171862"=5.4),
#'                   sample2.exp = c("ENSG00000141510"=1.6,"ENSG00000171862"=2.3))
#' dna.met <- S4Vectors::DataFrame(sample1.met = c("cg14324200"=0.5,"cg23867494"=0.1),
#'                        sample2.met =  c("cg14324200"=0.3,"cg23867494"=0.9))
#' createTSVTemplates(met = dna.met, exp = gene.exp)                       
#' @importFrom readr write_tsv
#' @export
createTSVTemplates <- function(met, exp) {
  assay <- c(rep("DNA methylation", ncol(met)),
             rep("Gene expression", ncol(exp)))
  primary <- rep("SampleX", ncol(met) + ncol(exp))
  colname <- c(colnames(met),colnames(exp))
  sampleMap <- data.frame(assay,primary,colname)
  message("===== Sample mapping example file ======")
  message("Saving example file as elmer_example_sample_mapping.tsv.")
  message("Please, fill primary column correctly")
  write_tsv(sampleMap,path = "elmer_example_sample_mapping.tsv")
  
  colData <- data.frame(primary = paste0("sample",1:ncol(met)), group = rep("To be filled",ncol(met)))
  message("===== Sample information example file ======")
  message("Saving example file as elmer_example_sample_metadata.tsv.")
  message("Please, fill primary column correctly, also you can add new columns as the example group column.")
  write_tsv(colData,path = "elmer_example_sample_metadata.tsv")
}

# splitmatix 
# @param x A matrix 
# @param by A character specify if split the matix by row or column.
# @return A list each of which is the value of each row/column in the matrix.
splitmatrix <- function(x,by="row") {
  if(by %in% "row"){
    out <- split(x, rownames(x))
  }else if (by %in% "col"){
    out <- split(x, colnames(x))
  }
  return(out)
}


#' lable linear regression formula 
#' @param df A data.frame object contains two variables: dependent 
#' variable (Dep) and explanation variable (Exp).
#' @param Dep A character specify dependent variable. The first column 
#' will be dependent variable as default.
#' @param Exp A character specify explanation variable. The second column 
#' will be explanation variable as default.
#' @return A linear regression formula
#' @importFrom stats coef lm
lm_eqn = function(df,Dep,Exp){
  if(missing(Dep)) Dep <- colnames(df)[1]
  if(missing(Exp)) Exp <- colnames(df)[2]
  m = lm(df[,Dep] ~ df[,Exp]);
  eq <- substitute(italic(y) == a + (b) %.% italic(x)*"\n"~~italic(r)^2~"="~r2, 
                   list(a = format(coef(m)[1], digits = 2), 
                        b = format(coef(m)[2], digits = 2), 
                        r2 = format(summary(m)$r.squared, digits = 3)))
  as.character(as.expression(eq));                 
}



#' getTSS to fetch GENCODE gene annotation (transcripts level) from Bioconductor package biomaRt
#' If upstream and downstream are specified in TSS list, promoter regions of GENCODE gene will be generated.
#' @description 
#' getTSS to fetch GENCODE gene annotation (transcripts level) from Bioconductor package biomaRt
#' If upstream and downstream are specified in TSS list, promoter regions of GENCODE gene will be generated.
#' @param TSS A list. Contains upstream and downstream like TSS=list(upstream, downstream).
#'  When upstream and downstream is specified, coordinates of promoter regions with gene annotation will be generated.
#' @param genome Which genome build will be used: hg38 (default) or hg19.
#' @return GENCODE gene annotation if TSS is not specified. Coordinates of GENCODE gene promoter regions if TSS is specified.
#' @examples
#' # get GENCODE gene annotation (transcripts level)
#' \dontrun{
#'     getTSS <- getTSS()
#'     getTSS <- getTSS(genome.build = "hg38", TSS=list(upstream=1000, downstream=1000))
#' }
#' @export
#' @author Lijing Yao (maintainer: lijingya@usc.edu)
#' @import GenomeInfoDb
#' @importFrom GenomicFeatures transcripts
#' @importFrom GenomicRanges makeGRangesFromDataFrame
#' @importFrom biomaRt useEnsembl
getTSS <- function(genome="hg38",TSS=list(upstream=NULL, downstream=NULL)){
  if (genome == "hg19"){
    # for hg19
    ensembl <- useMart(biomart = "ENSEMBL_MART_ENSEMBL",
                       host = "feb2014.archive.ensembl.org",
                       path = "/biomart/martservice" ,
                       dataset = "hsapiens_gene_ensembl")
    attributes <- c("chromosome_name",
                    "start_position",
                    "end_position", 
                    "strand",
                    "transcript_start",
                    "transcript_end",
                    "ensembl_transcript_id",
                    "ensembl_gene_id", "entrezgene",
                    "external_gene_id")
  } else {
    # for hg38
    ensembl <- tryCatch({
      useEnsembl("ensembl", dataset = "hsapiens_gene_ensembl",
                 mirror = "useast")
    },  error = function(e) {
      useEnsembl("ensembl",
                 dataset = "hsapiens_gene_ensembl",
                 mirror = "uswest")
    })
    attributes <- c("chromosome_name",
                    "start_position",
                    "end_position", "strand",
                    "ensembl_gene_id", 
                    "transcription_start_site",
                    "transcript_start",
                    "ensembl_transcript_id",
                    "transcript_end",
                    "external_gene_name")
  }
  chrom <- c(1:22, "X", "Y","M","*")
  db.datasets <- listDatasets(ensembl)
  description <- db.datasets[db.datasets$dataset=="hsapiens_gene_ensembl",]$description
  message(paste0("Downloading transcripts information. Using: ", description))
  
  filename <-  paste0(gsub("[[:punct:]]| ", "_",description),"_tss.rda")
  if(!file.exists(filename)) {
    tss <- getBM(attributes = attributes, filters = c("chromosome_name"), values = list(chrom), mart = ensembl)
    tss <- tss[!duplicated(tss$ensembl_transcript_id),]
    save(tss, file = filename)
  } else {
    tss <- get(load(filename))  
  } 
  if(genome == "hg19") tss$external_gene_name <- tss$external_gene_id
  tss$chromosome_name <-  paste0("chr", tss$chromosome_name)
  tss$strand[tss$strand == 1] <- "+" 
  tss$strand[tss$strand == -1] <- "-" 
  tss <- makeGRangesFromDataFrame(tss,start.field = "transcript_start", end.field = "transcript_end", keep.extra.columns = TRUE)
  
  if(!is.null(TSS$upstream) & !is.null(TSS$downstream)) 
    tss <- promoters(tss, upstream = TSS$upstream, downstream = TSS$downstream)

  return(tss)
}

#' @title  Get human TF list from the UNiprot database
#' @description This function gets the last version of human TF list from the UNiprot database
#' @importFrom readr read_tsv
#' @param genome.build Genome reference version "hg38" or "hg19"
#' @return A data frame with the ensemble gene id and entrezgene and gene symbol.
getTF <- function(genome.build = "hg38"){
  print.header("Accessing Uniprot to get last version of Human TFs","subsection")
  if(!file.exists("HumanTF.rda")){
    uniprotURL <- "http://www.uniprot.org/uniprot/?"
    query <- "query=reviewed:yes+AND+organism:9606+AND+%22transcription+factor%22&sort=score"
    fields <- "columns=id,entry%20name,protein%20names,genes,database(GeneWiki),database(Ensembl),database(GeneID)"
    format <- "format=tab"
    human.TF <- readr::read_tsv(paste0(uniprotURL,
                                       paste(query, fields,format, sep = "&")),
                                col_types = "ccccccc") 
    gene <- get.GRCh(genome.build, gsub(";","",human.TF$`Cross-reference (GeneID)`))
    gene  <- gene[!duplicated(gene),]
    save(gene, file = "HumanTF.rda")
  } else {
    gene <- get(load("HumanTF.rda"))
  }
  return(gene)
}

#' @importFrom biomaRt getBM useMart listDatasets
get.GRCh <- function(genome = "hg38", genes) {
  if (genome == "hg19"){
    # for hg19
    ensembl <- useMart(biomart = "ENSEMBL_MART_ENSEMBL",
                       host = "feb2014.archive.ensembl.org",
                       path = "/biomart/martservice" ,
                       dataset = "hsapiens_gene_ensembl")
    attributes <- c("ensembl_gene_id", "entrezgene","external_gene_id")
  } else {
    # for hg38
    ensembl <- useMart("ensembl", dataset = "hsapiens_gene_ensembl")
    attributes <- c("ensembl_gene_id", "entrezgene","external_gene_name")
  }
  gene.location <- getBM(attributes = attributes,
                         filters = c("entrezgene"),
                         values = list(genes), mart = ensembl)
  colnames(gene.location) <-  c("ensembl_gene_id", "entrezgene","external_gene_name")
  gene.location <- gene.location[match(genes,gene.location$entrezgene),]
  return(gene.location)
}

#' @title Get family of transcription factors
#' @description 
#' This will output a list each TF motif and TFs that binding the motis. Multiple TFs may
#' recognize a same motif such as TF family.  
#' The association between each motif famil and transcription factor was created using the 
#' (HOCOMOCO)[http://hocomoco.autosome.ru/human/mono] which TF structural families 
#' was created according to TFClass [@wingender2014tfclass]
#' This data is stored as a list whose elements 
#' are motifs and contents for each element are TFs which recognize the same motif that
#' is the name of the element. This data is used in function get.TFs in \pkg{ELMER} 
#' to identify the real regulator TF whose motif is enriched in a given set of probes 
#' and expression associate with average DNA methylation of these motif sites.
#' @importFrom rvest html_table  %>%
#' @importFrom xml2 read_html 
#' @export
#' @param classification Select if we will use Family classification or sub-family
#' @return A list of TFs and its family members
createMotifRelevantTfs <- function(classification = "family"){
  message("Retrieving TFClass ", classification," classification from ELMER.data.")
  if(classification == "family") motif.relevant.TFs <- getdata("TF.family")
  if(classification == "subfamily") motif.relevant.TFs <- getdata("TF.subfamily")
  return(motif.relevant.TFs)
}

#' @title Filtering probes
#' @description 
#' This function has some filters to the DNA methylation data
#' in each it selects probes to avoid correlations due to non-cancer 
#' contamination and for additional stringency.
#'  \itemize{
#' \item Filter 1: We usually call locus unmethylated when the methylation value < 0.3 and methylated when the methylation value > 0.3. 
#'       Therefore Meth_B is the percentage of methylation value > K. 
#'       Basically, this step will make sure we have at least a percentage of beta values lesser than K and n percentage of beta values greater K. 
#'       For example, if percentage is 5\%, the number of samples 100 and K = 0.3, 
#'       this filter will select probes that we have at least 5 (5\% of 100\%) samples have beta values > 0.3 and at least 5 samples have beta values < 0.3.
#'       This filter is importante as true promoters and enhancers usually have a pretty low value (of course purity can screw that up).  
#'       we often see lots of PMD probes across the genome with intermediate values like 0.4.  
#'       Choosing a value of 0.3 will certainly give some false negatives, but not compared to the number of false positives we thought we might get without this filter.
#' }
#' @references 
#' Yao, Lijing, et al. "Inferring regulatory element landscapes and transcription 
#' factor networks from cancer methylomes." Genome biology 16.1 (2015): 1.
#' Method section (Linking enhancer probes with methylation changes to target genes with expression changes).
#' @param data A MultiAssayExperiment with a DNA methylation martrix or a DNA methylation matrix
#' @param K Cut off to consider probes as methylated or unmethylated. Default: 0.3
#' @param percentage The percentage of samples we should have at least considered as methylated and unmethylated
#' @return An object with the same class, but with the probes removed.
#' @importFrom MultiAssayExperiment experiments<-
#' @export
#' @examples
#'  random.probe <- runif(100, 0, 1)
#'  bias_l.probe <- runif(100, 0, 0.3)
#'  bias_g.probe <- runif(100, 0.3, 1)
#'  met <- rbind(random.probe,bias_l.probe,bias_g.probe)
#'  met <- preAssociationProbeFiltering(data = met,  K = 0.3, percentage = 0.05)
#'  met <- rbind(random.probe,random.probe,random.probe)
#'  met <- preAssociationProbeFiltering(met,  K = 0.3, percentage = 0.05)
#'  data <- ELMER:::getdata("elmer.data.example") # Get data from ELMER.data
#'  data <- preAssociationProbeFiltering(data,  K = 0.3, percentage = 0.05)
#'  
#'  cg24741609 <- runif(100, 0, 1)
#'  cg17468663 <- runif(100, 0, 0.3)
#'  cg14036402 <- runif(100, 0.3, 1)
#'  met <- rbind(cg24741609,cg14036402,cg17468663)
#'  colnames(met) <- paste("sample",1:100)
#'  exp <- met
#'  rownames(exp) <- c("ENSG00000141510","ENSG00000171862","ENSG00000171863")
#'  sample.info <- S4Vectors::DataFrame(sample.type = rep(c("Normal", "Tumor"),50))
#'  rownames(sample.info) <- colnames(exp)
#'  mae <- createMAE(exp = exp, met = met, colData = sample.info, genome = "hg38") 
#'  mae <- preAssociationProbeFiltering(mae,  K = 0.3, percentage = 0.05)
preAssociationProbeFiltering <- function(data, K = 0.3, percentage = 0.05){
  print.header("Filtering probes", type = "section")
  message("For more information see function preAssociationProbeFiltering")
  
  if(class(data) == class(MultiAssayExperiment())) { 
    met <- assay(getMet(data))
  } else {
    met <- data
  }
  # In percentage how many probes are bigger than K ?
  Meth_B <- rowMeans(met > K, na.rm = TRUE)
  # We should  have at least 5% methylation value < K or at least 5% methylation value > K
  keep <- Meth_B < (1 - percentage) & Meth_B > percentage
  message("Making sure we have at least ", percentage * 100, "% of beta values lesser than ", K," and ", 
          percentage * 100, "% of beta values greater ",K,".") 
  if(length(keep) - sum(keep) != 0) {
    message("Removing ", length(keep) - sum(keep), " probes out of ", length(keep))
  } else {
    message("There were no probes to be removed")
  }
  if(class(data) == class(MultiAssayExperiment())) {
    experiments(data)["DNA methylation"][[1]] <- experiments(data)["DNA methylation"][[1]][keep,]
  } else {
    data <- data[keep,,drop = FALSE]
  }
  return(data)
}