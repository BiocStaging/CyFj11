#' @title UUID Structure Construction
#' @name uuid-construction
#' @keywords internal
NULL

#' Construct Complete JSON Structure with Correct UUID Relationships
#'
#' This function constructs a complete FlowJo workspace JSON structure
#' with correct UUID relationships according to the documented structure.
#'
#' @param template_data Optional template data to use as a base
#' @param analysis_uuid Optional analysis UUID to use
#' @return List representing complete FlowJo workspace structure
#' @keywords internal
construct_complete_json_structure <- function(template_data = NULL, analysis_uuid = NULL) {
  # Use provided analysis UUID or generate a new one
  if (is.null(analysis_uuid)) {
    analysis_uuid <- UUIDgenerate("BAJUUID_analysis")
  }
  
  # Initialize base workspace structure with ALL required fields
  workspace <- list(
    schemaVersion = "2.0.0",
    analysisUUID = analysis_uuid,
    uri = paste0("file:///analyses/analysis-", analysis_uuid, "/analysis-", analysis_uuid, ".json"),
    version = "11.0",
    populationDefinitions = list(),
    populations = list(),
    dataSources = list(),
    groups = list(),
    desyncTable = list(),
    compensation = list(),
    transformations = list(),
    reports = list(),
    compoundParameterSets = list(),
    compoundPopulations = list(),
    paramsetDefinitions = list(),
    platforms = list(),
    cytometers = list(),
    analysisRoot = list()
  )
  
  # If we have template data, use it to populate the structure
  if (!is.null(template_data)) {
    # Copy over any existing components from template
    component_types <- c("populationDefinitions", "populations", "dataSources", "groups", 
                         "reports", "compoundParameterSets", "compoundPopulations", 
                         "paramsetDefinitions", "platforms", "cytometers", "analysisRoot")
    
    for (component_type in component_types) {
      if (!is.null(template_data[[component_type]])) {
        workspace[[component_type]] <- template_data[[component_type]]
      }
    }
    
    # Copy other fields if they exist
    fields_to_copy <- c("schemaVersion", "version", "desyncTable", "compensation", "transformations")
    for (field in fields_to_copy) {
      if (!is.null(template_data[[field]])) {
        workspace[[field]] <- template_data[[field]]
      }
    }
  }
  
  # Ensure all required components exist
  component_types <- c("populationDefinitions", "populations", "dataSources", "groups", 
                       "reports", "compoundParameterSets", "compoundPopulations", 
                       "paramsetDefinitions", "platforms", "cytometers", "analysisRoot")
  
  for (component_type in component_types) {
    if (is.null(workspace[[component_type]])) {
      workspace[[component_type]] <- list()
    }
  }
  
  # Create analysisRoot if it doesn't exist
  if (length(workspace$analysisRoot) == 0) {
    workspace$analysisRoot <- create_initial_analysis_root(analysis_uuid, workspace)
  }
  
  # Create default groups if they don't exist
  if (length(workspace$groups) == 0) {
    workspace$groups <- create_default_groups(analysis_uuid)
  }
  
  # Create placeholder structures if they don't exist
  if (length(workspace$reports) == 0) {
    workspace$reports <- create_placeholder_reports(analysis_uuid)
  }
  
  if (length(workspace$platforms) == 0) {
    workspace$platforms <- create_placeholder_platforms(analysis_uuid)
  }
  
  if (length(workspace$cytometers) == 0) {
    workspace$cytometers <- create_placeholder_cytometers(analysis_uuid)
  }
  
  if (length(workspace$compoundParameterSets) == 0) {
    workspace$compoundParameterSets <- create_placeholder_compound_parameter_sets(analysis_uuid)
  }
  
  if (length(workspace$compoundPopulations) == 0) {
    workspace$compoundPopulations <- create_placeholder_compound_populations(analysis_uuid)
  }
  
  if (length(workspace$paramsetDefinitions) == 0) {
    workspace$paramsetDefinitions <- create_placeholder_paramset_definitions(analysis_uuid)
  }
  
  return(workspace)
}

#' Create Initial Analysis Root Structure
#'
#' @param analysis_uuid Analysis UUID
#' @param workspace Current workspace structure
#' @return List representing analysisRoot structure
#' @keywords internal
create_initial_analysis_root <- function(analysis_uuid, workspace) {
  analysis_root <- list()
  analysis_root[[analysis_uuid]] <- list(
    uuid = analysis_uuid,
    properties = list(
      acquiredData = list(
        groupId = UUIDgenerate("BAJUUID_group_aquired"),
        compoundPopulationId = UUIDgenerate("BAJUUID_compoundPop"),
        populationDefinitionId = UUIDgenerate("BAJUUID_popDef")
      ),
      compensationData = list(
        groupId = UUIDgenerate("BAJUUID_group_compensation"),
        compoundPopulationId = UUIDgenerate("BAJUUID_compoundPop"),
        populationDefinitionId = UUIDgenerate("BAJUUID_popDef")
      ),
      experimentData = list(
        groupId = UUIDgenerate("BAJUUID_group_Experiment"),
        compoundPopulationId = UUIDgenerate("BAJUUID_compoundPop"),
        populationDefinitionId = UUIDgenerate("BAJUUID_popDef")
      ),
      parameterSets = list(
        all = UUIDgenerate("BAJUUID_parameterSets_all"),
        compensated = UUIDgenerate("BAJUUID_parameterSets_compen"),
        uncompensated = UUIDgenerate("BAJUUID_parameterSets_uncompen"),
        derived = UUIDgenerate("BAJUUID_parameterSets_derived"),
        scatter = UUIDgenerate("BAJUUID_parameterSets_scatter"),
        metadata = UUIDgenerate("BAJUUID_parameterSets_metaData"),
        imageDerived = UUIDgenerate("BAJUUID_parameterSets_imageDerived")
      ),
      workbenchId = UUIDgenerate("BAJUUID_workbenchId"),
      workingDirectory = "/Users/flowjo/workspace",
      analysisWorkingDirectory = paste0("/Users/flowjo/workspace/analyses/analysis-", analysis_uuid)
    ),
    definition = list(
      transforms = list(),
      parameterMappings = list(),
      statisticDefinitions = list(
        CNT = list(statType = "Count"),
        FOP = list(statType = "FreqOfParent")
      ),
      samplesTableDefinition = list(columns = list()),
      imageWallSettings = list(palette = list())
    ),
    parents = list(
      "_analysis" = list(analysis_uuid),
      analysisRoot = list(),
      groups = list(),
      populationDefinitions = list(),
      compoundPopulations = list(),
      populations = list(),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(),
      cytometers = list(),
      platforms = list(),
      reports = list()
    ),
    children = list(
      analysisRoot = list(),
      groups = names(workspace$groups),
      populationDefinitions = names(workspace$populationDefinitions),
      compoundPopulations = names(workspace$compoundPopulations),
      populations = names(workspace$populations),
      paramsetDefinitions = names(workspace$paramsetDefinitions),
      compoundParameterSets = names(workspace$compoundParameterSets),
      dataSources = names(workspace$dataSources),
      cytometers = names(workspace$cytometers),
      platforms = names(workspace$platforms),
      reports = names(workspace$reports)
    ),
    results = list(),
    definitionVersion = 3L,
    resultsVersion = 3L,
    stableSince = 0L,
    recalcVersion = 0L
  )
  
  return(analysis_root)
}

