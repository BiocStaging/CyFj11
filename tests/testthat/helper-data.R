# Copyright (c) 2026 Institut Pasteur
# Author: Bernd Jagla
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

message("***** LOADING HELPER FILE *****")

#' Create Mock FlowJo v11 Workspace Structure
#' @keywords internal
create_mock_workspace <- function() {
  # Create minimal but valid FlowJo v11 JSON structure
  workspace <- list(
    json = list(
      `analysis-test-uuid.json` = list(
        # Groups
        groups = list(
          "group-uuid-1" = list(
            name = "Test Group 1",
            sampleRefs = c("sample-uuid-1", "sample-uuid-2")
          ),
          "group-uuid-2" = list(
            name = "Test Group 2",
            sampleRefs = c("sample-uuid-3")
          )
        ),
        
        # Data Sources (FCS file references)
        dataSources = list(
          "sample-uuid-1" = list(
            definition = list(
              uri = "/path/to/sample1.fcs",
              customKeywords = list(
                `$TOT` = "10000",
                `$DATE` = "01-Jan-2024",
                `File Name` = "sample1.fcs",
                `PATIENT ID` = "P001",
                TUBE = "1"
              )
            )
          ),
          "sample-uuid-2" = list(
            definition = list(
              uri = "/path/to/sample2.fcs",
              customKeywords = list(
                `$TOT` = "15000",
                `$DATE` = "01-Jan-2024",
                `File Name` = "sample2.fcs",
                `PATIENT ID` = "P001",
                TUBE = "2"
              )
            )
          ),
          "sample-uuid-3" = list(
            definition = list(
              uri = "/path/to/sample3.fcs",
              customKeywords = list(
                `$TOT` = "20000",
                `$DATE` = "02-Jan-2024",
                `File Name` = "sample3.fcs",
                `PATIENT ID` = "P002",
                TUBE = "1"
              )
            )
          )
        ),
        
        # Population Definitions (Gates)
        populationDefinitions = list(
          "pop-root-uuid" = list(
            uuid = "pop-root-uuid",
            definition = list(
              name = "root",
              type = "ROOT",
              kind = "UNIVERSAL"
            )
          ),
          "pop-live-uuid" = list(
            uuid = "pop-live-uuid",
            definition = list(
              name = "Live",
              type = "PolygonGate",
              kind = "GATE",
              parentUuid = "pop-root-uuid",
              gateDefinition = list(
                xParameter = "FSC-A",
                yParameter = "SSC-A",
                vertices = list(
                  list(x = 50000, y = 30000),
                  list(x = 200000, y = 30000),
                  list(x = 200000, y = 180000),
                  list(x = 50000, y = 180000)
                )
              ),
              # Desync table (per-sample gates)
              desyncTable = list(
                "sample-uuid-1" = list(
                  xParameter = "FSC-A",
                  yParameter = "SSC-A",
                  vertices = list(
                    list(x = 50000, y = 30000),
                    list(x = 200000, y = 30000),
                    list(x = 200000, y = 180000),
                    list(x = 50000, y = 180000)
                  )
                ),
                "sample-uuid-2" = list(
                  xParameter = "FSC-A",
                  yParameter = "SSC-A",
                  vertices = list(
                    list(x = 55000, y = 32000),  # Slightly different
                    list(x = 205000, y = 32000),
                    list(x = 205000, y = 185000),
                    list(x = 55000, y = 185000)
                  )
                )
              )
            )
          ),
          "pop-cd3-uuid" = list(
            uuid = "pop-cd3-uuid",
            definition = list(
              name = "CD3+",
              type = "RectangleGate",
              kind = "GATE",
              parentUuid = "pop-live-uuid",
              gateDefinition = list(
                xParameter = "CD3-FITC",
                yParameter = NULL,
                xMin = 1000,
                xMax = 250000
              ),
              desyncTable = list(
                "sample-uuid-1" = list(
                  xParameter = "CD3-FITC",
                  xMin = 1000,
                  xMax = 250000
                )
              )
            )
          ),
          "pop-cd4-uuid" = list(
            uuid = "pop-cd4-uuid",
            definition = list(
              name = "CD4+",
              type = "RectangleGate",
              kind = "GATE",
              parentUuid = "pop-cd3-uuid",
              gateDefinition = list(
                xParameter = "CD4-PE",
                yParameter = "CD8-APC",
                xMin = 1000,
                xMax = 250000,
                yMin = -1000,
                yMax = 10000
              )
            )
          )
        ),
        
        # Population Instances
        populations = list(
          "pop-inst-root-1" = list(
            uuid = "pop-inst-root-1",
            parentPopulation = NULL,
            counts = list(
              "sample-uuid-1" = 10000,
              "sample-uuid-2" = 15000
            )
          ),
          "pop-inst-live-1" = list(
            uuid = "pop-inst-live-1",
            parentPopulation = "pop-inst-root-1",
            counts = list(
              "sample-uuid-1" = 9500,
              "sample-uuid-2" = 14200
            )
          ),
          "pop-inst-cd3-1" = list(
            uuid = "pop-inst-cd3-1",
            parentPopulation = "pop-inst-live-1",
            counts = list(
              "sample-uuid-1" = 6800,
              "sample-uuid-2" = 10100
            )
          )
        )
      )
    ),
    manifests = list(
      `manifest.txt` = c(
        "analysis-test-uuid.json",
        "metadata.json"
      )
    )
  )
  
  return(workspace)
}

