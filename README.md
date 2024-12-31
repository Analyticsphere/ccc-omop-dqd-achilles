# ccc-omop-dqd-achilles

Run OHDSI's DataqualityDashboard and Achilles software on Connects EHR data as part of EHR pipeline.

Files:

1.  Dockerfile - Required to build minimal container for running `plumber`, `DataqualityDashboard` and `Achilles`.

2.  `cloudbuild.yaml` - A recipe used by Google Cloud Build to build and deploy the container and start up the plumber API.

3.  `dqd_plumber_api.R` - A plumber API with three endpoints:

    1.  `/heartbeat` - for testing
    2.  `/run-dqd` - for running the \`DataqualityDashboard\` for a given project and OMOP dataset
    3.  `/run-achilles` - for running the `Achilles` analyses for a given project and OMOP dataset

4.  `run_dqd` - Runs the `DataqualityDashboard`; referenced by plumber API.

5.  `run_achilles` - Runs Achilles; referenced by plumber API.

Tested with:

```         
===== R Version =====
R version 4.3.1 (2023-06-16) 

===== Loaded Packages and Their Versions =====
              Package Version
             Achilles   1.7.2
            bigrquery   1.5.1
    DatabaseConnector   6.3.2
 DataQualityDashboard   2.6.3
                  DBI   1.2.3
                 glue   1.8.0
              plumber   1.2.1
          sessioninfo   1.2.2
```
