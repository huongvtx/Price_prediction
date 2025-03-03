
rm(list=ls())

library(readr)
library(lubridate)
library(dplyr)


# Import datasets
ulp_nsw <- read_excel("nsw_u91.xlsx", sheet = "Sheet1") # NSW's U91
tgp <- read_excel("AIP_TGP_Data_15-Mar-2024.xlsx" , sheet = "Petrol TGP") # Average TGPs
mb <- read_excel("MB_2021_AUST.xlsx", sheet = "MB_2021_AUST")
poa <- read_excel("POA_2021_AUST.xlsx", sheet = "POA_2021_AUST")


# Get postcodes of NSW and ACT only
poa_nsw <- poa[grepl('^[18]', poa$MB_CODE_2021) , ]

tgp$AVERAGE_ULP_TGPS <- as.Date(tgp$AVERAGE_ULP_TGPS)


# Make string values consistent
ulp_nsw$ServiceStationName <- str_to_title(ulp_nsw$ServiceStationName)
ulp_nsw$Address <- str_to_title(ulp_nsw$Address)
ulp_nsw$Suburb <- str_to_title(ulp_nsw$Suburb)


# Get only rows at COB
ulp_nsw_cob <- ulp_nsw %>% 
  group_by(ServiceStationName, Address, Suburb, Postcode, Brand, Date) %>% 
  slice(which.max(Timestamp)) %>% 
  select(ServiceStationName, Address, Suburb, Postcode, Brand, Price, Date)


# Get the earliest and latest date of price change at a servo level
servo_dates_nsw <- ulp_nsw_cob %>% 
  group_by(Address, Suburb, Postcode, Brand) %>% 
  summarise(Min_date = min(Date), Max_date = max(Date)) %>% 
  mutate(Min_date = as.Date(Min_date), Max_date = as.Date(Max_date))


# Generate all combinations of servo and dates
all_dates_nsw <- lapply(1:nrow(servo_dates_nsw), function(i) {
  seq.Date(from = servo_dates_nsw$Min_date[i], to = servo_dates_nsw$Max_date[i], by = 'days')
})

all_dates_nsw_df <- data.frame(Address = rep(servo_dates_nsw$Address, lengths(all_dates_nsw)),
                               Suburb = rep(servo_dates_nsw$Suburb, lengths(all_dates_nsw)), 
                               Postcode = rep(servo_dates_nsw$Postcode, lengths(all_dates_nsw)), 
                               Brand = rep(servo_dates_nsw$Brand, lengths(all_dates_nsw)),
                               Date = unlist(all_dates_nsw))

all_dates_nsw_df$Date <- as.Date(all_dates_nsw_df$Date)


# Make full time sequence of servo
combined_nsw <- left_join(all_dates_nsw_df, distinct(ulp_nsw_cob[, -1]),
                          by = c('Address', 'Suburb', 'Postcode', 'Brand', 'Date')) %>%
  left_join(tgp[, 1:2], by = c('Date' = 'AVERAGE_ULP_TGPS')) %>% 
  left_join(poa_nsw[, 1:2], by = c('Postcode' = 'POA_CODE_2021'), multiple = 'any') %>% 
  rename(TGP = Sydney) %>% 
  left_join(mb[, c(1,11,13,15)], join_by(MB_CODE_2021))

# Fill in prices of un-reported dates
combined_nsw$Price <- na.locf(combined_nsw$Price, na.rm = FALSE)
combined_nsw$TGP <- na.locf(combined_nsw$TGP, na.rm = FALSE)


# Create new column of regions
combined_nsw$Region <- ifelse(grepl('^8', combined_nsw$MB_CODE_2021),
                              'ACT',
                              ifelse(grepl('inner', combined_nsw$SA4_NAME_2021, ignore.case = TRUE),
                                     'SYD metro',
                                     ifelse(combined_nsw$GCCSA_NAME_2021 == 'Greater Sydney',
                                            'SYD fringe',
                                            'Remote')))


combined_nsw %>% group_by(Region, Date, TGP) %>% 
  summarise(Avg_price = mean(Price))
  


