#!/usr/bin/Rscript --vanilla

################################################################################
#                                                                              #
# Script for converting orthographic transcriptions into phonetic IPA          #
# transcriptions using Phonetisaurus. Stressed vowels are preceded by a ˈ.     #
#                                                                              #
# Ubuntu 20.04 or newer, Python 3.8 or newer and R 4.4.0 or newer should have  #
# been installed.                                                              #
#                                                                              #
# Before running the script for the first time, enter the following commands   #
# in a terminal:                                                               #
#                                                                              #
# $ sudo pip3 install phonetisaurus                                            #
# $ sudo pip3 install lingpy                                                   #
# $ ln -s /usr/bin/python3.8 /usr/bin/python3                                  #
#                                                                              #
# $ sudo apt install r-base-core                                               #
# $ sudo apt install libcurl4-openssl-dev                                      #
# $ sudo apt install libxml2                                                   #
# $ sudo apt install libxml2-dev                                               #
# $ sudo apt install libpoppler-cpp-dev                                        #
# $ sudo apt install libssl-dev                                                #
#                                                                              #
# When running the script for the first time, missing R packages are installed #
# which can take a while!                                                      #
#                                                                              #
# The files 'g2p.fst', 'g2p_stress.fst' and 'fy_frysk-ud-1.0-20240313.udpipe'  #
# should reside in the same directory as where this script is stored.          #
#                                                                              #
# The file 'g2p.fst' contains a trained g2p model that was trained on the      #
# basis of the Frysk Hânwurdboek, the Foarkarswurdlist and a short supplemen-  #
# tary list. It does not include primary stress marks.                         #
#                                                                              #
# The file 'g2p_stress.fst' contains a trained g2p model that was trained on   #
# the basis of the Frysk Hânwurdboek and a short supplementary list. It        #
# includes primary stress marks.                                               #
#                                                                              #
# The file 'fy_frysk-ud-1.0-20240313.udpipe' contains a trained udpipe model.  #
#                                                                              #
# The file 'Frysk.txt' is added as an example text. It can be processed by     #
# entering the following command in a terminal:                                #
#                                                                              #
# $ ./graph2phon.R -i Frysk.txt -f -o Frysk.xlsx -x                            #
#                                                                              #
# where the result is stored as an Excel spreadsheet in Frysk.xlsx             #
#                                                                              #
# or read from pipe:                                                           #
#                                                                              #
# $ cat Frysk.txt|./graph2phon.R -i - -e -t > Frysk.tsv                        #
#                                                                              #
# or read from user input (close with Ctrl-d):                                 #
#                                                                              #
# $ ./graph2phon.R -i - -e -t > Frysk.tsv                                      #
#                                                                              #
# where the result is stored as a tab-separated file in Frysk.tsv.             #
#                                                                              #
# For information about usage and options enter:                               #
#                                                                              #
# $ ./graph2phon.R -h                                                          #
#                                                                              #
# Copyright: Fryske Akademy, Leeuwarden, The Netherlands, 23 July 2024.        #
# Contact  : wheeringa@fryske-akademy.nl                                       #
#                                                                              #
################################################################################

# install and load packages

packages = c("optparse", "readr", "readtext", "xml2", "rvest", "openxlsx", "stringr", "reticulate", "udpipe")

for (p in packages)
{
  if (suppressWarnings((!library(p, character.only=T, logical.return = T, quietly = T))))
  {
    cat("\nInstalling package", p, "...\n", file = stderr())
    suppressWarnings(install.packages(p, quiet = T, repos = "https://cloud.r-project.org/"))
  }
  
  if (suppressWarnings((!library(p, character.only=T, logical.return = T, quietly = T))))
  {
    cat("\nPackage", p, "not installed!\n\n", file = stderr())
    quit(status=1, save="no")
  }
}

if (!py_module_available('lingpy'))
  reticulate::py_install('lingpy', pip = TRUE)

builtins <- import_builtins()
lingpy   <- import("lingpy")
  
usage = "usage: %prog -i INPUT -e|-f|-w -l LEMMA -p POSTAG -o OUTPUT -t|-x|-c [-s]"

option_list = list(
  make_option(c("-i", "--input" ), action="store"     , help="text or file name or url of website"),

  make_option(c("-e", "--text"  ), action="store_true", help="input  is some text between ' and '"),
  make_option(c("-f", "--file"  ), action="store_true", help="input  is file (.txt, .docx, .html)"),
  make_option(c("-w", "--web"   ), action="store_true", help="input  is URL of website"),

  make_option(c("-l", "--lemma" ), action="store"     , help="UD lemma"),
  make_option(c("-p", "--postag"), action="store"     , help="UD Part-of-speech tag"),

  make_option(c("-o", "--output"), action="store"     , help="name of output file"),
  
  make_option(c("-t", "--tsv"   ), action="store_true", help="output is tab-separated file" ),
  make_option(c("-x", "--xlsx"  ), action="store_true", help="output is Microsoft Excel file"),
  
  make_option(c("-s", "--stress"), action="store_true", help="include primary stress marks")
); 

