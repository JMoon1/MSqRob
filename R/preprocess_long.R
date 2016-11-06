#' Preprocess data in "long" format
#'
#'
#' @description Performs a standard preprocessing pipeline on data frames in "long" format (i.e. the data frame has one observation row per measurement (thus, multiple rows per subject)).
#' By default, data are aggregated by the \code{aggr_by} column (typically the peptides column) via a prespecified aggregation function. Next, intensity values are log2 transformed and then quantile normalized. Next, the \code{\link[=smallestUniqueGroups]{smallestUniqueGroups}} function is applied,
#' which removes proteins groups for which any of its member proteins is present in a smaller protein group. Then, unwanted sequences (such as reverse sequences or unwanted sequences) are filtered out.
#' Next, irrelevant columns are dropped. Then, peptide sequences that are identified only once in a single mass spec run are removed because with only 1 identification, the model will be perfectly confounded. Finally, potential experimental annotations are added to the data frame.
#' @param df A data frame that contains data in "long" format.
#' @param accession A character indicating the column that contains the unit on which you want to do inference (typically the protein identifiers). Defaults to "ProteinName".
#' @param split A character indicating which string is used to separate accession groups.
#' @param exp_annotation Either the path to the file which contains the experiment annotation or a data frame containing the experiment annotation. Exactly one colum in the experiment annotation should contain the mass spec run names. Annotation in a file can be both a tab-delimited text document or an Excel file. For more details, see \code{\link[utils]{read.table}} and \code{\link[openxlsx]{read.xlsx}}. As an error protection measurement, leading and trailing spaces in each column are trimmed off. The default, \code{NULL} indicates there is no (extra) annotation to be added.
#' @param type_annot If \code{exp_annotation} is a path to a file, the type of file. \code{type_annot} is mostly obsolete as supported files will be automatically recognized by their extension. Currently only \code{"tab-delim"} (tab-delimited file), \code{"xlsx"} (Office Open XML Spreadsheet file) and \code{NULL} (file type decided based on the extension) are supported. If the extension is not recognized, the file will be assumed to be a tab-delimited file. Defaults to \code{NULL}.
#' @param quant_col A character indicating the column that contains the quantitative values of interest (mostly peptide intensities or peptide areas under the curve). Defaults to \code{"quant_value"} (the name of the column after importing via the \code{\link{importDIAData}} function).
#' @param run_col A character indicating the column in data frame \code{df} that contains the mass spec run names.
#' @param aggr_by A character indicating the column by which the data should be aggregated. We advise to aggregate the data by peptide sequence (thus aggregate over different charge states and modification statuses of the same peptide). If you only want to aggregate over charge states, set \code{aggr_by} to the column corresponding to the modified sequences. If no aggregation at all is desired, create a new column in which you paste together the modified sequences and the charge states. Data will never be aggregated over different \code{run_col}.
#' @param aggr_function The function used to aggregate intensity data. Defaults to \code{"sum"}.
#' @param logtransform A logical value indicating whether the intensities should be log-transformed. Defaults to \code{TRUE}.
#' @param base A positive or complex number: the base with respect to which logarithms are computed. Defaults to 2.
#' @param normalisation A character vector of length one that describes how to normalise the data frame \code{df}. See \code{\link[=normalise-methods]{normalise}} for details. Defaults to \code{"quantiles"}. If no normalisation is wanted, set \code{normalisation="none"}.
#' @param smallestUniqueGroups A logical indicating whether proteins groups for which any of its member proteins is present in a smaller protein group should be removed from the dataset. Defaults to \code{TRUE}.
#' @param useful_properties The columns of the data frame \code{df} that are useful in the further analysis and/or inspection of the data and should be retained. Defaults to \code{c("ProteinName","ProteinDescription","ProteinAccession","PeptideSequence")}.
#' @param filter A vector of names corresponding to the columns in the data frame \code{df} that contain a \code{filtersymbol} that indicates which rows should be removed from the data.
#' Typical examples are contaminants or reversed sequences. Defaults to \code{"IsDecoy"}.
#' @param filter_symbol A character indicating the symbol in the columns corresponding to the \code{filter} argument that is used to indicate rows that should be removed from the data. Defaults to "True".
#' @param minIdentified A numeric value indicating the minimal number of times a peptide sequence should be identified in the dataset in order not to be removed. Defaults to 2.
#' @param colClasses_df character. A vector of classes to be assumed for the columns of the data frame \code{df}. Recycled if necessary. If named and shorter than required, names are matched to the column names with unspecified values are taken to be NA.
#' Possible values are \code{NA} (the default, when \code{type.convert} is used), \code{NULL} (when the column is skipped), one of the atomic vector classes (\code{logical}, \code{integer}, \code{numeric}, \code{complex}, \code{character}, \code{raw}), or \code{factor}, \code{Date} or \code{POSIXct}. Otherwise there needs to be an as method (from package \code{methods}) for conversion from \code{character} to the specified formal class.
#' @param colClasses_exp character. Only used when the \code{exp_annotation} argument is a filepath. A vector of classes to be assumed for the columns of the experimental annotation data frame. Recycled if necessary. If named and shorter than required, names are matched to the column names with unspecified values are taken to be NA.
#' Possible values are \code{NA} (the default, when \code{type.convert} is used), \code{NULL} (when the column is skipped), one of the atomic vector classes (\code{logical}, \code{integer}, \code{numeric}, \code{complex}, \code{character}, \code{raw}), or \code{factor}, \code{Date} or \code{POSIXct}. Otherwise there needs to be an as method (from package \code{methods}) for conversion from \code{character} to the specified formal class.
#' @param ... Optional arguments to be passed to the normalisation methods.
#' @return A preprocessed data frame that is ready to be converted into a \code{\link[=protdata-class]{protdata}} object.
#' @include preprocess_hlpFunctions.R
#' @export
preprocess_long <- function(df, accession, split, exp_annotation=NULL, type_annot=NULL, quant_col="quant_value", run_col, aggr_by, aggr_function="sum", logtransform=TRUE, base=2, normalisation, smallestUniqueGroups=TRUE, useful_properties, filter, filter_symbol, minIdentified=2, colClasses_df=NA, colClasses_exp=NA, ...)
{
  #df <- read.table(file, sep = "\t", header = TRUE, quote="", comment.char = "", na.strings = c("NA","#N/A"))

  #Remove potential NA rows
  df <- df[!is.na(df[,quant_col]),]

  #1. Aggregate peptides with the same sequence (parameter "aggr_by") (but maybe different charges and/or modifications)

  df$MSqRob_ID <- apply(df[,c(aggr_by,filter,run_col), drop=FALSE], 1, paste , collapse = "_")

  doubleIDs <- df$MSqRob_ID[duplicated(df$MSqRob_ID)]

  if(length(doubleIDs)>0){

    classes <- lapply(df, class)
    uniqueIDs <- unique(doubleIDs)
    n <- length(uniqueIDs)

    #Everything to character
    df2 <- data.frame(lapply(df[0,], as.character), stringsAsFactors=FALSE)
    df2[n,] <- NA

    #22 minutes on our system...
    for(i in 1:n){

      tmp <- df[df$MSqRob_ID==uniqueIDs[i], , drop=FALSE]
      df2[i,] <- apply(tmp, 2, function(x){paste0(unique(x), collapse = split)})
      df2[i,quant_col] <- do.call(aggr_function,list(tmp[,quant_col]))

    }

    #Set classes back as they were (if possible)
    for(j in 1:length(classes)){

      df2[,j] <- tryCatch(as(df2[,j], unlist(classes[j])), error=function(e){
        return(as.factor(df2[,j]))},
        warning=function(w){
          return(as.factor(df2[,j]))})
    }

    #rbind: "Factors have their levels expanded as necessary"
    df <- rbind(df[!(df$MSqRob_ID %in% doubleIDs), , drop=FALSE],df2)
    #Controle:
    #length(df$MSqRob_ID)==length(unique(df$MSqRob_ID)) #TRUE

  }

  # Faster way to aggregate: check importDIAData.R: maybe implement here and in preprocess_wide.R as well!!!!!!!!
  # data <- data %>% ungroup() %>% group_by_(filename.var, get(aggr_by),
  #                                          protein.var) %>% summarise_(quant_value = sumquant)

  #If colClasses_df is specified, change the colClasses
  df <- addColClasses(df, colClasses_df)

  #2. Log-transform

  if(isTRUE(logtransform)){
    #Log transform
    df[,quant_col] <- log(df[,quant_col], base=base)
    #Change -Inf values in the peptide intensities to NA
    df[,quant_col][is.infinite(df[,quant_col])] <- NA
  }

  #3. Change format for normalisation
  runs <- unique(df[,run_col])
  n_run <- vapply(runs, function(x) {return(sum(df[,run_col]==x))}, 1)
  normmatrix <- matrix(nrow=max(n_run), ncol=length(runs))

  #Everything to matrix format
  for(i in 1:length(runs)){
    normmatrix[1:sum(df[,run_col]==runs[i]),i] <- df[,quant_col][df[,run_col]==runs[i]]
  }

  #4. Normalisation

  if(normalisation=="none"){
    normmatrix <- normmatrix
  } else if (normalisation == "vsn") {
    normmatrix <- exprs(vsn::vsn2(normmatrix, ...))
  } else if (normalisation == "quantiles") {
    normmatrix <- preprocessCore::normalize.quantiles(normmatrix, ...)
  } else if (normalisation == "quantiles.robust") {
    normmatrix <- preprocessCore::normalize.quantiles.robust(normmatrix, ...)
  } else if (normalisation == "center.mean") {
    center <- colMeans(normmatrix, na.rm = TRUE)
    normmatrix <- sweep(normmatrix, 2L, center, check.margin = FALSE, ...)
  } else if (normalisation == "center.median") {
    center <- apply(normmatrix, 2L, median, na.rm = TRUE)
    normmatrix <- sweep(normmatrix, 2L, center, check.margin = FALSE, ...)
  } else {
    switch(normalisation,
           max = div <- apply(normmatrix, 1L, max, na.rm = TRUE),
           sum = div <- rowSums(normmatrix, na.rm = TRUE))
    normmatrix <- normmatrix/div
  }

  #Put everything back...
  for(i in 1:length(runs)){
    df[,quant_col][df[,run_col]==runs[i]] <- normmatrix[1:sum(df[,run_col]==runs[i]),i]
  }


  #5. Our approach: a peptide can map to multiple proteins,
  #as long as there is none of these proteins present in a smaller subgroup
  if(isTRUE(smallestUniqueGroups)){
    groups2 <- smallestUniqueGroups(df[,accession], split=split)
    sel <- df[,accession] %in% groups2
    df <- df[sel,]
  }


  #6. Remove contaminants, reverse sequences, possibly only identified by site
  if(!is.null(filter)){
    filterdata <- df[,filter, drop=FALSE]
    #Sometimes, there are no contaminants or no reverse sequences, R then reads these empty columns as "NA"
    filterdata[is.na(filterdata)] <- ""
    sel <- rowSums(filterdata!= filter_symbol)==length(filter)
    df <- df[sel,]
  }

  #Retain only those properties in the fData slot that are useful (or might be useful) for our further analysis:
  #This always includes the accession (protein) as well as the peptide identifier (almost always)
  #If the accession, intensity or mass spec run is not present, add it

  if(!(accession %in% useful_properties)){useful_properties <- c(accession,useful_properties)}
  if(!(aggr_by %in% useful_properties)){useful_properties <- c(aggr_by,useful_properties)}
  if(!(run_col %in% useful_properties)){useful_properties <- c(run_col,useful_properties)}
  if(!(quant_col %in% useful_properties)){useful_properties <- c(quant_col,useful_properties)}

  df <- df[,useful_properties]


  #7. How many times shoud a peptide be identified?
  #We require by default at least 2 identifications of a peptide sequence, as with 1 identification, the model will be perfectly confounded
  keepers <- names(which(table(df[,aggr_by])>=minIdentified)) #Works only for character vector!!!
  df <- df[df[,aggr_by] %in% keepers,]


  #8. Add experiment annotation
  if(!is.null(exp_annotation)){
    #df <- dfLongAddAnnotation(df, run_col, exp_annotation, type_annot, colClasses_exp)
    attr(df, "MSqRob_exp_annotation") <- exp_annotation
  }

  return(df)
}