#' Create Default Groups Structure
#'
#' @param analysis_uuid Analysis UUID
#' @return List representing groups structure
#' @keywords internal
create_default_groups <- function(analysis_uuid) {
  groups <- list()
  
  # Create Acquired Data group
  acquired_uuid <- UUIDgenerate("BAJUUID_groupAquired")
  groups[[acquired_uuid]] <- list(
    uuid = acquired_uuid,
    definition = list(
      name = "Acquired Data",
      criteria = list(
        "And",
        list(inclusive = TRUE)
      ),
      color = "#0000FF"
    ),
    parents = list(
      "_analysis" = list(analysis_uuid),
      analysisRoot = list(analysis_uuid),
      groups = list(),
      populationDefinitions = list(),
      compoundPopulations = list(),
      populations = list(),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(),
      cytometers = list(),
      platforms = list(),
      reports = list()
    ),
    children = list(
      analysisRoot = list(),
      groups = list(),
      populationDefinitions = list(),
      compoundPopulations = list(),
      populations = list(),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(),
      cytometers = list(),
      platforms = list(),
      reports = list()
    ),
    results = list(
      dataSources = list()
    ),
    definitionVersion = 35L,
    resultsVersion = 35L,
    stableSince = 0L,
    recalcVersion = 0L
  )
  
  # Create Compensation Data group
  comp_uuid <- UUIDgenerate("BAJUUID_groupCompensation")
  groups[[comp_uuid]] <- list(
    uuid = comp_uuid,
    definition = list(
      name = "Compensation Data",
      criteria = list(
        "And",
        list(
          "Or",
          list(
            keyword = "$FIL",
            "function" = "Contains",
            value = "comp"
          ),
          list(
            keyword = "$FIL",
            "function" = "Contains",
            value = "unstained"
          ),
          list(
            keyword = "$FIL",
            "function" = "Contains",
            value = "stained control"
          ),
          list(
            keyword = "File Name",
            "function" = "Contains",
            value = "comp"
          ),
          list(
            keyword = "File Name",
            "function" = "Contains",
            value = "unstained"
          ),
          list(
            keyword = "File Name",
            "function" = "Contains",
            value = "stained control"
          )
        ),
        list(
          keyword = "$FIL",
          "function" = "Lacks",
          value = "FMO"
        ),
        list(
          keyword = "File Name",
          "function" = "Lacks",
          value = "FMO"
        ),
        list(
          keyword = "$FIL",
          "function" = "Lacks",
          value = "isotype"
        ),
        list(
          keyword = "File Name",
          "function" = "Lacks",
          value = "isotype"
        ),
        list(inclusive = TRUE)
      ),
      color = "#FF0000"
    ),
    parents = list(
      "_analysis" = list(analysis_uuid),
      analysisRoot = list(analysis_uuid),
      groups = list(),
      populationDefinitions = list(),
      compoundPopulations = list(),
      populations = list(),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(),
      cytometers = list(),
      platforms = list(),
      reports = list()
    ),
    children = list(
      analysisRoot = list(),
      groups = list(),
      populationDefinitions = list(),
      compoundPopulations = list(),
      populations = list(),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(),
      cytometers = list(),
      platforms = list(),
      reports = list()
    ),
    results = list(
      dataSources = list()
    ),
    definitionVersion = 35L,
    resultsVersion = 35L,
    stableSince = 0L,
    recalcVersion = 0L
  )
  
  # Create Experiment Data group
  exp_uuid <- UUIDgenerate("BAJUUID_groupExperimentData")
  groups[[exp_uuid]] <- list(
    uuid = exp_uuid,
    definition = list(
      name = "Experiment Data",
      criteria = list(
        "Or",
        list(
          "And",
          list(inclusive = TRUE),
          list(
            "Or",
            list(
              "And",
              list(
                keyword = "$FIL",
                "function" = "Lacks",
                value = "comp"
              ),
              list(
                keyword = "$FIL",
                "function" = "Lacks",
                value = "unstained"
              ),
              list(
                keyword = "$FIL",
                "function" = "Lacks",
                value = "stained control"
              ),
              list(
                keyword = "File Name",
                "function" = "Lacks",
                value = "comp"
              ),
              list(
                keyword = "File Name",
                "function" = "Lacks",
                value = "unstained"
              ),
              list(
                keyword = "File Name",
                "function" = "Lacks",
                value = "stained control"
              )
            ),
            list(
              keyword = "$FIL",
              "function" = "Contains",
              value = "FMO"
            ),
            list(
              keyword = "File Name",
              "function" = "Contains",
              value = "FMO"
            ),
            list(
              keyword = "$FIL",
              "function" = "Contains",
              value = "isotype"
            ),
            list(
              keyword = "File Name",
              "function" = "Contains",
              value = "isotype"
            )
          )
        ),
        list(allowList = list())
      ),
      color = "#00FF00"
    ),
    parents = list(
      "_analysis" = list(analysis_uuid),
      analysisRoot = list(analysis_uuid),
      groups = list(),
      populationDefinitions = list(),
      compoundPopulations = list(),
      populations = list(),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(),
      cytometers = list(),
      platforms = list(),
      reports = list()
    ),
    children = list(
      analysisRoot = list(),
      groups = list(),
      populationDefinitions = list(),
      compoundPopulations = list(),
      populations = list(),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(),
      cytometers = list(),
      platforms = list(),
      reports = list()
    ),
    results = list(
      dataSources = list()
    ),
    definitionVersion = 35L,
    resultsVersion = 35L,
    stableSince = 0L,
    recalcVersion = 0L
  )
  
  return(groups)
}

