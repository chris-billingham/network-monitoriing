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
                        isp = test[2],
                        test_server = test[5],
                        download = test[7],
                        download_bits = conv_to_bits(test[7]),
                        upload = test[9],
                        upload_bits = conv_to_bits(test[9]))

# load the old data
logger::log_info("reading old data")
old <- readRDS("data/speedtest.rds")

# append together
new <- dplyr::bind_rows(old, st_df)

# save data
logger::log_info("saving with new data")
saveRDS(new, "data/speedtest.rds")

# fin
logger::log_success("#fin")

