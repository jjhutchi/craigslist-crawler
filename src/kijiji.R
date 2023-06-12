# Install and load the required packages
pacman::p_load(rvest, dplyr, googlesheets4)
wd = "/Users/jordanhutchings/Documents/Documents - Jordan’s MacBook Air/MLDS/craigslist-crawler" # here::here() has issues with cronR
source(file.path(wd, "src/secrets.R"))

#' Collect listing title, price, location, and link
#' Return list of the information for the listing
parse_listing = function(l) {
  title <- html_text2(html_nodes(l, ".title"))[1]
  price <- html_text2(html_nodes(l, ".price"))
  location <- html_text2(html_nodes(l, ".location"))
  link <- sprintf("kijiji.ca%s", html_attr(html_nodes(l, "a.title"), "href"))
  
  list(title = title, price = price, location = location, link = link)
}

#' Read in already observed listings
#' Return new listings to prompt
triage_listings = function(listings) {
  
  listings_in = googlesheets4::range_read(ss, sheet = "listings")

  listings_out = listings |> 
    bind_rows() |> 
    filter(!link %in% listings_in$link)
  
  # update google sheet with parsed listings
  start_range = sprintf("A%s", nrow(listings_in) + 2)
  range_write(ss, 
              sheet = "listings", 
              data = listings_out, 
              range = start_range, 
              col_names=FALSE)
  
  # clear and save listings to look at in new googlesheet
  range = sprintf("A1:D%s", nrow(listings_in) + 2)
  range_delete(ss, sheet = "New Listings", range = range, shift = "up")
  range_write(ss, sheet = "New Listings", data = listings_out, col_names=TRUE)
  
  listings_out
}

#' Send push notifications to iPhone 
#' URL opens up the kijiji ad, multiple new ads push 30 seconds apart
send_message = function(outgoing_listings, url=new_listings_url) {
  new_listings = nrow(outgoing_listings)
  if(new_listings > 0){
    for (i in 1:new_listings) {
      app_title = outgoing_listings[i, ]$title
      app_url = sprintf("https://www.%s", outgoing_listings[i, ]$link)
      msg = sprintf("New listing apartment listing")
      pushoverr::pushover(message = msg, 
                          user = USER_KEY, 
                          app = APP_KEY, 
                          url = app_url, 
                          url_title = app_title)
      Sys.sleep(10)
    }
    
    }  
}


# Collect listings from URL
url = "https://www.kijiji.ca/b-apartments-condos/city-of-toronto/1+bedroom__bachelor+studio/c37l1700273a27949001?ll=43.665262%2C-79.398656&address=Rotman+School+of+Management%2C+Saint+George+Street%2C+Toronto%2C+ON&ad=offering&radius=1.5&price=__1700"
listing_elements = read_html(url) |> 
  html_nodes(".search-item")

# parse and send push notifications
listings = purrr::map(listing_elements, parse_listing)
outgoing_listings = triage_listings(listings)
send_message(outgoing_listings)
