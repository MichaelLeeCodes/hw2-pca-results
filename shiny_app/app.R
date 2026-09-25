library(shiny)
library(jpeg)
library(png)

source("R/compress_image.R")

## ---- helpers ---------------------------------------------------------

read_image_any <- function(path, orig_name) {
  ext <- tolower(tools::file_ext(orig_name))
  arr <- if (ext %in% c("jpg", "jpeg")) {
    jpeg::readJPEG(path)
  } else if (ext == "png") {
    png::readPNG(path)
  } else {
    stop("Please upload a .jpg or .png file.")
  }

  if (length(dim(arr)) == 2) {
    arr <- array(arr, dim = c(dim(arr), 1))
  }
  # drop an alpha channel if present
  if (dim(arr)[3] == 4) arr <- arr[, , 1:3, drop = FALSE]
  if (dim(arr)[3] == 2) arr <- arr[, , 1, drop = FALSE]
  arr
}

## rank-k approximation of every channel of an H x W x C image array
compress_array <- function(arr, k) {
  d <- dim(arr)
  out <- array(0, dim = d)
  total_error <- 0
  for (ch in seq_len(d[3])) {
    res <- compress_image(arr[, , ch], k)
    out[, , ch] <- pmin(pmax(res$approx, 0), 1)
    total_error <- total_error + res$error^2
  }
  list(image = out, error = sqrt(total_error))
}

write_temp_png <- function(arr) {
  f <- tempfile(fileext = ".png")
  png::writePNG(arr, f)
  f
}

## ---- UI ----------------------------------------------------------------

ui <- fluidPage(
  titlePanel("PCA Image Compressor"),
  sidebarLayout(
    sidebarPanel(
      width = 3,
      fileInput("upload", "1. Upload an image (JPG or PNG)", accept = c(".jpg", ".jpeg", ".png")),
      actionLink("use_demo", "...or try the demo image"),
      tags$hr(),
      sliderInput("k", "2. Compression level (k)", min = 1, max = 10, value = 5, step = 1),
      tags$hr(),
      h5("Compression stats"),
      tableOutput("stats")
    ),
    mainPanel(
      width = 9,
      fluidRow(
        column(6, h4("Original"), imageOutput("original_img", height = "auto")),
        column(6, h4("Compressed"), imageOutput("compressed_img", height = "auto"))
      ),
      tags$p(
        style = "color:#666; margin-top: 1.5rem;",
        "Each color channel of the image is approximated separately with a rank-k PCA ",
        "approximation, following X = Z U' (see Homework 2). Lower k = smaller / blurrier; ",
        "higher k = closer to the original."
      )
    )
  )
)

## ---- server --------------------------------------------------------------

server <- function(input, output, session) {

  img_data <- reactiveVal(NULL)
  # tracks the k to actually use; set directly (no client round-trip) so
  # renders never briefly use a stale slider value right after a new image loads
  k_val <- reactiveVal(5)

  observeEvent(input$k, {
    k_val(input$k)
  }, ignoreInit = TRUE)

  load_image <- function(path, name) {
    arr <- read_image_any(path, name)
    max_k <- min(dim(arr)[1], dim(arr)[2])
    default_k <- max(1, round(max_k * 0.1))
    updateSliderInput(session, "k", max = max_k, value = default_k)
    k_val(default_k)
    img_data(arr)
  }

  observeEvent(input$upload, {
    req(input$upload)
    load_image(input$upload$datapath, input$upload$name)
  })

  observeEvent(input$use_demo, {
    load_image("www/demo.png", "demo.png")
  })

  # start with the demo image loaded
  observeEvent(TRUE, {
    load_image("www/demo.png", "demo.png")
  }, once = TRUE)

  compressed <- reactive({
    req(img_data())
    k <- min(k_val(), min(dim(img_data())[1], dim(img_data())[2]))
    compress_array(img_data(), k)
  })

  output$original_img <- renderImage({
    req(img_data())
    path <- write_temp_png(img_data())
    d <- dim(img_data())
    list(src = path, contentType = "image/png", width = "100%",
         alt = "Original image")
  }, deleteFile = TRUE)

  output$compressed_img <- renderImage({
    req(compressed())
    path <- write_temp_png(compressed()$image)
    list(src = path, contentType = "image/png", width = "100%",
         alt = "Compressed image")
  }, deleteFile = TRUE)

  output$stats <- renderTable({
    req(img_data(), compressed())
    d <- dim(img_data())
    n <- d[1]; p <- d[2]; ch <- d[3]
    k <- min(k_val(), min(n, p))
    original_numbers <- n * p * ch
    compressed_numbers <- k * (n + p) * ch
    data.frame(
      Metric = c("Dimensions", "Channels", "k used", "Original numbers", "Compressed numbers", "Size reduction", "Frobenius error"),
      Value = c(
        paste0(n, " x ", p),
        as.character(ch),
        as.character(k),
        format(original_numbers, big.mark = ","),
        format(compressed_numbers, big.mark = ","),
        paste0(round(100 * (1 - compressed_numbers / original_numbers), 1), "%"),
        round(compressed()$error, 3)
      )
    )
  }, colnames = FALSE)
}

shinyApp(ui, server)
