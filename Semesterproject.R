# Install libraries & download data

library(tidyverse)
devtools::install_github("ComputationalMovementAnalysis/ComputationalMovementAnalysisData")
library(ComputationalMovementAnalysisData)
library(sf)
library(leaflet)
library(leaflet.extras2)
library(gganimate)
library(ggspatial)

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

### Convert schreck_locations_sf from crs 4326 (WGS84) to crs 2056 (CH1903+ / LV95)

schreck_locations_sf <- st_transform(schreck_locations_sf, crs = 2056)


## Visualize the data (schreck and wildschwein locations)

ggplot() +
  geom_sf(data = wildschwein_BE_sf, colour = "blue") +
  geom_sf(data = schreck_locations_sf, colour = "red", alpha = 0.5) +
  annotation_scale()


# Crop both sf data frames (wildschwein & schreck locations) to only show area with significant overlap

wildschwein_BE_sf_cropped <- st_crop(wildschwein_BE_sf, xmin = 6.9, xmax = 7.2, ymin = 46.9, ymax = 47.05)
schreck_locations_sf_cropped <- st_crop(schreck_locations_sf, xmin = 6.9, xmax = 7.2, ymin = 46.9, ymax = 47.05)

ggplot() +
  geom_sf(data = wildschwein_BE_sf_cropped, colour = "blue") +
  annotation_scale()

ggplot() +
  geom_sf(data = schreck_locations_sf_cropped, colour = "red", alpha = 0.5) +
  annotation_scale()

ggplot() +
  geom_sf(data = wildschwein_BE_sf_cropped, colour = "blue") +
  geom_sf(data = schreck_locations_sf_cropped, colour = "red", alpha = 0.5) +
  annotation_scale()


# Try to visualize the shreck events

# First step: Join the schreck locations with the schreck events

view(schreck_agenda)
view(schreck_locations_sf_cropped)

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
  annotation_scale()

ggplot() +
  geom_sf(data = schreck_agenda_and_locations_daily, mapping = aes(color = id)) +
  transition_manual(activeDay) +
  labs(title = 'Values at {(current_frame)}') +
  annotation_scale()



### Density plots for number of GPS points within radius around each schreck location over a certain number of days before, during and after schreck events ###

# Filter Schreck-Agenda to the times when we have Wildschwein Data
schreck_agenda_and_locations_filtered <- schreck_agenda_and_locations %>%
  filter(
    datum_on > min(wildschwein_BE_sf_cropped$DatetimeUTC),
    datum_off < max(wildschwein_BE_sf_cropped$DatetimeUTC)
  )
schreck_agenda_and_locations_filtered

# We do this to merge the two events each for WSS_2015_01, WSS_2015_03, WSS_2015_04
schreck_agenda_and_locations_merged <- schreck_agenda_and_locations_filtered %>%
  group_by(id) %>%
  summarise(
    datum_on = min(datum_on),
    datum_off = max(datum_off)
  )
schreck_agenda_and_locations_merged


# Create function that can automatically draw a denstiy plot for a specific schreck location 
# & specify number of days before and after schreck event that should appear on plot
# & specify the radius around schreck location
draw_density_plot <- function(schreck_id, radius, days_before, days_after) {
  # Filter schreck agenda to specific schreck
  specific_schreck <- schreck_agenda_and_locations_merged %>%
    filter(id == schreck_id)
  
  # Draw a circle around that schreck
  specific_schreck_circle <- st_buffer(specific_schreck, dist = radius)
  
  # Filter wildschwein points by date to only ones occuring within above-mentioned schreck event (7 days before, during and 21 days after)
  specific_schreck_wildschwein <- wildschwein_BE_sf_cropped %>%
    filter(
      DatetimeUTC > as.Date(specific_schreck$datum_on) - days_before,
      DatetimeUTC < as.Date(specific_schreck$datum_off) + days_after
    )
  
  # Filter the above-mentioned wildschwein points to ones within the schreck circle
  specific_schreck_wildschwein_cropped <- specific_schreck_wildschwein %>%
    st_filter(specific_schreck_circle)
  
  # Create a new convenience variable (date, without time)
  specific_schreck_wildschwein_cropped <- specific_schreck_wildschwein_cropped %>%
    mutate(
      date = as.Date(DatetimeUTC)
    )
  
  # Plot the number of wildschwein per day within the schreck circle from 7 days before until 21 days after the schreck event
  # Then add 2 lines to signify start and end off schreck event
  density_plot_specific_schreck <- specific_schreck_wildschwein_cropped %>%
    group_by(date) %>%
    ggplot() +
    geom_density(mapping = aes(x = date)) + 
    geom_segment(aes(x = as.Date(specific_schreck$datum_on), y = 0, xend = as.Date(specific_schreck$datum_on), yend = 0.05)) +
    geom_segment(aes(x = as.Date(specific_schreck$datum_off), y = 0, xend = as.Date(specific_schreck$datum_off), yend = 0.05))
  
  return(density_plot_specific_schreck)
}

# Draw the plots for each relevant schreck location

WSS_2015_01_plot <- draw_density_plot("WSS_2015_01", 150, 10, 14)
WSS_2015_01_plot

WSS_2015_03_plot <- draw_density_plot("WSS_2015_03", 150, 10, 14)
WSS_2015_03_plot

WSS_2015_04_plot <- draw_density_plot("WSS_2015_04", 150, 10, 14)
WSS_2015_04_plot

WSS_2016_01_plot <- draw_density_plot("WSS_2016_01", 150, 10, 14)
WSS_2016_01_plot

WSS_2016_05_plot <- draw_density_plot("WSS_2016_05", 150, 10, 14)
WSS_2016_05_plot

WSS_2016_06_plot <- draw_density_plot("WSS_2016_06", 150, 10, 14)
WSS_2016_06_plot

WSS_2016_13_plot <- draw_density_plot("WSS_2016_13", 150, 10, 14)
WSS_2016_13_plot
