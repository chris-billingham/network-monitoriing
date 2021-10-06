library(magrittr)

# run a speedtest
logger::log_info("running speedtest")
test <- system("/home/pi/.local/bin/speedtest", intern = TRUE)

# set up the conversion function
conv_to_bits <- function(bandwidth) {
  bandwidth_units <- stringr::str_extract(bandwidth, "[A-Za-z]+\\/s$")
  bandwidth_num <- as.numeric(stringr::str_extract(bandwidth, "[0-9.]+"))
  multiplier <- switch(bandwidth_units, "Mbit/s" = 1048576, "Kbit/s" = 1024)
  new_bandwidth <- bandwidth_num * multiplier
  return(new_bandwidth)
}

# create the update tibble
logger::log_info("creating speedtest dataframe")
st_df <- tibble::tibble(test_datetime = Sys.time(),
                        isp_name = stringr::str_extract(test[2], "[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}"),
                        isp_ip = stringr::str_match(test[2], "Testing from (.*?) \\(")[2],
                        test_server_name = stringr::str_match(test[5], "Hosted by (.*?) \\(")[2],
                        test_server_location = stringr::str_match(test[5], "\\((.*?)\\)")[2],
                        test_server_distance_km = as.numeric(stringr::str_extract(stringr::str_match(test[5], "\\[(.*?)\\]")[2],"[0-9\\.]+")),
                        test_server_ping_ms = as.numeric(stringr::str_extract(stringr::str_match(test[5], ": (.*?)$")[2],"[0-9\\.]+")),
                        download = test[7],
                        download_bits = conv_to_bits(test[7]),
                        upload = test[9],
                        upload_bits = conv_to_bits(test[9])) %>%
  dplyr::select(-download, -upload)

# load the old data
logger::log_info("reading old data")
old <- readRDS("/home/pi/nas-share/R/network-monitoring/data/speedtest.rds")

# append together
new <- dplyr::bind_rows(old, st_df)

# save data
logger::log_info("saving with new data")
saveRDS(new, "/home/pi/nas-share/R/network-monitoring/data/speedtest.rds")

# fin
logger::log_success("#fin")

