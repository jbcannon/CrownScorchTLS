# Regenerate man/figures/downloads.png from CRAN download logs.
# Runs weekly via .github/workflows/update-downloads.yaml; can also be rerun
# by hand to refresh the README figure.

daily <- jsonlite::fromJSON(
  "https://cranlogs.r-pkg.org/downloads/daily/2000-01-01:2100-01-01/CrownScorchTLS"
)$downloads[[1]]
daily$day <- as.Date(daily$day)

archive_date <- as.Date("2026-05-01")

weekly <- daily |>
  dplyr::mutate(week = as.Date(cut(day, "week", start.on.monday = FALSE))) |>
  dplyr::group_by(week) |>
  dplyr::summarize(downloads = sum(downloads), .groups = "drop")

p <- ggplot2::ggplot(weekly, ggplot2::aes(week, downloads)) +
  ggplot2::geom_col(fill = "#2a78d6", width = 6) +
  ggplot2::geom_vline(xintercept = as.numeric(archive_date),
                       linetype = "dashed", color = "#eb6834") +
  ggplot2::annotate("text", x = archive_date, y = max(weekly$downloads) * 1.05,
                     label = "Archived", color = "#eb6834", size = 3, hjust = 1) +
  ggplot2::labs(x = NULL, y = "Weekly downloads",
                title = "CrownScorchTLS CRAN downloads") +
  ggplot2::theme_bw() +
  ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
                 panel.grid.major.x = ggplot2::element_blank())

ggplot2::ggsave("man/figures/downloads.png", p, width = 7, height = 3, dpi = 200)
