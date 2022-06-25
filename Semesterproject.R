# Install libraries & download data

library(tidyverse)
devtools::install_github("ComputationalMovementAnalysis/ComputationalMovementAnalysisData")
library(ComputationalMovementAnalysisData)
library(sf)
library(leaflet)
library(leaflet.extras2)
library(gganimate)
library(ggspatial)
library(cowplot)
library(multcompView)


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
schreck_locations_sf


## Visualize the data (schreck and wildschwein locations)

ggplot() +
  geom_sf(data = wildschwein_BE_sf, colour = "blue") +
  geom_sf(data = schreck_locations_sf, colour = "red", alpha = 0.5) +
  annotation_scale() +
  coord_sf(datum=st_crs(2056))


# Crop both sf data frames (wildschwein & schreck locations) to only show area with significant overlap

wildschwein_BE_sf_cropped <- st_crop(wildschwein_BE_sf, xmin = 2560000, xmax = 2580000, ymin = 1200000, ymax = 1220000)
schreck_locations_sf_cropped <- st_crop(schreck_locations_sf, xmin = 2560000, xmax = 2580000, ymin = 1200000, ymax = 1220000)

ggplot() +
  geom_sf(data = wildschwein_BE_sf_cropped, colour = "blue") +
  annotation_scale() +
  coord_sf(datum=st_crs(2056))

ggplot() +
  geom_sf(data = schreck_locations_sf_cropped, colour = "red", alpha = 0.5) +
  annotation_scale() +
  coord_sf(datum=st_crs(2056))

ggplot() +
  geom_sf(data = wildschwein_BE_sf_cropped, colour = "blue") +
  geom_sf(data = schreck_locations_sf_cropped, colour = "red", alpha = 0.5) +
  annotation_scale() +
  coord_sf(datum=st_crs(2056))


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
  annotation_scale() +
  coord_sf(datum=st_crs(2056))

ggplot() +
  geom_sf(data = schreck_agenda_and_locations_daily, mapping = aes(color = id)) +
  transition_manual(activeDay) +
  labs(title = 'Values at {(current_frame)}') +
  annotation_scale() +
  coord_sf(datum=st_crs(2056))

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
# & specify the radii around schreck location
draw_density_plot <- function(schreck_id, radii, days_before, days_after) {
  # Filter schreck agenda to specific schreck
  specific_schreck <- schreck_agenda_and_locations_merged %>%
    filter(id == schreck_id)
  
  # Filter all wildschwein points by date to only ones occuring within above-mentioned schreck event (7 days before, during and 21 days after)
  specific_schreck_wildschwein <- wildschwein_BE_sf_cropped %>%
    filter(
      DatetimeUTC > as.Date(specific_schreck$datum_on) - days_before,
      DatetimeUTC < as.Date(specific_schreck$datum_off) + days_after
    )
  
  # For each radius (x) in radii... (this creates a vector with one SF data frame per radius in radii)
  schreck_specific_wildschwein_points <- radii %>% map(
    .f = function(x){
      # ... Create a circle / buffer with radius x around schreck 
      circle <- st_buffer(specific_schreck, x)
      # ... Filter all date-relevant wildschwin points to the ones in circle with radius x
      pigs_in_circle <- st_filter(specific_schreck_wildschwein, circle)
      # ... Add some convenience variables (radius and date) in order to visualize the density plots
      pigs_in_circle <- pigs_in_circle %>%
        mutate(
          radius = as.factor(x),
          date = as.Date(DatetimeUTC)
        )
      # ... return SF Data frame with the relevant pigs for radius x
      return(pigs_in_circle)
    }
  )
  
  # Combine all the SF data frames in schreck_specific_wildschwein_points to a singular data frame with variable 'radius'
  combined_wildschwein_points <- bind_rows(schreck_specific_wildschwein_points)
  
  
  # Plot the number of wildschwein per day within each schreck buffer for the specified dates
  combined_wildschwein_points %>%
    ggplot() +
    geom_density(mapping = aes(x = date, color = radius)) +
    # Then add 2 lines to signify start and end off schreck event
    geom_vline(xintercept =  as.Date(specific_schreck$datum_on), linetype="dotted", color = "blue", size = 1.5) +
    geom_vline(xintercept =  as.Date(specific_schreck$datum_off), linetype="dotted", color = "blue", size = 1.5) +
    labs(
      title = schreck_id, 
      subtitle = paste(
        "GPS Points:", nrow(combined_wildschwein_points),
        "|",
        "Schreck Duration:", (difftime(as.Date(specific_schreck$datum_off), as.Date(specific_schreck$datum_on), units = "days")),
        "days"
      )
    )
}