#' Create Placeholder Reports Structure
#'
#' @param analysis_uuid Analysis UUID
#' @return List representing reports structure
#' @keywords internal
create_placeholder_reports <- function(analysis_uuid) {
  report_uuid <- UUIDgenerate("BAJUUID_report")
  page_uuid <- UUIDgenerate("BAJUUID_page")
  
  reports <- list()
  reports[[report_uuid]] <- list(
    uuid = report_uuid,
    properties = structure(list(), names = character(0)),
    definition = list(
      name = "Report",
      reportSpec = list(
        layout = list(
          type = "custom",
          unitOfMeasurement = "inches",
          size = list(width = 2496.0, height = 1920.0)
        ),
        batchSettings = list(
          batchBy = "group",
          batchById = UUIDgenerate("BAJUUID_batchid"),
          iterator = list(
            type = "sample",
            sort = "ascending",
            keyword = "File Name",
            statistic = list(type = "Count")
          ),
          discriminator = list(
            type = "off",
            keyword = "File Name",
            statistic = list(type = "Count")
          ),
          direction = "across",
          rows = 1,
          columns = 1,
          interval = 1
        ),
        pages = list(
          page_uuid = list(
            id = page_uuid,
            type = "source",
            elements = list(
              charts = list(),
              graphs = list(),
              tables = list(),
              text = list(),
              groups = list(),
              images = list()
            )
          )
        ),
        pageOrder = list(page_uuid)
      )
    ),
    parents = list(
      "_analysis" = list(analysis_uuid),
      analysisRoot = list(),
      groups = list(),
      populationDefinitions = list(),
      compoundPopulations = list(),
      populations = list(),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(),
      cytometers = list(),
      platforms = list(),
      reports = list()
    ),
    children = list(
      analysisRoot = list(),
      groups = list(),
      populationDefinitions = list(),
      compoundPopulations = list(),
      populations = list(),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(),
      cytometers = list(),
      platforms = list(),
      reports = list()
    ),
    results = list(
      reportSpec = list(
        layout = list(
          type = "custom",
          unitOfMeasurement = "inches",
          size = list(width = 2496.0, height = 1920.0)
        ),
        batchSettings = list(
          batchBy = "group",
          batchById = UUIDgenerate("BAJUUID_baatchid"),
          iterator = list(
            type = "sample",
            sort = "ascending",
            keyword = "File Name",
            statistic = list(type = "Count")
          ),
          discriminator = list(
            type = "off",
            keyword = "File Name",
            statistic = list(type = "Count")
          ),
          direction = "across",
          rows = 1,
          columns = 1,
          interval = 1
        ),
        pages = list(
          page_key = list(
            id = paste0(page_uuid, ":0"),
            type = "batched",
            elements = list(
              charts = list(),
              graphs = list(),
              tables = list(),
              text = list(),
              groups = list(),
              images = list()
            ),
            sourcePageId = page_uuid
          )
        ),
        pageOrder = list(paste0(page_uuid, ":0"))
      )
    ),
    definitionVersion = 3L,
    resultsVersion = 3L,
    stableSince = 1L,
    recalcVersion = 1L
  )
  
  return(reports)
}

#' Create Placeholder Platforms Structure
#'
#' @param analysis_uuid Analysis UUID
#' @return List representing platforms structure
#' @keywords internal
create_placeholder_platforms <- function(analysis_uuid) {
  platform_uuid1 <- UUIDgenerate("BAJUUID_Platform")
  platform_uuid2 <- UUIDgenerate("BAJUUID_Platform2")
  
  platforms <- list(
    statisticalModeling = list()
  )
  
  # Create table platform
  platforms$statisticalModeling[[platform_uuid1]] <- list(
    uuid = platform_uuid1,
    properties = structure(list(), names = character(0)),
    definition = list(
      recalcPrefs = list(
        platformChanged = "recalculate",
        platformUndone = "recalculate",
        inputsRecalculated = "recalculate",
        annotationsChanged = "recalculate",
        samplesAdded = "n/a",
        samplesRemoved = "n/a"
      ),
      platformType = "statisticalModeling",
      name = "Table",
      model = "table",
      rowSpecification = list(
        summarization = "bySample",
        populationIds = list()
      ),
      factorSpecifications = list(
        list(
          columnId = "KEY:File Name",
          factorType = "keyword",
          dataType = "nominal",
          keywordName = "File Name",
          width = 200.0
        )
      ),
      responseSpecifications = list()
    ),
    parents = list(
      "_analysis" = list(analysis_uuid),
      analysisRoot = list(analysis_uuid),
      groups = list(),
      populationDefinitions = list(),
      compoundPopulations = list(UUIDgenerate("BAJUUID_compoundPopulations_ref")),
      populations = list(),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(),
      cytometers = list(),
      platforms = list(),
      reports = list()
    ),
    children = list(
      analysisRoot = list(),
      groups = list(),
      populationDefinitions = list(),
      compoundPopulations = list(),
      populations = list(),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(),
      cytometers = list(),
      platforms = list(platform_uuid2),
      reports = list()
    ),
    results = list(
      statistics = list(
        table = list(
          rows = list(),
          columns = list(
            list(
              columnId = "KEY:File Name",
              factorType = "keyword",
              dataType = "nominal",
              keywordName = "File Name",
              width = 200.0
            )
          ),
          values = list()
        )
      )
    ),
    definitionVersion = 5L,
    resultsVersion = 5L,
    stableSince = 3L,
    recalcVersion = 3L
  )
  
  # Create chart platform
  platforms$statisticalModeling[[platform_uuid2]] <- list(
    uuid = platform_uuid2,
    properties = structure(list(), names = character(0)),
    definition = list(
      recalcPrefs = list(
        platformChanged = "recalculate",
        platformUndone = "recalculate",
        inputsRecalculated = "recalculate",
        annotationsChanged = "recalculate",
        samplesAdded = "n/a",
        samplesRemoved = "n/a"
      ),
      platformType = "statisticalModeling",
      name = "Chart",
      model = "chart",
      rowSpecification = list(
        summarization = "bySample",
        populationIds = list()
      ),
      factorSpecifications = list(
        list(
          columnId = "KEY:File Name",
          factorType = "keyword",
          dataType = "nominal",
          keywordName = "File Name",
          width = 200.0
        )
      ),
      responseSpecifications = list(),
      parentModel = platform_uuid1,
      chartDefinition = list(
        type = "bar",
        settings = list(
          colorPalette = "Blues",
          fontColor = "#000000",
          fontStyle = "Regular",
          fontSize = 12,
          fontFamily = "Noto Sans",
          showLegend = TRUE,
          showTable = TRUE,
          showGuides = TRUE,
          showMinorTicks = FALSE,
          showMajorTicks = FALSE,
          showComparisonLine = FALSE,
          showPValue = FALSE,
          showSignificance = FALSE,
          rotateText = FALSE,
          ellipsisStyle = "post",
          scale = "linear",
          range = list(value = 0.0, auto = TRUE),
          statistic = "Mean",
          errorBars = list(enabled = TRUE, statistic = "sd")
        ),
        primaryAxis = "category",
        groupBy = list(enabled = FALSE, factor = ""),
        legends = list(),
        comparison = list(
          testStatistic = "Wilks' Lambda",
          mainFactor = "",
          primaryValue = ""
        )
      )
    ),
    parents = list(
      "_analysis" = list(analysis_uuid),
      analysisRoot = list(),
      groups = list(),
      populationDefinitions = list(),
      compoundPopulations = list(),
      populations = list(),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(),
      cytometers = list(),
      platforms = list(platform_uuid1),
      reports = list()
    ),
    children = list(
      analysisRoot = list(),
      groups = list(),
      populationDefinitions = list(),
      compoundPopulations = list(),
      populations = list(),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(),
      cytometers = list(),
      platforms = list(),
      reports = list()
    ),
    results = list(
      statistics = list(
        table = list(
          rows = list(),
          columns = list(),
          values = list()
        )
      )
    ),
    definitionVersion = 5L,
    resultsVersion = 5L,
    stableSince = 3L,
    recalcVersion = 3L
  )
  
  return(platforms)
}

