library(shiny)
library(shinyjs)
library(shinyWidgets)
library(shinysky)
library(shinyAce)
library(readr)
library(readtext)
library(xml2)
library(rvest)
library(openxlsx)
library(stringr)
library(reticulate); use_virtualenv("/opt/venv", required = TRUE);
library(udpipe)
library(ggplot2)

# sudo apt install python3-pip
# sudo pip3 install phonetisaurus
# sudo pip3 install lingpy

# sudo apt install libcurl4-openssl-dev
# sudo apt install libxml2
# sudo apt install libxml2-dev
# sudo apt install libssl-dev
# sudo apt install qpdf
# sudo apt install libpoppler-cpp-dev
# sudo apt install libjpeg-dev

# remotes::install_github("ropensci/readODS")

################################################################################

ui <- tagList(
  useShinyjs(),

  includeCSS("www/styles.css"), extendShinyjs(script = "extend.js", functions = "clearUpload"),
  titlePanel(title = HTML("<div class='title'>G2P Frysk<div>"), windowTitle = "G2P Frysk"),

  tags$head(
    tags$link(rel="icon", href="FA2.png"),

    tags$meta(charset="UTF-8"),
    tags$meta(name   ="description", content="G2P Frysk is a web app for converting Frisian text to phonetic IPA transcriptions."),
  ),

  navbarPage
  (
    title=NULL, id = "navBar", collapsible = TRUE,

    tabPanel
    (
      title = HTML("<span class='glyphicon glyphicon-cog' style='font-size: 100%'></span>&nbsp;Run"),
      value = "run",

      fluidPage
      (
        style = "border: 1px solid silver; min-height: calc(100vh - 203px); background-color: #eeeefe",

        br(),

        fluidPage(
          align="left",
          style='max-width: 880px;',

          p("This service is freely available. If you use this service, you agree that data obtained by us during such use can be used for further improvements of this system."),
        ),

        align="center",
        br(),

        HTML("<p style='font-weight: bold;'>Select Input:</p>"),
        br(),

        icon(NULL),

        radioGroupButtons(
          inputId    = "selInput",
          label      = NULL,
          choices    = c("<i class='glyphicon glyphicon-font' ></i> Text" = "Text" ,
                         "<i class='glyphicon glyphicon-file' ></i> File" = "File" ,
                         "<i class='glyphicon glyphicon-globe'></i> Web"  = "Web" ),
          individual = TRUE,
          selected   = "Text"
        ),

        br(),
        uiOutput("getInput"),
        br(),

        splitLayout
        (
          cellWidths = c("215px", "90px"),
          pickerInput('selModel', NULL, c("excl. primary stress marks", "incl. primary stress marks"), selected="excl. primary stress marks", multiple=FALSE, width="205px", options = pickerOptions(title = "Language", dropupAuto = F, container = 'body')),
          shiny::actionButton("clearButton", HTML("<span class='glyphicon glyphicon-erase' style='font-size: 90%'></span>&nbsp;Clear"))
        ),

        br(),
        busyIndicator(text = NULL, wait = 1000),
        uiOutput("showResults"),
        br(), br(), br(), br()
      ),

      br()
    ),

    tabPanel
    (
      title = HTML("<span class='glyphicon glyphicon-signal' style='font-size: 100%'></span>&nbsp;Graphs"),
      value = "graphs",

      fluidPage
      (
        style = "border: 1px solid silver; min-height: calc(100vh - 203px); background-color: #eeeefe",

        br(),

        splitLayout(
          cellWidths = c("280px", "auto"),
          cellArgs = list(style = "padding: 0px"),

          fluidPage(
            style = "border: 1px solid silver; min-height: calc(100vh - 243px); background-color: #eeeefe",

            br(), br(),

            radioButtons("selGraph", NULL, choices = c(
              "Frequencies of characters",
              "Frequencies of phonetic segments"),

              selected = "Frequencies of phonetic segments", inline = FALSE
            ),

            br()
          ),

          uiOutput("showAnalyses")
        )
      ),

      br()
    ),

    tabPanel
    (
      title = HTML("<span class='glyphicon glyphicon-info-sign' style='font-size: 100%'></span>&nbsp;About"),
      value = "about",

      fluidPage
      (
        style = "border: 1px solid silver; min-height: calc(100vh - 203px); background-color: #eeeefe",

        br(),

        h5(strong("About")),
        p("G2P Frysk is a web app for converting Frisian text to phonetic IPA transcriptions. The following people were involved in the development of G2P Frysk: Wilbert Heeringa (Fryske Akademy, implementation G2P Frysk), Eduard Drenth (Fryske Akademy, building web service), Hans Van de Velde (Fryske Akademy, project manager), Pieter Duijff (Fryske Akademy, advice), Jelske Dijkstra (Fryske Akademy, advice), Hindrik Sijens (Fryske Akademy, advice). Comments are welcome and can be sent to", img(src = 'email.png', height = 19, align = "center"),"."),
        br(),

        h5(strong("GitHub")),
        p("The source code of this app and a command line script are available in the", a("Fryske Akademy Github repository", href = "https://github.com/fryske-akademy/G2P-Frysk", target = "_blank"), "."),
        br(),

        h5(strong("System requirements")),
        p("G2P Frysk runs best on a computer with a monitor with a minimum resolution of 1370 x 870 (width x height). The use of Chrome, Chromium, Firefox or Opera as a web browser is to be preferred."),
        br(),

        h5(strong("How to cite this app")),
        p(HTML("Heeringa, Wilbert & Drenth, Eduard & Van de Velde, Hans (2024). G2P Frysk [computer program]. Retrieved 4 July 2024 from <span style='font-family: \"Lucida Console\", \"Menlo\", \"Monaco\", \"Courier\", monospace;'>https://fryske-akademy.nl/fa-apps/graph2phon/</span>.")),
        br(),

        h5(strong("Implementation")),
        p("The model underlying this app is trained on the basis of the Frysk Hânwurdboek, the Foarkarswurdlist and a short supplementary list. The model was trained using the", a("Python wrapper", href = "https://pypi.org/project/phonetisaurus/", target = "_blank"), "of the ", a("Phonetisaurus", href = "https://github.com/AdolfVonKleist/Phonetisaurus", target = "_blank"), "grapheme to phoneme tool. In the app itself the model is used by Phonetisaurus in order to convert orthographic transcriptions into phonetic IPA transcriptions. The interface of G2P Frysk is implemented as a Shiny app. Shiny was developed by RStudio. This app uses the following R packages:"),
        br(),

        tags$div(tags$ul
        (
          tags$li(tags$span(HTML("<span style='color:blue'>base</span>"), p("R Core Team (2017). R: A language and environment for statistical computing. R Foundation for Statistical Computing, Vienna, Austria. https://www.R-project.org/"))),
          tags$li(tags$span(HTML("<span style='color:blue'>shiny</span>"), p("Winston Chang, Joe Cheng, J.J. Allaire, Yihui Xie and Jonathan McPherson (2017). shiny: Web Application Framework for R. R package version 1.0.0. https://CRAN.R-project.org/package=shiny"))),
          tags$li(tags$span(HTML("<span style='color:blue'>shinyjs</span>"), p("Dean Attali (2018). shinyjs: Easily Improve the User Experience of Your Shiny Apps in Seconds. R package version 1.0. https://CRAN.R-project.org/package=shinyjs"))),
          tags$li(tags$span(HTML("<span style='color:blue'>shinyWidgets</span>"), p("Victor Perrier, Fanny Meyer and David Granjon (2019). shinyWidgets: Custom Inputs Widgets for Shiny. R package version 0.5.0. https://CRAN.R-project.org/package=shinyWidgets"))),
          tags$li(tags$span(HTML("<span style='color:blue'>htmlwidgets</span>"), p("Vaidyanathan R, Xie Y, Allaire J, Cheng J, Sievert C, Russell K (2023). _htmlwidgets: HTML Widgets for R_. R package version 1.6.4. https://doi.org/10.32614/CRAN.package.htmlwidgets"))),
          tags$li(tags$span(HTML("<span style='color:blue'>shinysky</span>"), p("Dai ZJ (2019). shinysky: A Set of Shiny Components and Widgets. R package version 0.1.3. https://github.com/AnalytixWare/ShinySky"))),
          tags$li(tags$span(HTML("<span style='color:blue'>shinyAce</span>"), p("Vincent Nijs, Forest Fang, Trestle Technology, LLC and Jeff Allen (2019). shinyAce: Ace Editor Bindings for Shiny. R package version 0.4.1. https://CRAN.R-project.org/package=shinyAce"))),
          tags$li(tags$span(HTML("<span style='color:blue'>readr</span>"), p("Hadley Wickham, Jim Hester and Romain Francois (2018). readr: Read Rectangular Text Data. R package version 1.3.1. https://CRAN.R-project.org/package=readr"))),
          tags$li(tags$span(HTML("<span style='color:blue'>readtext</span>"), p("Benoit K, Obeng A (2021). _readtext: Import and Handling for Plain and Formatted Text Files_. R package version 0.81, https://CRAN.R-project.org/package=readtext"))),
          tags$li(tags$span(HTML("<span style='color:blue'>xml2</span>"), p("Hadley Wickham, Jim Hester and Jeroen Ooms (2021). xml2: Parse XML. R package version 1.3.3. https://CRAN.R-project.org/package=xml2"))),
          tags$li(tags$span(HTML("<span style='color:blue'>rvest</span>"), p("Hadley Wickham (2021). rvest: Easily Harvest (Scrape) Web Pages. R package version 1.0.2. https://CRAN.R-project.org/package=rvest"))),
          tags$li(tags$span(HTML("<span style='color:blue'>openxlsx</span>"), p("Philipp Schauberger and Alexander Walker (2020). openxlsx: Read, Write and Edit xlsx Files. R package version 4.2.3. https://CRAN.R-project.org/package=openxlsx"))),
          tags$li(tags$span(HTML("<span style='color:blue'>stringr</span>"), p("Hadley Wickham (2019). stringr: Simple, Consistent Wrappers for Common String Operations. R package version 1.4.0. https://CRAN.R-project.org/package=stringr"))),
          tags$li(tags$span(HTML("<span style='color:blue'>reticulate</span>"), p("Ushey K, Allaire J, Tang Y (2024). _reticulate: Interface to 'Python'_. R package version 1.40.0. https://doi.org/10.32614/CRAN.package.reticulate"))),
          tags$li(tags$span(HTML("<span style='color:blue'>udpipe</span>"), p("Wijffels J (2023). _udpipe: Tokenization, Parts of Speech Tagging, Lemmatization and Dependency Parsing with the 'UDPipe' 'NLP' Toolkit_. R package version 0.8.11. https://doi.org/10.32614/CRAN.package.udpipe"))),
          tags$li(tags$span(HTML("<span style='color:blue'>DT</span>"), p("Yihui Xie, Joe Cheng and Xianying Tan (2019). DT: A Wrapper of the JavaScript Library 'DataTables'. R package version 0.11. https://CRAN.R-project.org/package=DT"))),
          tags$li(tags$span(HTML("<span style='color:blue'>ggplot2</span>"), p("H. Wickham. ggplot2: Elegant Graphics for Data Analysis. Springer-Verlag New York, 2016.")))
        )),

        br(),
        p("The icons used in this app are glyphs taken from the set of", a("Bootstrap Glyphicons", href = "https://getbootstrap.com/docs/3.3/components/", target = "_blank"), "which includes over 250 glyphs from the", a("Glyphicon", href = "https://glyphicons.com/", target = "_blank"), "Halflings set."),
        br(),
        br()
      ),

      br()
    ),

    tabPanel
    (
      title = HTML("<span class='glyphicon glyphicon-exclamation-sign' style='font-size: 100%'></span>&nbsp;Disclaimer"),
      value = "disclaimer",

      fluidPage
      (
        style = "border: 1px solid silver; min-height: calc(100vh - 203px); background-color: #eeeefe",

        br(),
        h5(strong("Liability")),
        p("This app is provided 'as is' without warranty of any kind, either express or implied, including, but not limited to, the implied warranties of fitness for a purpose, or the warranty of non-infringement. Without limiting the foregoing, the Fryske Akademy makes no warranty that: 1) the app will meet your requirements, 2) the app will be uninterrupted, timely, secure or error-free, 3) the results that may be obtained from the use of the app will be effective, accurate or reliable, 4) the quality of the app will meet your expectations, 5) any errors in the app will be corrected."),
        br(),
        p("The app and its documentation could include technical or other mistakes, inaccuracies or typographical errors. The Fryske Akademy may make changes to the app or documentation made available on its web site. The app and its documentation may be out of date, and the Fryske Akademy makes no commitment to update such materials."),
        br(),
        p("The Fryske Akademy assumes no responsibility for errors or ommissions in the app or documentation available from its web site."),
        br(),
        p("In no event shall the Fryske Akademy be liable to you or any third parties for any special, punitive, incidental, indirect or consequential damages of any kind, or any damages whatsoever, including, without limitation, those resulting from loss of use, data or profits, whether or not the Fryske Akademy has been advised of the possibility of such damages, and on any theory of liability, arising out of or in connection with the use of this software."),
        br(),
        p("The use of the app is done at your own discretion and risk and with agreement that you will be solely responsible for any damage to your computer system or loss of data that results from such activities. No advice or information, whether oral or written, obtained by you from the Fryske Akademy shall create any warranty for the software."),
        br(),
        h5(strong("Other")),
        p("The disclaimer may be changed from time to time."),
        br()
      ),

      br()
    )
  ),

  tags$footer
  (
    tags$table(style = "width:100%",
               tags$tr
               (
                 tags$td(tags$a(tags$img(src="FA1.png", style = "height: 35px; margin-top: 9px; margin-left : 22px;"),
                                href    = "https://www.fryske-akademy.nl/en/"),
                                style   = "width: 40%; text-align: left;",
                                class   = "balk",
                                onclick = "window.open('https://www.fryske-akademy.nl/en/', '_blank'); return false;",
                                target  = "_blank"),
                 tags$td(textOutput("heartbeat"))
               )
    )
  )
)

