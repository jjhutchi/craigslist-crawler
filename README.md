# Webscraping Kijiji Apartment listings

I collect Kijiji postings for apartments within 1.5 Km of the 
Rotman School of Management every 20 minutes. If there are any new 
postings, I send a push notification using `pushoverr` to my iPhone 
providing the and title and URL. 

## For Use

Update the URL arguments in the `kijiji.R` script. Unless you are using the 
bot to look for postings in Toronto, you'll need to additionally update the 
base URL. 

I set up pushover notifications by following a blog post by Brian Connelly, 
[R Phone Home: Notifications with pushoverr](https://bconnelly.net/posts/r-phone-home/). 

I used `cronR` for automating the script, but any approach works. There can 
probably be improvements made on how to set relative paths when scheduling 
with cronR. 