# Draw the plots for each relevant schreck location

WSS_2015_01_plot <- draw_density_plot("WSS_2015_01", c(100, 200, 400), 10, 14)
WSS_2015_01_plot

WSS_2015_03_plot <- draw_density_plot("WSS_2015_03", c(100, 200, 400), 10, 14)
WSS_2015_03_plot

WSS_2015_04_plot <- draw_density_plot("WSS_2015_04", c(100, 200, 400), 10, 14)
WSS_2015_04_plot

WSS_2016_01_plot <- draw_density_plot("WSS_2016_01", c(100, 200, 400), 10, 14)
WSS_2016_01_plot

WSS_2016_05_plot <- draw_density_plot("WSS_2016_05", c(100, 200, 400), 10, 14)
WSS_2016_05_plot

WSS_2016_06_plot <- draw_density_plot("WSS_2016_06", c(100, 200, 400), 10, 14)
WSS_2016_06_plot

WSS_2016_13_plot <- draw_density_plot("WSS_2016_13", c(100, 200, 400), 10, 14)
WSS_2016_13_plot

plot_grid(WSS_2015_01_plot, WSS_2015_03_plot, WSS_2015_04_plot, WSS_2016_01_plot, WSS_2016_05_plot)


# Show how the circles lie over each other to determine whether to combine some Schreck-Locations

schreck_agenda_and_locations_merged_cricles <- st_buffer(schreck_agenda_and_locations_merged, 250)
schreck_agenda_and_locations_merged_cricles

