
                                         ## SCRAPEO DE MEDIAMARKT ##

  

library(tidyverse)
library(xml2)
library(httr)
library(lubridate)
library(stringdist)
library(fuzzyjoin)

userAgent <- "" # ADD YOUR USER AGENT
set_config(user_agent(userAgent))

wdPath <- "" # SET THE WORKING DIRECTORY ON THE REPOSITORY (./Web-scraping-Smartphones-prices-in-Spain)
setwd(wdPath) 


df_md <- read.csv2("Data/DF_MD.csv")
df_MM <- read.csv2("Data/MediaMarkt_precios.csv")





# Ajustar nombres de columnas para luego juntar
df_MM <- df_MM %>%
  rename(
    "NAME" = Nombre, 
    "MEMORY_INT" = Memoria_interna,
    "MEMORY_RAM" = RAM,
    "PRECIO" = Precio,
    "PVPR" = Precio_sin_descuento,
    "CONNECTION" = Conexion,
    "Link" = Links
  ) 

# Pequeña limpieza
df_MM <- df_MM %>% mutate(MEMORY_RAM = paste0(MEMORY_RAM, " RAM"))
df_md$NAME <- toupper(df_md$NAME)

# METODO POR ELIMINACIÓN DE PALABRAS AUSENTES EN LA MD
df_md$NAME <- df_md$NAME %>% str_replace_all("(\\+|PLUS)", " PLUS") %>% str_squish()
df_md$NAME <- df_md$NAME %>% str_remove_all("(\\(.+\\)|\\(.+$)") # quito todos los parentesis
df_md$NAME <- df_md$NAME %>% str_remove_all("(\\[.+\\]|\\[.+$)") # quito todos los corchetes
df_md$NAME <- df_md$NAME %>% str_remove_all("[^A-Za-z0-9\\s]") # quito todos los caracteres especiales

df_MM$NAME <- df_MM$NAME %>% str_replace_all("(\\+|PLUS)", " PLUS") %>% str_squish() 
df_MM$NAME <- df_MM$NAME %>% str_remove_all("(\\(.+\\)|\\(.+$)") # quito todos los parentesis
df_MM$NAME <- df_MM$NAME %>% str_remove_all("(\\[.+\\]|\\[.+$)") # quito todos los corchetes
df_MM$NAME <- df_MM$NAME %>% str_remove_all("[^A-Za-z0-9\\s]") # quito todos los caracteres especiales

# Todas las palabras en la columna NAME de MD
words_vector <- function(nameCol){
  wordsVector <- c()
  for (i in nameCol) {
    newWords <- i %>% toupper() %>% str_squish() %>% str_split(" ") %>% unlist()
    wordsVector <- unique(c(wordsVector, newWords))
  }
  return(wordsVector)
}

# aplico la función
md_words <- words_vector(df_md$NAME)
MM_words <- words_vector(df_MM$NAME)

# conservo las de df_MM que no coincidan
words_to_remove <- MM_words[!MM_words %in% md_words]
words_to_remove <- c(words_to_remove, "SMART(\\s)?PHONE", "DUAL", "SIM", "BLACK", "2022") # add words to remove

# las ordeno de más a menos caracteres
words_to_remove <- words_to_remove[order(nchar(words_to_remove), decreasing = TRUE)]
words_to_remove_rgx <- c()
for (w in words_to_remove) {
  newRgx <- paste0("((?<![A-Z0-9])", w, "(?![A-Z0-9]))")
  words_to_remove_rgx <- c(words_to_remove_rgx, newRgx)
}
# quito todas las palabras que no están en la MD
nombresFiltrados <- str_replace_all(df_MM$NAME, paste(words_to_remove_rgx, collapse = "|"), " ") %>% str_squish() # IMPORTANTE aqui hay que decir que solo quite las palbras como tal, no solo las strings. algo como (?<!([0-9]|[AZ])) ... (?!([0-9]|[AZ]))

df_MM$newName <- nombresFiltrados
df_MM <- df_MM %>% mutate(
  # newName = str_remove_all(newName, "\\(.{3,}\\)"),
  # newName = str_remove_all(newName, "\\s(3|4|5)G($|\\s)"),
  newName = str_replace_all(newName, "\\bSAMSUNG\\b(?!\\s*GALAXY)", "SAMSUNG GALAXY")
)



# METODO CON STRINGDIST
df_parejas_dist <- data.frame(
  'marketplace_name' = character(0),
  'md_name' = character(0),
  'str_dist_jaccard' = numeric(0),
  'str_dist_jw' = numeric(0),
  'str_dist_lv' = numeric(0),
  'lv_ponderated' = numeric(0),
  'SUMA' = numeric(0)
)

