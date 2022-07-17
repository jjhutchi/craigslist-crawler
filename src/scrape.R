library(rvest)
library(httr)
library(jsonlite)

wd = "/Users/jordanhutchings/Documents/Documents - Jordan’s MacBook Air/MLDS/craigslist-crawler"
source(file.path(wd, "src/push_notification.R"))

# scrape the craigslist ----

# Setup URL
base = "https://toronto.craigslist.org/search/toronto-on/apa?availabilityMode=0&"
LAT = "43.66532376779693" # are Rotman school of management
LNG = "-79.39860792142129"
MAX_PRICE = "3200"
MIN_BDRM = "2"
RADIUS = "1.2" # is 1.9Km
SORT = "date"

url = sprintf("%slat=%s&lon=%s&max_price=%s&min_bedrooms=%s&search_distance=%s&sort=%s", base, LAT, LNG, MAX_PRICE, MIN_BDRM, RADIUS, SORT)
page = rvest::read_html(url)

# get the url of the postings
links = page |> 
  rvest::html_nodes(".result-row") |> 
  rvest::html_element("a") |> 
  rvest::html_attr("href")

# get the date of the postings
times = page |> 
  rvest::html_nodes(".result-date") |> 
  rvest::html_attr("datetime")

# titles
titles = page |> 
  rvest::html_nodes(".result-heading") |> 
  rvest::html_text(trim = TRUE)


# check for new postings ----

# check for log, o/w make log
if(!"listing-urls.txt" %in% list.files(file.path(wd, "data"))){
  write("Posting_Title|URL", file = file.path(wd, "data/listing-urls.txt"))
}

current_time = as.POSIXct(Sys.time(), tz = "")
THRESH = 20 # check for new posts in past 30 minutes
old_postings = read.delim(file.path(wd, "data/listing-urls.txt"), sep = "|", header = TRUE)

new_postings = links[difftime(current_time, as.POSIXct(times, tz = ""), units = "mins") < THRESH]
new_postings = new_postings[!new_postings %in% old_postings$URL] # remove links we've already sent 
new_notifications = length(new_postings)

SEND_PUSH = new_notifications > 0

if(SEND_PUSH){
  for(i in new_notifications) {
    url = links[i]
    title = titles[i]
    
    push(url, title)
    
    # write data to log
    log = paste(title, url = url, sep = "|", collapse="\n")
    write(log, file = file.path(wd, "data/listing-urls.txt"), append=TRUE)
  }
}
