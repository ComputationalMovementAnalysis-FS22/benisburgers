---
output:
  word_document: default
  html_document: default
---
# Proposal for Semester Project

**Patterns & Trends in Environmental Data / Computational Movement
Analysis Geo 880**

| Semester:      | FS22                              |
|----------------|---------------------------------- |
| **Data:**      | Wild Boar Movement Data           |
| **Title:**     | Check how to Schreck              |
| **Student 1:** | Fabienne Gräppi                   |
| **Student 2:** | Benjamin Bar-Gera                 |

## Abstract 
<!-- (50-60 words) -->

## Research Questions
<!-- (50-60 words) -->
- How effective are the Wildschwein-Schreck (WS) at keeping away wild boar and how long do these effects last?
- What settings (mode, noise level, interval, azimuth) and setting-combintations are most effective at keeping away wild boar?

## Results / products
<!-- What do you expect, anticipate? -->
- Interactive time-sequenced maps that illustrate how the WS affect the spatial distribution of the wild boar 
- A linear and a logarithmic model which show how the different WS factors (mode, noise level, interval, azimuth) affect the spatial distribution of the wild boar
- A list of recommendations for the most effective WS settings (mode, noise level, interval, azimuth) at keeping wild boar away

## Data
<!-- What data will you use? Will you require additional context data? Where do you get this data from? Do you already have all the data? -->
- Primarily wildschwein_BE (wild boar locations in the study area Bern / Fanel) to know where the wild boars have been before, during and after the WS (i.e., the response variable) 
- Schreck_agenda (the logs of when the Wildschwein-Schrecks were off / on) in combination with schreck_locations (the WS respective locations) to determine what WS went off where and when and what its settings were (i.e., the independent variables)

## Analytical concepts
<!-- Which analytical concepts will you use? What conceptual movement spaces and respective modelling approaches of trajectories will you be using? What additional spatial analysis methods will you be using? -->
- Interactive time-sequenced maps will show how and if the WS events influence the spatial distribution of the wild boar (i.e., is there a visually discernible change in the wild boar’s location because of WS events)
- Using linear regression and logistic regression, we will determine whether the WS has any determinable effect on the presence/absence of wild boar, and if so, which factors (mode, noise level, interval, azimuth) have the most significant effects
- After analyzing which WS factors have a significant effect on the spatial distribution of wild boar, we will try to determine, which settings and combinations of settings are most effective at keeping the animals away, we will do so visually with boxplots and interaction plots 

## R concepts
<!-- Which R concepts, functions, packages will you mainly use. What additional spatial analysis methods will you be using? -->
- To figure out whether the WS influences the animals, we can only focus on animals that are within the vicinity of the WS before the event 
- These animals do not need to be in the area necessarily right before the Schreck event has happened, however, they must be in the area often enough before, that it is discernible whether their presence has decreased during and after the Schreck event 
- The ‘area’ is a radius drawn around the individual Schreck devices. The size of this radius is either to be pre-determined OR we try it out with different radii to determine how far the effect of the WS goes

- Let us talk specifically: 
    - We have WS A at location XYZ 
    - We draw a circle with a radius of 500 meters around WS A, we call this area Zone A 
    - There are now four options:

        - Option A:
            - We determine either the amount of time spent by all wild boar within Zone A or the number of wild boars that were present in Zone A within 1 week BEFORE the beginning of the Schreck, and we compare this to the absolute number of individuals in Zone A during the Schreck phase, and after the Schreck phase 
            - We can then compare the Before-Schreck period to the 1-Week-During-Schreck, 2-Week-During-Schreck etc. and 1-Week-After-Schreck, 2-Week-After-Schreck, 3-Week-After-Schreck phase to see if there is an effect, and esp. when the effect is measurable and how fast the effect diminishes with time after the Schreck is done 
            - We can do this comparison visually with a boxplot and compare it with an ANOVA 
            - However, this method does not provide us with any results about which factors have the strongest influence on the presence of wild boar and which settings are the most effective at frightening away wild boar<br/><br/>

        - Option B:
            - We create a generalized mixed effect model, specifically a logistic regression (the response variable is variable)  
            - The explanatory variables include mode, noise level, interval, azimuth, and time that has passed since the Schreck event has passed 
            - The response variable equals presence (1) or absence (0) of individual wild boar in Zone A (see above)  
            - Again, we would only focus on individuals that were within Zone A on at least XYZ days during the week prior to the Schreck event 
            - We can then see which, if any factors, have an influence on the presence and absence of wild boar within the Schreck-affected zone 
            - We then take the statistically significant factors and determine the most effective settings and combination of settings visually using point-plots and interaction plots<br/><br/>

        - Option C:
            - We repeat the above analysis multiple times with different radii to determine how far the effects of the WS go<br/><br/>

        - Option D: 
            - We create a generalized mixed effect model, specifically a linear regression (the response variable is continuous) 
            - All else equals the above settings<br/><br/>

## Risk analysis
<!-- What could be the biggest challenges/problems you might face? What is your plan B? -->
- The complexity of the linear models might overwhelm us 
- Insufficient number of datapoints for each WS-zone and timespan for a proper statistical analysis 
- Right setting of radius, as we do not know yet the range of the WS 
- Honestly, that is the only risk I see, data is sufficiently available  

## Questions? 
<!-- Which questions would you like to discuss at the coaching session? -->
- How realistic and doable is this?