#' Create Placeholder Cytometers Structure
#'
#' @param analysis_uuid Analysis UUID
#' @return List representing cytometers structure
#' @keywords internal
create_placeholder_cytometers <- function(analysis_uuid) {
  cytometer_uuid <- UUIDgenerate("BAJUUID_cytometer")
  
  cytometers <- list()
  cytometers[[cytometer_uuid]] <- list(
    uuid = cytometer_uuid,
    properties = structure(list(), names = character(0)),  # CHANGED: was list(), needs to be {}
    definition = list(
      cytometer = "",  # NOTE: JSON has "ID7000" - this needs to come from FCS data
      system = "",     # NOTE: JSON has "Microsoft Windows 10 Famille" - this needs to come from FCS data
      cytometerTransformSpec = list(
        name = "GENERIC",  # CHANGED: was "Generic", should be "GENERIC"
        match = "",
        logRescale = 1.0,  # CHANGED: was format_transformation_parameter(0.9999999403953552, "rescale")
        linearRescale = 1.0,  # CHANGED: was format_transformation_parameter(0.9999999403953552, "rescale")
        useFCSEmbeddedTransforms = TRUE,  # CHANGED: was TRUE (correct but check capitalization)
        transformRules = list()  # CHANGED: was populated with 3 rules, JSON shows []
      ),
      transforms = list()  # NOTE: JSON has many transforms - this needs to be populated from FCS parameters
    ),
    parents = list(
      `_analysis` = I(c(analysis_uuid)),  # CHANGED: was analysis_uuid, needs to be array
      analysisRoot = I(c(analysis_uuid)),  # CHANGED: was list(), needs to be array with analysis_uuid
      groups = list(),
      populationDefinitions = list(),
      compoundPopulations = list(),
      populations = list(),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(),
      cytometers = list(),
      platforms = list(),
      reports = list()
    ),
    children = list(
      analysisRoot = list(),
      groups = list(),
      populationDefinitions = list(),
      compoundPopulations = list(),
      populations = list(),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(),  # NOTE: JSON shows 3 UUIDs - needs to be populated
      cytometers = list(),
      platforms = list(),
      reports = list()
    ),
    results = structure(list(), names = character(0)),  # CHANGED: was list(), needs to be {}
    definitionVersion = 35L,  # CHANGED: was 3, should be 35L
    resultsVersion = 35L,     # CHANGED: was 3, should be 35L
    stableSince = 0L,         # CHANGED: was 0, should be 0L
    recalcVersion = 0L        # CHANGED: was 0, should be 0L
  )
  
  return(cytometers)
}

# Function to determine appropriate transform for a parameter
determine_transform <- function(param_name, ff, trans_list, keywords) {
  
  # Check if transform exists in GatingSet transforms
  if (!is.null(trans_list) && param_name %in% names(trans_list)) {
    trans_obj <- trans_list[[param_name]]
    return(convert_flowcore_transform(trans_obj))
  }
  
  # Check for $PnE (display values) in keywords for logicle/biex hints
  param_idx <- which(colnames(ff) == param_name)
  pne_key <- paste0("$P", param_idx, "E")
  
  # Determine transform based on parameter characteristics
  param_range <- range(exprs(ff)[, param_name], na.rm = TRUE)
  
  # Check if parameter is FSC/SSC scatter parameter
  is_scatter <- grepl("^(FSC|SSC)|scatter", param_name, ignore.case = TRUE)
  
  if (is_scatter) {
    # FSC/SSC parameters - check suffix
    if (grepl("-A$", param_name, ignore.case = TRUE)) {
      # Area parameters - Biexponential
      return(list(
        transformType = "Biex",
        T = 262144.0,  # Typical for scatter
        A = 0.0,
        M = 4.5,
        W = -10.0,
        vectorLength = 256L,
        autoWidthBasis = FALSE
      ))
    } else if (grepl("-[WH]$", param_name, ignore.case = TRUE)) {
      # Width and Height parameters - Log
      return(list(
        transformType = "Log",
        decadesOffset = 1.0,
        numberDecades = 6.0,
        shift = 0.0,
        negate = FALSE
      ))
    } else {
      # Base FSC/SSC without suffix - Linear
      return(list(
        transformType = "Linear",
        scale = 1.0,
        offset = 0.0
      ))
    }
  } else {
    # Fluorescent parameters - typically Log
    return(list(
      transformType = "Log",
      decadesOffset = 1.0,
      numberDecades = 4.5,
      shift = 0.0,
      negate = FALSE
    ))
  }
}

# Convert flowCore transform objects to the required format
convert_flowcore_transform <- function(trans_obj) {
  
  if (inherits(trans_obj, "logicleTransform")) {
    # Logicle/Biex transform
    return(list(
      transformType = "Biex",
      T = trans_obj@T,
      A = trans_obj@A,
      M = trans_obj@M,
      W = trans_obj@W,
      vectorLength = 256L,
      autoWidthBasis = FALSE
    ))
  } else if (inherits(trans_obj, "biexponentialTransform")) {
    return(list(
      transformType = "Biex",
      T = trans_obj@T %||% 1000000.0,
      A = trans_obj@a %||% 0.0,
      M = trans_obj@c %||% 4.5,
      W = trans_obj@w %||% -10.0,
      vectorLength = 256L,
      autoWidthBasis = FALSE
    ))
  } else if (inherits(trans_obj, "logTransform")) {
    return(list(
      transformType = "Log",
      decadesOffset = 1.0,
      numberDecades = trans_obj@logbase %||% 10.0,
      shift = 0.0,
      negate = FALSE
    ))
  } else if (inherits(trans_obj, "asinhtTransform")) {
    # Convert asinh to Log approximation
    return(list(
      transformType = "Log",
      decadesOffset = 1.0,
      numberDecades = 5.0,
      shift = 0.0,
      negate = FALSE
    ))
  } else {
    # Default to Linear
    return(list(
      transformType = "Linear",
      scale = 1.0,
      offset = 0.0
    ))
  }
}