option_parser <- OptionParser(usage=usage, option_list=option_list)
opt <- parse_args(option_parser)

if (length(opt) == 1)
{  
  print_help(option_parser)
  quit(status=1, save="no")
}

if (is.null(opt$input))
{
  con <- file("stdin")
  string <- scan(con, what=character(), quote="")
  close(con)
}                    else
if (unlist(opt$input) == "-")
{
  con <- file("stdin")
  string <- scan(con, what=character(), quote="")
  close(con)
}                    else
{
  string <- unlist(opt$input)
}

if ((!is.null(opt$text) && (opt$text==T)) & ( is.null(opt$file)) & ( is.null(opt$web)))
  input <- "text"    else

if (( is.null(opt$text)) & (!is.null(opt$file) && (opt$file==T)) & ( is.null(opt$web)))
  input <- "file"    else

if (( is.null(opt$text)) & ( is.null(opt$file)) & (!is.null(opt$web) && (opt$web==T)))
  input <- "web"     else
{  
  print_help(option_parser)
  quit(status=1, save="no")
}

if (is.null(opt$output))
{
  result <- stdout()
}                    else
if (unlist(opt$output) == "-")
{
  result <- stdout()
}                    else
{
  result <- unlist(opt$output)
}

if ((!is.null(opt$tsv) && (opt$tsv==T)) & (is.null(opt$xlsx)) & (is.null(opt$connlu)))
  output <- "tsv"    else

if ((is.null(opt$tsv)) & (!is.null(opt$xlsx) && (opt$xlsx==T)) & (is.null(opt$connlu)))
  output <- "xlsx"   else
{  
  print_help(option_parser)
  quit(status=1, save="no")
}  

if (!is.null(opt$stress) && (opt$stress==T))
  stress <- T        else
  stress <- F

# read data

if (input=="text")
{
  s <- string
}
  
if (input=="file")
{
  if (file.exists(string))
  {
    s <- readtext(file = string, encoding = "UTF-8")$text
  }
  else 
  {
    cat("File ", string, "not found.\n", file = stderr())
    quit(status=1, save="no")
  }
}

if (input=="web")
{
  site <- NULL
  
  tryCatch(
    site <- read_html(string),
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
      s <- paste(text$text, sep = "", collapse = "\n\n")
    else
      s <- ""
  }
  else
  {
    cat("\nNo website found at given URL!\n\n", file = stderr())
    quit(status=1, save="no")
  }
}

s <- paste(s, collapse = " ")

if (trimws(s) == "")
  quit(status=1, save="no")

# process text

segments   <- c("i", "y", "ỹ", "ɨ", "ʉ", "ɯ", "u", "ɪ", "ʏ", "ʊ", "e", "ø", "ɘ", "ɵ", "ɤ", "o", "ə", "ɛ", "œ", "ɜ", "ɞ", "ʌ", "ɔ", "æ", "ɐ", "a", "ɶ", "ɑ", "ɒ", "p", "b", "t", "d", "ʈ", "ɖ", "c", "ɟ", "k", "ɡ", "q", "ɢ", "ʔ", "m", "ɱ", "n", "ɳ", "ɲ", "ŋ", "ʙ", "r", "ʀ", "ⱱ", "ɾ", "ɽ", "ɸ", "β", "f", "v", "θ", "ð", "s", "z", "ʃ", "ʒ", "ʂ", "ʐ", "ç", "ʝ", "x", "ɣ", "χ", "ʁ", "ħ", "ʕ", "h", "ɦ", "ɬ", "ɮ", "ʋ", "ɹ", "ɻ", "j", "ɰ", "l", "ɭ", "ʎ", "ʟ", "w")
vowels     <- c("i", "y", "ỹ", "ɨ", "ʉ", "ɯ", "u", "u̯", "ɪ", "ʏ", "ʊ", "e", "ø", "ɘ", "ɵ", "ɤ", "o", "ɛ", "œ", "ɜ", "ɞ", "ʌ", "ɔ", "æ", "ɐ", "a", "ɶ", "ɑ", "ɒ")
diphtriph  <- c("j oˑ u̯", "j ɔˑ u̯", "j u u̯", "j yˑ u̯", "u̯ aˑ i̯", "u̯ aː i̯", "u̯ o i̯", "aˑ i̯", "aˑ ĩ̯", "aː i̯", "ɛˑ i̯", "iˑ ə", "iˑ ə̃", "ɪˑ ə", "iˑ u̯", "oˑ ə", "oˑ ə̃", "o i̯", "oː i̯", "oˑ u̯", "ɔ i̯", "ɔˑ u̯", "œˑ i̯", "øˑ ə", "uˑ ə", "yˑ ə", "uˑ i̯", "j a", "j ɛ", "j ɪ", "j o", "j ɔ", "u̯ a", "u̯ aː", "u̯ ãː", "u̯ o", "u̯ õ")
diphtriph0 <- gsub(" ", "", diphtriph)

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
      p <- unlist(system(command = paste0("phonetisaurus predict --model g2p_stress.fst --casing ignore ", lemma), intern = TRUE))
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

