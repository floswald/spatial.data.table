#' Encode Simple Feature
#'
#' Converts coordinates from simple-feature objects (\code{sf}) into encoded polylines
#'
#' @param sf simple-feature object (from \code{library(sf)})
#'
#' @examples
#' library(sf)
#' library(magrittr)
#'
#' sf_poly <- st_as_sfc(c("POLYGON((-80.190 25.774, -66.118 18.466, -64.757 32.321))",
#'                        "POLYGON((-70.579 28.745, -67.514 29.570, -66.668 27.339))")) %>%
#'           st_sf()
#'
#' EncodeSF(sf_poly)
#'
#' @export
EncodeSF <- function(sf){

	dataCols <- setdiff(names(sf), attr(sf, 'sf_column'))
	if(length(dataCols) == 0){
		dt <- data.table::data.table(id = 1:nrow(sf))
	}else{
		dt <- data.table::as.data.table(sf)[, dataCols, with = F]
		## TODO:
		## accept an ID column
		dt[, id := .I]
	}

	geom <- sf::st_geometry(sf)

	dt_geom <- EncodePolyline(geom)

	return(dt_geom)
	#return(dt[ dt_geom, on = c(id = ".id"), nomatch = 0])

}


EncodePolyline <- function(geom) UseMethod("encodePolyline")


#' @export
encodePolyline.sfc_LINESTRING <- function(geom){

		pl <- sapply(1:length(geom), function(x){
			m <- unlist(geom[[x]])
			encode_pl(m[,2],m[,1])
		})

		return(data.table::data.table(.id = 1:length(geom),
																	polyline = pl))
}

#' @export
encodePolyline.sfc_POLYGON <- function(geom){

	data.table::rbindlist(
		lapply(geom, function(x){
				data.table::data.table(
					polyline = sapply(x, function(y){
						encode_pl(y[,2],y[,1])
						})
				)
		}), idcol = T
	)
}

#' @export
encodePolyline.sfc_MULTIPOLYGON <- function(geom){

	data.table::rbindlist(

		lapply(geom, function(x){

			data.table::rbindlist(

				lapply(x, function(y){
					pl <- sapply(y, function(z){
						encode_pl(z[,2], z[,1])
					})
					lineId <- seq_along(pl)
					hole = lineId > 1
					data.table::data.table(lineId = lineId, polyline = pl, hole = hole)
				})
			)
		}), idcol = T
	)
}

#' @export
encodePolyline.default <- function(geom){
	message(paste0("Many apologies, I don't know how to handle objects of class ", class(geom)))
}







