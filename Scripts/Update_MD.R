
                                          # MASTERDATA Update #


library(tidyverse)
library(xml2)
library(httr)
library(lubridate)

userAgent <- "" # ADD YOUR USER AGENT

set_config(user_agent(userAgent))

wdPath <- "" # SET THE WORKING DIRECTORY ON THE REPOSITORY (./Web-scraping-Smartphones-prices-in-Spain)
setwd(wdPath) 


df_md_path <- "Data/DF_MD.csv" 
md_hist_path <- "Data/Histórico/DF_MD_hist.csv"
df_md <- read_csv2(df_md_path)
# lo guardo en histórico
write_csv2(df_md, md_hist_path)
# Saco los url de todos los productos
url_list <- df_md$URL




#Abrir URL filtrada por año, disponibilidad y fabricante
gsmarena_url <- "https://www.gsmarena.com/results.php3?nYearMin=2020&sMakers=80&sAvailabilities=1"
# gsmarena_url <- "https://www.gsmarena.com/xiaomi-phones-80.php"
# gsmarena_url <- "https://www.gsmarena.com/apple-phones-48.php"
# gsmarena_url <- "https://www.gsmarena.com/samsung-phones-9.php"

# Lista de nº de fabricantes que me interesan
fabricantes_list <- c('48','107','121','45','58','4','95','82','118','9','98','80','62', "7", "130", "20")
# '48', APPLE
# '107', GOOGLE
# '121', HONOR
# '45', HTC
# '58', HUAWEI
# '4', MOTOROLA
# '95', ONEPLUS
# '82', OPPO
# '118', REALME
# '9', SAMSUNG
# '98', VIVO
# '80', XIAOMI
# '62' ZTE
# '7', SONY
# '130', CUBOT
# '20', LG

# Generar lista de enlaces de búsqueda filtrados para cada fabricante

url_complete_fabr_list <- c()

for (fabr_number in fabricantes_list){
  fabr_complete_url <- gsmarena_url %>% str_replace("Makers=80", paste0("Makers=", fabr_number))
  
  url_complete_fabr_list <- c(url_complete_fabr_list, fabr_complete_url)
}

url_complete_fabr_list



# Extraer el URL de cada producto
prod_url_list <- c()

for (url in url_complete_fabr_list){
  fabr_html <- read_html(url)
  prod_semi_url <- fabr_html %>% xml_find_all("//div[@class = 'makers']//a") %>% xml_attr("href")
  
  prod_complete_url <- paste0("https://www.gsmarena.com/", prod_semi_url)
  prod_url_list <- c(prod_url_list, prod_complete_url)
  
  Sys.sleep(12)
}

prod_url_list




# Eliminar las url que ya existen en la MD
newprod_url_list <- prod_url_list[!prod_url_list %in% url_list & prod_url_list != "https://www.gsmarena.com/"]


#Extracción de características


# Extraer características de cada producto

new_masterdata_raw <- data.frame(
    NAME = character(),
    MODEL_ID = character(),
    RELEASE_DATE = character(),
    STATUS = character(),
    BULK = character(),
    SIZE = character(),
    COLORS = character(),
    RESOLUTION = character(),
    OPERATIVE_SYSTEM = character(),
    CHIPSET = character(),
    CPU = character(),
    GPU = character(),
    MEMORY_INT = character(),
    MEMORY_RAM = character(),
    CARD_SLOT = character(),
    CONNECTION = character(),
    BLUETOOTH = character(),
    NFC = character(),
    USB = character(),
    BATTERY_MAH = character(),
    BATTERY_TYPE = character(),
    BATTERY_WIRELESS = character(),
    URL = character()
)

newprod_url_list <- newprod_url_list[!newprod_url_list %in% new_masterdata_raw$URL]

