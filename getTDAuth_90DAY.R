require("reticulate");require("httr");require("dplyr");require("purrr")
require("data.table");require("rvest")
# py_install("selenium")
# py_install("datetime",pip = TRUE)
source_python("authTD.py")

api_key = "*************"      # insert your api key
callback = "https://127.0.0.1" # from TD App
# first time run -> must authenticate 
# Chrome Driver: https://chromedriver.chromium.org/downloads
# ** Re-run in 90 days **
token = authentication(client_id=api_key, redirect_uri=callback,
                       tdauser=NULL, tdapass=NULL)
token2 = token # avoids overwriting token
# second time run -> pass in refresher token after authentication
# ** Re-run if authentication > 30 minutes **
# token = access_token(refresh_token=token2$refresh_token, client_id=api_key)
saveRDS(token2,"~/Desktop/R/token90.rds")
# get Real-Time Quotes
getQuoteTD = function(ticker)
{
  btoken = paste0("Bearer ",token$access_token)
  url = paste0("https://api.tdameritrade.com/v1/marketdata/quotes?apikey=",
               api_key,"&symbol=",ticker)
  pg = html_session(url)
  # get data by passing in url and cookies
  pg <- 
    pg %>% rvest:::request_GET(paste0("https://api.tdameritrade.com/v1/marketdata/quotes?apikey=",
                                      api_key,"&symbol=",ticker),
                               config = httr::add_headers(`Authorization` = btoken)
    )
  
  # raw data
  data_raw <- httr::content(pg$response)
  tmp = rbindlist(data_raw)
  if(tmp$delayed[1] == TRUE)
  {
    token = readRDS("token90.rds")
    token = access_token(refresh_token=token2$refresh_token, client_id=api_key)
    
    btoken = paste0("Bearer ",token$access_token)
    url = paste0("https://api.tdameritrade.com/v1/marketdata/quotes?apikey=",
                 api_key,"&symbol=",ticker)
    pg = html_session(url)
    # get data by passing in url and cookies
    pg <- 
      pg %>% rvest:::request_GET(paste0("https://api.tdameritrade.com/v1/marketdata/quotes?apikey=",
                                        api_key,"&symbol=",ticker),
                                 config = httr::add_headers(`Authorization` = btoken)
      )
    
    # raw data
    data_raw <- httr::content(pg$response)
    tmp = rbindlist(data_raw)
  }
  tmp$quoteTimeInLong = as.POSIXct(tmp$quoteTimeInLong/1000,origin = "1970-01-01")
  tmp$tradeTimeInLong = as.POSIXct(tmp$tradeTimeInLong/1000,origin = "1970-01-01")
  tmp$regularMarketTradeTimeInLong = as.POSIXct(tmp$regularMarketTradeTimeInLong/1000,origin = "1970-01-01")
  tmp
}

# get Quote
df = getQuoteTD("AMZN")