#' Create Mock FCS Files
#' @keywords internal
create_mock_fcs_files <- function(dir) {
  # Create simple FCS file structure for testing
  # This would require flowCore to create proper FCS files
  
  if (!requireNamespace("flowCore", quietly = TRUE)) {
    return(character(0))
  }
  
  library(flowCore)
  library(stats)
  
  # Create mock flow data
  set.seed(123)
  
  # Sample 1
  ncells1 <- 1000
  mat1 <- matrix(
    c(
      stats::rnorm(ncells1, mean = 100000, sd = 30000),  # FSC-A
      stats::rnorm(ncells1, mean = 80000, sd = 25000),   # SSC-A
      c(stats::rnorm(ncells1 * 0.7, mean = 50000, sd = 20000),  # CD3-FITC (70% positive)
        stats::rnorm(ncells1 * 0.3, mean = 500, sd = 200)),
      stats::rnorm(ncells1, mean = 30000, sd = 15000),   # CD4-PE
      stats::rnorm(ncells1, mean = 25000, sd = 12000)    # CD8-APC
    ),
    ncol = 5
  )
  colnames(mat1) <- c("FSC-A", "SSC-A", "CD3-FITC", "CD4-PE", "CD8-APC")
  
  ff1 <- flowFrame(mat1)
  keyword(ff1) <- list(
    `$TOT` = ncells1,
    `$DATE` = "01-Jan-2024",
    `PATIENT ID` = "P001",
    TUBE = "1"
  )
  
  write.FCS(ff1, file.path(dir, "sample1.fcs"))
  
  # Sample 2
  ncells2 <- 1500
  mat2 <- matrix(
    c(
      stats::rnorm(ncells2, mean = 105000, sd = 32000),
      stats::rnorm(ncells2, mean = 82000, sd = 26000),
      c(stats::rnorm(ncells2 * 0.65, mean = 55000, sd = 22000),
        stats::rnorm(ncells2 * 0.35, mean = 600, sd = 250)),
      stats::rnorm(ncells2, mean = 32000, sd = 16000),
      stats::rnorm(ncells2, mean = 27000, sd = 13000)
    ),
    ncol = 5
  )
  colnames(mat2) <- c("FSC-A", "SSC-A", "CD3-FITC", "CD4-PE", "CD8-APC")
  
  ff2 <- flowFrame(mat2)
  keyword(ff2) <- list(
    `$TOT` = ncells2,
    `$DATE` = "01-Jan-2024",
    `PATIENT ID` = "P001",
    TUBE = "2"
  )
  
  write.FCS(ff2, file.path(dir, "sample2.fcs"))
  
  # Sample 3
  ncells3 <- 2000
  mat3 <- matrix(
    c(
      stats::rnorm(ncells3, mean = 98000, sd = 28000),
      stats::rnorm(ncells3, mean = 78000, sd = 24000),
      c(stats::rnorm(ncells3 * 0.75, mean = 48000, sd = 18000),
        stats::rnorm(ncells3 * 0.25, mean = 450, sd = 180)),
      stats::rnorm(ncells3, mean = 28000, sd = 14000),
      stats::rnorm(ncells3, mean = 23000, sd = 11000)
    ),
    ncol = 5
  )
  colnames(mat3) <- c("FSC-A", "SSC-A", "CD3-FITC", "CD4-PE", "CD8-APC")
  
  ff3 <- flowFrame(mat3)
  keyword(ff3) <- list(
    `$TOT` = ncells3,
    `$DATE` = "02-Jan-2024",
    `PATIENT ID` = "P002",
    TUBE = "1"
  )
  
  write.FCS(ff3, file.path(dir, "sample3.fcs"))
  
  return(c("sample1.fcs", "sample2.fcs", "sample3.fcs"))
}