for (url in newprod_url_list){
  
  product_html <- url %>% read_html()
  Sys.sleep(14)
  
  # NOMBRE DE MODELO
  name <- product_html %>% xml_find_all("//h1[@data-spec = 'modelname']") %>% xml_text()
  model_id <- product_html %>% xml_find_all("//tr//td[@data-spec = 'models']") %>% xml_text()
  # FECHA DE SALIDA
  released <- product_html %>% xml_find_all("//span[@data-spec = 'released-hl']") %>% xml_text() # if 'cancelled', next iteration
  status <- product_html %>% xml_find_all("//tr//td[@data-spec = 'status']") %>% xml_text()
  
  # DIMENSIONES
  bulk <- product_html %>% xml_find_all("//span[@data-spec = 'body-hl']") %>% xml_text()
  size <- product_html %>% xml_find_all("//td[@data-spec = 'displaysize']") %>% xml_text()
  available_colors <- product_html %>% xml_find_all("//tr//td[@data-spec = 'colors']") %>% xml_text()
  
  # PANTALLA
  resolution <- product_html %>% xml_find_all("//tr//td[@data-spec = 'displayresolution']") %>% xml_text()
  
  # SISTEMA OPERATIVO 
  OS <- product_html %>% xml_find_all("//tr//td[@data-spec = 'os']") %>% xml_text()
  # CHIPSET
  chipset <- product_html %>% xml_find_all("//tr//td[@data-spec = 'chipset']") %>% xml_text()
  # CPU
  cpu <- product_html %>% xml_find_all("//tr//td[@data-spec = 'cpu']") %>% xml_text()
  # GPU
  gpu <- product_html %>% xml_find_all("//tr//td[@data-spec = 'gpu']") %>% xml_text()
  
  
  # MEMORIA
  memory_raw <- product_html %>% xml_find_all("//tr//td[@data-spec = 'internalmemory']") %>% xml_text()
  memory_raw <- ifelse(length(memory_raw) == 0, "No", memory_raw) 
  if (memory_raw == "No") {
    memory_int <- "No"
    memory_ram <- "No"
  } else {
    memory_splitted <- unlist(str_split(memory_raw, ",\\s"))
    
    memory_int <- memory_splitted %>%
      str_extract("\\d+[M|G|T]B") %>%
      str_squish()
    
    memory_ram <- memory_splitted %>%
      str_extract("\\d+.B RAM") %>%
      str_squish()
  }
  card_slot <- product_html %>% xml_find_all("//tr//td[@data-spec = 'memoryslot']") %>% xml_text()
  
  # CONNECTIONS
  bluetooth <- product_html %>% xml_find_all("//tr//td[@data-spec = 'bluetooth']") %>% xml_text()
  nfc <- product_html %>% xml_find_all("//tr//td[@data-spec = 'nfc']") %>% xml_text()
  usb <- product_html %>% xml_find_all("//tr//td[@data-spec = 'usb']") %>% xml_text()
  
  # RED
  conn_raw <- product_html %>% xml_find_all("//a[@data-spec = 'nettech']") %>% xml_text()
  conn <- case_when(
    grepl("5G", conn_raw) ~ "5G",
    grepl("LTE", conn_raw) ~ "4G",
    grepl("HSPA", conn_raw) ~ "3G",
    grepl("GSM", conn_raw) ~ "2G",
    TRUE ~ NA_character_ 
  )
  
  # BATTERY
  battery_raw <- product_html %>% xml_find_all("//tr//td[@data-spec = 'batdescription1']") %>% xml_text()
  battery_mah <- battery_raw %>% str_extract("\\d*? mAh") %>% str_squish()
  battery_type <- battery_raw %>% str_extract(".*(?= \\d)") %>% str_squish()
  
  battery_charge_raw <- product_html %>% xml_find_all("//table[tr//td[@data-spec = 'batdescription1']]//td[@class = 'nfo']") %>% xml_text()
  battery_charge_raw <- ifelse(length(battery_charge_raw) > 1, paste(battery_charge_raw, collapse = "-"), battery_charge_raw)
  
  battery_charge <- battery_charge_raw %>% str_extract(".*") %>% str_remove_all("\\(advertised\\)") %>% str_squish()
  battery_wireless_raw <- battery_charge_raw %>% str_remove_all("/r/") %>% str_squish() %>% toupper()
  if (grepl("WIRELESS", battery_wireless_raw)){
    battery_wireless = "Yes"
  } else {
    battery_wireless = "No"
  }
  for (memo in seq(1:length(memory_int))){
    df_actual <- data.frame(
      NAME = ifelse(length(name) == 0, "No", name),
      MODEL_ID = ifelse(length(model_id) == 0, "No", model_id),
      RELEASE_DATE = ifelse(length(released) == 0, "No", released),
      STATUS = ifelse(length(status) == 0, "No", status),
      BULK = ifelse(length(bulk) == 0, "No", bulk),
      SIZE = ifelse(length(size) == 0, "No", size),
      COLORS = ifelse(length(available_colors) == 0, "No", available_colors),
      RESOLUTION = ifelse(length(resolution) == 0, "No", resolution),
      OPERATIVE_SYSTEM = ifelse(length(OS) == 0, "No", OS),
      CHIPSET = ifelse(length(chipset) == 0, "No", chipset),
      CPU = ifelse(length(cpu) == 0, "No", cpu),
      GPU = ifelse(length(gpu) == 0, "No", gpu),
      MEMORY_RAM = memory_ram[memo],
      MEMORY_INT = memory_int[memo],
      MEMORY_RAW = memory_raw,
      CARD_SLOT = ifelse(length(card_slot) == 0, "No", card_slot),
      CONNECTION = conn,
      BLUETOOTH = ifelse(length(bluetooth) == 0, "No", bluetooth),
      NFC = ifelse(length(nfc) == 0, "No", nfc),
      USB = ifelse(length(usb) == 0, "No", usb),
      BATTERY_MAH = ifelse(length(battery_mah) == 0, "No", battery_mah),
      BATTERY_TYPE = ifelse(length(battery_type) == 0, "No", battery_type),
      BATTERY_WIRELESS = ifelse(length(battery_wireless) == 0, "No", battery_wireless),
      URL = ifelse(length(url) == 0, "No", url)
    )
    new_masterdata_raw <- rbind(new_masterdata_raw, df_actual)
  }
  print(n_distinct(new_masterdata_raw$URL))
}


