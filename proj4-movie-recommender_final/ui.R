## ui.R
library(shiny)
library(shinydashboard)
library(recommenderlab)
library(data.table)
library(ShinyRatingInput)
library(shinyjs)
library(dplyr)
library(Matrix)
library(reshape2)
library(DT)
library(rsconnect) # for deploying to shinyapps.io
library(shinyBS)

source('functions/helpers.R')

shinyUI(
    dashboardPage(
      
          ##########################
          ##### App Header and Color
          ##########################
          
          skin = "purple",
          dashboardHeader(title = "Movie Recommender"),
          
          #############
          ##### Sidebar
          #############
          
          dashboardSidebar(
            column(12,
                   h6(strong("Created by:")),
                   h6("Preethal Joseph, pjoseph3"),
                   h6("Rajesh Maheswaran, rajeshm2"),
                   h6("Tessa Hagen, tessah2")
            )
          ),
          
          ####################################
          ##### Main Dashboard Body Code Below
          ####################################
          
          dashboardBody(includeCSS("css/movies.css"),
              # set formatting for app title          
              fluidRow(
                column(12, align="center",
                       tags$head(tags$style(HTML('
                        h2 {
                        font-family: "Rockwell", Times, "Times New Roman", serif;
                        font-weight: bold;
                        font-size: 44px;
                        }
                        '))),
                       h2(strong("MOVIE RECOMMENDER")),
                       br()
                       )
              ),
              # Instructions Box
              fluidRow(
                useShinyjs(),
                box(
                  width = 12, solidHeader = TRUE,
                  #title = "Instructions:",
                  h4("Fill out the forms in System I or System II below to receive movie recommendations."),
                )
              ),
              
              ############################
              ##### System I UI Code Below
              ############################
              
              fluidRow(
                column(12, 
                   h3(strong("SYSTEM I")),
                   h4("Receive recommendations tailored to your favorite movie genre.  By default, results are sorted by Popularity (count of ratings)."))
              ),
              # System I Box
              fluidRow(
                useShinyjs(),
                box(
                  width = 12, status = "primary", solidHeader = TRUE,
                  title = "Discover movies you might like based on your favorite genre:",
                  br(),
                  selectInput("genre", h4(strong("What is your favorite movie genre?")), 
                              choices = c("All", 
                                          unique(as.character(sort(movies$Genres))))), # fetches unique list of Genres
                  br()
                  #############################################################################################
                  # System I genre-based recommendations are returned to the UI here via "results_system_I" from server.R
                  #############################################################################################
                  , h4(strong("Recommendations:"))
                  , h6("Results may take a moment to load.")
                  , br()
                  , DT::dataTableOutput("results_system_I")
                  
                )
              ),
              # seperate System I Section from System II Section
              fluidRow(
                column(12, align="center",
                  tags$head(tags$style(HTML('
                        h1 {
                        font-weight: bold;
                        font-size: 48px;
                        }
                        '))),
                  h1(strong("OR")),
                  br()
                ),
                
                
                #############################
                ##### System II UI Code Below
                #############################
                
                
                column(12, 
                  h3(strong("SYSTEM II")),
                  h4("Receive recommendations based on your movie ratings."))
                ),
              # System II Box for Ratings
              fluidRow(
                  box(width = 12, title = "Step 1: Rate as many movies as possible:", status = "primary", solidHeader = TRUE, collapsible = TRUE,
                      div(class = "rateitems",
                          uiOutput('ratings')
                      )
                  )
                ),
              # System II Box for Results
              fluidRow(
                  useShinyjs(),
                  box(
                    width = 12, status = "primary", solidHeader = TRUE,
                    title = "Step 2: Discover movies you might like based on your ratings:",
                    br(),
                    withBusyIndicatorUI(
                      actionButton("btn", "Click here to get your recommendations", class = "btn-warning")
                    ),
                    h6("Results may take a moment to load."),
                    br(),
                    #############################################################################################
                    # System II recommendations are returned to the UI here via "results_system_II" from server.R
                    #############################################################################################
                    tableOutput("results_system_II"),
                    br(),
                    h4("After running System II once, the session must be reset to try again.  Click the button below to refresh the page:"), 
                    br(),
                    tags$a(href="javascript:history.go(0)", 
                           popify(tags$i(class="fa fa-refresh fa-5x"),
                                  title = "Reload", 
                                  content = "Click here to restart the Shiny session",
                                  placement = "right"))
                  )
               )
          )
    )
) 