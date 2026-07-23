#!/usr/bin/env Rscript
# Script to extract NK1_1+/- populations within Singlets2 gate
# with percentages based on the FlowJo workspace

library(CyFj11)

# Path to FlowJo workspace
ws_path <- "flowjo_export_tests/test14/test14_export.flowjo"

cat("================================================================================\n")
cat("Extract NK1_1+/- Populations within Singlets2 Gate\n")
cat("================================================================================\n\n")

# Read the FlowJo workspace
cat("Reading FlowJo workspace:", ws_path, "\n")
ws <- read_flowjo11_workspace(ws_path)

# Build a map of population definition UUID -> name
get_def_name <- function(uuid) {
  def <- ws$populationDefinitions[[uuid]]
  if (!is.null(def) && !is.null(def$definition$name)) {
    return(paste(def$definition$name, collapse = " "))
  }
  return(NA_character_)
}

# Build a map of population UUID -> definition UUID
get_pop_def_uuid <- function(pop_uuid) {
  if (is.null(pop_uuid) || length(pop_uuid) == 0) return(NA_character_)
  pop <- ws$populations[[pop_uuid]]
  if (!is.null(pop) && !is.null(pop$parents$populationDefinitions)) {
    def_uuids <- pop$parents$populationDefinitions
    if (is.list(def_uuids)) {
      return(def_uuids[[1]])
    } else {
      return(def_uuids[1])
    }
  }
  return(NA_character_)
}

# Get parent population UUIDs for a given population
get_parent_pops <- function(pop_uuid) {
  pop <- ws$populations[[pop_uuid]]
  if (!is.null(pop) && !is.null(pop$parents$populations)) {
    result <- pop$parents$populations
    # Convert list to character vector if needed
    if (is.list(result)) {
      return(unlist(result))
    }
    return(result)
  }
  return(character(0))
}

# Find the population definition UUID for a given name
find_def_by_name <- function(target_name) {
  for (uuid in names(ws$populationDefinitions)) {
    name <- get_def_name(uuid)
    if (!is.na(name) && name == target_name) {
      return(uuid)
    }
  }
  return(NA_character_)
}

cat("\n=== Population Definitions ===\n")
for (uuid in names(ws$populationDefinitions)) {
  name <- get_def_name(uuid)
  if (!is.na(name) && grepl("NK1|Singlets", name, ignore.case = TRUE)) {
    cat("  ", name, ":", uuid, "\n")
  }
}

# Find Singlets2 population definition
singlets2_def_uuid <- find_def_by_name("Singlets2")
nk1_plus_def_uuid <- find_def_by_name("NK1_1+")
nk1_minus_def_uuid <- find_def_by_name("NK1_1-")

cat("\n=== Looking for NK1 populations within Singlets2 ===\n")

# Find all populations and their hierarchy
cat("\nPopulation Hierarchy:\n")
cat("---------------------\n")

# Build reverse map: definition UUID -> population UUIDs
def_to_pops <- list()
for (pop_uuid in names(ws$populations)) {
  def_uuid <- get_pop_def_uuid(pop_uuid)
  if (!is.na(def_uuid)) {
    if (is.null(def_to_pops[[def_uuid]])) {
      def_to_pops[[def_uuid]] <- character(0)
    }
    def_to_pops[[def_uuid]] <- c(def_to_pops[[def_uuid]], pop_uuid)
  }
}

# Print population info for relevant definitions
relevant_names <- c("Singlets", "Singlets2", "NK1_1+", "NK1_1-")
for (name in relevant_names) {
  def_uuid <- find_def_by_name(name)
  if (!is.na(def_uuid) && !is.null(def_to_pops[[def_uuid]])) {
    for (pop_uuid in def_to_pops[[def_uuid]]) {
      pop <- ws$populations[[pop_uuid]]
      count <- pop$results$count
      fop <- pop$results$statistics$FOP
      parents <- get_parent_pops(pop_uuid)
      parent_names <- sapply(parents, function(p) {
        p_def <- get_pop_def_uuid(p)
        get_def_name(p_def)
      })
      cat(sprintf("  %s: count=%s (%s%% of parent), parents=[%s]\n",
                  name, count, fop, paste(parent_names, collapse=", ")))
    }
  }
}