for (nombre in df_MM$newName) {
  string <- nombre
  # string <- "XIAOMI REDMI NOTE 13 PRO 5G"
  
  df_str_dist <- data.frame(
    'marketplace_name' = string,
    'md_name' = df_md$NAME,
    'str_dist_jaccard' = stringdist(string, df_md$NAME, method = "jaccard"),
    'str_dist_jw' = stringdist(string, df_md$NAME, method = "jw"),
    'str_dist_lv' = stringdist(string, df_md$NAME, method = "lv")
  )
  
  df_str_dist_match <- df_str_dist %>% mutate(
    lv_ponderated = str_dist_lv*0.01,
    SUMA = lv_ponderated + str_dist_jaccard + str_dist_jw #+ qgram_ponderated
  ) %>% 
    arrange(SUMA) %>% 
    distinct() %>% 
    slice(1) 
  
  df_parejas_dist <- rbind(df_parejas_dist, df_str_dist_match) %>% 
    arrange(SUMA)
}



# creo el primer check de parejas detectadas de nombres para luego unir con md
str_dist_threshold <- 0.1 # limite de str_dist a partir el cual acepto las parejas

df_parejas <- df_parejas_dist %>% 
  filter(SUMA < str_dist_threshold) %>% 
  select(marketplace_name, md_name) %>% 
  distinct()





# junto df_parejas con df_MM*******!!!!!! (creo que pilla mal las rows, me parecen pocas)
df_parejas <- df_parejas %>% rename("newName" = marketplace_name)
df_MM <- left_join(df_parejas, df_MM, by = "newName") 



# LIMPIEZA MM
df_MM$MEMORY_INT[is.na(df_MM$MEMORY_INT) | df_MM$MEMORY_INT == ''] <- 
  df_md$MEMORY_INT[match(df_MM$md_name[is.na(df_MM$MEMORY_INT) | df_MM$MEMORY_INT == ''], df_md$NAME)] # rellena las memorias internas que faltaban en df_MM con las de df_md

df_MM$MEMORY_RAM[df_MM$MEMORY_RAM == " RAM"| df_MM$MEMORY_RAM == "APPLE RAM"] <- 
  df_md$MEMORY_RAM[match(df_MM$md_name[df_MM$MEMORY_RAM == " RAM"| df_MM$MEMORY_RAM == "APPLE RAM"], df_md$NAME)] # lo mismo con la ram

df_MM$CONNECTION[df_MM$CONNECTION == "" | df_MM$CONNECTION == "2-4G"] <- 
  df_md$CONNECTION[match(df_MM$md_name[df_MM$CONNECTION == "" | df_MM$CONNECTION == "2-4G"], df_md$NAME)] # lo mismo con la conexión




# juntar df_MM con MD
df_MM <- df_MM %>% mutate(marketplace_name = NAME)
df_MM <- df_MM %>% mutate(NAME = md_name) 

df_merged <- left_join(df_MM, df_md, by = c("NAME", "MEMORY_INT", "MEMORY_RAM", "CONNECTION")) %>% distinct(md_name, PRECIO, MEMORY_INT, MEMORY_RAM, CONNECTION, .keep_all = TRUE) 
df_prod_new <- df_merged %>% filter(!is.na(URL))  %>% 
  # deja solo los precios más bajos
  group_by(NAME, MEMORY_INT, MEMORY_RAM, CONNECTION) %>%
  slice_min(PRECIO, with_ties = FALSE) %>%
  ungroup() %>% 
  select(-Source)





# este chunk guarda el df_prod actual en df_prod_hist
df_prod_prev <- read.csv2("Data/DF_PROD.csv")
df_prod_hist <- read.csv2("Data/Histórico/DF_PROD_hist.csv")

df_prod_hist <- rbind(df_prod_prev, df_prod_hist) # une el df_prod previo con el df_prod_hist

write_csv2(df_prod_hist, "Data/Histórico/DF_PROD_hist.csv")



# names(df_prod_prev) <- names(df_prod_new)
# elimina las entradas de la marketplace antiguas e introduce las nuevas
df_prod_updated <- df_prod_new %>% 
  rbind(df_prod_prev) %>%
  filter(!(Marketplace == "MediaMarkt" & TimeStamp < (today() - days(7)))) # AJUSTAR SEGUN FABRICANTE

# Guardo
write_csv2(df_prod_updated, "Data/DF_PROD.csv")


