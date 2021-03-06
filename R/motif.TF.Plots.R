#' motif.enrichment.plot to plot bar plots showing motif enrichment ORs and  95\% confidence interval for ORs
#' @description 
#' motif.enrichment.plot to plot bar plots showing motif enrichment ORs and 
#' 95\% confidence interval for ORs. Option motif.enrichment can be a data frame 
#' generated by \code{\link{get.enriched.motif}} or a path of XX.csv saved by the 
#' same function.
#'@param motif.enrichment A data frame or a file path of get.enriched.motif output
#'motif.enrichment.csv file.
#'@param significant A list to select subset of motif. Default is NULL.
#'@param dir.out A path specify the directory to which the figures will be saved. 
#'Current directory is default.
#'@param save A logic. If true (default), figure will be saved to dir.out.
#'@param label A character. Labels the outputs figure.
#'@param title Plot title. Default: no title
#'@param summary Create a summary table along with the plot, it is necessary 
#'to add two new columns to object (NumOfProbes and PercentageOfProbes)
#'@return A figure shows the enrichment level for selected motifs.
#'@details motif.enrichment If input data.frame object, it should contain "motif",
#' "OR", "lowerOR", "upperOR" columns. motif specifies name of motif; 
#' OR specifies Odds Ratio, lowerOR specifies lower boundary of OR (95%) ; 
#' upperOR specifies upper boundary of OR(95%).
#'@details significant A list used to select subset of motif.enrichment by the 
#'cutoff of OR, lowerOR, upperOR. significant=list(OR=1). More than one cutoff 
#'can be specified such as significant = list(OR=1, lowerOR=1,upperOR=4) 
#'@importFrom ggplot2 aes ggplot geom_point geom_errorbar coord_flip geom_abline
#' @usage 
#' motif.enrichment.plot(motif.enrichment, significant = NULL, 
#'                       dir.out = "./", save = TRUE, label = NULL,
#'                       title = NULL, summary = FALSE)
#' @author 
#' Lijing Yao (creator: lijingya@usc.edu) 
#' @references 
#' Yao, Lijing, et al. "Inferring regulatory element landscapes and transcription 
#' factor networks from cancer methylomes." Genome biology 16.1 (2015): 1.
#'@export
#'@importFrom grid gpar 
#'@importFrom gridExtra grid.arrange arrangeGrob
#'@examples
#' motif.enrichment <- data.frame(motif=c("TP53","NR3C1","E2F1","EBF1","RFX5","ZNF143", "CTCF"),
#'                                OR=c(19.33,4.83,1, 4.18, 3.67,3.03,2.49),
#'                                lowerOR =c(10,3,1.09,1.9,1.5,1.9, 0.82),
#'                                upperOR =c(23,5,3,7,6,5,5),
#'                                stringsAsFactors=FALSE)
#' motif.enrichment.plot(motif.enrichment=motif.enrichment,
#'                       significant=list(OR=3),
#'                       label="hypo", save=FALSE)
#' motif.enrichment.plot(motif.enrichment = motif.enrichment,
#'                       significant = list(OR = 3),
#'                       label = "hypo", 
#'                       title = "OR for paired probes hypomethylated in Mutant vs WT",
#'                       save = FALSE)
#' motif.enrichment <- data.frame(motif=c("TP53","NR3C1","E2F1","EBF1","RFX5","ZNF143", "CTCF"),
#'                                OR=c(19.33,4.83,1, 4.18, 3.67,3.03,2.49),
#'                                lowerOR =c(10,3,1.09,1.9,1.5,1.5, 0.82),
#'                                upperOR =c(23,5,3,7,6,5,5),
#'                                NumOfProbes = c(23,5,3,7,6,5,5),
#'                                PercentageOfProbes = c(0.23,0.05,0.03,0.07,0.06,0.05,0.05),
#'                                stringsAsFactors=FALSE)
#' motif.enrichment.plot(motif.enrichment=motif.enrichment,
#'                       significant=list(OR=3),
#'                       label="hypo", save=FALSE)
#' motif.enrichment.plot(motif.enrichment = motif.enrichment,
#'                       significant = list(OR = 3),
#'                       label = "hypo", 
#'                       summary = TRUE,
#'                       title = "OR for paired probes hypomethylated in Mutant vs WT",
#'                       save = TRUE)
motif.enrichment.plot <- function(motif.enrichment, 
                                  significant = NULL, 
                                  dir.out ="./", 
                                  save = TRUE,
                                  label = NULL,
                                  title = NULL, 
                                  summary = FALSE){
  if(missing(motif.enrichment)) stop("motif.enrichment is missing.")
  if(is.character(motif.enrichment)){
    motif.enrichment <- read.csv(motif.enrichment, stringsAsFactors=FALSE)
  }
  if(!is.null(significant)){
    for(i in names(significant)){
      motif.enrichment <- motif.enrichment[motif.enrichment[,i] > significant[[i]],]
    }
  } 
  if(nrow(motif.enrichment) == 0) return(NULL)
  motif.enrichment <- motif.enrichment[order(motif.enrichment$lowerOR,decreasing = TRUE),]
  
  if(summary){
    or.col <- paste0(round(motif.enrichment$OR,digits = 2), 
                     " (", round(motif.enrichment$lowerOR,digits = 2),"-", 
                     round(motif.enrichment$upperOR,digits = 2),")")
    probe.col <- paste0(motif.enrichment$NumOfProbes,
                        " (", round(motif.enrichment$PercentageOfProbes, digits = 2),"%)")
    lab <- data.frame(x = factor(c("",as.character(motif.enrichment$motif)), 
                                 levels = rev(c("",as.character(motif.enrichment$motif)))),
                      y = rep(c(1,2,3),each=length(motif.enrichment$motif) + 1),
                      z = c("Motif",gsub("_HUMAN.H10MO.*","",as.character(motif.enrichment$motif)),
                            "Odds ratio \n (95% CI)",
                            or.col, 
                            "# probes \n(% of paired)",
                            probe.col)
    )
    
    data_table <-  ggplot(lab, aes(x = y, y = x, label = format(z, nsmall = 1))) +
      theme_minimal() + 
      geom_text(size = 2.5, hjust=0, vjust=0.5) +
      geom_hline(aes(yintercept=c(nrow(motif.enrichment) - 0.5))) + 
      labs(x="",y="") +
      coord_cartesian(xlim=c(1,3.8)) +
      theme(panel.grid.major = element_blank(), 
            panel.grid.minor.x  = element_blank(),panel.background =element_blank(), 
            legend.position = "none",
            panel.border = element_blank(), 
            axis.text.x = element_text(colour="white"),#element_blank(),
            axis.text.y = element_blank(), 
            axis.ticks = element_line(colour="white"),#element_blank(),
            plot.margin = unit(c(0,0,0,0), "lines"))
    
    motif.enrichment$motif <- factor(motif.enrichment$motif,
                                     levels=as.character(motif.enrichment$motif[nrow(motif.enrichment):1]))
    limits <- aes(ymax = upperOR, ymin=lowerOR)
    motif.enrichment$probes <- NULL
    motif.enrichment <- rbind(motif.enrichment,c(NA,NA,NA,NA))
    P <- ggplot(motif.enrichment, aes(x=motif, y=OR)) +
      geom_point() +
      geom_errorbar(limits, width=0.3) +
      coord_flip() +
      geom_abline(intercept = 1, slope = 0, linetype = "3313")+
      theme_bw() +
      theme(panel.grid.major = element_blank()) +
      xlab("") + ylab("Odds Ratio") +
      ggtitle(label = NULL, subtitle = NULL) + 
      scale_y_continuous(breaks=c(1,pretty(motif.enrichment$OR, n = 5))) + 
      theme(axis.text.y = element_blank(), 
            axis.ticks = element_line(colour="white"),#element_blank(),
            plot.margin = unit(c(0,0,0,0), "lines"))
    
    suppressWarnings({
      P <-  arrangeGrob(data_table, P, ncol=2,
                    widths = c(1,2), 
                    heights = c(0.95,0.05),top = title) 
        
    })    
  } else {
    
    motif.enrichment$motif <- factor(motif.enrichment$motif,
                                     levels=as.character(motif.enrichment$motif[nrow(motif.enrichment):1]))
    limits <- aes(ymax = upperOR, ymin=lowerOR)
    P <- ggplot(motif.enrichment, aes(x=motif, y=OR)) +
      geom_point() +
      geom_errorbar(limits, width=0.3) +
      coord_flip() +
      geom_abline(intercept = 1, slope = 0, linetype = "3313")+
      theme_bw() +
      theme(panel.grid.major = element_blank()) +
      xlab("Motifs") + ylab("Odds Ratio") +
      ggtitle(label = title, subtitle = NULL) + 
      scale_y_continuous(breaks=c(1,pretty(motif.enrichment$OR, n = 5)))
  }
  if(save) {
    ggsave(filename = sprintf("%s/%s.motif.enrichment.pdf",dir.out,label),
                  useDingbats = FALSE, 
                  plot = P,
                  width = 10, 
                  limitsize = FALSE,
                  height = 2 * round(nrow(motif.enrichment)/8))
    return()
  }
  if(summary) grid.arrange(P)
  return(P)
}