#### TRANSFORMACIÓN DE VARIABLES



new_md <- new_masterdata_raw

new_md$NAME <- toupper(new_md$NAME) 
new_md <- new_md %>% mutate(
  NAME = str_remove_all(NAME, "\\(.{3,}\\)"),
  NAME = str_remove_all(NAME, "\\s(3|4|5)G($|\\s)"),
  NAME = str_replace_all(NAME, "\\+", "PLUS"),
  RELEASE_DATE = str_remove(
    str_extract(RELEASE_DATE, "\\d.+"), 
    "\\s\\d{1,2}"), # extraigo solo la fecha
  AVAILABLE = ifelse(grepl("Available", STATUS), 1, 0) # Creo variable binaria para su disponibilidad en el mercado
)

# cambio los Qx por un mes
new_md <- new_md %>% mutate(
  RELEASE_DATE = str_replace(RELEASE_DATE, "Q1", "March"),
  RELEASE_DATE = str_replace(RELEASE_DATE, "Q2", "June"),
  RELEASE_DATE = str_replace(RELEASE_DATE, "Q3", "September"),
  RELEASE_DATE = str_replace(RELEASE_DATE, "Q4", "December")
)

# Añado el mes a los que no tienen y lo transformo todo en fecha
new_md <- new_md %>% mutate(
  RELEASE_DATE = ifelse(grepl("^\\d{4}$", RELEASE_DATE), paste0(RELEASE_DATE, ", July"), RELEASE_DATE),
  RELEASE_DATE = format(ymd(paste0(RELEASE_DATE, " 1")), "%m/%Y")
)