ggplot() +
  geom_sf(data = schreck_agenda_and_locations_merged_cricles) +
  geom_sf(
    data = schreck_agenda_and_locations_merged, 
    mapping = aes(color = paste(id, "|", "on:", datum_on, "|", "off:", datum_off))
    ) +
  annotation_scale() +
  coord_sf(datum=st_crs(2056)) +
  labs(color = 'Schreck ID | Date On | Date Off', title = "Radius: 250 m")


  #### Play around with leaflet: Interactive map with the Wildschwein Locations and the Schreck Location for one specific Schreck ####

  # Filter schreck agenda to specific schreck
  specific_schreck <- schreck_agenda_and_locations_merged %>%
    filter(id == "WSS_2015_01")
  specific_schreck
  
  # Draw a circle around that schreck
  specific_schreck_circle <- st_buffer(specific_schreck, dist = 500)
  
  # Filter wildschwein points by date to only ones occuring within above-mentioned schreck event (10 days before, during and 14 days after)
  specific_schreck_wildschwein <- wildschwein_BE_sf_cropped %>%
    filter(
      DatetimeUTC > as.Date(specific_schreck$datum_on) - 10,
      DatetimeUTC < as.Date(specific_schreck$datum_off) + 14
    )
  
  # Filter the above-mentioned wildschwein points to ones within the schreck circle
  specific_schreck_wildschwein_cropped <- specific_schreck_wildschwein %>%
    st_filter(specific_schreck_circle)
  
  # Create a new convenience variable (date, without time)
  specific_schreck_wildschwein_cropped <- specific_schreck_wildschwein_cropped %>%
    mutate(
      date = as.Date(DatetimeUTC)
    )
  
  view(specific_schreck_wildschwein_cropped)
  
  ggplot(specific_schreck_wildschwein_cropped) +
    geom_sf(aes(group = date)) +
    transition_time(date)
  
  # Convert back to lon/lat format (WGS83), otherwise leaflet doesn't work
  
  wildschwein_4326 <- st_transform(specific_schreck_wildschwein_cropped, crs = 4326)
  wildschwein_4326
  
  specific_schreck_4326 <- st_transform(specific_schreck, crs = 4326)
  specific_schreck_4326
  
  leaflet(data = specific_schreck_4326) %>%
    addTiles() %>%
    addCircleMarkers() %>%
    addTimeslider(data = wildschwein_4326,
                  options = timesliderOptions(
                    position = "topright",
                    timeAttribute = "DatetimeUTC",
                    sameDate = TRUE,
                    alwaysShowDate = TRUE)) %>%
    setView(-72, 22, 4)
  
  
  #### Model, Tukey-Test and Plot as a function ####

  # Extract labels and factor levels from Tukey post-hoc 
  generate_label_df <- function(tukey, variable){
    Tukey.levels <- tukey[[variable]][,4]
    Tukey.labels <- data.frame(multcompLetters(Tukey.levels)['Letters'])
    Tukey.labels$period = rownames(Tukey.labels)
    Tukey.labels = Tukey.labels[order(Tukey.labels$period) , ]
    return(Tukey.labels)
  }

  # Function which generates model, anova, post-hoc tukey test and a boxplot for specified schreck and radius
  anova_for_schreck <- function(schreck_id, radius) {
    
    # Filter schreck agenda to specific schreck
    specific_schreck <- schreck_agenda_and_locations_merged %>%
        filter(id == schreck_id)
    
    # Create buffer zone with radius around specific schreck
    specific_schreck_circle <- st_buffer(specific_schreck, dist = radius)
    
    # Filter out only the wild boar within the buffer zone
    wildschwein_in_circle <- wildschwein_BE_sf_cropped %>%
      st_filter(specific_schreck_circle) %>%
      mutate(
        date = as.Date(DatetimeUTC),
        period = 
          ifelse(DatetimeUTC < specific_schreck_circle$datum_on, "BEFORE", 
                 ifelse(DatetimeUTC > specific_schreck_circle$datum_off, "AFTER", 
                        "DURING")))
    
    # Group the gps points by day
    wildschwein_per_day <- wildschwein_in_circle %>%
      st_drop_geometry() %>%
      group_by(date, period) %>%
      summarise(
        total_per_day = n()
      )
    
    # Estimate the effect of the period on the number of WS GPS Points per day:
    model <- lm(wildschwein_per_day$total_per_day ~ wildschwein_per_day$period)
    anova <- aov(model)
    
    # Tukey test to study each pair of period:
    tukey <- TukeyHSD(x = anova, 'wildschwein_per_day$period', conf.level = 0.95)
    
    # Apply the function to the dataset
    labels <- generate_label_df(tukey , "wildschwein_per_day$period")
    
    wildschwein_per_day <- wildschwein_per_day %>%
      left_join(labels, by = "period")
    
    wildschwein_per_day <- wildschwein_per_day %>%
      mutate(
        period = factor(period, levels = c("BEFORE", "DURING", "AFTER")) 
      )
    
    gg_labels <- wildschwein_per_day %>%
      group_by(period, Letters) %>%
      summarise(
        height = max(total_per_day)
      )
    
    
    print(str(wildschwein_per_day))
    
    p <- wildschwein_per_day %>%
      ggplot() +
      geom_boxplot(mapping = aes(x = period, y = total_per_day)) +
      ylim(NA, 1.1 * max(wildschwein_per_day$total_per_day)) +
      labs(
        x = "Period in relation to Schreck Event",
        y = "# of GPS points within buffer zone per day (r = 100m)"
      ) + 
      geom_text(data = gg_labels,
                aes(x = period, y = height, label = Letters),
                vjust = -1.5, hjust = "inward")
    
    returnedList <- list("model" = model, "anova" = anova, "wildschwein_per_day" = wildschwein_per_day, "plot" = p)
    
  }
  
  # Run above function for schreck WSS_2015_01
  WSS_2015_01_package <- anova_for_schreck("WSS_2015_01", 100)
  summary(WSS_2015_01_package$model)
  summary(WSS_2015_01_package$anova)
  WSS_2015_01_package$wildschwein_per_day
  WSS_2015_01_package$plot
  
  