#' TF.rank.plot to plot the scores (-log10(P value)) which assess the correlation between 
#' TF expression and average DNA methylation at motif sites.
#' @description 
#' TF.rank.plot is a function to plot the scores (-log10(P value)) which assess the
#' correlation between TF expression and average DNA methylation at motif sites. The the motif 
#' relevant TF and top3 TFs will be labeled in a different color.
#'@importFrom ggplot2 scale_color_manual geom_vline geom_text position_jitter 
#'@importFrom ggplot2 annotation_custom unit ggplot_gtable ggplot_build
#'@importFrom ggrepel geom_text_repel
#'@param motif.pvalue A matrix or a path specifying location of  "XXX.with.motif.pvalue.rda"
#'which is output of getTF. 
#'@param motif A vector of characters specify the motif to plot
#'@param TF.label A list shows the label for each motif. If TF.label is not specified, 
#'the motif relevant TF and top3 TF will be labeled.
#'@param dir.out A path specify the directory to which the figures will be saved. 
#'Current directory is default.
#'@param save A logic. If true (default), figure will be saved to dir.out.
#'@return A plot shows the score (-log(P value)) of association between TF
#'expression and DNA methylation at sites of a certain motif.
#'@export
#' @author Lijing Yao (maintainer: lijingya@usc.edu)
#' @importFrom graphics plot
#' @importFrom ggplot2 ggsave
#'@examples
#' library(ELMER)
#'   data <- tryCatch(ELMER:::getdata("elmer.data.example"), error = function(e) {
#'   message(e)
#'   data(elmer.data.example, envir = environment())
#'   })
#' enriched.motif <- list("P53_HUMAN.H10MO.B"= c("cg00329272", "cg10097755", "cg08928189",
#'                                  "cg17153775", "cg21156590", "cg19749688", "cg12590404",
#'                                  "cg24517858", "cg00329272", "cg09010107", "cg15386853",
#'                                  "cg10097755", "cg09247779", "cg09181054"))
#' TF <- get.TFs(data, 
#'               enriched.motif, 
#'               group.col = "definition",
#'               group1 = "Primary solid Tumor", 
#'               group2 = "Solid Tissue Normal",
#'               TFs = data.frame(
#'                      external_gene_name=c("TP53","TP63","TP73"),
#'                      ensembl_gene_id= c("ENSG00000141510",
#'                                         "ENSG00000073282",
#'                                         "ENSG00000078900"),
#'                      stringsAsFactors = FALSE),
#'              label="hypo")
#' TF.meth.cor <- get(load("getTF.hypo.TFs.with.motif.pvalue.rda"))            
#' TF.rank.plot(motif.pvalue=TF.meth.cor,  
#'             motif="P53_HUMAN.H10MO.B", 
#'             TF.label=createMotifRelevantTfs("subfamily")["P53_HUMAN.H10MO.B"],
#'             save=TRUE)
#' TF.rank.plot(motif.pvalue=TF.meth.cor,  
#'             motif="P53_HUMAN.H10MO.B", 
#'             save=TRUE)
#' # Same as above
#' TF.rank.plot(motif.pvalue=TF.meth.cor,  
#'             motif="P53_HUMAN.H10MO.B", 
#'             dir.out = "TFplots",
#'             TF.label=createMotifRelevantTfs("family")["P53_HUMAN.H10MO.B"],
#'             save=TRUE)
TF.rank.plot <- function(motif.pvalue, 
                         motif, 
                         TF.label, 
                         dir.out = "./", 
                         save = TRUE){
  if(missing(motif.pvalue)) stop("motif.pvalue should be specified.")
  if(missing(motif)) stop("Please specify which motif you want to plot.")
  if(!all(motif %in% colnames(motif.pvalue))) {
    print(knitr::kable(sort(colnames(motif.pvalue)), col.names = "motifs"))
    stop("One of the motifs does not match. Select from the list above")
  }
  if(is.character(motif.pvalue)) {
    motif.pvalue <- get(load(motif.pvalue)) # The data is in the one and only variable
  }
  if(missing(TF.label)){
    motif.relavent.TFs <- createMotifRelevantTfs()
    TF.label <- motif.relavent.TFs[motif]
    specify <- "No"
  } else {
    specify <- "Yes"
  }
  significant <- floor(0.05 * nrow(motif.pvalue))
  motif.pvalue <- -log10(motif.pvalue)
  
  Plots <- list()
  for(i in motif){
    df <- data.frame(pvalue = motif.pvalue[,i], Gene = rownames(motif.pvalue), stringAsFactors = FALSE)
    df <- df[order(df$pvalue, decreasing = TRUE),]
    df$rank <- 1:nrow(df)
    TF.sub <- TF.label[[i]]
    #if(specify %in% "No"){
    #  TF.sub <- TF.sub[TF.sub %in% df$Gene[1:floor(0.05 * nrow(df))]]
    #}
    df$label <- "No"
    df$label[df$Gene %in% TF.sub|df$rank %in% 1:3] <- "Yes"
    df.label <- data.frame(pvalue = df$pvalue[df$label %in% "Yes"], 
                           text = as.character(df$Gene[df$label %in% "Yes"]), 
                           x = which(df$label %in% "Yes"), stringsAsFactors = FALSE)
    highlight <- df[df$label=="Yes",]
    P <- ggplot(df, aes(x=rank, y=pvalue, color=factor(label, levels = c("Yes","No"))))+
      scale_color_manual(values = c("red","black","purple"))+
      geom_vline(xintercept=significant, linetype = "3313")+
      geom_point() +
      theme_bw() +
      theme(panel.grid.major = element_blank(),
            panel.grid.minor = element_blank())+
      theme(legend.position="none")+
      labs(x = "Rank", y ="-log10 P value", title=i) + 
      geom_point(data=highlight, aes(x=rank, y=pvalue))
    
    df$Gene <- as.character(df$Gene)
    df$Gene[df$label %in% "No"] <- "" 
    P <- P + geom_text_repel(
      data = df,
      aes(label = Gene),
      min.segment.length = unit(0.0, "lines"),
      size = 3,
      segment.color = "gray",
      nudge_x = 10,
      show.legend = FALSE,
      fontface = 'bold', color = 'black',
      box.padding = unit(0.5, "lines"),
      point.padding = unit(1.0, "lines")
    ) 
    
    
    if(save){
      dir.create(dir.out, showWarnings = FALSE,recursive = TRUE)
      file <- sprintf("%s/%s.TFrankPlot.pdf",dir.out,i)
      message("Saving plot as: ", file)
      ggsave(P,filename = file, height = 8, width = 10)
    }
    Plots[[i]] <- P
  }
  if(!save) return(Plots)
}




