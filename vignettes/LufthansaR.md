---
title: "LufthansaR"
date: "`r Sys.Date()`"
---


## Introduction to LufthansaR

`LufthansaR` is an API wrapper package for R. It enables programmers to access to [Lufthansa Open API](https://developer.lufthansa.com/docs) from R environment.

This document introduces you to LufthansaR's basic set of tools, and show how to use them. Once you have installed the package, read `vignette("LufthansaR")` to learn more.

## Lufthansa Open API

To have access to Lufthansa Open API, one has to sign in to Mashery, Lufthansa's developer platform, and apply for a key. Please visit [here](https://developer.lufthansa.com/docs/API_basics/). 


![API_reg](../image/API_reg.png)


Once you are registered, you will be given:

- a key and
- a secret

These two values can be exchanged for a _short-lived_ access token. A valid access token must be sent with every API request while accessing any Lufthansa's API. In other words, every Lufthansa API requires you to pass Oauth token when getting the data from it.

## How to install LufthansaR

You can install `LufthansaR` development version from GitHub

```{r, eval=FALSE}
devtools::install_github("peter0083/LufthansaR")
```

CRAN version of the package will be scheduled to be added in the next version.

## Usage

You can load `LufthansaR` as follows.

```{r, eval=FALSE}
library(LufthansaR)
```

This will load the core `lufthansaR` functions.


## How to deal with Lufthansa Open API credentials

You can store your client ID and secret in a `~/.Renviron` file. R loads this file as
a system variable in each new session. The package uses these variables to request
new keys if needed. The `.Renviron` file should contain the lines

```
LUFTHANSA_API_CLIENT_ID = 'xxxxxxxxxxxxxxxxxxxxxxxx'
LUFTHANSA_API_CLIENT_SECRET = 'xxxxxxxxxx'
```

which specify the key and secret pair. This package does not remember the id or the
secret.


**NOTE: The name of the variables should be EXACTLY:**

- `LUFTHANSA_API_CLIENT_ID`
- `LUFTHANSA_API_CLIENT_SECRET`


Because tokens last for 1.5 days and to prevent the abuse of continuously requesting
new tokens, the package by default stores the token and its expiry in a file in the
working directory called `.lufthansa-token`. Caching the token provides a way of
using it across R sessions until it expires. Functions in the package use the `get_token()`
command to access the API. For more information about the function, see `help(get_token)`.

Caching the token can be turned off by setting the following R option through
```
options(lufthansar_token_cache = FALSE)
```

Alternately, one can choose where to cache the token by using a filename instead
```
options(lufthansar_token_cache = 'path/to/.token-cache')
```

Users can see the token being used and its expiry by calling
```
LufthansaR::get_creds_from_env()
```


## How to see the active token used

Get the current token being used by the package.

```{r, eval=FALSE}
LufthansaR::get_token()
```

Each token is valid for a specified period of time. When the token is valid, `LufthansaR` uses the `Client ID` and `Client Secret` in your `.Renviron`.

## How to get flight status

This `get_flight_status()` function will print out the flight information

```{r, eval=FALSE}
f_status <- LufthansaR::get_flight_status(flight_num ="LH493", verbose = TRUE)
```

The default is the flight status for today. However, you can call 5 days into the future by passing `dep_date="2018-04-15"` argument. The departure date (YYYY-MM-DD) in the local time of the departure airport.  To supress the update message that is printed, pass the argument `verbose = FALSE`.

`LufthansaR` package utilizes `httr` to parse JSON content. You can access to different attributes of the already-parsed content:

```{r, eval=FALSE}
# Departure Airport abbreviation
f_status$Departure$AirportCode

# Scheduled Departure Time (departure local time)
f_status$Departure$ScheduledTimeLocal$DateTime

# Departure Terminal
f_status$Departure$Terminal$Name

# Departure Status
f_status$Departure$TimeStatus$Definition

# Arrival Airport abbreviation
f_status$Arrival$AirportCode

# Scheduled Arrival Time (arrival local time)
f_status$Arrival$ScheduledTimeLocal$DateTime

# Arrival Terminal
f_status$Arrival$Terminal$Name

# Arrival Status
f_status$Arrival$TimeStatus$Definition
```


## Getting status of flights arriving at a particular airport

Let's load some packages that we will use below.

```{r, eval=FALSE}
library(tidyverse)
library(lubridate)
```


To obtain the information about flights at the arrival airport,

```{r, eval=FALSE}
get_flight_status_arrival(airport = "YVR", fromDateTime = "2018-04-13T00:00")
```

The output is the `httr` parsed content. The format of `fromDateTime` is `YYYY-MM-DDTHH:MM`. This is ISO-8601 date format.
Let's assume that we are interested in flights arriving at `FRA` around this time. And let's assume we are interested in showing some departure delays of those flights in a visualization.

```{r, eval=FALSE}
# This to get the current local time at FRA and convert it to the ISO-8601 format.
tm <- as.POSIXlt(Sys.time(), tz="Europe/Berlin", "%Y-%m-%dT%H:%M")
tm_FRA <- strftime(tm,  "%Y-%m-%dT%H:%M")
# to parse the content
parsed_content <- LufthansaR::get_flight_status_arrival(airport = "FRA", fromDateTime = tm_FRA)
```


You can see the content return by typing `parsed_content`. It is possible that there might not be any flight arriving at the time specified. Let's first see how many flights the API returns.


```{r, eval=FALSE}

if (parsed_content$FlightStatusResource$Meta$TotalCount == 1){

  (no_flight_returned <-parsed_content$FlightStatusResource$Meta$TotalCount)

} else{

  (no_flight_returned <- summary(parsed_content$FlightStatusResource$Flights)[1])

}
```


In the following, a visualization is created by using the return content for departure delay for those flight arriving at FRA.


```{r, fig.width=7.5, fig.height=5, fig.align="center", eval=FALSE}

# The following is performed if the API returns some flight information
if(!(is.nan(no_flight_returned) | no_flight_returned <= 1)){
  flight_departure_data <- data.frame(dept_airport = rep(NA, no_flight_returned),
            scheduled_dept =rep(NA, no_flight_returned), actual_dept =rep(NA, no_flight_returned))

  # wrangle the data
  for (i in 1:no_flight_returned){

    flight_departure_data$dept_airport[i] <-
      parsed_content$FlightStatusResource$Flights[[1]][[i]]$Departure$AirportCode

    flight_departure_data$scheduled_dept[i] <-
      parsed_content$FlightStatusResource$Flights[[1]][[i]]$Departure$ScheduledTimeLocal$DateTime

    flight_departure_data$actual_dept[i] <-
      ifelse (is.null(parsed_content$FlightStatusResource$Flights[[1]][[i]]$Departure$ActualTimeLocal$DateTime), NA, parsed_content$FlightStatusResource$Flights[[1]][[i]]$Departure$ActualTimeLocal$DateTime)
  }

  # clean the json data
  flight_departure_data$delay <-
    -as.numeric(as.duration(interval(ymd_hm(flight_departure_data$actual_dept),                                                                          ymd_hm(flight_departure_data$scheduled_dept))), "minutes")
  flight_departure_data<- flight_departure_data %>%
    mutate(status = ifelse(is.na(delay), "not departed",
                         ifelse(delay>0, "delayed departure", "early/on-time"))) %>%
    mutate(delay = ifelse(is.na(delay), 1,  delay))

  # visualize the result
  ggplot(data=flight_departure_data, aes(x=as.factor(dept_airport), y=delay)) +
    geom_bar(stat="identity", aes(fill=status)) +
    coord_flip() +
    ggtitle(paste0("Delay Status at the Departure Airports for the Flights arriving at ", "FRA")) +
    theme(legend.position = "bottom") +
    xlab("Airport") +
    ylab("Delay (minutes)")
  } else {

  print("No more than one flight information available at this time!")

}
```



![flight_arrival_png](../image/flight_arrival_viz.png)


## Getting status of flights departing from a particular airport

To obtain the information about flights at the departure airport,

```{r, eval=FALSE}
get_flight_status_departure(airport = "YVR", fromDateTime = "2018-04-13T00:00")
```

The output is the `httr` parsed content. The format of `fromDateTime` is `YYYY-MM-DDTHH:MM`. This is ISO-8601 date format.
Let's assume that we are interested in flights departing from `FRA` around this time.

```{r, eval=FALSE}
# This to get the current local time at FRA and convert it to the ISO-8601 format.
tm <- as.POSIXlt(Sys.time(), tz="Europe/Berlin", "%Y-%m-%dT%H:%M")
tm_FRA <- strftime(tm,  "%Y-%m-%dT%H:%M")

# to parse the content
parsed_content <- LufthansaR::get_flight_status_departure(airport = "FRA", fromDateTime = tm_FRA)
```

You can see the content return by typing `parsed_content`. It is possible that there might not be any flight arriving at the time specified. It is possible that there might not be any flight arriving at the time specified. Let's first see how many flights the API returns.

```{r, eval=FALSE}
# to count the number of flights returned

if (parsed_content$FlightStatusResource$Meta$TotalCount == 1){

  (no_flight_returned <-parsed_content$FlightStatusResource$Meta$TotalCount)

  } else {

  (no_flight_returned <- summary(parsed_content$FlightStatusResource$Flights)[1])

}
```


```{r, eval=FALSE}
# The following is performed if the API returns more than one flight

if(!(is.nan(no_flight_returned) | no_flight_returned <= 1)){
  flight_departure_data <- data.frame(flight_code = rep(NA, no_flight_returned),
            scheduled_dept =rep(NA, no_flight_returned), destination_airport =rep(NA, no_flight_returned), arrival_time =rep(NA, no_flight_returned))

  # data wrangling
  for (i in 1:no_flight_returned){

    flight_departure_data$flight_code[i] <-
      paste0( parsed_content$FlightStatusResource$Flights[[1]][[i]]$MarketingCarrier$AirlineID,parsed_content$FlightStatusResource$Flights[[1]][[i]]$MarketingCarrier$FlightNumber)

    flight_departure_data$scheduled_dept[i] <-
      parsed_content$FlightStatusResource$Flights[[1]][[i]]$Departure$ScheduledTimeLocal$DateTime

    flight_departure_data$destination_airport[i] <- parsed_content$FlightStatusResource$Flights[[1]][[i]]$Arrival$AirportCode

    flight_departure_data$arrival_time[i] <- parsed_content$FlightStatusResource$Flights[[1]][[i]]$Arrival$ScheduledTimeLocal
  }

flight_departure_data

} else {

  print("No flight information available at this time!")

}

```


The following is a data frame of the departure data returned by Lufthansa API.

|    | flight_code | scheduled_dept   | destination_airport | arrival_time     |
|----|-------------|------------------|---------------------|------------------|
| 1  | LH1392      | 2018-04-15T09:00 | PRG                 | 2018-04-15T10:00 |
| 2  | LH1388      | 2018-04-15T09:00 | POZ                 | 2018-04-15T10:15 |
| 3  | OS262       | 2018-04-15T09:00 | SZG                 | 2018-04-15T09:55 |
| 4  | LH048       | 2018-04-15T09:00 | HAJ                 | 2018-04-15T09:50 |
| 5  | LH902       | 2018-04-15T09:00 | LHR                 | 2018-04-15T09:40 |
| 6  | LH1250      | 2018-04-15T09:00 | LNZ                 | 2018-04-15T10:00 |
| 7  | LH1214      | 2018-04-15T09:00 | GVA                 | 2018-04-15T10:05 |
| 8  | LH1336      | 2018-04-15T09:00 | BUD                 | 2018-04-15T10:30 |
| 9  | LH1298      | 2018-04-15T09:05 | IST                 | 2018-04-15T13:00 |
| 10 | LH260       | 2018-04-15T09:05 | GOA                 | 2018-04-15T10:30 |
| 11 | LH988       | 2018-04-15T09:05 | AMS                 | 2018-04-15T10:20 |
| 12 | LH248       | 2018-04-15T09:10 | MXP                 | 2018-04-15T10:20 |
| 13 | LH1358      | 2018-04-15T09:10 | WRO                 | 2018-04-15T10:25 |
| 14 | LH1158      | 2018-04-15T09:10 | PMI                 | 2018-04-15T11:15 |
| 15 | LH352       | 2018-04-15T09:10 | BRE                 | 2018-04-15T10:05 |
| 16 | LH1470      | 2018-04-15T09:10 | TSR                 | 2018-04-15T12:00 |
| 17 | LH836       | 2018-04-15T09:10 | BLL                 | 2018-04-15T10:25 |
| 18 | LH1148      | 2018-04-15T09:10 | AGP                 | 2018-04-15T12:05 |
| 19 | LH810       | 2018-04-15T09:10 | GOT                 | 2018-04-15T10:45 |
| 20 | LH074       | 2018-04-15T09:10 | DUS                 | 2018-04-15T10:00 |
