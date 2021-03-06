## This file contains all functions dealing with multiple entries/indices##
## Exported functions are on top, internal functions below ##



#' Find common columns
#'
#' This is a convenience function to find all column names in a data frame starting with the same string that can
#' then be used for [fhir_melt()].
#'
#' It is intended for use on data frames with column names that have been automatically produced by [fhir_design()]/[fhir_crack()]
#' and follow the form `level1.level2.level3` such as `name.given` or `code.coding.system`.
#' Note that this function will only work on column names following exactly this scheme.
#'
#' The resulting character vector can be used for melting all columns belonging to the same attribute in an indexed data frame,
#' see `?fhir_melt`.
#'
#' @param data_frame A data.frame/data.table with automatically named columns as produced by [fhir_crack()].
#' @param column_names_prefix A string containing the common prefix of the desired columns.
#' @return A character vector with the names of all columns matching `column_names_prefix`.
#' @examples
#' #unserialize example bundles
#' bundles <- fhir_unserialize(bundles = medication_bundles)
#'
#' #crack Patient Resources
#' pats <- fhir_table_description(resource = "Patient")
#'
#' df <- fhir_crack(bundles = bundles, design = pats)
#'
#' #look at automatically generated names
#' names(df)
#'
#' #extract all column names beginning with the string "name"
#' fhir_common_columns(data_frame = df, column_names_prefix = "name")
#' @export
#' @seealso [fhir_melt()], [fhir_rm_indices()]
#'
fhir_common_columns <- function(data_frame, column_names_prefix) {
	if(!is.data.frame(data_frame)) {
		stop(
			"You need to supply a data.frame or data.table to the argument indexed_data_frame.",
			"The object you supplied is of type ", class(data_frame), "."
		)
	}
	pattern_column_names  <- paste0("^", column_names_prefix, "($|\\.+)")
	column_names <- names(data_frame)
	hits <- grepl(pattern_column_names, column_names)
	if(!any(hits)) {stop("The column prefix you gave doesn't appear in any of the column names.")}
	column_names[hits]
}


#' Melt multiple entries
#'
#' This function divides multiple entries in an indexed data frame as produced by [fhir_crack()].
#' into separate rows.
#'
#' Every row containing values that consist of multiple entries on the variables specified by the argument `columns`
#' will be turned into multiple rows, one for each entry. Values on other variables will be repeated in all the new rows.
#'
#' The new data.frame will contain only the molten variables (if `all_cloumns = FALSE`) or all variables
#' (if `all_columns = TRUE`) as well as an additional variable `resource_identifier` that maps which rows came
#' from the same origin. The name of this column can be changed in the argument `id_name`.
#'
#' For a more detailed description on how to use this function please see the corresponding package vignette.
#'
#' @param indexed_data_frame A data.frame/data.table with indexed multiple entries.
#' @param columns A character vector specifying the names of all columns that should be molten simultaneously.
#' It is advisable to only melt columns simultaneously that belong to the same (repeating) attribute!
#' @param brackets A character vector of length two, defining the brackets used for the indices.
#' @param sep A character vector of length one defining the separator that was used when pasting together multiple entries in [fhir_crack()].
#' @param id_name A character vector of length one, the name of the column that will hold the identification of the origin of the new rows.
#' @param all_columns Return all columns? Defaults to `FALSE`, meaning only those specified in `columns` are returned.
#'
#' @return A data.frame/data.table where each entry from the variables in `columns` appears in a separate row.
#'
#' @examples
#' #unserialize example
#' bundles <- fhir_unserialize(bundles = example_bundles1)
#'
#' #crack fhir resources
#' table_desc <- fhir_table_description(resource = "Patient",
#'                                      style = fhir_style(brackets = c("[","]"),
#'                                                         sep = " "))
#' df <- fhir_crack(bundles = bundles, design = table_desc)
#'
#' #find all column names associated with attribute address
#' col_names <- fhir_common_columns(df, "address")
#'
#' #original data frame
#' df
#'
#' #only keep address columns
#' fhir_melt(indexed_data_frame = df, columns = col_names,
#'           brackets = c("[","]"), sep = " ")
#'
#' #keep all columns
#' fhir_melt(indexed_data_frame = df, columns = col_names,
#'           brackets = c("[","]"), sep = " ", all_columns = TRUE)
#' @export
#' @seealso [fhir_common_columns()], [fhir_rm_indices()]

fhir_melt <- function(
	indexed_data_frame,
	columns,
	brackets = c("<", ">"),
	sep = " ",
	id_name = "resource_identifier",
	all_columns = FALSE) {

	if(!is.data.frame(indexed_data_frame)) {
		stop(
			"You need to supply a data.frame or data.table to the argument indexed_data_frame.",
			"The object you supplied is of type ", class(indexed_data_frame), "."
		)
	}
	if(!all(columns %in% names(indexed_data_frame))) {
		stop("Not all column names you gave match with the column names in the data frame.")
	}
	indexed_dt <- copy(indexed_data_frame) #copy to avoid side effects
	is_DT <- data.table::is.data.table(x = indexed_dt)
	if(!is_DT) {data.table::setDT(x = indexed_dt)}
	brackets <- fix_brackets(brackets = brackets)
	d <- data.table::rbindlist(
		lapply(
			seq_len(nrow(indexed_dt)),
			function(row.id) {
				e <-melt_row(
					row = indexed_dt[row.id,],
					columns = columns,
					brackets = brackets,
					sep = sep,
					all_columns = all_columns
				)
				if(0 < nrow(e)) {e[seq_len(nrow(e)), (id_name) := row.id]}
				e
			}
		),
		fill = TRUE
	)
	if(nrow(d) == 0) {warning("The brackets you specified don't seem to appear in the indices of the provided data.frame. Returning NULL.")}
	if(!is.null(d) && 0 < nrow(d)) {
		data.table::setorderv(x = d, cols = id_name)
		if(!is_DT) {setDF(d)}
		return(d)
	}
}


