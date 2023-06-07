# Huge ChatGPT assist in the code
# Install and load the required packages
# install.packages("rvest")
pacman::p_load(rvest, dplyr, purrr, googlesheets4)
wd <- "/Users/jordanhutchings/Documents/Documents - Jordan’s MacBook Air/MLDS/craigslist-crawler"
source(file.path(wd, "src/secrets.R"))
ss = "https://docs.google.com/spreadsheets/d/1GeqLaAEex_l3wIofmft5d5BrbZlreRqtuwVB-qxpjFI/edit?usp=sharing"
new_listings_url = "https://docs.google.com/spreadsheets/d/1GeqLaAEex_l3wIofmft5d5BrbZlreRqtuwVB-qxpjFI/edit#gid=424295943"

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
#' Notifications include link to GoogleSheet with info on the postings
send_message = function(outgoing_listings, url=new_listings_url) {
  new_listings = nrow(outgoing_listings)
  msg = sprintf("Toronto Apartments - %s new listings", 
                new_listings)
  if(new_listings > 0){
    pushoverr::pushover(message = msg, 
                        user = USER_KEY, 
                        app = APP_KEY, 
                        url = url)
    }  
}


# Collect URLs
url = "https://www.kijiji.ca/b-apartments-condos/city-of-toronto/1+bedroom__bachelor+studio/c37l1700273a27949001?ll=43.665262%2C-79.398656&address=Rotman+School+of+Management%2C+Saint+George+Street%2C+Toronto%2C+ON&ad=offering&radius=1.5&price=__1700"
listing_elements = read_html(url) |> 
  html_nodes(".search-item")

# parse and send notifications
listings = purrr::map(listing_elements, parse_listing)
outgoing_listings = triage_listings(listings)
send_message(outgoing_listings)