#' Preprocess Spectronaut tsv files
#'
#'
#' @description Performs a standard preprocessing pipeline on data frames originating from Spectronaut tsv files.
#' By default, data are aggregated by the \code{aggr_by} column (typically the peptides column) via a prespecified aggregation function. Next, intensity values are log2 transformed and then quantile normalized. Next, the \code{\link[=smallestUniqueGroups]{smallestUniqueGroups}} function is applied,
#' which removes proteins groups for which any of its member proteins is present in a smaller protein group. Then, reverse sequences are removed.
#' Next, irrelevant columns are dropped. Then, peptide sequences that are identified only once in a single mass spec run are removed because with only 1 identification, the model will be perfectly confounded. Finally, potential experimental annotations are added to the data frame.
#' @param df A data frame that contains data originating from a Spectronaut tsv file.
#' @param accession A character indicating the column that contains the unit on which you want to do inference (typically the protein identifiers). Defaults to "EG.ProteinId".
#' @param exp_annotation Either the path to the file which contains the experiment annotation or a data frame containing the experiment annotation. Exactly one colum in the experiment annotation should contain the mass spec run names. Annotation in a file can be both a tab-delimited text document or an Excel file. For more details, see \code{\link[utils]{read.table}} and \code{\link[openxlsx]{read.xlsx}}. As an error protection measurement, leading and trailing spaces in each column are trimmed off. The default, \code{NULL} indicates there is no (extra) annotation to be added.
#' @param type_annot If \code{exp_annotation} is a path to a file, the type of file. \code{type_annot} is mostly obsolete as supported files will be automatically recognized by their extension. Currently only \code{"tab-delim"} (tab-delimited file), \code{"xlsx"} (Office Open XML Spreadsheet file) and \code{NULL} (file type decided based on the extension) are supported. If the extension is not recognized, the file will be assumed to be a tab-delimited file. Defaults to \code{NULL}.
#' @param quant_col A character indicating the column that contains the quantitative values of interest (mostly peptide intensities or peptide areas under the curve). Defaults to "quant_value" (the name of the column after importing via the \code{\link{importDIAData}} function).
#' @param run_col A character indicating the column that contains the mass spec run names. Defaults to \code{"R.FileName"}.
#' @param aggr_by A character indicating the column by which the data should be aggregated. The default \code{"EG.StrippedSequence"} will aggregate the data over different charge states and modification statuses. If you only want to aggregate over charge states, set \code{aggr_by} to the "EG.ModifiedSequence" column. If no aggregation at all is desired, create a new column in which you paste together the "EG.ModifiedSequence" and the "FG.Charge". Data will never be aggregated over different \code{run_col}.
#' @param aggr_function The function used to aggregate intensity data. Defaults to \code{"sum"}.
#' @param logtransform A logical value indicating whether the intensities should be log-transformed. Defaults to \code{TRUE}.
#' @param base A positive or complex number: the base with respect to which logarithms are computed. Defaults to 2.
#' @param normalisation A character vector of length one that describes how to normalise the data frame \code{df}. See \code{\link[=normalise-methods]{normalise}} for details. Defaults to \code{"quantiles"}. If no normalisation is wanted, set \code{normalisation="none"}.
#' @param smallestUniqueGroups A logical indicating whether proteins groups for which any of its member proteins is present in a smaller protein group should be removed from the dataset. Defaults to \code{TRUE}.
#' @param useful_properties The columns of the data frame \code{df} that are useful in the further analysis and/or inspection of the data and should be retained. Defaults to \code{c("species")}.
#' @param filter A vector of names corresponding to the columns in the data frame \code{df} that contain a \code{filtersymbol} that indicates which rows should be removed from the data.
#' Typical examples are contaminants or reversed sequences. Defaults to \code{"IsDecoy"}.
#' @param filter_symbol A character indicating the symbol in the columns corresponding to the \code{filter} argument that is used to indicate rows that should be removed from the data. Defaults to "True".
#' @param minIdentified A numeric value indicating the minimal number of times a peptide sequence should be identified in the dataset in order not to be removed. Defaults to 2.
#' @param colClasses_df character. A vector of classes to be assumed for the columns of the data frame \code{df}. Recycled if necessary. If named and shorter than required, names are matched to the column names with unspecified values are taken to be NA.
#' Possible values are \code{NA} (the default, when \code{type.convert} is used), \code{NULL} (when the column is skipped), one of the atomic vector classes (\code{logical}, \code{integer}, \code{numeric}, \code{complex}, \code{character}, \code{raw}), or \code{factor}, \code{Date} or \code{POSIXct}. Otherwise there needs to be an as method (from package \code{methods}) for conversion from \code{character} to the specified formal class.
#' @param colClasses_exp character. Only used when the \code{exp_annotation} argument is a filepath. A vector of classes to be assumed for the columns of the experimental annotation data frame. Recycled if necessary. If named and shorter than required, names are matched to the column names with unspecified values are taken to be NA.
#' Possible values are \code{NA} (the default, when \code{type.convert} is used), \code{NULL} (when the column is skipped), one of the atomic vector classes (\code{logical}, \code{integer}, \code{numeric}, \code{complex}, \code{character}, \code{raw}), or \code{factor}, \code{Date} or \code{POSIXct}. Otherwise there needs to be an as method (from package \code{methods}) for conversion from \code{character} to the specified formal class.
#' @param ... Optional arguments to be passed to the normalisation methods.
#' @return A preprocessed data frame that is ready to be converted into a \code{\link[=protdata-class]{protdata}} object.
#' @export
preprocess_Spectronaut <- function(df, accession="EG.ProteinId", exp_annotation=NULL, type_annot=NULL, quant_col="quant_value", run_col="R.FileName", aggr_by="EG.StrippedSequence", aggr_function="sum", logtransform=TRUE, base=2, normalisation="quantiles", smallestUniqueGroups=TRUE, useful_properties=c("species"), filter="EG.IsDecoy", filter_symbol=TRUE, minIdentified=2, colClasses_df=NA, colClasses_exp=NA, ...){

  dfnew <- preprocess_long(df, accession=accession, split="/", exp_annotation=exp_annotation, type_annot=type_annot, quant_col=quant_col, run_col=run_col, aggr_by=aggr_by, aggr_function=aggr_function, logtransform=logtransform, base=base, normalisation=normalisation, smallestUniqueGroups=smallestUniqueGroups, useful_properties=useful_properties, filter=filter, filter_symbol=filter_symbol, minIdentified=minIdentified, colClasses_df=colClasses_df, colClasses_exp=colClasses_exp)
  return(dfnew)

}