# Now find NK1_1+ and NK1_1- that are descendants of Singlets2
cat("\n=== NK1_1+/- within Singlets2 ===\n")

# Find Singlets2 populations
singlets2_pops <- def_to_pops[[singlets2_def_uuid]]

# Function to check if a population is a descendant of Singlets2
is_descendant_of_singlets2 <- function(pop_uuid, visited = NULL) {
  if (is.null(visited)) visited <- character(0)
  if (pop_uuid %in% visited) return(FALSE)
  visited <- c(visited, pop_uuid)

  parents <- get_parent_pops(pop_uuid)
  if (length(parents) == 0) return(FALSE)

  for (parent_uuid in parents) {
    parent_def_uuid <- get_pop_def_uuid(parent_uuid)
    parent_def_name <- get_def_name(parent_def_uuid)
    if (parent_def_name == "Singlets2") return(TRUE)
    if (is_descendant_of_singlets2(parent_uuid, visited)) return(TRUE)
  }
  return(FALSE)
}

# Helper to print parent chain
print_parent_chain <- function(pop_uuid, indent = "      ") {
  parents <- get_parent_pops(pop_uuid)
  visited <- character(0)
  while (length(parents) > 0) {
    parent_uuid <- parents[1]
    if (parent_uuid %in% visited) break
    visited <- c(visited, parent_uuid)
    parent_def_uuid <- get_pop_def_uuid(parent_uuid)
    parent_name <- get_def_name(parent_def_uuid)
    if (is.na(parent_name)) {
      parents <- get_parent_pops(parent_uuid)
      next
    }
    parent_pop <- ws$populations[[parent_uuid]]
    parent_count <- parent_pop$results$count
    parent_fop <- parent_pop$results$statistics$FOP
    cat(sprintf("%s<- %s (count=%s, %s%%)\n", indent, parent_name, parent_count, parent_fop))
    parents <- get_parent_pops(parent_uuid)
  }
}

# Find NK1_1+ populations that are within Singlets2
cat("\nNK1_1+ populations:\n")
nk1_plus_pops <- def_to_pops[[nk1_plus_def_uuid]]
for (pop_uuid in nk1_plus_pops) {
  pop <- ws$populations[[pop_uuid]]
  count <- pop$results$count
  fop <- pop$results$statistics$FOP

  in_singlets2 <- is_descendant_of_singlets2(pop_uuid)
  cat(sprintf("  UUID: %s\n", pop_uuid))
  cat(sprintf("    Count: %s (%s%% of parent)\n", count, fop))
  cat(sprintf("    Within Singlets2: %s\n", ifelse(in_singlets2, "YES", "no")))

  # Print full parent chain
  print_parent_chain(pop_uuid)
}

cat("\nNK1_1- populations:\n")
nk1_minus_pops <- def_to_pops[[nk1_minus_def_uuid]]
for (pop_uuid in nk1_minus_pops) {
  pop <- ws$populations[[pop_uuid]]
  count <- pop$results$count
  fop <- pop$results$statistics$FOP

  in_singlets2 <- is_descendant_of_singlets2(pop_uuid)
  cat(sprintf("  UUID: %s\n", pop_uuid))
  cat(sprintf("    Count: %s (%s%% of parent)\n", count, fop))
  cat(sprintf("    Within Singlets2: %s\n", ifelse(in_singlets2, "YES", "no")))

  # Print full parent chain
  print_parent_chain(pop_uuid)
}

# Calculate percentages relative to Singlets2
cat("\n=== Summary: NK1_1+/- within Singlets2 Gate ===\n")
cat("===============================================================================\n\n")

