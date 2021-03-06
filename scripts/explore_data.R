# author: Diana lin
# date: 2020-03-05

# Description of the script and the command-line arguments
"This script conducts exploratory data analysis with the processed data. The plots are saved to the specified directory.

Usage: explore_data.R --processed_data=<processed_data> --path_to_images=<path> --path_to_data=<path>" -> doc

# load packages
suppressMessages(library(tidyverse))
suppressMessages(library(docopt))
suppressMessages(library(corrplot))
suppressMessages(library(glue))
suppressMessages(library(scales))
suppressMessages(library(here))
suppressMessages(library(reshape2))

# Read in the command line arguments
option <- docopt(doc)

# Main function
main <- function(processed_data, image_path,data_path) {
  
  # check if command-line files exist: the processed data
  if (!file.exists(processed_data)) {
    stop(glue("The file {processed_data} does not exist!"))
  }
  
  # if the path given includes the root directory, then, rewrite path to equal to 'relative' directory path from the root
  # this way the use of here can be used in the rest of the script
  root <- paste0(here(),"/")
  if (str_detect(image_path,root)) {
    image_path <- paste0(str_remove(image_path,root))
  }
  
  if (str_detect(data_path,root)) {
    data_path <- paste0(str_remove(data_path,root))
  }
  
  # if the directory does not exist, create the directory with parent directories
  if (!dir.exists(here(image_path))) {
    dir.create(here(image_path), recursive = TRUE)
  }
  if (!dir.exists(here(data_path))) {
    dir.create(here(data_path), recursive = TRUE)
  }
  # read in the processed data, each column corresponding to a type
  processed_data_in <- read_csv(processed_data,
           col_types = cols(
             age = col_integer(),
             sex = readr::col_factor(),
             bmi = col_double(),
             children = col_integer(),
             smoker = readr::col_factor(),
             region = readr::col_factor(),
             sex_dummy = col_integer(),
             smoker_dummy = col_integer(),
             southeast = col_integer(),
             southwest = col_integer(),
             northwest = col_integer(),
             northeast = col_integer(),
             charges = col_double(),
             age_range = readr::col_factor())
  )
  
  # calculate the correlation for the processed data
  costs_correlations <- processed_data_in %>%
    select(-sex, -smoker, -region, -age_range) %>% # remove the columns that are not dummy variables %>%
    rename(sex = sex_dummy, smoker = smoker_dummy) %>%
    cor()
  # round the values to 2 decimal places
  costs_correlations <- round(costs_correlations,2)
  saveRDS(costs_correlations, paste0(here(data_path), "/correlation.rds"))
  # save and plot the corrplot
  # png(filename = paste(image_path,"corrplot.png",sep = "/"))
  # corrplot(costs_correlations,
  #          type = "upper",
  #          method = "color",
  #          tl.srt=45,
  #          addCoef.col = "black",
  #          diag = FALSE)
  # print("Saving image")
  # dev.off()
  costs_correlations[lower.tri(costs_correlations)]<- NA
  melted_costs <- melt(costs_correlations, na.rm = TRUE)
  melted_costs <- filter(melted_costs, Var1 != Var2)
  melted_costs %>%
    ggplot(aes(Var2, Var1, fill = value)) +
    geom_tile(color = "white") +
    # theme_minimal() +
    theme(axis.text.x = element_text(
      angle = 45,
      vjust = 1,
      size = 12,
      hjust = 1
    ),
    axis.text.y = element_text(size =12)) +
    xlab("") +
    ylab("") +
    ggtitle("Correlation Between All Variables")+ 
    scale_fill_gradient2(
      low = "blue",
      high = "red",
      mid = "white",
      midpoint = 0,
      limit = c(-1, 1),
      space = "Lab",
      name = ""
    ) + geom_text(aes(Var2, Var1, label = value), color = "black", size = 4)+
    do.call(paste0("theme","_minimal"),list()) + theme(axis.text.x = element_text(
      angle = 45,
      vjust = 1,
      size = 12,
      hjust = 1
    ),
    axis.text.y = element_text(size =12), text = element_text(family = "HelveticaNeue"))+
    ggsave(filename = paste(here(image_path),"corrplot.png",sep = "/"), device = "png")
  
  
  # filter the processed_data for the ones without dummy variables to resemble 'raw data'
  raw_data_in <- processed_data_in %>%
    select(c(age, sex, bmi, children, smoker, region, charges, age_range))

  # plot and save faceted plot
  ggplot(raw_data_in, aes(x=bmi, y=charges, colour = smoker)) + 
    geom_point() +
    scale_color_manual(values = c("#E7B800" , "#52854C"))+
    theme_bw() +
    facet_grid(sex ~ region, labeller = label_both) +
    labs(x = 'BMI',
         y = 'Charges (USD)') +
    scale_y_continuous(labels = dollar) +
    ggsave(filename = paste(here(image_path),"facet.png",sep = "/"), device = "png")
  
  # plot age histogram
  raw_data_in %>% 
    ggplot(aes(x=age_range,fill=sex)) +
    geom_bar(position = "dodge") +
    xlab("Age Ranges") +
    ylab("Count")+
    theme_bw() +
    theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())+
    ggsave(filename = paste(here(image_path), "age_histogram.png", sep = "/"), device = "png")
  
  # plot stacked bar chart
  raw_data_in %>%
    group_by(sex, region) %>%
    summarize(count = n()) %>%
    ggplot(aes(fill = sex, x = region, y=count)) +
    geom_bar(position="stack", stat="identity") +
    geom_text(data = raw_data_in %>%
                group_by(sex, region) %>%
                summarize(count = n()) %>%
                group_by(region) %>% 
                mutate(sum = sum(count) , percent = round(count/sum*100,1)) %>%
                filter(sex == "female") , mapping = aes(fill= NULL, x = region, y = sum + 20, label=paste( percent,"% female", sep="")))+
    theme_bw() +
    theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())+
    ggsave(filename = paste(here(image_path), "region_barchart.png", sep = "/"), device = "png")
  
  # print successful message
  print(glue("The four plots have been successfully saved in the {image_path} directory."))
}

# call main function 
main(option$processed_data, option$path_to_images, option$path_to_data)