extract_cytometer_info <- function(gs, cytometer_id) {
  
  # Get flowFrame depending on input type
  ff <- gh_pop_get_data(gs[[1]], "root")
  trans_list <- gh_get_transformations(gs[[1]])
  
  # Extract keywords
  keywords <- keyword(ff)
  
  # Extract cytometer info
  cytometer <- keywords[["$CYT"]] %||% 
    keywords[["CYTOMETER"]] %||% 
    keywords[["$CYTSN"]] %||% 
    "Unknown"
  
  # Extract system info
  system <- keywords[["$SYS"]] %||% 
    keywords[["SYSTEM"]] %||% 
    keywords[["$OS"]] %||%
    "Unknown"
  
  # Create cytometer transform spec
  cytometerTransformSpec <- list(
    name = "GENERIC",
    match = "",
    logRescale = 1.0,
    linearRescale = 1.0,
    useFCSEmbeddedTransforms = TRUE,
    transformRules = list()
  )
  
  # Create definition
  definition <- list(
    cytometer = cytometer,
    system = system,
    cytometerTransformSpec = cytometerTransformSpec
  )
  params <- parameters(ff)
  param_names <- colnames(ff)
  param_desc <- params$desc
  
  transforms <- list()
  for (i in seq_along(param_names)) {
    param_name <- param_names[i]
    desc_name <- param_desc[i]
    
    # Skip time parameters typically
    if (grepl("time", param_name, ignore.case = TRUE)) {
      next
    }
    
    # Create parameter spec
    parameterSpec <- list(name = param_name)
    if (!is.na(desc_name) && desc_name != "") {
      parameterSpec$descriptiveName <- desc_name
    }
    
    # Determine transform
    transform <- determine_transform(
      param_name = param_name,
      ff = ff,
      trans_list = trans_list,
      keywords = keywords
    )
    
    # Add to transforms list
    transforms[[length(transforms) + 1]] <- list(
      parameterSpec = parameterSpec,
      transform = transform,
      targetType = "cytometer",
      targetId = cytometer_id
    )
  }
  definition$transforms = transforms
  return(definition)
}

create_cytometers <- function(gs) {
  cytometer_uuid <- UUIDgenerate("BAJUUID_cytometer")
  cytometers <- list()
  cytometers[[cytometer_uuid]] <- list(
    uuid = cytometer_uuid,
    properties = structure(list(), names = character(0)),  
    definition = extract_cytometer_info(gs, cytometer_uuid),
    parents = list(
      `_analysis` = I(c("ANALYSIS_UUID")),  
      analysisRoot = I(c("ANALYSIS_UUID")), 
      groups = list(),
      populationDefinitions = list(),
      compoundPopulations = list(),
      populations = list(),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(),
      cytometers = list(),
      platforms = list(),
      reports = list()
    ),
    children = list(
      analysisRoot = list(),
      groups = list(),
      populationDefinitions = list(),
      compoundPopulations = list(),
      populations = list(),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(),  # NOTE: JSON shows 3 UUIDs - needs to be populated
      cytometers = list(),
      platforms = list(),
      reports = list()
    ),
    results = structure(list(), names = character(0)), 
    definitionVersion = 35L, 
    resultsVersion = 35L,     # CHANGED: was 3, should be 35L
    stableSince = 0L,         # CHANGED: was 0, should be 0L
    recalcVersion = 0L        # CHANGED: was 0, should be 0L
  )
  
  return(cytometers)
}

#' Create Placeholder Compound Parameter Sets Structure
#'
#' @param analysis_uuid Analysis UUID
#' @return List representing compoundParameterSets structure
#' @keywords internal
create_placeholder_compound_parameter_sets <- function(analysis_uuid) {
  # Create multiple parameter set types
  compound_parameter_sets <- list()
  
  # All parameters
  all_uuid <- UUIDgenerate("BAJUUID_all parameters")
  compound_parameter_sets[[all_uuid]] <- list(
    uuid = all_uuid,
    properties = structure(list(), names = character(0)),
    definition = list(
      name = "All",
      description = "All parameters.",
      type = "rule",
      includeDownstream = TRUE,
      rule = list(
        conditions = list(
          list(type = "ParameterAll")
        )
      )
    ),
    parents = list(
      "_analysis" = list(analysis_uuid),
      analysisRoot = list(),
      groups = list(),
      populationDefinitions = list(),
      compoundPopulations = list(),
      populations = list(),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(),
      cytometers = list(),
      platforms = list(),
      reports = list()
    ),
    children = list(
      analysisRoot = list(),
      groups = list(),
      populationDefinitions = list(),
      compoundPopulations = list(),
      populations = list(),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(),
      cytometers = list(),
      platforms = list(),
      reports = list()
    ),
    results = list(),
    definitionVersion = 3L,
    resultsVersion = 3L,
    stableSince = 0L,
    recalcVersion = 0L
  )
  
  return(compound_parameter_sets)
}

create_compound_parameter_sets <- function(analysis_uuid, groups, paramsetDefinitions) {
  # Create multiple parameter set types
  compound_parameter_sets <- list()
  # browser()
  for(grp in names(groups)){
    grpName = sub("^BAJUUID_(.*):.*$", "\\1", grp)
    
    for(psd in names(paramsetDefinitions)){
      psdName = sub("^BAJUUID_(.*):.*$", "\\1", psd)
      uuid_str  <- UUIDgenerate(paste0("BAJUUID_", grpName, "_", psdName))
      
      compound_parameter_sets[[uuid_str]] <- list(
        uuid = uuid_str,
        properties = structure(list(), names = character(0)),
        properties = structure(list(), names = character(0)),
        definition = structure(list(), names = character(0)),
        parents = list(
          "_analysis" = list(analysis_uuid),
          analysisRoot = list(),
          groups = list(grp),
          populationDefinitions = list(),
          compoundPopulations = list(),
          populations = list(),
          paramsetDefinitions = list(psd),
          compoundParameterSets = list(),
          dataSources = list(),
          cytometers = list(),
          platforms = list(),
          reports = list()
        ),
        children = list(
          analysisRoot = list(),
          groups = list(),
          populationDefinitions = list(),
          compoundPopulations = list(),
          populations = list(),
          paramsetDefinitions = list(),
          compoundParameterSets = list(),
          dataSources = list(),
          cytometers = list(),
          platforms = list(),
          reports = list()
        ),
        results = list(
          "count" = 0L,
          "parameters" =  structure(list(), names = character(0))
        ),
        definitionVersion = 35L,
        resultsVersion = 35L,
        stableSince = 35L,
        recalcVersion = 35L
      )
      
    }
  }
  # All parameters
  
  
  return(compound_parameter_sets)
}


#' Create Placeholder Compound Populations Structure
#'
#' @param analysis_uuid Analysis UUID
#' @return List representing compoundPopulations structure
#' @keywords internal
create_placeholder_compound_populations <- function(analysis_uuid) {
  compound_populations <- list()
  
  # Create a basic compound population
  compound_uuid <- UUIDgenerate("BAJUUID_compound_uuid")
  compound_populations[[compound_uuid]] <- list(
    uuid = compound_uuid,
    properties = structure(list(), names = character(0)),
    definition = list(
      name = "Compound Population",
      description = "Generated compound population.",
      type = "compound",
      includeDownstream = TRUE
    ),
    parents = list(
      "_analysis" = list(analysis_uuid),
      analysisRoot = list(),
      groups = list(),
      populationDefinitions = list(),
      compoundPopulations = list(),
      populations = list(),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(),
      cytometers = list(),
      platforms = list(),
      reports = list()
    ),
    children = list(
      analysisRoot = list(),
      groups = list(),
      populationDefinitions = list(),
      compoundPopulations = list(),
      populations = list(),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(),
      cytometers = list(),
      platforms = list(),
      reports = list()
    ),
    results = list(),
    definitionVersion = 3L,
    resultsVersion = 3L,
    stableSince = 0L,
    recalcVersion = 0L
  )
  
  return(compound_populations)
}

