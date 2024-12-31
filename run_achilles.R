#' Execute Achilles Analyses on a Specified BigQuery Dataset
#'
#' This function connects to a Google BigQuery dataset and generates Achilles
#' artifacts for a given dataset.
#'
#' @param project_id Character. The Google Cloud project ID.
#' @param dataset_id Character. The BigQuery dataset ID.
#'
#' @return Invisibly returns TRUE if the data quality checks are executed successfully.
#'
#' @examples
# run_achilles(
#'   project_id = "nih-nci-dceg-connect-dev",
#'   dataset_id = "synthea_cdm53"
#' )
run_achilles <- function(project_id, dataset_id) {

  # Load dependencies
  library(bigrquery)
  library(DatabaseConnector)
  library(DBI)
  library(Achilles)
  
  # Set JDBC driver location
  # DatabaseConnector::downloadJdbcDrivers(dbms="bigquery", pathToDriver='./jdbcDrivers')
  pathToDriver <- 'jdbcDrivers/'
  
  # Authenticate to BigQuery
  bigrquery::bq_auth()
  
  # Retrieve the access token, refresh token, client id and client secret
  token <- bigrquery::bq_token()
  
  # Define the JDBC URL
  # ref: https://www.progress.com/tutorials/jdbc/a-complete-guide-for-google-bigquery-authentication
  # ref: https://github.com/jdposada/BQJdbcConnectionStringR
  jdbc_url <- glue::glue(
    "jdbc:bigquery://https://www.googleapis.com/bigquery/v2:443;",
    "ProjectId={project_id};",
    "DatasetId={dataset_id};",
    "DefalutDataset={dataset_id};",
    "OAuthType=2;",
    "EnableSession=1;",
    "OAuthAccessToken={token$auth_token$credentials$access_token};",
    "AllowLargeResults=1;"
  )
  
  # Create a connection details object
  connection_details <- DatabaseConnector::createConnectionDetails(
    dbms = "bigquery",
    connectionString = jdbc_url,
    pathToDriver = Sys.getenv("DATABASECONNECTOR_JAR_FOLDER", pathToDriver),
    user = "",
    password = ""
  )
  
  # Connect to the database
  conn <- DatabaseConnector::connect(connection_details)
  
  ## Execute Achilles package
  outputFolder <- "./Achilles/output"
  
  fully_qualified_db <- paste0(project_id, ".", dataset_id)
  Achilles::achilles(
    connectionDetails = connection_details,
    cdmDatabaseSchema = fully_qualified_db,
    resultsDatabaseSchema = fully_qualified_db,
    outputFolder = outputFolder
  )
  
  message("Achilles analyses executed successfully.")
  
  invisible(TRUE)
}