pacman::p_load(cronR)

wd = getwd()
script = file.path(wd, "src/scrape.R")
cmd = cron_rscript(script,
                   log_append = TRUE,
                   log_timestamp = TRUE)
cron_add(command = cmd,
         frequency ='*/20 * * * *',
         id = "Cl-Toronto-Apt",
         description = "Webscraping Toronto Apartments off Craigslist",
         tags = "webscraping")
