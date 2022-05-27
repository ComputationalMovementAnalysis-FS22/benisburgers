# Install libraries & download data

library(tidyverse)
devtools::install_github("ComputationalMovementAnalysis/ComputationalMovementAnalysisData")
library(ComputationalMovementAnalysisData)
library(sf)
library(leaflet)
library(leaflet.extras2)
library(gganimate)

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


## Visualize the data (schreck and wildschwein locations)

ggplot() +
  geom_sf(data = wildschwein_BE_sf, colour = "blue") +
  geom_sf(data = schreck_locations_sf, colour = "red", alpha = 0.5)


# Crop both sf data frames (wildschwein & schreck locations) to only show area with significant overlap

wildschwein_BE_sf_cropped <- st_crop(wildschwein_BE_sf, xmin = 6.9, xmax = 7.2, ymin = 46.9, ymax = 47.05)
schreck_locations_sf_cropped <- st_crop(schreck_locations_sf, xmin = 6.9, xmax = 7.2, ymin = 46.9, ymax = 47.05)

ggplot() +
  geom_sf(data = wildschwein_BE_sf_cropped, colour = "blue")

ggplot() +
  geom_sf(data = schreck_locations_sf_cropped, colour = "red", alpha = 0.5)

ggplot() +
  geom_sf(data = wildschwein_BE_sf_cropped, colour = "blue") +
  geom_sf(data = schreck_locations_sf_cropped, colour = "red", alpha = 0.5)


# Try to visualize the shreck events

# First step: Join the schreck locations with the schreck events

view(schreck_agenda)

schreck_agenda_and_locations <- schreck_locations_sf_cropped %>%
  left_join(schreck_agenda, by = "id")

view(schreck_agenda_and_locations)

# Second step: Create a new data frame for every day for every schreck location that is active (see column 'activeDay')

schreck_agenda_and_locations_daily <- schreck_agenda_and_locations %>%
  mutate(activeDay = map2(datum_on, datum_off, seq, by = "1 day")) %>%
  unnest
view(schreck_agenda_and_locations_daily)

# Try to visualize these events somehow


ggplot(data = schreck_agenda_and_locations_daily) +
  geom_sf(mapping = aes(color = id)) +
  transition_manual(activeDay)

ggplot() +
  geom_sf(data = schreck_agenda_and_locations_daily, mapping = aes(color = id) +
  transition_manual(activeDay) +
  labs(title = 'Values at {(current_frame)}')