graph2phon <- function(ud, stress)
{
  ud <- subset(ud, token!="-")
  
  p <- gsub("'" , "\\'", ud$token, fixed = TRUE)
  p <- gsub("^-", "", p)
  p <- gsub("-$", "", p)
  p <- num2word(p)
  p <- tolower(paste(p, collapse = " "))

  if (!stress)
    m <- "g2p.fst"
  if ( stress)
    m <- "g2p_stress.fst"

  if (p!="")
  {
    p <- unlist(system(command = paste0("phonetisaurus predict --model ", m, " --casing ignore ", p), intern = TRUE))
    
    if (length(p) == nrow(ud))
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
        
        if ((gi=="In") | (gi=="in"))
          pi <- "ən"
        
        if ((gi=="It") | (gi=="it"))
          pi <- "ət"

        if ((pi!="kykyky") & (pi!="kˈykyky") & stress)
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
      cat("\nThe text likely contains one or more words composed exclusively of unknown tokens!\n\n", file = stderr())
      quit(status=1, save="no")
    }
  }  
  else
  {
    cat("\nThe text consists only of unknown tokens!\n\n", file = stderr())
    quit(status=1, save="no")
  }  
}

annotateUD <- function(s)
{
  return(as.data.frame(udpipe(x = s, object = udpipe_load_model(file = "fy_frysk-ud-1.0-20240313.udpipe"))))
}

processText <- function(s, optLemma, optPosTag)
{
  s <- str_replace_all(s, "[^[:alnum:][:space:][’][-]]", "")
  s <- str_replace_all(s, "^\\’(?=([:alpha:][:alpha:]))", "")
  s <- str_replace_all(s, "(?<=([:space:]|[:punct:]))\\’(?=([:alpha:][:alpha:]))", " ")
  s <- str_replace_all(s, "\\’ ", " ")
  s <- str_replace_all(s, "\\’$", "")
	
  if (nchar(s) > 0)
  {
    if ((is.null(optLemma)) & (is.null(optPosTag)))
      result <- annotateUD(s)[,9:11]
    else
    
    if (!grepl(" ", s))
    {
      if ((!is.null(optLemma)) & ( is.null(optPosTag)))
      {
        result <- annotateUD(s)[,9:11]
        result$lemma <- optLemma
      }
      else
	
      if (( is.null(optLemma)) & (!is.null(optPosTag)))
      {
        result <- annotateUD(s)[,9:11]
        result$upos  <- optPosTag
      }
      else
	
      if ((!is.null(optLemma)) & (!is.null(optPosTag)))
      {
        result <- data.frame(
          token = s,
          lemma = optLemma,
          upos  = optPosTag
        )
      }	
      else {}
    }
    else
    {
      cat("\nLemma and/or POS tag cannot be combined with multiple words!\n\n", file = stderr())
      quit(status=1, save="no")
    }  
  }	  
  else
  {
    cat("\nThe text is empty or consists only of unknown tokens!\n\n", file = stderr())
    quit(status=1, save="no")
  }  

  return(result)
}

# write result

if  (output=="tsv")
  write.table(graph2phon(processText(s, opt$lemma, opt$postag), stress), result, sep = "\t", na = "", dec = ".", row.names = FALSE, col.names = TRUE)

if ((output=="xlsx") & (result!=stdout()))
  write.xlsx (graph2phon(processText(s, opt$lemma, opt$postag), stress), result, sheetName = "table", headerStyle = createStyle(textDecoration = "BOLD"), rowNames=FALSE, colNames=TRUE, na.string = "", firstRow = TRUE)

if ((output=="xlsx") & (result==stdout()))
  cat("\nMicrosoft Excel file cannot be printed to stdout!\n", file = stderr())

cat("\nDONE\n\n", file = stderr())
