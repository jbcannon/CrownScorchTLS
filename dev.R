# Regenerate man/figures/downloads.png from CRAN download logs.
# Run automatically every week by .github/workflows/update-downloads.yaml;
# can also be rerun by hand (needs jsonlite, dplyr, ggplot2, scales).

daily <- jsonlite::fromJSON(
  "https://cranlogs.r-pkg.org/downloads/daily/2000-01-01:2100-01-01/CrownScorchTLS"
)$downloads[[1]]
stopifnot(is.data.frame(daily), nrow(daily) > 0)
daily$day <- as.Date(daily$day)

# Archived when its dependency lidR was archived; restored with 0.1.2.
archive_date    <- as.Date("2026-05-01")
reinstated_date <- as.Date("2026-09-17")

# cranlogs omits days with no downloads, so fill every week through the
# current one with zeros. Weeks start on Sunday.
week_start <- function(x) as.Date(cut(x, "week", start.on.monday = FALSE))
data_through <- max(daily$day)

weekly <- daily |>
  dplyr::mutate(week = week_start(day)) |>
  dplyr::group_by(week) |>
  dplyr::summarize(downloads = sum(downloads), .groups = "drop")

weekly <- data.frame(
  week = seq(min(weekly$week), week_start(max(Sys.Date(), data_through)), by = "7 days")
) |>
  dplyr::left_join(weekly, by = "week") |>
  dplyr::mutate(
    downloads = dplyr::coalesce(downloads, 0L),
    partial   = week + 6 > data_through,  # week not yet fully reported
    mid       = week + 3
  )

# Chart chrome (light surface); bars in the crown-hull green used in the
# package figures, text in neutral ink tones.
surface <- "#fcfcfb"; ink <- "#0b0b0b"; ink2 <- "#52514e"; muted <- "#898781"
grid <- "#e1e0d9"; axis <- "#c3c2b7"; green <- "#588824"

peak <- weekly[which.max(weekly$downloads), ]
ymax <- max(weekly$downloads)

p <- ggplot2::ggplot(weekly, ggplot2::aes(mid, downloads)) +
  # the stretch when the package was off CRAN
  ggplot2::annotate("rect", xmin = archive_date, xmax = reinstated_date,
                    ymin = 0, ymax = Inf, fill = grid, alpha = 0.35) +
  ggplot2::geom_col(ggplot2::aes(alpha = partial), fill = green, width = 5) +
  ggplot2::scale_alpha_manual(values = c(`FALSE` = 1, `TRUE` = 0.4), guide = "none") +
  ggplot2::geom_vline(xintercept = archive_date, color = muted, linewidth = 0.4) +
  ggplot2::geom_vline(xintercept = reinstated_date, color = muted, linewidth = 0.4) +
  ggplot2::annotate("text", x = archive_date + 4, y = ymax * 1.18,
                    label = "Archived from CRAN", color = ink2, size = 3, hjust = 0) +
  ggplot2::annotate("text", x = reinstated_date - 4, y = ymax * 1.18,
                    label = "Reinstated", color = ink2, size = 3, hjust = 1) +
  ggplot2::annotate("text", x = peak$mid, y = peak$downloads + ymax * 0.05,
                    label = format(peak$downloads, big.mark = ","),
                    color = ink2, size = 3, vjust = 0) +
  # one tick per month; the year is printed under the first tick and each January
  ggplot2::scale_x_date(date_breaks = "1 month",
                        labels = scales::label_date_short(),
                        expand = ggplot2::expansion(mult = 0.02)) +
  ggplot2::scale_y_continuous(labels = scales::label_comma(),
                              expand = ggplot2::expansion(mult = c(0, 0.08))) +
  ggplot2::coord_cartesian(ylim = c(0, ymax * 1.2), clip = "off") +
  ggplot2::labs(
    x = NULL, y = NULL,
    title = "CRAN downloads per week",
    subtitle = paste0(format(sum(daily$downloads), big.mark = ","),
                      " downloads since ", format(min(daily$day), "%b %Y")),
    caption = paste0("Lighter bar = week in progress. Data through ",
                     format(data_through, "%b %d, %Y"), " via cranlogs.")
  ) +
  ggplot2::theme_minimal(base_size = 11) +
  ggplot2::theme(
    plot.background   = ggplot2::element_rect(fill = surface, color = NA),
    panel.background  = ggplot2::element_rect(fill = surface, color = NA),
    panel.grid.major.y = ggplot2::element_line(color = grid, linewidth = 0.3),
    panel.grid.major.x = ggplot2::element_blank(),
    panel.grid.minor   = ggplot2::element_blank(),
    axis.line.x  = ggplot2::element_line(color = axis, linewidth = 0.4),
    axis.ticks.x = ggplot2::element_line(color = axis, linewidth = 0.4),
    axis.text    = ggplot2::element_text(color = muted),
    plot.title    = ggplot2::element_text(color = ink, face = "bold", size = 14),
    plot.subtitle = ggplot2::element_text(color = ink2, margin = ggplot2::margin(b = 12)),
    plot.caption  = ggplot2::element_text(color = muted, size = 8, hjust = 0,
                                          margin = ggplot2::margin(t = 10)),
    plot.caption.position = "plot",
    plot.title.position   = "plot",
    plot.margin = ggplot2::margin(16, 20, 12, 16)
  )

ggplot2::ggsave("man/figures/downloads.png", p, width = 7, height = 3.4, dpi = 200,
                bg = surface)