#' Preprocess Skyline tsv files
#'
#'
#' @description Performs a standard preprocessing pipeline on data frames originating from Skyline tsv files.
#' By default, data are aggregated by the \code{aggr_by} column (typically the peptides column) via a prespecified aggregation function. Next, intensity values are log2 transformed and then quantile normalized. Next, the \code{\link[=smallestUniqueGroups]{smallestUniqueGroups}} function is applied,
#' which removes proteins groups for which any of its member proteins is present in a smaller protein group. Then, reverse sequences are removed.
#' Next, irrelevant columns are dropped. Then, peptide sequences that are identified only once in a single mass spec run are removed because with only 1 identification, the model will be perfectly confounded. Finally, potential experimental annotations are added to the data frame.
#' @param df A data frame that contains data originating from a Skyline tsv file.
#' @param accession A character indicating the column that contains the unit on which you want to do inference (typically the protein identifiers). Defaults to "ProteinName".
#' @param exp_annotation Either the path to the file which contains the experiment annotation or a data frame containing the experiment annotation. Exactly one colum in the experiment annotation should contain the mass spec run names. Annotation in a file can be both a tab-delimited text document or an Excel file. For more details, see \code{\link[utils]{read.table}} and \code{\link[openxlsx]{read.xlsx}}. As an error protection measurement, leading and trailing spaces in each column are trimmed off. The default, \code{NULL} indicates there is no (extra) annotation to be added.
#' @param type_annot If \code{exp_annotation} is a path to a file, the type of file. \code{type_annot} is mostly obsolete as supported files will be automatically recognized by their extension. Currently only \code{"tab-delim"} (tab-delimited file), \code{"xlsx"} (Office Open XML Spreadsheet file) and \code{NULL} (file type decided based on the extension) are supported. If the extension is not recognized, the file will be assumed to be a tab-delimited file. Defaults to \code{NULL}.
#' @param quant_col A character indicating the column that contains the quantitative values of interest (mostly peptide intensities or peptide areas under the curve). Defaults to \code{"quant_value"} (the name of the column after importing via the \code{\link{importDIAData}} function).
#' @param run_col A character indicating the column that contains the mass spec run names. Defaults to \code{"ReplicateName"}.
#' @param aggr_by A character indicating the column by which the data should be aggregated. The default \code{"PeptideSequence"} will aggregate the data over different charge states and modification statuses. If you only want to aggregate over charge states, set \code{aggr_by} to the "ModifiedSequence" column. If no aggregation at all is desired, create a new column in which you paste together the "ModifiedSequence" and the "PrecursorCharge". Data will never be aggregated over different \code{run_col}.
#' @param aggr_function The function used to aggregate intensity data. Defaults to \code{"sum"}.
#' @param logtransform A logical value indicating whether the intensities should be log-transformed. Defaults to \code{TRUE}.
#' @param base A positive or complex number: the base with respect to which logarithms are computed. Defaults to 2.
#' @param normalisation A character vector of length one that describes how to normalise the data frame \code{df}. See \code{\link[=normalise-methods]{normalise}} for details. Defaults to \code{"quantiles"}. If no normalisation is wanted, set \code{normalisation="none"}.
#' @param smallestUniqueGroups A logical indicating whether proteins groups for which any of its member proteins is present in a smaller protein group should be removed from the dataset. Defaults to \code{TRUE}.
#' @param useful_properties The columns of the data frame \code{df} that are useful in the further analysis and/or inspection of the data and should be retained. Defaults to \code{c("ProteinName","ProteinDescription","ProteinAccession","PeptideSequence")}.
#' @param filter A vector of names corresponding to the columns in the data frame \code{df} that contain a \code{filtersymbol} that indicates which rows should be removed from the data.
#' Typical examples are contaminants or reversed sequences. Defaults to \code{"IsDecoy"}.
#' @param filter_symbol A character indicating the symbol in the columns corresponding to the \code{filter} argument that is used to indicate rows that should be removed from the data. Defaults to "True".
#' @param minIdentified A numeric value indicating the minimal number of times a peptide sequence should be identified in the dataset in order not to be removed. Defaults to 2.
#' @param colClasses_df character. A vector of classes to be assumed for the columns of the data frame \code{df}. Recycled if necessary. If named and shorter than required, names are matched to the column names with unspecified values are taken to be NA.
#' Possible values are \code{NA} (the default, when \code{type.convert} is used), \code{NULL} (when the column is skipped), one of the atomic vector classes (\code{logical}, \code{integer}, \code{numeric}, \code{complex}, \code{character}, \code{raw}), or \code{factor}, \code{Date} or \code{POSIXct}. Otherwise there needs to be an as method (from package \code{methods}) for conversion from \code{character} to the specified formal class.
#' @param colClasses_exp character. Only used when the \code{exp_annotation} argument is a filepath. A vector of classes to be assumed for the columns of the experimental annotation data frame. Recycled if necessary. If named and shorter than required, names are matched to the column names with unspecified values are taken to be NA.
#' Possible values are \code{NA} (the default, when \code{type.convert} is used), \code{NULL} (when the column is skipped), one of the atomic vector classes (\code{logical}, \code{integer}, \code{numeric}, \code{complex}, \code{character}, \code{raw}), or \code{factor}, \code{Date} or \code{POSIXct}. Otherwise there needs to be an as method (from package \code{methods}) for conversion from \code{character} to the specified formal class.
#' @param ... Optional arguments to be passed to the normalisation methods.
#' @return A preprocessed data frame that is ready to be converted into a \code{\link[=protdata-class]{protdata}} object.
#' @export
preprocess_Skyline <- function(df, accession="ProteinName", exp_annotation=NULL, type_annot=NULL, quant_col="quant_value", run_col="ReplicateName", aggr_by="PeptideSequence", aggr_function="sum", logtransform=TRUE, base=2, normalisation="quantiles", smallestUniqueGroups=TRUE, useful_properties=c("ProteinName","ProteinDescription","ProteinAccession","PeptideSequence"), filter="IsDecoy", filter_symbol="True", minIdentified=2, colClasses_df=NA, colClasses_exp=NA, ...){

  dfnew <- preprocess_long(df, accession=accession, split="/", exp_annotation=exp_annotation, type_annot=type_annot, quant_col=quant_col, run_col=run_col, aggr_by=aggr_by, aggr_function=aggr_function, logtransform=logtransform, base=base, normalisation=normalisation, smallestUniqueGroups=smallestUniqueGroups, useful_properties=useful_properties, filter=filter, filter_symbol=filter_symbol, minIdentified=minIdentified, colClasses_df=colClasses_df, colClasses_exp=colClasses_exp)
  return(dfnew)

}

