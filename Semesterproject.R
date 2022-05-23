# Install libraries & download data

library(tidyverse)
devtools::install_github("ComputationalMovementAnalysis/ComputationalMovementAnalysisData")
library(ComputationalMovementAnalysisData)
library(sf)

wildschwein_BE
wildschwein_metadata
wildschwein_overlap_temp

schreck_agenda
schreck_locations


# Exploratory Data Analysis

## Convert data to sf formats

schreck_locations
schreck_locations_sf <- st_as_sf(schreck_locations,
                                 coords = c("lon", "lat"),
                                 crs = 4326)
schreck_locations_sf

wildschwein_BE
wildschwein_BE_sf <- st_as_sf(wildschwein_BE,
                                 coords = c("E", "N"),
                                 crs = 2056)
wildschwein_BE_sf

### Convert wildschwein_BE from crs 2056 (WGS84) to crs 4326 (CH1903+ / LV95)

wildschwein_BE_sf <- st_transform(wildschwein_BE_sf, crs = 4326)
wildschwein_BE_sf


## Visualize the data

# for Macs (alternatively just use ggplot() instead of x11_ggplot())
x11_ggplot <- function(...) {
  X11(type = "cairo")
  ggplot(...)
}

x11_ggplot() +
  geom_sf(data = schreck_locations_sf, colour = "red") +
  geom_sf(data = wildschwein_BE_sf, colour = "blue") +
  annotation_scale()

ggplot() +
  geom_point(data = wildschwein_BE, mapping = aes(x = E, y = N))

ggplot() +
  geom_point(data = schreck_locations, mapping = aes(x = lon, y = lat))
