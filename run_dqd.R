#' Execute Data Quality Checks on a Specified BigQuery Dataset
#'
#' This function connects to a Google BigQuery dataset and executes data quality
#' checks using the DataQualityDashboard package. 
#'
#' @param project_id Character. The Google Cloud project ID.
#' @param dataset_id Character. The BigQuery dataset ID.
#' @param cdm_source_name Character. A human-readable name for your CDM source. Default is "Synthea 5.3".
#' @param cdm_version Character. The CDM version to target (e.g., "5.3"). Default is "5.3".
#'
#' @return Invisibly returns TRUE if the data quality checks are executed successfully.
#'
#' @examples
#' run_dqd(
#'   project_id = "nih-nci-dceg-connect-dev",
#'   dataset_id = "synthea_cdm53",
#'   cdm_source_name = "Synthea 5.3",
#'   cdm_version = "5.3"
#' )
run_dqd <- function(project_id,
                    dataset_id,
                    cdm_source_name,
                    cdm_version) {
  
  library(bigrquery)
  library(DatabaseConnector)
  library(DBI)
  library(glue)
  library(DataQualityDashboard)
  
  # Authenticate to BigQuery
  bigrquery::bq_auth()
  
  # Retrieve the access token
  token <- bigrquery::bq_token()
  
  # Define the JDBC URL
  jdbc_url <- glue(
    "jdbc:bigquery://https://www.googleapis.com/bigquery/v2:443;",
    "ProjectId={project_id};",
    "DatasetId={dataset_id};",
    "DefalutDataset={dataset_id};",
    "OAuthType=2;",
    "EnableSession=1;",
    "OAuthAccessToken={token$auth_token$credentials$access_token};",
    "AllowLargeResults=1;"
  )
  
  # DatabaseConnector::downloadJdbcDrivers(dbms="bigquery", pathToDriver='./jdbcDrivers')
  pathToDriver <- 'jdbcDrivers/'
  
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
  on.exit(DatabaseConnector::disconnect(conn), add = TRUE)
  
  # Define schemas and source information
  fully_qualified_db <- paste0(project_id, ".", dataset_id)
  cdm_database_schema <- fully_qualified_db
  results_database_schema <- fully_qualified_db
  cdm_source_name <- cdm_source_name
  cdm_version <- cdm_version
  
  # Hardcoded configurations based on Eddy's (EAF) decisions
  num_threads <- 1 # on Redshift, 3 seems to work well; (EAF) -> on every other database engine, anything other than 1 does NOT work
  
  sql_only <- FALSE # set to TRUE if you just want to get the SQL scripts and not actually run the queries
  sql_only_incremental_insert <- FALSE # set to TRUE if you want the generated SQL queries to calculate DQD results and insert them into a database table (@resultsDatabaseSchema.@writeTableName)
  sql_only_union_count <- 1  # in sqlOnlyIncrementalInsert mode, the number of check sqls to union in a single query; higher numbers can improve performance in some DBMS (e.g. a value of 25 may be 25x faster)
  
  output_folder <- "./DQD/output" # where should the results and logs go?
  output_file <- "results.json"
  
  verbose_mode <- TRUE # set to FALSE if you don't want the logs to be printed to the console
  
  write_to_table <- FALSE # Set to FALSE - there's a bug in DQD and results won't ever be written to database (EAF)
  
  write_table_name <- "dqdashboard_results" # Default table is "dqdashboard_results" (EAF)
  
  write_to_csv <- TRUE # change from default FALSE value to TRUE in order to generate CSV flat file (EAF)
  csv_file <- "results.csv" # set CSV file name to same filename as JSON, except extension (EAF)
  
  check_levels <- c("TABLE", "FIELD", "CONCEPT") # which DQ check levels to run
  
  check_names <- c() # Recommend always running everything - don't specify anything here (EAF)
  
  tables_to_exclude <- c() 
  # Defaults are below - don't skip vocab tables, we want to confirm we received *everything* (EAF)
  # tables_to_exclude <- c("CONCEPT", "VOCABULARY", "CONCEPT_ANCESTOR", "CONCEPT_RELATIONSHIP", "CONCEPT_CLASS", "CONCEPT_SYNONYM", "RELATIONSHIP", "DOMAIN") # list of CDM table names to skip evaluating checks against; by default DQD excludes the vocab tables
  
  # Execute data quality checks
  DataQualityDashboard::executeDqChecks(
    connectionDetails = connection_details,
    cdmDatabaseSchema = cdm_database_schema,
    resultsDatabaseSchema = results_database_schema,
    cdmSourceName = cdm_source_name,
    cdmVersion = cdm_version,
    numThreads = num_threads,
    sqlOnly = sql_only,
    sqlOnlyUnionCount = sql_only_union_count,
    sqlOnlyIncrementalInsert = sql_only_incremental_insert,
    outputFolder = output_folder,
    outputFile = output_file,
    verboseMode = verbose_mode,
    writeToTable = write_to_table,
    writeTableName = write_table_name,
    writeToCsv = write_to_csv,
    csvFile = csv_file,
    checkLevels = check_levels,
    tablesToExclude = tables_to_exclude,
    checkNames = check_names
  )
  
  message("Data quality checks executed successfully.")
  
  invisible(TRUE)
}
