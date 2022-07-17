# Using Pushover for push notifications to my Phone and watch
# inspiration blog post: https://bconnelly.net/posts/r-phone-home/

wd = "/Users/jordanhutchings/Documents/Documents - Jordan’s MacBook Air/MLDS/craigslist-crawler"
source(file.path(wd, "src/secrets.R"))

push = function(url, msg) {
  
  pushoverr::pushover(message = msg, 
                      user = USER_KEY, 
                      app = APP_KEY, 
                      url = url)
  Sys.sleep(10) # to prevent overloading
}