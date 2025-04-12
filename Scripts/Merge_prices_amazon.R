
                                                  # AMAZON MERGE PRICES #

library(tidyverse)
library(xml2)
library(httr)
library(lubridate)
library(stringdist)
library(fuzzyjoin)

# LEO DATAFRAMES
df_amazon <- read.csv2("C:/Users/Jorge Pascual S/Desktop/Web-scraping-Smartphones-prices-in-Spain/Data/dfAmazonSelenium.csv")
df_md <- read.csv2("C:/Users/Jorge Pascual S/Desktop/Web-scraping-Smartphones-prices-in-Spain/Data/DF_MD.csv")

# Ajustar nombres de columnas para luego juntar
df_amazon <- df_amazon %>%
  rename(
    "NAME" = Nombre, 
    "MEMORY_INT" = Memoria_interna,
    "MEMORY_RAM" = RAM,
    "PRECIO" = Precio,
    "PVPR" = Precio_sin_descuento
  ) 

# Pequeña limpieza
df_amazon <- df_amazon %>% mutate(MEMORY_RAM = paste0(MEMORY_RAM, " RAM"))
df_md$NAME <- toupper(df_md$NAME)

# METODO POR ELIMINACIÓN DE PALABRAS AUSENTES EN LA MD
df_md$NAME <- df_md$NAME %>% str_replace_all("(\\+|PLUS)", " PLUS") %>% str_squish()
df_md$NAME <- df_md$NAME %>% str_remove_all("(\\(.+\\)|\\(.+$)") # quito todos los parentesis
df_md$NAME <- df_md$NAME %>% str_remove_all("(\\[.+\\]|\\[.+$)") # quito todos los corchetes
df_md$NAME <- df_md$NAME %>% str_remove_all("[^A-Za-z0-9\\s]") # quito todos los caracteres especiales

df_amazon$NAME <- df_amazon$NAME %>% str_replace_all("(\\+|PLUS)", " PLUS") %>% str_squish() 
df_amazon$NAME <- df_amazon$NAME %>% str_remove_all("(\\(.+\\)|\\(.+$)") # quito todos los parentesis
df_amazon$NAME <- df_amazon$NAME %>% str_remove_all("(\\[.+\\]|\\[.+$)") # quito todos los corchetes
df_amazon$NAME <- df_amazon$NAME %>% str_remove_all("[^A-Za-z0-9\\s]") # quito todos los caracteres especiales

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
amazon_words <- words_vector(df_amazon$NAME)

# conservo las de df_amazon que no coincidan
words_to_remove <- amazon_words[!amazon_words %in% md_words]
words_to_remove <- c(words_to_remove, "SMART(\\s)?PHONE", "DUAL", "SIM", "BLACK", "2022") # add words to remove

# las ordeno de más a menos caracteres
words_to_remove <- words_to_remove[order(nchar(words_to_remove), decreasing = TRUE)]
words_to_remove_rgx <- c()
for (w in words_to_remove) {
  newRgx <- paste0("((?<![A-Z0-9])", w, "(?![A-Z0-9]))")
  words_to_remove_rgx <- c(words_to_remove_rgx, newRgx)
}
# quito todas las palabras que no están en la MD
nombresFiltrados <- str_replace_all(df_amazon$NAME, paste(words_to_remove_rgx, collapse = "|"), " ") %>% str_squish() # IMPORTANTE aqui hay que decir que solo quite las palbras como tal, no solo las strings. algo como (?<!([0-9]|[AZ])) ... (?!([0-9]|[AZ]))

df_amazon$newName <- nombresFiltrados
df_amazon <- df_amazon %>% mutate(
  # newName = str_remove_all(newName, "\\(.{3,}\\)"),
  # newName = str_remove_all(newName, "\\s(3|4|5)G($|\\s)"),
  newName = str_replace_all(newName, "\\bSAMSUNG\\b(?!\\s*GALAXY)", "SAMSUNG GALAXY")
)

