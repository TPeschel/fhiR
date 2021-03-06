% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fhir_table_description.R
\docType{class}
\name{fhir_table_description-class}
\alias{fhir_table_description-class}
\title{A S4 class describing the form of data.frame produced by \code{\link[=fhir_crack]{fhir_crack()}}}
\description{
A \code{fhir_table_description} is part of a \code{fhir_design} and holds the information \code{\link[=fhir_crack]{fhir_crack()}} needs to flatten (aka crack)
FHIR resources from a FHIR bundle and is created with \code{\link[=fhir_table_description]{fhir_table_description()}}.
There should be one \code{fhir_table_description} per resource type as \code{\link[=fhir_crack]{fhir_crack()}} will create one data.frame/data.table
per resource type. See Details.
}
\details{
A \code{fhir_table_description} consists of
the following elements:
\itemize{
\item The resource element: Defines the resource type (e.g. \code{Patient} or \code{Observation}). See \code{\link[=fhir_resource_type]{fhir_resource_type()}}.
\item The cols element: Contains the column names and XPath expressions defining the columns to extract.
If this element is empty, \code{\link[=fhir_crack]{fhir_crack()}} will extract all available elements of the resource and name the
columns automatically. See \code{\link[=fhir_columns]{fhir_columns()}}.
\item The style element: Defines how to deal with multiple entries to the same element and whether empty columns are
removed. See \code{\link[=fhir_style]{fhir_style()}}.
}

A full \code{fhir_table_description} looks for example like this:\preformatted{fhir_resource_type: Patient

fhir_columns:
column name | xpath expression
------------------------
name        | name/family
gender      | gender
id          | id

fhir_style:
sep: ||
brackets: '[' ']'
rm_empty_cols: FALSE
}
}
\section{Slots}{

\describe{
\item{\code{resource}}{An object of class \linkS4class{fhir_resource_type} defining the resource type that
should be extracted.}

\item{\code{cols}}{An object of class \linkS4class{fhir_columns} describing which columns should be created and how.
If this is an empty \linkS4class{fhir_columns} object, the call to \code{\link[=fhir_crack]{fhir_crack()}} will extract all available
elements and put them in automatically named columns.}

\item{\code{style}}{An object of class \linkS4class{fhir_style} describing how to deal with multiple entries and emtpy columns.}
}}

\seealso{
\code{\link[=fhir_resource_type]{fhir_resource_type()}},\code{\link[=fhir_columns]{fhir_columns()}},\code{\link[=fhir_style]{fhir_style()}}, \code{\link[=fhir_design]{fhir_design()}}, \code{\link[=fhir_crack]{fhir_crack()}}
}