find_popDef_uuid <- function(gates, name = "Ungated"){
  if(name ==  "root") name = "Ungated"
  uuids = c()
  for(gate in gates){
    if(name == gate$definition$name){
      uuids = c(uuids, gate$uuid)
    }
  }
  uuids
}

#' Create Root Compound Population
#'
#' @param compound_uuid UUID for the compound population
#' @param analysis_uuid UUID for the analysis
#' @param compensation_group_uuid UUID for the compensation group
#' @param ungated_pop_defs UUID(s) for ungated population definitions
#' @return List representing compound population root in FlowJo format
#' @keywords internal
create_compound_populations_root <- function(compound_uuid, analysis_uuid, compensation_group_uuid, ungated_pop_defs) {
  list(
    uuid = compound_uuid,
    properties = structure(list(), names = character(0)),
    definition = list(
      populationNumber = 0L
    ),
    parents = list(
      `_analysis` = list(analysis_uuid),
      `_group` = list(compensation_group_uuid),
      analysisRoot = list(),
      groups = list(compensation_group_uuid),
      populationDefinitions = list(ungated_pop_defs),
      compoundPopulations = character(0),
      populations = character(0),
      paramsetDefinitions = character(0),
      compoundParameterSets = character(0),
      dataSources = character(0),
      cytometers = character(0),
      platforms = character(0),
      reports = character(0)
    ),
    children = list(
      analysisRoot = character(0),
      groups = character(0),
      populationDefinitions = character(0),
      compoundPopulations = character(0),
      populations = character(0),
      paramsetDefinitions = character(0),
      compoundParameterSets = character(0),
      dataSources = character(0),
      cytometers = character(0),
      platforms = character(0),
      reports = character(0)
    ),
    results = list(
      status = "empty",
      validPopulations = 0L,
      invalidPopulations = 0L,
      count = 0L,
      statistics = list(
        CNT = "0",
        FOP = "0"
      )
    ),
    definitionVersion = 35L,
    resultsVersion = 35L,
    stableSince = 35L,
    recalcVersion = 35L
  )
}

# use root not ungated
find_pop_uuid <- function(populations, samples, pop_target = "root"){
  sample_uuids = samples %>% names()
  
  sample_key = list()
  for (samp in samples){
    sample_key[[samp$definition$customKeywords$`File Name` ]] = samp$uuid
  }
  output = list()
  for (pop in populations){
    pop$parents$`_dataSource`
    pop$uuid
    if (pop_target == pop$parents$populationDefinitions[[1]]){
      output[[pop$uuid]] = pop$parents$`_dataSource`[[1]]
    }
  }
  if (any(duplicated(output))){
    #TODO this should not happen, give warning
  }
  return(names(output))
}

create_compound_populations_root2 <- function(compound_uuid, analysis_uuid, acquired_group_uuid, 
                                              ungated_pop_defs, pops, platforms, children=NULL) {
  
  if(!is.null(children)){
    children = paste0("BAJUUID_compoundPop_", children)
  }
  
  compound_pop <- list(
    uuid = compound_uuid,
    properties = structure(list(), names = character(0)),
    definition = list(
      populationNumber = 0L
    ),
    parents = list(
      `_analysis` = list(analysis_uuid),
      `_group` = list(acquired_group_uuid),
      analysisRoot = list(),
      groups = list(acquired_group_uuid),
      populationDefinitions = list(ungated_pop_defs),
      compoundPopulations = list(),
      populations = list(pops),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(),
      cytometers = list(),
      platforms = list(),
      reports = list()
    ),
    children = list(
      analysisRoot = list(),
      groups = list(),
      populationDefinitions = list(),
      compoundPopulations = list(children),
      populations = list(),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(),
      cytometers = list(),
      platforms = list(platforms),
      reports = list()
    ),
    results = list(
      status = "empty",
      validPopulations = 0L,
      invalidPopulations = 0L,
      count = -1L,
      statistics = list(
        CNT = -1L,
        FOP = 100L
      )
    ),
    definitionVersion = 35L,
    resultsVersion = 35L,
    stableSince = 35L,
    recalcVersion = 35L
  )
  
  return(compound_pop)
}

create_compound_populations_list <- function(
  compound_uuid, analysis_uuid, acquired_group_uuid, parentDef, pops,ungated_pop_defs, gs, children){
  
  
  compound_pop <- list(
    uuid = compound_uuid,
    properties = structure(list(), names = character(0)),
    definition = list(
      populationNumber = 0L
    ),
    parents = list(
      `_analysis` = list(analysis_uuid),
      `_group` = list(acquired_group_uuid),
      analysisRoot = list(),
      groups = list(acquired_group_uuid),
      populationDefinitions = list(ungated_pop_defs),
      compoundPopulations = list(),
      populations = list(pops),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(),
      cytometers = list(),
      platforms = list(),
      reports = list()
    ),
    children = list(
      analysisRoot = list(),
      groups = list(),
      populationDefinitions = list(),
      compoundPopulations = list(children),
      populations = list(),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(),
      cytometers = list(),
      platforms = list("PLATFORM_UUID"),
      reports = list()
    ),
    results = list(
      status = "valid",
      validPopulations = 0L, # number of samples included
      invalidPopulations = 0L,
      count = -1L,
      statistics = list(
        CNT = -1L,
        FOP = 100L
      )
    ),
    definitionVersion = 35L,
    resultsVersion = 35L,
    stableSince = 35L,
    recalcVersion = 35L
  )
  
  return(compound_pop)
}