#' Remove indices from data.frame/data.table
#'
#' Removes the indices in front of multiple entries as produced by [fhir_crack()] when brackets are provided in
#' the design.
#' @param indexed_data_frame A data frame with indices for multiple entries as produced by [fhir_crack()]
#' @param brackets A character vector of length two defining the brackets that were used in [fhir_crack()]
#' @param columns A character vector of column names, indicating from which columns indices should be removed.
#' Defaults to all columns.
#'
#' @return A data frame without indices.
#' @export
#'
#' @examples
#'
#' #unserialize example
#' bundles <- fhir_unserialize(bundles = example_bundles1)
#'
#' patients <- fhir_table_description(resource = "Patient")
#'
#' df <- fhir_crack(bundles = bundles,
#'                   design = patients,
#'                   brackets = c("[", "]"))
#'
#' df_indices_removed <- fhir_rm_indices(indexed_data_frame = df, brackets=c("[", "]"))
#'
#' @seealso [fhir_melt()]


fhir_rm_indices <- function(indexed_data_frame, brackets = c("<", ">"), columns = names( indexed_data_frame )) {
	if(!is.data.frame(indexed_data_frame)) {
		stop(
			"You need to supply a data.frame or data.table to the argument indexed_data_frame.",
			"The object you supplied is of type ", class(indexed_data_frame), "."
		)
	}
	indexed_dt <- copy(indexed_data_frame) #copy to avoid side effects
	is_DT <- data.table::is.data.table(x = indexed_dt)
	if(!is_DT) {data.table::setDT(x = indexed_dt)}
	brackets <- fix_brackets(brackets = brackets)
	brackets.escaped <- esc(s = brackets)
	pattern.ids <- paste0(brackets.escaped[1], "([0-9]+\\.*)*", brackets.escaped[2])
	if(!any(grepl(pattern.ids, indexed_dt))) {
		warning("The brackets you specified don't seem to appear in the data.frame.")
	}
	result <- data.table::data.table(gsub(pattern = pattern.ids, replacement = "", x = as.matrix(indexed_dt[,columns, with = FALSE])))
	indexed_dt[,columns] <- result
	if(!is_DT) {data.table::setDF(x = indexed_dt)}
	indexed_dt
}

########################################################################################
########################################################################################


#' Turn a row with multiple entries into a data frame
#'
#' @param row One row of an indexed data frame
#' @param columns A character vector specifying the names of all columns that should be molten simultaneously.
#' It is advisable to only melt columns simultaneously that belong to the same (repeating) attribute!
#' @param brackets A character vector of length 2, defining the brackets used for the indices.
#' @param sep A character vector of length one, the separator.
#' @param all_columns Return all columns? Defaults to `FALSE`, meaning only those specified in `columns` are returned.
#' @return A data frame with nrow > 1.
#' @noRd


melt_row <- function(row, columns, brackets = c("<", ">"), sep = " ", all_columns = FALSE) {
	row <- as.data.frame(row)
	col.names.mutable  <- columns
	col.names.constant <- setdiff(names(row), col.names.mutable)
	row.mutable  <- row[col.names.mutable]
	row.constant <- row[col.names.constant]
	brackets.escaped <- esc(s = brackets)
	pattern.ids <- paste0(brackets.escaped[1], "([0-9]+\\.*)+", brackets.escaped[2])
	ids <- stringr::str_extract_all(string = row.mutable, pattern = pattern.ids)
	names(ids) <- col.names.mutable
	pattern.items <- paste0(brackets.escaped[1], "([0-9]+\\.*)+", brackets.escaped[2])
	items <- stringr::str_split(string = row.mutable, pattern = pattern.items)
	items <- lapply(
		items,
		function(i) {
			if(!all(is.na(i)) && i[1] == "") {i[2:length(i)]} else {i}
		}
	)
	names(items) <- col.names.mutable
	d <- if(all_columns) {row[0, , FALSE]} else {row[0, col.names.mutable, FALSE]}
	for(i in names(ids)) {
		id <- ids[[i]]
		if(!all(is.na(id))) {
			it <- items[[i]]
			new.rows <- gsub(paste0(brackets.escaped[1], "([0-9]+)\\.*.*"), "\\1", id)
			new.ids <- gsub(paste0("(", brackets.escaped[1], ")([0-9]+)\\.*(.*", brackets.escaped[2], ")" ), "\\1\\3", id)
			unique.new.rows <- unique(new.rows)
			set <- paste0(new.ids, it)
			f <- sapply(
				unique.new.rows,
				function(unr) {
					fltr <- unr == new.rows
					paste0(set[fltr], collapse = "")
				}
			)
			for(n in unique.new.rows) {
				d[as.numeric(n), i] <- gsub(pattern = paste0(esc(sep), "$"), replacement = "", x = f[names(f) == n], perl = TRUE)
			}
		}
	}
	if (0 < length(col.names.constant) && all_columns) {
		if (0 < nrow(d)) {
			d[, col.names.constant] <- dplyr::select(.data = row, col.names.constant)
		} else{
			d[1, col.names.constant] <- dplyr::select(.data = row, col.names.constant)
		}
	}
	data.table::data.table(d)
}