# Caracteristicas físicas
new_md <- new_md %>% mutate(
  WEIGHT = sapply(str_extract_all(BULK, "\\d+(\\.\\d+)?(\\s)?(g|kg|mg)"), function(x) paste(x, collapse = ", ")), 
  THICKNESS = sapply(str_extract_all(BULK, "\\d+(\\.\\d+)?(\\s)?mm"), function(x) paste(x, collapse = ", ")), 
  INCHES = sapply(str_extract_all(SIZE, "\\d+.+(?=[Ii]nches)"), function(x) as.numeric(paste(x, collapse = ", "))), 
  SCREEN_TO_BODY = sapply(str_extract_all(SIZE, "\\d+(\\.\\d+)?% screen-to-body ratio"), function(x) paste(x, collapse = ", ")) 
)

# Resolucion
new_md <- new_md %>% mutate(
  RESOLUTION_PIXELS = str_extract(RESOLUTION, "\\d+ x \\d+(?= pixels)"),
  PIXEL_DENSITY = as.numeric(str_extract(RESOLUTION, "\\d+(?= ppi)"))
)

# Sistema Operativo
new_md <- new_md %>% mutate(
  OS_BRAND = str_extract(OPERATIVE_SYSTEM, ".+Watch OS|^.[^(\\s|,)]+"),
  OS_MODEL = str_remove(OPERATIVE_SYSTEM, "(, no )?Google Play Services& - 2 GB RAM versionAndroid 11 - 3 GB RAM version&, planned.+& - InternationalAndroid 12, MagicOS 7 - China")
)

# CHIPSET
new_md <- new_md %>% mutate(
  CHIP_BRAND = str_extract(CHIPSET, "^[^\\s,]+"), # Extrae hasta el primer espacio o coma
  CHIP_MODEL = sapply(CHIPSET, function(x) { 
    extracted <- str_extract(x, ".*?(?= \\(\\d+ nm)")
    ifelse(is.na(extracted), x, extracted) 
  }),
  CHIP_SIZE_NM = str_extract(CHIPSET, "\\d+(?= nm)") # Extrae el tamaño en nm
)

# CPU
new_md <- new_md %>% mutate(
  CPU_EXTENDED = CPU,
  CPU = sapply(CPU, function(x) { 
    extracted <- str_extract(x, ".+(?=\\s-\\s)")
    ifelse(is.na(extracted), x, extracted) 
  })
)
new_md$CPU <- str_replace_all(new_md$CPU, "8-core","Octa-core")
new_md$CPU <- str_replace_all(new_md$CPU, "10-core","Deca-core")

new_md <- new_md %>% mutate(
  CPU_CORES = case_when(
    str_detect(tolower(CPU), "dual") ~ 2,
    str_detect(tolower(CPU), "quad") ~ 4,
    str_detect(tolower(CPU), "penta") ~ 5,
    str_detect(tolower(CPU), "hexa") ~ 6,
    str_detect(tolower(CPU), "octa") ~ 8,
    str_detect(tolower(CPU), "nona") ~ 9,
    str_detect(tolower(CPU), "deca") ~ 10,
    TRUE ~ NA_real_ # En caso de que no coincida con ningún patrón
  )
) 

# GPU
new_md <- new_md %>% mutate(
  GPU_EXTENDED = GPU,
  GPU = str_remove(GPU, "\\s-\\s.+")
)

