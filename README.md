# 📱📊 Ojeador de Precios de Smartphones en España

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Jorge%20Pascual%20Segovia-blue?logo=linkedin)](https://www.linkedin.com/in/jorge-pascual-segovia-39/)


**En este proyecto, he desarrollado diversos scripts en Python y R para aprender y ejercitar el uso de herramientas de Data Harvesting para recopilar datos en la web, como selenium, xml y httr. El resultado es un conjunto de scripts que recopilan los datos y los precios de los smartphone en diferentes marketplaces populares en España. Estos datos alimentan una plantilla Power BI que permite buscar, filtrar y comparar distintos modelos de una manera sencilla y visual**

## 📂 Estructura del Repositorio

* `Scripts/`
    * `script_Smartphone_Masterdata.Rmd`: Script para crear la tabla maestra inicial de smartphones desde gsmarena.com
    * `Update_MD.R`: Script para actualizar la tabla maestra con nuevos dispositivos desde gsmarena.com
    * `Scrapeo_MM.R`: Script para scrapear precios de smartphones desde MediaMarkt.es
    * `Amazon_short.py`: Script para scrapear precios de smartphones desde Amazon.es
    * `Merge_prices_amazon.R`: Script para integrar los precios de Amazon con la tabla maestra
* `Compare.pbit`: Plantilla de Power BI para la visualización y comparación de datos

**Nota Importante:** Este repositorio **no incluye una carpeta llamada `Data`**. Los scripts generarán archivos de datos durante su ejecución. **Una vez clonado el repositorio, el usuario deberá crear manualmente una carpeta llamada `Data` en la raíz del repositorio para que los scripts puedan guardar y leer los datos correctamente.**

## ¿Cómo Funcionan los Scripts?

El flujo de trabajo de los scripts se divide en las siguientes etapas:

1.  **Creación y Actualización de la Tabla Maestra de Smartphones (gsmarena.com):**
    * `script_Smartphone_Masterdata.Rmd`: Este script realiza un web scraping del sitio web gsmarena.com para construir una tabla maestra inicial que contiene las características detalladas de diversos smartphones. Esta tabla sirve como base de datos para la integración posterior.
    * `Update_MD.R`: Este script se encarga de buscar nuevos modelos de smartphones en gsmarena.com y actualizar la tabla maestra existente con sus especificaciones.

2.  **Scraping de Precios (MediaMarkt y Amazon):**
    * `Scrapeo_MM.R`: Este script extrae los precios de los smartphones ofrecidos en el sitio web de MediaMarkt España (MediaMarkt.es).
    * `Scripts/Amazon_short.py`: Este script extrae los precios de los smartphones ofrecidos en el sitio web de Amazon España (Amazon.es).

3.  **Integración de Precios y Actualización de la Tabla Comparativa:**
    * `En el caso de MediaMarkt, los datos se integran en el mismo script del scraping `Scrapeo_MM.R`.
    * En el caso de Amazon, la información recopilada se integra con el script `Merge_prices_amazon.R`.
    * `DF_PROD`: Esta dataframe es el resultado del procesamiento de los datos recopilados y alimenta la plantilla de Power BI (`Compare.pbit`) que es el resultado final de este proyecto, `el comparador`.

## El Comparador

El archivo `Compare.pbit` es una plantilla de Power BI que se conecta a los datos procesados por los scripts. Al abrir esta plantilla (requiere tener Power BI Desktop instalado), podrás:

* **Buscar** smartphones específicos por nombre o características.
* **Filtrar** dispositivos por marca, rango de precios, especificaciones técnicas, etc.
* **Comparar** en tablas las características y precios de diferentes smartphones.

El objetivo de este proyecto es contribuir al desarrollo de herramientas que, como consumidores, nos ayuden a tomar decisiones desde el acceso fácil y claro a la información, en lugar de basarlas en campañas de marketing en un mercado altamente competitivo en el que hay cientos de dispositivos. 

## Paso a paso

Para utilizar este repositorio, sigue estos pasos:

1.  **Clona el repositorio:**
    ```bash
    git clone [https://github.com/JorPS/Web-scraping-Smartphones-prices-in-Spain.git](https://github.com/JorPS/Web-scraping-Smartphones-prices-in-Spain.git)
    cd TuRepositorio
    ```

2.  **Crea la carpeta `Data`:**
    ```bash
    mkdir Data
    ```
    Crea una carpeta llamada `Data` en la raíz del repositorio.

3.  **Instala las dependencias:**
    Navega a la carpeta `Scripts` y asegúrate de tener instaladas las bibliotecas de Python necesarias (por ejemplo, `selenium` o `pandas`). Puedes usar `pip` para instalarlas:
    ```bash
    cd Scripts
    pip install -r requirements.txt
    ```
    Además, antes de ejecutar un script de R, asegúrate de tener instaladas las librerías necesarias ejecutando la siguiente línea en la consola de R.
    ```r
    install.packages(c("tidyverse", "xml2", "httr", "lubridate"))
    ```

4.  **Ejecuta los scripts:**
    Ejecuta los scripts en el orden lógico para crear la tabla maestra, scrapear los precios e integrarlos. Es posible que necesites revisar y ajustar las rutas de los archivos dentro de los scripts según tu configuración.

5.  **Abre `Compare.pbit` en Power BI Desktop:**
    Una vez que los scripts hayan generado los archivos de datos en la carpeta `Data`, abre la plantilla `Compare.pbit` con Power BI Desktop. Power BI te pedirá que conectes la plantilla a las fuentes de datos generadas.

**Consideraciones importantes:**

* Los sitios web pueden cambiar su estructura, lo que podría requerir **ajustes en el código de los scripts** para que sigan funcionando correctamente.
* La ejecución de los scripts de scraping puede llevar tiempo, dependiendo de la cantidad de datos a extraer y la velocidad de tu conexión a internet.
* Es posible que necesites **instalar los drivers de los navegadores** utilizados por Selenium (por ejemplo, ChromeDriver para Chrome, GeckoDriver para Firefox) y configurar sus rutas en el código si no están en tu PATH.
* La **creación y estructura de los archivos de datos** generados por los scripts son la base para el funcionamiento de la plantilla de Power BI. Asegúrate de que los scripts se ejecuten correctamente para generar los datos esperados.

## ¡Toda contribución es bienvenida!

Este es un proyecto que he comenzado para aprender, desarrollar y practicar mis habilidades con herramientas de Data Harvesting y las contribuciones son bienvenidas, siempre desde la buena fe y aras de compartir. Si tienes ideas para mejorar los scripts, añadir nuevas fuentes de datos, optimizar el rendimiento o mejorar la plantilla de Power BI, no dudes en crear un *fork* del repositorio y enviar tus *pull requests*.

La licencia que permite que este proyecto sea de código abierto es Apache-2.0, cuyos detalles están en el archivo LICENSE.txt o en [https://www.apache.org/licenses/LICENSE-2.0.txt](https://www.apache.org/licenses/LICENSE-2.0.txt)

## ¿Más?

Puedes encontrar más información sobre mi en mi perfil de LinkedIn:

**Jorge Pascual Segovia | LinkedIn**: [https://www.linkedin.com/in/jorge-pascual-segovia-39/](https://www.linkedin.com/in/jorge-pascual-segovia-39/)

¡Gracias por tu interés y espero que el proyecto te sea de utilidad!