# Generate all combinations of brand and dates
all_dates <- lapply(1:nrow(brand_dates), function(i) {
  seq.Date(from = brand_dates$min_date[i], to = brand_dates$max_date[i], by = "days")
})
all_dates_df <- data.frame(brand = rep(brand_dates$brand, lengths(all_dates)), 
                           date = unlist(all_dates), price = NA) %>%
  as.Date(date)

# Join the new data frame with your existing data frame
combined_df <- left_join(all_dates_df, data.frame(brand = existing_brands, date = existing_dates, price = existing_prices),
                         by = c("brand", "date")) %>% 
  select('brand', 'date', 'price.y')

combined_df$price.y <- na.locf(combined_df$price.y, na.rm = FALSE)

################################################################################

ulp <- read_csv("NSW_Fuel_Prices_202301_202401.csv",
                     col_types = cols(Date = col_date(format = '%d/%m/%Y')))

sa4_stats <- ulp %>% filter(Year==2023) %>% group_by(SA4_NAME_2021) %>%
  summarise(N_stations = n_distinct(Address),
            Min = min(Price),
            Q1 = stats::quantile(Price, probs = .25),
            Mean = mean(Price),
            Median = median(Price),
            Q3 = stats::quantile(Price, probs = .75),
            Max = max(Price),
            SD = sd(Price),
            Skewness = moments::skewness(Price),
            Kurtosis = moments::kurtosis(Price))

brand <- ulp_2023 %>% 
  filter(year(Date) == 2023 & Region == 'SYD inner') %>% 
  group_by(Brand) %>% 
  summarise(n_stations = n_distinct(Address),
            Mean = mean(Price),
            Median = median(Price),
            Max = max(Price),
            Min = min(Price),
            SD = sd(Price))

###############################################################################
###############################################################################

# Forecast ULP Price

regs <- read.csv("C:/Users/vutxu/OneDrive/Documents/INFS 5135 Advanced BI and Analytics/Region stats_ NSW_SA4.csv")
regs <- regs %>% select(c('SA4_Name', 'Cluster.Name'))

# Join ULP with region stats
ulp_join <- left_join(ulp, regs, join_by(SA4_NAME_2021 == SA4_Name)) %>% 
  filter(Year == 2023 & !is.na(Cluster.Name)) # Filter out ACT and 2024 data

df_clus <- ulp_join %>% group_by(Date, Cluster.Name) %>% 
  summarise(Mean_Price = mean(Price))

# Split into 2 df corresponding to 2 clusters
df_c1 <- df_clus %>% filter(Cluster.Name == 'Cluster1') %>% select(-Cluster.Name)
df_c2 <- df_clus %>% filter(Cluster.Name == 'Cluster2') %>% select(-Cluster.Name)

# Plot time series of Mean Price
df_c1 %>% ggplot()+geom_line(aes(x=Date, y = Mean_Price)) + theme_minimal()
df_c2 %>% ggplot()+geom_line(aes(x=Date, y = Mean_Price)) + theme_minimal()

# Finding ARIMA parameters
fit_arima_1 <- auto.arima(df_c1$Mean_Price, seasonal = TRUE)
fit_arima_2 <- auto.arima(df_c2$Mean_Price, seasonal = TRUE)

fit_arima_1
fit_arima_2

arima_1 <- Arima(df_c1$Mean_Price[1:358], model=fit_arima_1)
arima_2 <- Arima(df_c2$Mean_Price[1:358], model=fit_arima_2)                 

pred_1 <- forecast(arima_1, h=7)
pred_2 <- forecast(arima_2, h=7)

accur_1 <- accuracy(pred_1, df_c1[359:365, "Mean_Price"]$Mean_Price)
accur_2 <- accuracy(pred_2, df_c2[359:365, "Mean_Price"]$Mean_Price)

accur_1
accur_2

# Export to csv
write.csv(df_clus, 
          file = 'NSW_Prices_By_Cluster.csv',
          row.names = FALSE)

actual <- c(1.1405,1.137,1.097,1.1215,1.042,0.9665)
forecast <- c(1.13633,1.114453,1.092102,1.069769,1.047287,1.024774)
accuracy(object = forecast, x = actual)

