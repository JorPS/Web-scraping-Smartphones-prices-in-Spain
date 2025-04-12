# Libraries
import pandas as pd
from pandasgui import show
import numpy as np
import os
import time
from selenium import webdriver # importa el driver
from selenium.webdriver.common.by import By # importa el by que es necesario para usar xpath
from selenium.common.exceptions import NoSuchElementException # importa el error no such element exception para manejar trys
import re # string manipulation
import datetime

# SCRAPING

driver = webdriver.Firefox() # abro driver
main_page_amazon = 'https://www.amazon.es/s?rh=n%3A599370031%2Cn%3A665492031%2Cn%3A17425698031&dc&qid=1739268994&rnid=665492031&ref=sr_nr_n_4'
driver.get(main_page_amazon)# Navegación
time.sleep(2)

# Quito cookies
cookieButton = driver.find_element(By.XPATH, '//button[@id="sp-cc-rejectall-link"]') # rechazar cookies
cookieButton.click()

dfAmazon = pd.DataFrame(columns=[
    'Fabricante', 'Nombre', 'Precio', 'Precio_sin_descuento',
    'Memoria_interna', 'RAM', 'Conexion', 'Stock',
    'Literal', 'Link', 'TimeStamp', 'Source', 'Marketplace'
])

# Lista de fabricantes
fabrList = brands = ["APPLE", "GOOGLE", "HONOR", "HTC", "HUAWEI", "MOTOROLA", "ONEPLUS", "OPPO", 
          "REALME", "SAMSUNG", "VIVO", "XIAOMI", "ZTE", "SONY", "CUBOT", "LG"]