# Get Singlets2 count
singlets2_pop_uuid <- def_to_pops[[singlets2_def_uuid]][1]
singlets2_count <- ws$populations[[singlets2_pop_uuid]]$results$count

cat(sprintf("Singlets2 total count: %s\n\n", singlets2_count))

# NK1_1+ within Singlets2
nk1_plus_count <- ws$populations[[nk1_plus_pops[1]]]$results$count
nk1_plus_pct_of_singlets2 <- 100 * nk1_plus_count / singlets2_count
nk1_plus_pct_of_total <- 100 * nk1_plus_count / ws$populations[[def_to_pops[[find_def_by_name("Ungated")]][1]]]$results$count

cat(sprintf("NK1_1+ within Singlets2:\n"))
cat(sprintf("  Count: %d\n", nk1_plus_count))
cat(sprintf("  %% of Singlets2: %.2f%%\n", nk1_plus_pct_of_singlets2))
cat(sprintf("  %% of Total (Ungated): %.2f%%\n\n", nk1_plus_pct_of_total))

# NK1_1- within Singlets2
nk1_minus_count <- ws$populations[[nk1_minus_pops[1]]]$results$count
nk1_minus_pct_of_singlets2 <- 100 * nk1_minus_count / singlets2_count
nk1_minus_pct_of_total <- 100 * nk1_minus_count / ws$populations[[def_to_pops[[find_def_by_name("Ungated")]][1]]]$results$count

cat(sprintf("NK1_1- within Singlets2:\n"))
cat(sprintf("  Count: %d\n", nk1_minus_count))
cat(sprintf("  %% of Singlets2: %.2f%%\n", nk1_minus_pct_of_singlets2))
cat(sprintf("  %% of Total (Ungated): %.2f%%\n\n", nk1_minus_pct_of_total))

# Gate information for Singlets2
cat("Singlets2 Gate (2D gate for NK1_1+/- populations):\n")
singlets2_def <- ws$populationDefinitions[[singlets2_def_uuid]]
if (!is.null(singlets2_def$definition)) {
  def <- singlets2_def$definition

  # Gate definition
  if (!is.null(def$gateDefinition)) {
    gate_def <- def$gateDefinition
    cat(sprintf("  Gate Type: %s\n", gate_def$type))

    # Get parameter names
    x_param <- gate_def$xParameter
    y_param <- gate_def$yParameter
    if (!is.null(x_param)) cat(sprintf("  X Parameter: %s\n", x_param))
    if (!is.null(y_param)) cat(sprintf("  Y Parameter: %s\n", y_param))

    # Rectangle gate coordinates
    if (gate_def$type == "rectangle") {
      if (!is.null(gate_def$xMin)) cat(sprintf("  xMin: %s\n", gate_def$xMin))
      if (!is.null(gate_def$x$max)) cat(sprintf("  xMax: %s\n", gate_def$x$max))
      if (!is.null(gate_def$yMin)) cat(sprintf("  yMin: %s\n", gate_def$yMin))
      if (!is.null(gate_def$y$max)) cat(sprintf("  yMax: %s\n", gate_def$y$max))
    }

    # Polygon gate vertices
    if (!is.null(gate_def$xVertices)) {
      cat(sprintf("  xVertices: %s\n", paste(gate_def$xVertices, collapse=", ")))
    }
    if (!is.null(gate_def$yVertices)) {
      cat(sprintf("  yVertices: %s\n", paste(gate_def$yVertices, collapse=", ")))
    }
  }
}

# Check for 2D gate in compound populations
cat("\nLooking for 2D gate definition in compound populations...\n")
for (uuid in names(ws$compoundPopulations)) {
  cp <- ws$compoundPopulations[[uuid]]
  if (!is.null(cp$properties$name)) {
    name <- cp$properties$name
    if (grepl("Singlets2", name, ignore.case = TRUE)) {
      cat(sprintf("  Found compound population: %s (UUID: %s)\n", name, uuid))
    }
  }
}

cat("\n================================================================================\n")
cat("Done.\n")
