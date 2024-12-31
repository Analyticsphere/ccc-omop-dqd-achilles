library(plumber)
library(bigrquery)
library(DBI)
library(DatabaseConnector)
library(DataQualityDashboard)
library(Achilles)
library(glue)

#* @apiTitle BigQuery Data Quality Checks and Achilles Analyses API
#* @apiDescription This API provides endpoints to execute comprehensive data quality checks and Achilles analyses on Google BigQuery datasets using the DataQualityDashboard and Achilles packages. 

#* Check if the API is healthy
#* @get /heartbeat
function() {
  print("Alive!")
  return(
    list(
      status = "success",
      message = "API is healthy!"
    )
  )
}


#* Run Data Quality Checks on a BigQuery Dataset
#*
#* This endpoint triggers the execution of data quality checks on a specified BigQuery dataset.
#*
#* @param project_id The Google Cloud project ID. Default is "nih-nci-dceg-connect-dev".
#* @param dataset_id The BigQuery dataset ID. Default is "synthea_cdm53".
#* @param cdm_source_name A human-readable name for your CDM source. Default is "Synthea 5.3".
#* @param cdm_version The CDM version to target (e.g., "5.3"). Default is "5.3".
#* @get /run_dqd
#* @response 200 A message indicating that the data quality checks have been initiated.
#* @response 400 Bad request. Missing or invalid parameters.
#* @response 500 Internal server error. An error occurred during execution.
function(req, res, 
         project_id = "nih-nci-dceg-connect-dev", 
         dataset_id = "synthea_cdm53", 
         cdm_source_name = "Synthea 5.3", 
         cdm_version = "5.3") {
  
  # Validate required parameters
  if (missing(project_id) || missing(dataset_id)) {
    res$status <- 400 # Bad Request
    return(list(
      status = "error",
      message = "Missing required parameters: project_id and dataset_id are required."
    ))
  }
  
  # Try to execute the data quality checks
  tryCatch({
    source('run_dqd.R')
    run_dqd(
      project_id = project_id,
      dataset_id = dataset_id,
      cdm_source_name = cdm_source_name,
      cdm_version = cdm_version
    )
    
    res$status <- 200
    return(list(
      status = "success",
      message = "Data quality checks executed successfully."
    ))
  }, error = function(e) {
    res$status <- 500 # Internal Server Error
    return(list(
      status = "error",
      message = "An error occurred while executing data quality checks.",
      details = e$message
    ))
  })
}


#* Run Achilles Analyses on a BigQuery Dataset
#*
#* This endpoint triggers the execution of Achilles analyses on a specified BigQuery dataset.
#*
#* @param project_id The Google Cloud project ID. Default is "nih-nci-dceg-connect-dev".
#* @param dataset_id The BigQuery dataset ID. Default is "synthea_cdm53".
#* @get /run_achilles
#* @response 200 A message indicating that the Achilles analyses have been initiated.
#* @response 400 Bad request. Missing or invalid parameters.
#* @response 500 Internal server error. An error occurred during execution.
function(req, res, 
         project_id = "nih-nci-dceg-connect-dev", 
         dataset_id = "synthea_cdm53") {
  
  # Validate required parameters
  if (missing(project_id) || missing(dataset_id)) {
    res$status <- 400 # Bad Request
    return(list(
      status = "error",
      message = "Missing required parameters: project_id and dataset_id are required."
    ))
  }
  
  # Try to execute the Achilles analyses
  tryCatch({
    source('run_achilles.R')
    run_achilles(
      project_id = project_id,
      dataset_id = dataset_id
    )
    
    res$status <- 200
    return(list(
      status = "success",
      message = "Achilles analyses executed successfully."
    ))
  }, error = function(e) {
    res$status <- 500 # Internal Server Error
    return(list(
      status = "error",
      message = "An error occurred while executing Achilles analyses.",
      details = e$message
    ))
  })
}