create_compound_populations <- function(analysis_uuid, gs, groups, populations, gates, samples) {
  compound_populations <- list()
  # browser()
  # Create a root compound population
  sample_uuids = samples %>% names()
  compound_uuid <- UUIDgenerate("BAJUUID_compoundPopRoot")
  compensation_group_uuid = names(groups)[startsWith(names(groups), "UUID_groupCompensation:")]
  ungated_pop_defs = find_popDef_uuid(gates, "Ungated")
  compound_populations[[compound_uuid]] <- create_compound_populations_root(compound_uuid,analysis_uuid, compensation_group_uuid, ungated_pop_defs)
  
  
  # 2nd node, still referring to ungated
  compound_uuid <- UUIDgenerate("BAJUUID_compoundPopRoot2")
  acquired_group_uuid = names(groups)[startsWith(names(groups), "BAJUUID_groupAquired:")]
  current_pop = "root"
  #TODO try catchd
  parent=NULL
  pops = find_pop_uuid(populations, samples, "root")
  platforms = "PLATFORMS_UUID"
  
  compound_populations[[compound_uuid]] <- create_compound_populations_root2(compound_uuid,analysis_uuid, acquired_group_uuid, ungated_pop_defs, pops, platforms)
  
  
  # 3rd node, still referring to ungated, but now with children
  compound_uuid <- UUIDgenerate("BAJUUID_compoundPopRoot3")
  acquired_group_uuid = names(groups)[startsWith(names(groups), "BAJUUID_groupAquired:")]
  current_pop = "root"
  #TODO try catchd
  parent=NULL
  children = gs_pop_get_children(gs,current_pop, path = "auto")
  pops = find_pop_uuid(populations, samples, "root")
  platforms = NULL
  
  compound_populations[[compound_uuid]] <- create_compound_populations_root2(compound_uuid,analysis_uuid, acquired_group_uuid, ungated_pop_defs, pops, platforms, children)
  
  # real populations
  gs_pops = gs_get_pop_paths(gs, path = "auto")
  for(current_pop in gs_pops){
    if(current_pop == "root") next
    compound_uuid <- UUIDgenerate(paste0("BAJUUID_compoundPop_", current_pop))
    
    children = gs_pop_get_children(gs,current_pop, path = "auto")
    parent = gs_pop_get_parent(gs, current_pop, path = "auto")
    parentDef = find_popDef_uuid(gates, parent)
    pops = find_pop_uuid(populations = populations, samples = samples, pop_target = current_pop)
    compound_populations[[compound_uuid]] <- create_compound_populations_list(
      compound_uuid, analysis_uuid, acquired_group_uuid, parentDef, pops, ungated_pop_defs, gs, children)
    
  }
  
  
  compound_populations[[compound_uuid]] <- list(
    uuid = compound_uuid,
    properties = structure(list(), names = character(0)),
    definition = list(
      name = "Compound Population",
      description = "Generated compound population.",
      type = "compound",
      includeDownstream = TRUE
    ),
    parents = list(
      "_analysis" = list(analysis_uuid),
      analysisRoot = list(),
      groups = list(),
      populationDefinitions = list(),
      compoundPopulations = list(),
      populations = list(),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(),
      cytometers = list(),
      platforms = list(),
      reports = list()
    ),
    children = list(
      analysisRoot = list(),
      groups = list(),
      populationDefinitions = list(),
      compoundPopulations = list(),
      populations = list(),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(),
      cytometers = list(),
      platforms = list(),
      reports = list()
    ),
    results = list(),
    definitionVersion = 3L,
    resultsVersion = 3L,
    stableSince = 0L,
    recalcVersion = 0L
  )
  
  return(compound_populations)
}

#' Create Placeholder Paramset Definitions Structure
#'
#' @param analysis_uuid Analysis UUID
#' @return List representing paramsetDefinitions structure
#' @keywords internal
create_placeholder_paramset_definitions <- function(analysis_uuid) {
  paramset_definitions <- list()
  
  # Create a basic parameter set definition
  paramset_uuid <- UUIDgenerate("BAJUUID_paramset_uuid")
  paramset_definitions[[paramset_uuid]] <- list(
    uuid = paramset_uuid,
    properties = structure(list(), names = character(0)),
    definition = list(
      name = "Parameter Set",
      description = "Generated parameter set.",
      type = "paramset",
      includeDownstream = TRUE
    ),
    parents = list(
      "_analysis" = list(analysis_uuid),
      analysisRoot = list(),
      groups = list(),
      populationDefinitions = list(),
      compoundPopulations = list(),
      populations = list(),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(),
      cytometers = list(),
      platforms = list(),
      reports = list()
    ),
    children = list(
      analysisRoot = list(),
      groups = list(),
      populationDefinitions = list(),
      compoundPopulations = list(),
      populations = list(),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(),
      cytometers = list(),
      platforms = list(),
      reports = list()
    ),
    results = list(),
    definitionVersion = 3L,
    resultsVersion = 3L,
    stableSince = 0L,
    recalcVersion = 0L
  )
  
  return(paramset_definitions)
}

create_paramset_definitions <- function(analysis_uuid, UUID_groupAquired) {
  paramset_definitions <- list()
  # Define the 8 different parameter set configurations
  paramset_configs <- list(
    list(
      name = "Derived",
      description = "Derived (calculated) parameters.",
      type = "rule",
      includeDownstream = TRUE,
      rule = list(conditions = list(list(type = "ParameterIsDerived")))
    ),
    list(
      name = "All",
      description = "All parameters.",
      type = "rule",
      includeDownstream = TRUE,
      rule = list(conditions = list(list(type = "ParameterAll")))
    ),
    list(
      name = "Image Derived",
      description = "Image-derived parameters.",
      type = "rule",
      includeDownstream = FALSE,
      rule = list(conditions = list(list(type = "ParameterIsImageDerived")))
    ),
    list(
      name = "Scatter",
      description = "Scatter parameters.",
      type = "rule",
      includeDownstream = FALSE,
      rule = list(conditions = list(list(type = "ParameterIsScatter")))
    ),
    list(
      name = "Compensated",
      description = "Compensated and Unmixed parameters.",
      type = "rule",
      includeDownstream = FALSE,
      rule = list(conditions = list(list(type = "ParameterIsUnmixed")))
    ),
    list(
      name = "Parameter Set",
      description = "",
      type = "static",
      includeDownstream = TRUE,
      parameterSpecs = list()
    ),
    list(
      name = "Metadata",
      description = "Metadata parameters.",
      type = "rule",
      includeDownstream = FALSE,
      rule = list(conditions = list(list(type = "ParameterIsMetadata")))
    ),
    list(
      name = "Uncompensated",
      description = "Raw fluorescent, mass, or other detector data.",
      type = "rule",
      includeDownstream = FALSE,
      rule = list(conditions = list(list(type = "ParameterIsRawData")))
    )
  )
  
  # Create each parameter set definition
  for (config in paramset_configs) {
    paramset_uuid <- UUIDgenerate(paste0("BAJUUID_paramset_",config$name))
    
    # Build definition based on type
    definition <- list(
      name = config$name,
      description = config$description,
      type = config$type,
      includeDownstream = config$includeDownstream
    )
    
    # Add rule or parameterSpecs depending on type
    if (config$type == "rule") {
      definition$rule <- config$rule
    } else if (config$type == "static") {
      definition$parameterSpecs <- config$parameterSpecs
    }
    
    paramset_definitions[[paramset_uuid]] <- list(
      uuid = paramset_uuid,
      properties = structure(list(), names = character(0)),
      definition = definition,
      parents = list(
        "_analysis" = list(analysis_uuid),
        analysisRoot = list(),
        groups = list(UUID_groupAquired),
        populationDefinitions = list(),
        compoundPopulations = list(),
        populations = list(),
        paramsetDefinitions = list(),
        compoundParameterSets = list(),
        dataSources = list(),
        cytometers = list(),
        platforms = list(),
        reports = list()
      ),
      children = list(
        analysisRoot = list(),
        groups = list(),
        populationDefinitions = list(),
        compoundPopulations = list(),
        populations = list(),
        paramsetDefinitions = list(),
        compoundParameterSets = list("three entries linking groups with compoundParameterSets"),
        dataSources = list(),
        cytometers = list(),
        platforms = list(),
        reports = list()
      ),
      results = structure(list(), names = character(0)),
      definitionVersion = 3L,
      resultsVersion = 3L,
      stableSince = 0L,
      recalcVersion = 0L
    )
  }
  
  return(paramset_definitions)
}