for fabr in fabrList:
    time.sleep(6)
    searchBar = driver.find_element(By.XPATH, '//input[@id = "twotabsearchtextbox"]')
    searchBar.clear()
    searchBar.send_keys(fabr + ' smartphone')

    searchButton = driver.find_element(By.XPATH,'//input[@id = "nav-search-submit-button"]')
    searchButton.click()
    time.sleep(1)
    productosNuevos = driver.find_element(By.XPATH, '//ul[@aria-labelledby="p_n_condition-type-title"]//a/span')
    productosNuevos.click()
    time.sleep(6)
    current_url = driver.current_url

    # Páginas de resultados
    pagItemsRaw = driver.find_elements(By.XPATH, '//span[@class="s-pagination-strip"]//ul/*')
    nextPage = pagItemsRaw[-1]
    pagItems = []

    for li in pagItemsRaw: pagItems.append(li.text)
    pagItems

    nPages = max([int(p) for p in pagItems if p.isdigit()]) #engancho el número más alto de pagItems
    if nPages > 12: nPages = 12

    for page in range(0, nPages):
        time.sleep(10)
        # Literales
        literales_raw = driver.find_elements(By.XPATH, '//div[@data-component-type="s-search-result"]//h2[@aria-label]')
        literales = []
        for lr in literales_raw: literales.append(lr.get_attribute('aria-label'))
        literales = [s for s in literales if len(s) <= 190] # filtro y quito los que tienen literales demasiado largos
        literales = [s for s in literales if "reacondicionado" not in s.lower()]
        literales = [s for s in literales if not re.search(r"[\"'‘’“”]", s)] # quito los que tengan comillas

        names = []
        precios = []
        pvpr = []
        url_list = []
        memory_int = []
        memory_ram = []
        conn = []

        for lr in literales:
        # PVP
            try:
                currentPriceRaw = driver.find_element(By.XPATH, '//div[@data-component-type="s-search-result"]'+
                            f"[.//h2[@aria-label='{lr}']]"+
                            '//span[@class="a-price"]')
                currentPVP = currentPriceRaw.text
            except NoSuchElementException:
                currentPVP = ""
            precios.append(currentPVP)
        # PVPR
            try:
                currentPvprRaw = driver.find_element(By.XPATH, "//div[@data-component-type='s-search-result']"+
                            f"[.//h2[@aria-label='{lr}']]"+
                            "//span[@class='a-price a-text-price' and @data-a-color='secondary']")
                currentPvpr = currentPvprRaw.text
            except NoSuchElementException:
                currentPvpr = ""    
            pvpr.append(currentPvpr)      
        # URLs
            currentUrl = driver.find_element(By.XPATH, '//div[@data-component-type="s-search-result"]'+
                            f"[.//h2[@aria-label='{lr}']]"+
                            '//div[@data-cy="title-recipe"]/a[@href]')
            url_list.append(currentUrl.get_attribute('href'))
        # Memory Int
            try:
                currentMemoRaw = driver.find_element(By.XPATH, '//div[@data-component-type="s-search-result"]'+
                            f"[.//h2[@aria-label='{lr}']]"+
                            '//div[@data-cy="product-details-recipe"]'+
                            '//div[@class="puisg-col-inner"]'+
                            '[.//span[contains(text(), "Capacidad")]]'+ 
                            '//span[@class="a-text-bold"]')
                currentMemo = currentMemoRaw.text
            except NoSuchElementException:
                currentMemo = ""    
            memory_int.append(currentMemo)   
        # Name
            matchName = re.match(r'.*\d+(\s)?(M|G|T)B.*', lr)

            if matchName: 
                current_name = re.sub(r'(\()?\d+(\s)?(M|G|T)B.*', '', lr.upper())
                current_name = re.sub(r'\sDE(\s|$)', '', current_name)
                current_name_clean = re.sub(r'\s+', ' ', current_name.strip())
                names.append(current_name_clean)
            else:
                names.append(lr) 
        # RAM
            matchRAM = re.search(r'(?<!\d)(1|2|3|4|6|8|12|16)(\s)(M|G|T)B', lr.upper())
                
            if matchRAM: current_ram = matchRAM.group(0).strip()  
            else: current_ram = "0"
            memory_ram.append(current_ram)
        # Connection
            matchConn = re.search(r'(?<!\d)(3|4|5)G(\s|,|$)', lr.upper())
                
            if matchConn: current_conn = matchConn.group(0).strip()  
            else: current_conn = ""
            conn.append(current_conn)
            
        # Dataframe
        current_dfAmazon = pd.DataFrame({
        'Fabricante': fabr,
        'Nombre': names,
        'Precio': precios,
        'Precio_sin_descuento': pvpr,
        'Memoria_interna': memory_int,
        'RAM': memory_ram,
        'Conexion': conn,
        'Stock': True,
        'Literal': literales,
        'Link': url_list,
        'TimeStamp': datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        'Source': current_url,
        'Marketplace': 'Amazon'
        })

        dfAmazon = pd.concat([dfAmazon, current_dfAmazon])

        try: 
            current_pagItemsRaw = driver.find_elements(By.XPATH, '//span[@class="s-pagination-strip"]//ul/*')
            current_nextPage = current_pagItemsRaw[-1]
            nextPageButton = current_nextPage.text
        except Exception: 
            nextPageButton = ''
        if nextPageButton == 'Siguiente': current_nextPage.click()
        else: break

driver.quit()

# LIMPIEZA

# Nombre
dfAmazon['Nombre'] = dfAmazon['Nombre'].str.upper()
## Eliminar lo que no empiece por el fabricante. auriculares, anuncios patrocinados, fundas
dfAmazon = dfAmazon[dfAmazon.apply(lambda row: row['Nombre'].startswith(row['Fabricante']), axis=1)]
dfAmazon = dfAmazon[~dfAmazon['Nombre'].str.contains('AURICULARES', na=False)]
dfAmazon = dfAmazon[~dfAmazon['Nombre'].str.contains('ANUNCIO|PATROCINADO', na=False)]


# Precio
dfAmazon['Precio'] = dfAmazon['Precio'].str.replace('.', '', regex=False).str.replace('€', '').str.replace('\n', '.', regex=False)
dfAmazon['Precio'] = pd.to_numeric(dfAmazon['Precio'], errors='coerce')

