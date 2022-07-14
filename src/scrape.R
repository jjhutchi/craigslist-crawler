library(rvest)
library(httr)
library(jsonlite)

source("src/push_notification.R")

# scrape the craigslist ----

# get the page
url = "https://toronto.craigslist.org/search/toronto-on/apa?availabilityMode=0&lat=43.66166976164281&lon=-79.3920780935351&max_price=3200&min_bedrooms=2&search_distance=0.6275801554108181&sort=date"
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
if(!"listing-urls.txt" %in% list.files("data")){
  write("Posting Title|URL", file = "data/listing-urls.txt")
}

current_time = as.POSIXct(Sys.time(), tz = "")
THRESH = 20 # check for new posts in past 20 minutes
old_postings = read.delim("data/listing-urls.txt", sep = "|", header = FALSE)

new_postings = links[difftime(current_time, as.POSIXct(times, tz = ""), units = "mins") < THRESH]
new_postings = new_postings[!new_postings %in% old_postings$V2] # remove links we've already sent 
new_notifications = length(new_postings)

SEND_PUSH = new_notifications > 0

if(SEND_PUSH){
  for(i in new_notifications) {
    url = links[i]
    title = titles[i]
    
    push(url, title)
    
    # write data to log
    log = paste(title, url = url, sep = "|", collapse="\n")
    write(log, file = "data/listing-urls.txt", append=TRUE)
  }
}