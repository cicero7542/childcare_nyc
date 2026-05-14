# Model Results: Childcare in NYC 

# This script reproduces the demand-side analysis. It reproduces the Poisson Model and 
# some of the data cleaning used for the spatial analysis. 
# The spatial analysis (Lee's L bivariate choropleth) was conducted in
# ArcGIS Pro and is not reproducible via R alone. The script exports the
# inputs needed for that analysis (kid_sum.csv) and documents what was done.


library(ipumsr)      # for IPUMS API
library(tidyverse)   # for data management
library(BayesFactor) # for Bayesian model 
library(rstanarm)    # for modeling 
library(olsrr)       # for ordinary least square regression 
library(modelsummary) # for describing many models 

## Set API key to access IPUMS. You can register for an IPUMS API key here: https://developer.ipums.org/docs/v2/get-started/
my_key <- "Your API Key Here"

set_ipums_api_key(my_key)

## see list of data
sample_list <- get_sample_info("usa")

## define an extract
extract <- define_extract_micro(
  collection = "usa",                    # defines general data collection
  description = "ACS PUMS Data, 2024",   # defines specific data source
  samples = c("us2024a"),                # defines records based on a specific survey form 
  variables = c("COUNTYFIP",
                "SEX", "AGE", "RACE", "HISPAN",   #Includes location data "COUNTYFIP" "PUMA", demographic "Sex" "Age" "Race" "HISPAN" for Hispanic
                "INCTOT", "POVERTY", "NCHLT5", "PUMA"), #"INCOT" for Income Total, "POVERTY", "NCHLT5" for Number of Children Under 5". 
  data_quality_flags = TRUE              # will add indicator of potential data problems (e.g. missing values)
)


## submit the API and download results

extract <- submit_extract(extract)     # submits the request to ipums.org
wait_for_extract(extract)              # idles until the download is ready
filepath <- download_extract(extract)  # downloads to your working directory

## read data

ddi <- read_ipums_ddi(filepath)  # unzips and reads the code book (ddi file)
data <- read_ipums_micro(ddi)    # unzips and reads the data based on ddi, ads variable labels, etc. 


# Identify NYC PUMAs 
#Using the 2020 PUMAs from IPUMS, documentation here: https://www.census.gov/programs-surveys/geography/guidance/geo-areas/pumas.html

nyc_pumas <- c(4101:4165, #Manhattan
               4201:4263, #Bronx
               4301:4318, #Brooklyn
               4401:4414, #Queens
               4501:4503) #Staten Island



# Clean data to filter for NYC PUMAs, 
# omit minors and seniors,
# and add race/ethnicity categories,
# The main variable here, HISPAN, measures if the surveyed person identifies as ethnically Hispanic or not. 

nyc_data <- data %>% 
  filter(PUMA %in% nyc_pumas) %>%                     #Filters for the NYC PUMA's identified earlier 
  filter(AGE >= 18, AGE <= 50) %>%                    #Filters for adults between the ages of 18 and 50
  mutate(
    race_eth = case_when(
      HISPAN %in% 1:4 ~ "Hispanic",                   #Identifies Hispanic 
      HISPAN == 0 & RACE == 1 ~ "White_NH",           #Identifies White Non-Hispanic 
      HISPAN == 0 & RACE == 2 ~ "Black_NH",           #Identifies Black Non-Hispanic
      HISPAN == 0 & RACE %in% c(4, 5, 6) ~ "Asian_NH",#Identifies Asian Non-Hispanic 
      TRUE ~ "Other_NH"                               #Identifies Other Non-Hispanic 
    )
  )

# Also Clean for Lee's Spatial L, number of children in NYC PUMAs. 
# This is another approach to gather information on number of children in NYC, and is used for mapping in Figure 4.  

kid_data <- data %>% 
  filter(PUMA %in% nyc_pumas) %>% 
  filter(AGE <= 5) %>% 
  mutate(
    race_eth = case_when(
      HISPAN %in% 1:4 ~ "Hispanic",                     
      HISPAN == 0 & RACE == 1 ~ "White_NH", 
      HISPAN == 0 & RACE == 2 ~ "Black_NH", 
      HISPAN == 0 & RACE %in% c(4, 5, 6) ~ "Asian_NH",
      TRUE ~ "Other_NH"
    )
  )

kid_data <- kid_data %>% 
  filter(HISPAN %in% 1:4)

# weighted count by PUMA. Because the IPUMS survey includes weighted counts, multiplying the raw count by the weight
# gives the weighted count or the true estimate of how many live in a given PUMA. 
kid_summary <- kid_data %>%
  group_by(PUMA) %>%
  summarise(
    raw_count      = n(),                        # how many in the sample
    weighted_count = sum(PERWT, na.rm = TRUE)    # actual population estimate
  )

print(kid_summary)

write_csv(kid_summary, "Your File Location Here")


#relevel the factorization of race_eth for later modeling. This is done because the poisson model will treat
#the default as the baseline comparison. This refactoring code makes sure the baseline comparison group is White non Hispanic. 

nyc_data <- nyc_data %>% 
  mutate(race_eth = factor(as.character(race_eth),
                           levels = c("White_NH", "Black_NH",
                                      "Hispanic", "Asian_NH", "Other_NH")))


# EDA. Looks at some standard stats. 

nyc_data %>% 
  group_by(race_eth) %>% 
  summarise(
    n = n(),
    mean_kid = mean(NCHLT5),
    sd_kid = sd(NCHLT5), 
    mean_age = mean(AGE), 
    sd_age = sd(AGE)
  )




### Building a poisson regression model 

## With many variables
poisson_formula <- NCHLT5 ~ race_eth + AGE + SEX + INCTOT + POVERTY 

poisson_model <- glm(poisson_formula, 
                     family = "poisson", 
                     data = nyc_data)

summary(poisson_model)

## With fewer variables

poisson_formula2 <- NCHLT5 ~ race_eth + AGE

poisson_model2 <- glm(poisson_formula2, 
                     family = "poisson", 
                     data = nyc_data)

summary(poisson_model2)


##compare 


modelsummary(list(poisson_model , poisson_model2))