################################################################################

server <- function(input, output, session)
{
  observeEvent(input$navBar,
  {
    if (getUrlHash() == paste0("#", input$navBar)) return()
    updateQueryString(paste0("#", input$navBar), mode = "push")
  })

  observeEvent(getUrlHash(),
  {
    Hash <- getUrlHash()
    if (Hash == paste0("#", input$navBar)) return()
    Hash <- gsub("#", "", Hash)
    updateNavbarPage(session, "navBar", selected=Hash)
  })
  
  output$heartbeat <- renderText(
  {
    invalidateLater(5000)
    Sys.time()
  })

  ##############################################################################

  global <- reactiveValues(firstFY=TRUE, firstNL=TRUE, firstEN=TRUE, UDfy=NULL, UDnl=NULL, UDen=NULL, model=NULL)

  global$model <- udpipe_load_model(file = paste0("www/frisian_frysk-ud-1.00-240313.udpipe"))
  
  segments   <- c("i", "y", "ỹ", "ɨ", "ʉ", "ɯ", "u", "ɪ", "ʏ", "ʊ", "e", "ø", "ɘ", "ɵ", "ɤ", "o", "ə", "ɛ", "œ", "ɜ", "ɞ", "ʌ", "ɔ", "æ", "ɐ", "a", "ɶ", "ɑ", "ɒ", "p", "b", "t", "d", "ʈ", "ɖ", "c", "ɟ", "k", "ɡ", "q", "ɢ", "ʔ", "m", "ɱ", "n", "ɳ", "ɲ", "ŋ", "ʙ", "r", "ʀ", "ⱱ", "ɾ", "ɽ", "ɸ", "β", "f", "v", "θ", "ð", "s", "z", "ʃ", "ʒ", "ʂ", "ʐ", "ç", "ʝ", "x", "ɣ", "χ", "ʁ", "ħ", "ʕ", "h", "ɦ", "ɬ", "ɮ", "ʋ", "ɹ", "ɻ", "j", "ɰ", "l", "ɭ", "ʎ", "ʟ", "w")
  vowels     <- c("i", "y", "ỹ", "ɨ", "ʉ", "ɯ", "u", "u̯", "ɪ", "ʏ", "ʊ", "e", "ø", "ɘ", "ɵ", "ɤ", "o", "ɛ", "œ", "ɜ", "ɞ", "ʌ", "ɔ", "æ", "ɐ", "a", "ɶ", "ɑ", "ɒ")
  diphtriph  <- c("j oˑ u̯", "j ɔˑ u̯", "j u u̯", "j yˑ u̯", "u̯ aˑ i̯", "u̯ aː i̯", "u̯ o i̯", "aˑ i̯", "aˑ ĩ̯", "aː i̯", "ɛˑ i̯", "iˑ ə", "iˑ ə̃", "ɪˑ ə", "iˑ u̯", "oˑ ə", "oˑ ə̃", "o i̯", "oː i̯", "oˑ u̯", "ɔ i̯", "ɔˑ u̯", "œˑ i̯", "øˑ ə", "uˑ ə", "yˑ ə", "uˑ i̯", "j a", "j ɛ", "j ɪ", "j o", "j ɔ", "u̯ a", "u̯ aː", "u̯ ãː", "u̯ o", "u̯ õ")
  diphtriph0 <- gsub(" ", "", diphtriph)

  builtins <- import_builtins()
  lingpy   <- import("lingpy")
  
  ##############################################################################
  
  output$aceEditor <- renderUI(
  {
    aceEditor(
      outputId            = "ace",
      value               = "",
      placeholder         = "Enter your text here.",
      mode                = "plain_text",
      height              = "200px",
      fontSize            = 17,
      wordWrap            = TRUE,
      showLineNumbers     = FALSE,
      highlightActiveLine = FALSE,
      showPrintMargin     = FALSE
    )
  })

  fileContent <- reactive(
  {
    req(input$fileInput)
    return(readtext(file = input$fileInput$datapath, encoding = "UTF-8")$text)
  })

  webContent <- reactive(
  {
    req(input$webURL)

    site <- NULL

    tryCatch(
      site <- read_html(input$webURL),
      error   = function(something) {},
      warning = function(something) {}
    )

    if (length(site)>0)
    {
      text <- html_text(html_nodes(site, 'p'))
      text <- gsub("\n", "", text)
      text <- gsub("([)[0-9]+(]))", "", text)

      text <- data.frame(text)
      text <- subset(text, str_count(text, "\\w+") > 1)
      text <- subset(text, grepl("[A-Z|a-z]", text))

      if (nrow(text) > 0)
        return(paste(text$text, sep = "", collapse = "\n\n"))
      else
        return(NULL)
    }
    else
      return(NULL)
  })

  output$getInput <- renderUI(
  {
    req(input$selInput)

    if (input$selInput=="Text")
      return(div(uiOutput("aceEditor"), class='format'))
    if (input$selInput=="File")
      return(div(fileInput('fileInput', NULL, accept = c(".txt", ".docx", ".html"), placeholder='Browse or drop your file here (.txt, .docx, .html)', width="100%"), class='format', style = "background-color: #eeeefe"))
    if (input$selInput=="Web")
      return(div(HTML("<input type='text' id='webURL' class='web' placeholder='Enter web address'><div style='height: 40px'></div>"), class='format', style = "background-color: #eeeefe"))
  })

  observeEvent(input$clearButton,
  {
    if (input$selInput=="Text")
      updateAceEditor(session, "ace", value = 1)
    if (input$selInput=="File")
      js$clearUpload()
    if (input$selInput=="Web")
      updateTextInput(session, "webURL", value = "")
  })

  checkText <- reactive(
  {
    req(input$selInput)

    if (input$selInput=="Text")
      s <- input$ace
    if (input$selInput=="File")
      s <- fileContent()
    if (input$selInput=="Web" )
      s <- webContent()

    if (!is.null(s) && (trimws(s) == ""))
      return(NULL)
    
    return(s)
  })

  checkWithF <- function(gi, pi, lemma, pos)
  {
    if (grepl("ôf$", gi))
    {
      if (!grepl("chôf$", gi) & grepl("hôf$", gi))
        withF <- T
      else
      
      if (grepl("(^|d|l|k|t|m|n)(r|d|l)ôf", gi))
        withF <- T
      else
        
      if (grepl("((ke)|(me)|(ne)|(ea)|(ee))(r|d)ôf", gi))
        withF <- T
      else
        withF <- F
        
      if (withF & !grepl("f$", pi))
        pi <- gsub("ɔː$", "ɔːf", pi)
      else
          
      if (!withF & grepl("f$", pi))
        pi <- gsub("ɔːf$", "ɔː", pi)
      else {}
    }
    else
      
    if  ((toupper(pos)=="VERB") & grepl( "ytse$", lemma) & grepl("ytst$" , gi))
      pi <- gsub("ist$", "itst", pi)
    else
        
    if  ((toupper(pos)=="VERB") & grepl("oetse$", lemma) & grepl("oetst$", gi))
      pi <- gsub("ust$", "utst", pi)
    else
          
    if  ((toupper(pos)=="VERB") & grepl( "etse$", lemma) & grepl("etst$" , gi))
      pi <- gsub("ɛst$", "ɛtst", pi)
    else
    
    if  ((toupper(pos)=="VERB") & grepl("ɛst$", pi))
      pi <- gsub("ɛst$", "əst", pi)
    else
    
    if  ((toupper(pos)=="VERB") & grepl( "ɛt$", pi))
      pi <- gsub( "ɛt$",  "ət", pi)
    else
      
    if (((toupper(pos)=="NOUN") | (toupper(pos)=="ADJ")) & (gi!=lemma))
    {
      if (grepl("ɛrs$", pi))
        pi <- gsub("ɛrs$" ,  "ərs", pi)
      else
          
      if (grepl( "ɛs$", pi))
        pi <- gsub( "ɛs$" ,   "əs", pi)
      else {}
          
      if (grepl("zers$", gi) & grepl( "zəs$", pi))
        pi <- gsub("zəs$" ,  "zrs", pi)
      else
            
      if (grepl("gers$", gi) & grepl( "ɡɛːs$", pi))
        pi <- gsub("ɡɛːs$",  "ɡrs", pi)
      else {}  
    }
    else
    
    if (grepl("ysk$", gi) & grepl("is$", pi))
      pi <- gsub("is$", "isk", pi)
    else {}

    return(pi)
  }

  num2word <- function(p)
  {
    p <- gsub("\\d{2,}", "qqq", p)
    p <- gsub("0", "nul"    , p)
    p <- gsub("1", "ien"    , p)
    p <- gsub("2", "twa"    , p)
    p <- gsub("3", "trije"  , p)
    p <- gsub("4", "fjouwer", p)
    p <- gsub("5", "fiif"   , p)
    p <- gsub("6", "seis"   , p)
    p <- gsub("7", "sân"    , p)
    p <- gsub("8", "acht"   , p)
    p <- gsub("9", "njoggen", p)
    
    return(p)
  }

  checkStress <- function(gi, pi, lemma, upos)
  {
    ns <- str_count(pi, "ˈ")

    if (ns == 0)
    {
      if (gi!=lemma)
      {
        lemma <- num2word(lemma)
        p <- unlist(system(command = paste0("/opt/venv/bin/phonetisaurus predict --model /srv/shiny-server/www/g2p_stress.fst --casing ignore ", lemma), intern = TRUE))
        sep <- str_locate(p, " ")[1]
        pl <- substr(p, sep+1, nchar(p))
        pl <- gsub(" ", "", pl)
        pl <- gsub("tt$", "t", pl)
        pl <- checkWithF (lemma, pl, lemma, upos)
        
        if (str_count(pl, "ˈ") > 0)
        {
          pl <- sub("ˈ", "&", pl)
     
          multi <- lingpy$Multiple(c(pi,pl))
          multi$prog_align()
          
          a <- strsplit(builtins$str(multi), split="\n")
          
          a1 <- unlist(strsplit(a[[1]][1], split="\t"))
          a2 <- unlist(strsplit(a[[1]][2], split="\t"))
          
          a1[which(a2=="&")] <- "ˈ"
          a1 <- paste0(a1, collapse = "")
          a1 <- gsub("-", "", a1)
          return(a1)
        }
        else {}        
      }
      else {}
      
      for (i in 1:nchar(pi))
      {
        ch <- substring(pi, i, i)
          
        if (is.element(ch, vowels))
        {
          pi <- sub(ch, paste0("ˈ",ch), pi)
          break
        }
      }
      
      if (!grepl("ˈ", pi))
      {
        for (i in 1:nchar(pi))
        {
          ch <- substring(pi, i, i)
          
          if (is.element(ch, "ə"))
          {
            pi <- sub(ch, paste0("ˈ",ch), pi)
            break
          }
        }
      }
    }
    else
    
    if (ns >  1)
    {
      pi <-  sub("ˈ", "#", pi, fixed = T)
      pi <- gsub("ˈ", "" , pi, fixed = T)
      pi <-  sub("#", "ˈ", pi, fixed = T)
    }
    else {}
    
    return(pi)
  }

  graph2phon <- function(ud)
  {
    ud <- subset(ud, token!="-")

    p <- gsub("'" , "\\'", ud$token, fixed = TRUE)
    p <- gsub("^-", "", p)
    p <- gsub("-$", "", p)
    p <- num2word(p)
    p <- tolower(paste(p, collapse = " "))
    
    if (input$selModel=="excl. primary stress marks")
      m <- "g2p.fst"
    if (input$selModel=="incl. primary stress marks")
      m <- "g2p_stress.fst"

    if (p!="")
    {
      p <- unlist(system(command = paste0("/opt/venv/bin/phonetisaurus predict --model /srv/shiny-server/www/", m, " --casing ignore ", p), intern = TRUE))
    
      if ((length(p))== nrow(ud))
      {
        df <- data.frame()
        
        for (i in 1:length(p))
        {
          sep <- str_locate(p[i], " ")[1]
          
          gi <- substr(p[i], 1, sep-1)
          
          pi <- substr(p[i], sep+1, nchar(p[i]))
          pi <- gsub(" ", "", pi)
          pi <- gsub("tt$", "t", pi)
          pi <- checkWithF(gi, pi, tolower(ud$lemma[i]), ud$upos[i])
          
          if ((pi!="kykyky") & (pi!="kˈykyky") & (input$selModel=="incl. primary stress marks"))
            pi <- checkStress(gi, pi, tolower(ud$lemma[i]), ud$upos[i])
          
          df <- rbind(df, data.frame(graphemic=gi, phonemic=pi))
        }
        
        df$graphemic <- ud$token
        df$lemma     <- ud$lemma
        df$upos      <- ud$upos
  
        df$phonemic  <- gsub( "kykyky", "...", df$phonemic)
        df$phonemic  <- gsub("kˈykyky", "...", df$phonemic)

        for (i in 1:length(segments))
        {
          df$phonemic <- gsub(segments[i], paste0(" ", segments[i]), df$phonemic)
        }
        
        df$phonemic <- trimws(df$phonemic, "both")
        
        for (i in 1:length(diphtriph))
        {
          df$phonemic <- gsub(diphtriph[i], diphtriph0[i], df$phonemic)
          
          diphtriph2  <- sub(" ", "ˈ ", diphtriph[i])
          diphtriph20 <- paste0("ˈ", diphtriph0[i])
          
          df$phonemic <- gsub(diphtriph2, diphtriph20, df$phonemic)
          
          diphtriph3  <- sub(" ([^ ]*)$", "ˈ \\1", diphtriph[i])
          diphtriph30 <- paste0("ˈ", diphtriph0[i])
          
          df$phonemic <- gsub(diphtriph3, diphtriph30, df$phonemic)
        }
        
        df$phonemic <- gsub("ˈ " , " ˈ", df$phonemic)
        df$phonemic <- gsub("^ ˈ", "ˈ" , df$phonemic)

        return(df)
      }
      else
      {
        showNotification("The text likely contains one or more words composed exclusively of unknown tokens!", type = "error")
        return(NULL)
      }
    }
    else
    {
      showNotification("The text consists only of unknown tokens!", type = "error")
      return(NULL)
    }
  }

  annotateUD <- function(s)
  {
    result <- as.data.frame(udpipe(x = s, object=global$model))
    result$term_id <- NULL
  
    return(result)
  }

  processText <- function(s)
  {
    s <- str_replace_all(s, "[^[:alnum:][:space:][’][-]]", "")
    s <- str_replace_all(s, "^\\’(?=([:alpha:][:alpha:]))", "")
    s <- str_replace_all(s, "(?<=([:space:]|[:punct:]))\\’(?=([:alpha:][:alpha:]))", " ")
    s <- str_replace_all(s, "\\’ ", " ")
    s <- str_replace_all(s, "\\’$", "") 
	  
    if (nchar(s) > 0)
	    return(annotateUD(s)[,8:10])
    else
    {
      showNotification("The text is empty or consists only of unknown tokens!", type = "error")
      return(NULL)
    }	  
  }

  resultUD <- reactive(
  {
    req(checkText())
    result <- processText(checkText())
    
    if (is.data.frame(result))
      return(graph2phon(result))
    else
      return(NULL)
  })

  output$resultUD <- DT::renderDataTable(
    resultUD(),
    options = list(scrollX = TRUE, searching = FALSE, pageLength = 500, lengthChange = FALSE, 
                   initComplete = htmlwidgets::JS("function(settings, json) {", "$(this.api().table().container()).css({'font-family': 'Courier'});", "}" ))
  )

  output$showResults <- renderUI(
  {
    req(checkText())

    tagList(
      HTML("<p style='font-weight: bold;'>Output Table:</p>"),
      div(DT::dataTableOutput('resultUD'), class='format'),

      br(), br(),

      splitLayout
      (
        cellWidths = c("270px", "150px"),

        pickerInput('selFormat', label = "Format: ", c("Tab-delimited text", "Microsoft Excel"), selected="Microsoft Excel", multiple=FALSE, width="150px", options = pickerOptions(title = "Format", dropupAuto = F, container = 'body')),
        downloadButton("downloadTable", "Download Table")
      )
    )
  })

  fileName <- function()
  {
    if (input$selFormat=="Tab-delimited text")
      ext <- "tsv"

    if (input$selFormat=="Microsoft Excel")
      ext <- "xlsx"

    return(paste0("G2P.", ext))
  }

  output$downloadTable <- downloadHandler(filename = fileName, content = function(file)
  {
    if (input$selFormat=="Tab-delimited text")
      write.table(resultUD(), file, sep = "\t", na = "NA", dec = ".", row.names = FALSE, col.names = TRUE)

    if (input$selFormat=="Microsoft Excel")
      write.xlsx (resultUD(), file, sheetName = "table", headerStyle = createStyle(textDecoration = "BOLD"), rowNames=FALSE, colNames=TRUE, na.string = "", firstRow = TRUE)
  })

  ##############################################################################

  resultCP1 <- function(df)
  {
    s <- paste0(df$graphemic, collapse = "")
    s <- as.data.frame(table(unlist(strsplit(s,split=""))))

    colnames(s)[1] <- "character"
    colnames(s)[2] <- "count"

    return(s)
  }

  output$graph1 <- renderPlot(
  {
    req(input$selGraph)
    req(resultUD())

    cp <- resultCP1(resultUD())

    p  <- ggplot(data=cp, aes(x=character, y=count)) +
      geom_bar(stat="identity", fill="steelblue") +
      theme_minimal() +
      theme(text = element_text(size=14))

    print(p)
  })

  resultCP2 <- function(df)
  {
    phonemes  <- c("_", "i", "y", "u", "ɪ", "ʏ", "ʊ", "e", "ø", "o", "ə", "ɛ", "œ", "ɔ", "æ", "a", "ɑ", "p", "b", "t", "d", "k", "ɡ", "ʔ", "m", "n", "ŋ", "r",  "ʀ",  "f", "v", "s", "z", "x", "ɣ", "h", "ʋ", "j", "w", "l")

    all <- paste(df$phonemic, collapse = " ")

    for (ph in phonemes)
    {
      all <- gsub(ph, paste0(" ", ph), all)
    }

    phonemes1 <- c("aː i̯", "ɔˑ u̯", "j oˑ u̯", "j ɛ", "ɪˑ ə", "øˑ ə", "aˑ i̯", "j ɪ", "iˑ ə", "ɛˑ i̯", "oː i̯", "u̯ a", "oˑ ə", "uˑ i̯", "o i̯", "ɔˑ u̯", "u̯ o i̯", "j ø", "øˑ ə", "u̯ o", "œˑ i̯")
    phonemes2 <- c("aːi̯" , "ɔˑu̯" , "joˑu̯"  , "jɛ" , "ɪˑə" , "øˑə" , "aˑi̯" , "jɪ" , "iˑə" , "ɛˑi̯" , "oːi̯" , "u̯a" , "oˑə" , "uˑi̯" , "oi̯" , "ɔˑu̯" , "u̯oi̯"  , "jø" , "øˑə" , "u̯o" , "œˑi̯" )

    for (i in 1:length(phonemes1))
    {
      all <- gsub(phonemes1[i], phonemes2[i], all)
    }

    all <- strsplit(all, " ")
    all <- data.frame(phoneme = unlist(all))
    all$count <- 1

    ag <- aggregate(count~phoneme, data=all, FUN=sum)
    ag <- subset(ag, phoneme!="" )
    ag <- subset(ag, phoneme!="_")

    return(ag)
  }

  output$graph2 <- renderPlot(
  {
    req(input$selGraph)
    req(resultUD())

    cp <- resultCP2(resultUD())

    p  <- ggplot(data=cp, aes(x=phoneme, y=count)) +
          geom_bar(stat="identity", fill="steelblue") +
          theme_minimal() +
          theme(text = element_text(size=14))

    print(p)
  })

  output$showAnalyses <- renderUI(
  {
    req(resultUD())

    if (input$selGraph=="Frequencies of characters")
    {
      return(
        fluidPage(
          style="min-width: calc(100vw - 610px);",
          align="center",

          busyIndicator(text = NULL, wait = 1000),
          plotOutput("graph1", width = "830px"),
        )
      )
    }

    if (input$selGraph=="Frequencies of phonetic segments")
    {
      return(
        fluidPage(
          style="min-width: calc(100vw - 610px);",
          align="center",

          busyIndicator(text = NULL, wait = 1000),
          plotOutput("graph2", width = "830px"),
        )
      )
    }
  })
}

################################################################################

options(shiny.sanitize.errors = TRUE)
options(shiny.usecairo=FALSE)
options(shiny.maxRequestSize=20*1024^2)

shinyApp(ui = ui, server = server)

################################################################################