# Precio sin descuento
dfAmazon['Precio_sin_descuento'] = dfAmazon['Precio_sin_descuento'].str.replace('€', '').str.replace(',', '.', 
                                                                                                     regex=False)
dfAmazon['Precio_sin_descuento'] = pd.to_numeric(dfAmazon['Precio_sin_descuento'], errors='coerce')
dfAmazon['Precio_sin_descuento'] = dfAmazon['Precio_sin_descuento'].replace('', pd.NA).fillna(dfAmazon['Precio'])

# Memoria
dfAmazon['Memoria_interna'] = dfAmazon['Memoria_interna'].str.replace('1024(\s)GB', '1 TB').str.replace('\s', '')
dfAmazon = dfAmazon[~dfAmazon['Memoria_interna'].str.contains('MB', na=False)]

for lr in dfAmazon['Literal']:
    memo_int_regex = r'((32|64|128|256|512)(.0+)?(\s)?(GB|([\+\/,])?(\s)?(?<!\d)(2|3|4|6|8|12|16)(\s)?GB)|(1|2)(\s)?TB)' # no puede ser cualquier dígito.
    memo_ram_regex = r'(?<!\d)(2|3|4|6|8|12|16)(\s)?(GB|([\+\/,])?(\s)?((32|64|128|256|512)(.0+)?(\s)?GB|(1|2)(\s)?TB))' # ambas lineas lo que detectan es principalmente las cantidades usuales de GB y contempla que puede estar en formato ram/memoria o meoria/ram. podria ñaadir que fuera opcional el ultimo GB

    match_int = re.search(memo_int_regex, lr.upper())
    match_ram = re.search(memo_ram_regex, lr.upper())
    # Memoria interna
    if match_int: 
        bytesUnit = re.findall(r'(GB|TB)', lr.upper())[0]
        memo_int_num = max([int(num) for num in match_int.groups() if num and num.isdigit()])
        memo_int = str(memo_int_num) + str(bytesUnit)

        dfAmazon.loc[dfAmazon['Literal'] == lr, 'Memoria_interna'] = memo_int
    # Memoria RAM
    if match_ram: 
        memo_ram_num = min([int(num) for num in match_ram.groups() if num and num.isdigit()])
        memo_ram = str(memo_ram_num) + 'GB'

        dfAmazon.loc[dfAmazon['Literal'] == lr, 'RAM'] = memo_ram

#### filtrar RAM y memoria que sean igual a la cantidad usual de int y ram, los que no, se vacían pero se quedan en el df
dfAmazon.loc[~dfAmazon['Memoria_interna'].str.match(r'((32|64|128|256|512)GB|(1|2)TB)', na=False), 'Memoria_interna'] = ''
dfAmazon.loc[~dfAmazon['RAM'].str.match(r'(?<!\d)(1|2|3|4|6|8|12|16)GB', na=False), 'RAM'] = ''

# Conexión
dfAmazon.loc[(dfAmazon['Conexion'] != '5G') & (dfAmazon['Precio'] > 99), 'Conexion'] = '4G'

# Stock
## if precio = 0, FALSE
dfAmazon.loc[dfAmazon['Precio'].isna(), 'Stock'] = False

# GUARDADO

# PATHS
path_dfAmazon = r"C:\Users\Jorge Pascual S\Desktop\Web-scraping-Smartphones-prices-in-Spain\Data\dfAmazonSelenium.csv"
path_dfAmazonHist = r"C:\Users\Jorge Pascual S\Desktop\Web-scraping-Smartphones-prices-in-Spain\Data\Histórico\dfAmazonHist.csv"
# GUARDADO
## junto el previo con el histórico
dfAmazonPrev = pd.read_csv(path_dfAmazon, sep=';')
dfAmazonHist = pd.read_csv(path_dfAmazonHist, sep=';')
dfAmazonHist = pd.concat([dfAmazonPrev, dfAmazonHist])
## guardo el histórico
dfAmazonHist.to_csv(path_dfAmazonHist, sep=';', index=False)
## guardo el nuevo
dfAmazon.to_csv(path_dfAmazon, sep=';', index=False)