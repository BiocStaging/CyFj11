library(CyFj11)
library(ggcyto)

ws_path <- "flowjo_export_tests/test14/test14_export.flowjo"
ws <- read_flowjo11_workspace(ws_path)
gs <- fj11_to_gatingset(ws, group_name = 1,path = "flowjo_export_tests/test14/output/")
gs = gs[[1]]
# Rename to avoid t() conflict
trans_fn  <- gh_get_transformations(gs[[1]])[["Comp-PE-A"]]
inv_fn    <- gh_get_transformations(gs[[1]], inverse = TRUE)[["Comp-PE-A"]]
pa        <- attributes(trans_fn)$parameters
# Define breaks in raw fluorescence space
raw_breaks <- c(-1000, -500, -10, 0,  500, 1000, 5000, 10000, 50000, 100000)
labels_breaks <- c(bquote(-10^.(3)), bquote(), bquote(), bquote(0),  bquote(), bquote(10^.(3)),bquote(), bquote(10^.(4)), bquote(), bquote(10^.(5)))
raw_minor_breaks <- c(
  # negative/linear region
  seq(-1000,0,100),
  # log region: 2-9 between each decade
  200, 300, 400, 500, 600, 700, 800, 900,
  2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000,
  20000, 30000, 40000, 50000, 60000, 70000, 80000, 90000
)
biexp_breaks <- sapply(raw_breaks, trans_fn)

p <- ggcyto(gs[[1]], 
            aes(x = `Comp-PE-A`, y = `FSC-A`),
            subset = "Singlets2") +
  geom_hex(bins = 256) +
  scale_fill_gradientn(
    colours = c("blue4","blue","cyan","green","yellow","orange","red"),
    trans   = "sqrt",
    guide   = "none"
  ) +
  geom_gate(c("NK1_1+", "NK1_1-")) +
  geom_stats(
    gate   = c("NK1_1+", "NK1_1-"),
    type   = c("gate", "percent"),
    size   = 7,
    color  = "black",
    adjust = c(0.5, 1.2)
  ) +
  scale_x_flowjo_biexp(
    maxValue   = pa$maxValue,
    widthBasis = pa$widthBasis,
    pos        = pa$pos,
    limits = c(-700, 262144),
    breaks = trans_fn(raw_breaks),
    minor_breaks = trans_fn(raw_minor_breaks),
    labels     = labels_breaks,
    guide        = guide_axis(minor.ticks = TRUE) 
  ) +
  scale_y_continuous(
    labels = function(x) paste0(x / 1000, "k")
  ) +
  labs(x = "Comp-PE-A :: NK1_1", y = "FSC-A") +
  theme_classic(base_size = 16)  +
  theme(
    strip.text       = element_blank(),
    strip.background = element_blank(),
    plot.title       = element_blank(),
    panel.border     = element_rect(colour = "black", fill = NA, linewidth = 0.8),
    axis.line        = element_blank(),
    axis.ticks.length.x       = unit(6, "pt"),   # <-- major ticks
    axis.minor.ticks.length.x = rel(0.5),        # <-- minor ticks shorter
    axis.ticks.length.y       = unit(6, "pt"),
    axis.minor.ticks.length.y = rel(0.5)
    
  ) +
  coord_cartesian(
    xlim = trans_fn(c(-700, 262144)),   # raw space, no t() conflict now
    ylim = c(0, 250000)
  )

p



ggsave("flowjo_export_tests/test14/R_NK1_1_gate.png", 
       plot   = p, 
       width  = 6,      # inches
       height = 6,      # inches
       dpi    = 600)    # resolution

print(p)