# MEMORY
new_md <- new_md %>%
  mutate(
    MEMORY_INT = ifelse(str_detect(MEMORY_INT, "^\\d+TB \\d+GB$"), str_extract(MEMORY_INT, "^\\d+TB"), MEMORY_INT),  
    MEMORY_RAM = ifelse(str_detect(MEMORY_INT, "^\\d+TB \\d+GB$"), str_extract(MEMORY_INT, "\\d+GB$"), MEMORY_RAM),
    MEMORY_INT_KB = case_when(
      str_detect(MEMORY_INT, "MB") ~ as.numeric(str_extract(MEMORY_INT, "\\d+")) * 1024,  # MB a KB (binario)
      str_detect(MEMORY_INT, "GB") ~ as.numeric(str_extract(MEMORY_INT, "\\d+")) * 1024 * 1024,  # GB a KB (binario)
      str_detect(MEMORY_INT, "TB") ~ as.numeric(str_extract(MEMORY_INT, "\\d+")) * 1024 * 1024 * 1024,  # TB a KB (binario)
      TRUE ~ NA_real_  # En caso de que no coincida con ninguna unidad
    ),
    
    MEMORY_RAM_KB = case_when(
      str_detect(MEMORY_RAM, "MB") ~ as.numeric(str_extract(MEMORY_RAM, "\\d+")) * 1024,  # MB a KB (binario)
      str_detect(MEMORY_RAM, "GB") ~ as.numeric(str_extract(MEMORY_RAM, "\\d+")) * 1024 * 1024,  # GB a KB (binario)
      str_detect(MEMORY_RAM, "TB") ~ as.numeric(str_extract(MEMORY_RAM, "\\d+")) * 1024 * 1024 * 1024,  # TB a KB (binario)
      TRUE ~ NA_real_  # En caso de que no coincida con ninguna unidad
    )
  )

# CARD SLOT 
new_md <- new_md %>% mutate(
  CARD_SLOT_EXTENDED = CARD_SLOT,
  CARD_SLOT = case_when(
    CARD_SLOT_EXTENDED %in% c("Unspecified", "To be confirmed") ~ "?",
    CARD_SLOT_EXTENDED == "No" ~ "No",
    !CARD_SLOT_EXTENDED %in% c("Unspecified", "To be confirmed", "No") ~ "Yes",
  ),
  MEMORY_CARD = case_when(
    CARD_SLOT == "Yes" ~ str_extract(CARD_SLOT_EXTENDED, "^[^\\s,]+"),
    CARD_SLOT != "Yes" ~ NA
  ),
  MEMORY_CARD_GB = case_when(
    grepl("\\d+(\\s)(M|G|T)B", toupper(CARD_SLOT_EXTENDED)) ~ str_extract(CARD_SLOT_EXTENDED, "\\d+(\\s)(M|G|T)B"),
    !grepl("\\d+(\\s)(M|G|T)B", toupper(CARD_SLOT_EXTENDED)) ~ NA
  )
)

# BLUETOOTH
new_md <- new_md %>% mutate(
  BLUETOOTH = str_remove(BLUETOOTH, "(\\(|after).+"),
  BLUETOOTH_VERSION = as.numeric(str_extract(BLUETOOTH, "\\d\\.\\d"))
)

# NFC
new_md$NFC_EXTENDED <- new_md$NFC
new_md <- new_md %>% mutate(
  NFC = case_when(
    grepl("(C|c)hina", NFC_EXTENDED) ~ "No",
    NFC_EXTENDED == "No" ~ "No",
    grepl("Yes", NFC_EXTENDED) ~ "Yes",
    TRUE ~ "?", 
  )
)

# USB
new_md <- new_md %>% mutate(
  USB_TYPE = case_when(
    grepl("Lightning", USB) ~ "Lightning",
    grepl("MicroUSB", USB) ~ "MicroUSB",
    grepl("USB", USB) & grepl("-C", USB) ~ "USB Type C",
    grepl("No", USB) ~ "No",
    TRUE ~ "Other"
  )
)

# BATTERY
new_md$BATTERY_MAH_NUM <- as.numeric(str_extract(new_md$BATTERY_MAH, "\\d+")) 
new_md$BATTERY_TYPE_EXTENDED <- new_md$BATTERY_TYPE
new_md <- new_md %>% mutate(
  BATTERY_TYPE = case_when(
    grepl("Li-Po", BATTERY_TYPE_EXTENDED) ~ "Li-Po",
    grepl("Li-Ion", BATTERY_TYPE_EXTENDED) ~ "Li-Ion",
    grepl("Si/C", BATTERY_TYPE_EXTENDED) ~ "Si/C",
    TRUE ~ "Other"
  )
)



# Merge with main MD


# Merge
updated_df_md <- rbind(df_md, new_md)




# Save
write_csv2(updated_df_md, "Data/DF_MD.csv")