#' Format Transformation Parameter
#'
#' @param value Numeric value to format
#' @param type Type of parameter ("rescale" or "decades")
#' @return Formatted parameter value
#' @keywords internal
format_transformation_parameter <- function(value, type) {
  if (type == "rescale") {
    # For rescale values, we typically want high precision
    return(format(value, digits = 15, scientific = FALSE))
  } else if (type == "decades") {
    # For decades values, we typically want fewer decimal places
    return(format(round(value, 4), nsmall = 4))
  } else {
    return(as.character(value))
  }
}

find_uuid_names <- function(groups, name) {
  pattern <- paste0("^", name, ":")
  names(groups)[grep(pattern, names(groups), ignore.case = TRUE)]
}

validate_workspace <- function(workspace) {
  required_names <- c("schemaVersion", "analysisUUID", "uri", "reports", 
                      "populationDefinitions", "compoundParameterSets", 
                      "compoundPopulations", "paramsetDefinitions", "groups", 
                      "dataSources", "platforms", "cytometers", 
                      "analysisRoot", "populations")
  
  missing <- setdiff(required_names, names(workspace))
  
  if (length(missing) > 0) {
    stop("Workspace is missing required names: ", 
         paste(missing, collapse = ", "))
  }
  
  return(TRUE)
}

#' Create Complete Analysis Root Structure
#' 
#' @param analysis_uuid Analysis UUID
#' @param samples Sample data
#' @param gates Gate data
#' @param groups Group data
#' @return List representing complete analysisRoot structure
#' @keywords internal
create_analysis_root <- function(workspace) {
  # Get sample UUIDs
  
  validate_workspace(workspace)
  # browser()
  sample_uuids <- names(workspace$dataSources)
  analysis_uuid = workspace$analysisUUID
  # Get gate definition UUIDs
  gate_uuids <- names(workspace$populationDefinitions)
  
  # Get group UUIDs
  group_uuids <- names(workspace$groups)
  
  # Get cytometer UUIDs (will be populated later)
  cytometer_uuids <- list()
  
  # Get platform UUIDs (will be populated later)
  platform_uuids <- list()
  
  # Get report UUIDs (will be populated later)
  report_uuids <- list()
  names(workspace$populationDefinitions)
  names(workspace$groups)
  names(workspace$paramsetDefinitions)
  find_uuid_names(workspace$compoundPopulations, "BAJUUID_compoundPopRoot2")
  find_uuid_names(workspace$populationDefinitions, "BAJUUID_compoundPopRoot2")
  find_popDef_uuid(workspace$populationDefinitions, "Ungated")
  analysis_root <- list()
  analysis_root[[analysis_uuid]] <- list(
    uuid = analysis_uuid,
    properties = list(
      acquiredData = list(
        groupId = find_uuid_names(workspace$groups, "BAJUUID_groupAquired"),
        compoundPopulationId = find_uuid_names(workspace$compoundPopulations, "BAJUUID_compoundPopRoot2"),
        populationDefinitionId = find_popDef_uuid(workspace$populationDefinitions, "Ungated")
      ),
      compensationData = list(
        groupId = find_uuid_names(workspace$groups, "BAJUUID_groupCompensation"),
        compoundPopulationId = find_uuid_names(workspace$compoundPopulations, "BAJUUID_compoundPopRoot"), 
        populationDefinitionId = find_popDef_uuid(workspace$populationDefinitions, "Ungated")
      ),
      experimentData = list(
        groupId = find_uuid_names(workspace$groups, "BAJUUID_groupExperimentData"),
        compoundPopulationId = find_uuid_names(workspace$compoundPopulations, "BAJUUID_compoundPopRoot3"),
        populationDefinitionId = find_popDef_uuid(workspace$populationDefinitions, "Ungated")
      ),
      parameterSets = list(
        all = find_uuid_names(workspace$paramsetDefinitions, "BAJUUID_paramset_All"),
        compensated = find_uuid_names(workspace$paramsetDefinitions, "BAJUUID_paramset_Compensated"),
        uncompensated = find_uuid_names(workspace$paramsetDefinitions, "BAJUUID_paramset_Uncompensated"),
        derived = find_uuid_names(workspace$paramsetDefinitions, "BAJUUID_paramset_Derived"),
        scatter = find_uuid_names(workspace$paramsetDefinitions, "BAJUUID_paramset_Scatter"),
        metadata = find_uuid_names(workspace$paramsetDefinitions, "BAJUUID_paramset_Metadata"),
        imageDerived = find_uuid_names(workspace$paramsetDefinitions, "BAJUUID_paramset_Image Derived")
      ),
      workbenchId = "65a0a712-7fd3-424d-9983-9da0f903d4ba", #
      workingDirectory = "/Users/flowjo/workspace",
      analysisWorkingDirectory = paste0("/Users/flowjo/workspace/analysis-", analysis_uuid)
    ),
    definition = list(
      transforms = list(),
      parameterMappings = structure(list(), names = character(0)),  # CHANGED: was list()
      statisticDefinitions = list(
        CNT = list(statType = "Count"),
        FOP = list(statType = "FreqOfParent")
      ),
      samplesTableDefinition = list(columns = list()),
      imageWallSettings = list(palette = list())
    ),
    parents = list(
      `_analysis` = I(c(analysis_uuid)),
      analysisRoot = list(),
      groups = list(),
      populationDefinitions = list(),
      compoundPopulations = list(),
      populations = list(),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(),
      cytometers = list(),
      platforms = list(),
      reports = list()
    ),
    children = list(
      analysisRoot = list(),
      groups = find_uuid_names(workspace$groups, "BAJUUID_groupAquired"),
      populationDefinitions = find_popDef_uuid(workspace$populationDefinitions, "Ungated"),
      compoundPopulations = list(),
      populations = list(),
      paramsetDefinitions = list(),
      compoundParameterSets = list(),
      dataSources = list(names(workspace$dataSources)),  
      cytometers = list(names(workspace$cytometers)),
      platforms = list(names(workspace$platforms[[1]])),
      reports = list(names(workspace$reports))
    ),
    results = structure(list(), names = character(0)),
    definitionVersion = 35L, 
    resultsVersion = 35L,      
    stableSince = 0L,       
    recalcVersion = 0L         
  )
  
  return(analysis_root)
}
