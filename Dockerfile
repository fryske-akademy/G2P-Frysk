# Use the Rocker project’s Shiny base image
FROM rocker/shiny:4.5.1

# Install system dependencies
RUN apt update
RUN apt-get install -y python3
RUN apt-get install -y python3-pip
RUN apt-get install -y python3-dev
RUN apt-get install -y python3-venv
RUN apt-get install -y wget 
RUN apt-get install -y libcurl4-openssl-dev
RUN apt-get install -y libxml2
RUN apt-get install -y libxml2-dev
RUN apt-get install -y libssl-dev
RUN apt-get install -y qpdf
RUN apt-get install -y libpoppler-cpp-dev
RUN apt-get install -y libjpeg-dev
RUN apt-get install -y xdg-utils
RUN apt-get install -y g++
RUN rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python3 -m venv /opt/venv

# Activate virtual environment
ENV PATH="/opt/venv/bin:$PATH"

# Install pip and other packages
RUN pip install --upgrade pip setuptools wheel lingpy

# Copy your app to the container
COPY ./ /srv/shiny-server/

# Move custom config into place
RUN mv /srv/shiny-server/shiny-server.conf /etc/shiny-server/shiny-server.conf

# Install phonetisaurus
RUN pip install /srv/shiny-server/phonetisaurus-0.3.0-py3-none-manylinux1_x86_64.whl    

# Set permissions
RUN chown -R shiny:shiny /srv/shiny-server

# Install R package dependencies
RUN R -e "install.packages('shiny',        dependencies=TRUE, repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('shinyjs',      dependencies=TRUE, repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('shinyWidgets', dependencies=TRUE, repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('htmlwidgets' , dependencies=TRUE, repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('shinyAce',     dependencies=TRUE, repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('readr',        dependencies=TRUE, repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('readtext',     dependencies=TRUE, repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('xml2',         dependencies=TRUE, repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('rvest',        dependencies=TRUE, repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('openxlsx',     dependencies=TRUE, repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('stringr',      dependencies=TRUE, repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('reticulate',   dependencies=TRUE, repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('udpipe',       dependencies=TRUE, repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('DT',           dependencies=TRUE, repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('ggplot2',      dependencies=TRUE, repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('readODS',      dependencies=TRUE, repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('RJSONIO',      dependencies=TRUE, repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('plyr',         dependencies=TRUE, repos='https://cloud.r-project.org/')"
RUN R -e "install.packages('/srv/shiny-server/shinysky_0.1.3.tar.gz', repos=NULL, type='source')"

# Expose the Shiny port
EXPOSE 3838

# Run the Shiny app
CMD ["/usr/bin/shiny-server"]