# METODO CON STRINGDIST
df_parejas_dist <- data.frame(
  'amazon_name' = character(0),
  'md_name' = character(0),
  'str_dist_jaccard' = numeric(0),
  'str_dist_jw' = numeric(0),
  'str_dist_lv' = numeric(0),
  'lv_ponderated' = numeric(0),
  'SUMA' = numeric(0)
)

for (nombre in df_amazon$newName) {
  string <- nombre
  # string <- "XIAOMI REDMI NOTE 13 PRO 5G"
  
  df_str_dist <- data.frame(
    'amazon_name' = string,
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
str_dist_threshold <- 0.06 # limite de str_dist a partir el cual acepto las parejas

df_parejas <- df_parejas_dist %>% 
  filter(SUMA < str_dist_threshold) %>% 
  select(amazon_name, md_name) %>% 
  distinct()

# junto df_parejas con df_amazon
df_parejas <- df_parejas %>% rename("newName" = amazon_name)
df_amazon <- left_join(df_parejas, df_amazon, by = "newName") 

# LIMPIEZA AMAZON
df_amazon$MEMORY_INT[is.na(df_amazon$MEMORY_INT) | df_amazon$MEMORY_INT == ''] <- 
  df_md$MEMORY_INT[match(df_amazon$md_name[is.na(df_amazon$MEMORY_INT) | df_amazon$MEMORY_INT == ''], df_md$NAME)] # rellena las memorias internas que faltaban en df_amazon con las de df_md

df_amazon$MEMORY_RAM[df_amazon$MEMORY_RAM == " RAM"] <- 
  df_md$MEMORY_RAM[match(df_amazon$md_name[df_amazon$MEMORY_RAM == " RAM"], df_md$NAME)] # lo mismo con la ram

df_amazon$Conexion[df_amazon$Conexion == ""] <- 
  df_md$CONNECTION[match(df_amazon$md_name[df_amazon$Conexion == ""], df_md$NAME)] # lo mismo con la conexión

# juntar df_amazon con MD
df_amazon <- df_amazon %>% mutate(AMAZON_NAME = NAME)
df_amazon <- df_amazon %>% mutate(NAME = md_name) 
df_amazon <- df_amazon %>% rename("CONNECTION" = Conexion)

df_merged <- left_join(df_amazon, df_md, by = c("NAME", "MEMORY_INT", "MEMORY_RAM", "CONNECTION")) %>% distinct(md_name, PRECIO, MEMORY_INT, MEMORY_RAM, CONNECTION, .keep_all = TRUE) 
df_prod <- df_merged %>% filter(!is.na(URL))  %>% 
  # deja solo los precios más bajos
  group_by(NAME, MEMORY_INT, MEMORY_RAM, CONNECTION) %>%
  slice_min(PRECIO, with_ties = FALSE) %>%
  ungroup() 

# GUARDADO
# Guardo el df_prod actual en df_prod_hist
df_prod_prev <- read.csv2("C:/Users/Jorge Pascual S/Desktop/Web-scraping-Smartphones-prices-in-Spain/Data/DF_PROD.csv")
df_prod_hist <- read.csv2("C:/Users/Jorge Pascual S/Desktop/Web-scraping-Smartphones-prices-in-Spain/Data/Histórico/DF_PROD_hist.csv")

df_prod_hist <- rbind(df_prod_prev, df_prod_hist) # une el df_prod previo con el df_prod_hist

write_csv2(df_prod_hist, "C:/Users/Jorge Pascual S/Desktop/Web-scraping-Smartphones-prices-in-Spain/Data/Histórico/DF_PROD_hist.csv")

# Elimina las entradas de la marketplace antiguas e introduce las nuevas
df_prod_new <- df_prod %>% 
  rbind(df_prod_prev) %>%
  filter(!(Marketplace == "Amazon" & TimeStamp < (today() - days(2)))) # SOLO VALIDO PARA AMAZON, AJUSTAR SEGUN FABRICANTE

# Guardo
write_csv2(df_prod_new, "C:/Users/Jorge Pascual S/Desktop/Web-scraping-Smartphones-prices-in-Spain/Data/DF_PROD.csv")