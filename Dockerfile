# Use the official Rocker tidyverse image as the base
FROM rocker/tidyverse:4.3.1

# Install system dependencies and R packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends openjdk-11-jre-headless && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install R packages using Rocker's included `install2.r` function
RUN install2.r --error plumber bigrquery DBI rJava remotes \
        ParallelLogger SqlRender DatabaseConnector Achilles

# Install additional R packages from GitHub
RUN R -e "remotes::install_github('OHDSI/DataQualityDashboard@v2.6.3', dependencies = TRUE)"
RUN R -e "remotes::install_version('plumber')"

# Configure R to use Java
RUN R CMD javareconf

# Set the working directory
WORKDIR /app

# Copy application code into the container
COPY . /app

# Make output directories
RUN mkdir /Achilles/output && mkdir /DQD/output

# Expose the desired port (optional but recommended)
EXPOSE 8080

# Define the entrypoint to run the Plumber API
ENTRYPOINT ["R", "-e", "pr <- plumber::plumb('plumber_api.R'); pr$run(host='0.0.0.0', port=as.numeric(Sys.getenv('PORT')))"]