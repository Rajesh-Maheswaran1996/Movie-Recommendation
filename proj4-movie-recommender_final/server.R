## server.R


######################
##### Define Functions
######################


# for System II
get_user_ratings = function(value_list) {
  dat = data.table(MovieID = sapply(strsplit(names(value_list), "_"), 
                                    function(x) ifelse(length(x) > 1, x[[2]], NA)),
                   Rating = unlist(as.character(value_list)))
  dat = dat[!is.null(Rating) & !is.na(MovieID)]
  dat[Rating == " ", Rating := 0]
  dat[, ':=' (MovieID = as.numeric(MovieID), Rating = as.numeric(Rating))]
  dat = dat[Rating > 0]
}


##################
##### Read in Data
##################


####################################
##### Shiny Server Code Starts Below
####################################



shinyServer(function(input, output, session) {
  
  ################################
  ##### System I Server Code Below
  ################################
  
  # System I 
  
  
  #src = "E:/myApp/www/Rlogo.png",
  
  output$results_system_I <- DT::renderDataTable(DT::datatable({
    data2 <- movies
    data2 <- data2 %>%
      select(Title, Image, Median_Rating, Count_of_Ratings) %>%
      arrange(desc(Count_of_Ratings))
    if (input$genre != "All") {
      data2 <- movies[movies$Genres == input$genre,]
      data2 <- data2 %>%
        select(Title, Image, Median_Rating, Count_of_Ratings) %>%
        arrange(desc(Count_of_Ratings))
        
    }
    data2
  }, class = "nowrap hover row-border", escape=FALSE, options = list(dom = 't',
                                  scrollX = TRUE, autoWidth = TRUE)))
  
  
  #############################
  ##### System II UI Code Below
  #############################
  
  
  # show the movies to be rated for system II
  output$ratings <- renderUI({
    num_rows <- 20
    num_movies <- 6 # movies per row
    
    lapply(1:num_rows, function(i) {
      list(fluidRow(lapply(1:num_movies, function(j) {
        list(box(width = 2,
                 div(style = "text-align:center", img(src = movies$image_url[(i - 1) * num_movies + j], height = 150)),
                 div(style = "text-align:center; color: #999999", strong(movies$Title[(i - 1) * num_movies + j])),
                 div(style = "text-align:center; font-size: 150%; color: #f0ad4e;", ratingInput(paste0("select_", movies$MovieID[(i - 1) * num_movies + j]), label = "", dataStop = 5)))) #00c0ef
      })))
    })
  })
  
  
  # Calculate recommendations when the button is clicked for system II
  df2 <- eventReactive(input$btn, {
    withBusyIndicatorServer("btn", { # showing the busy indicator
      # hide the rating container
      useShinyjs()
      jsCode <- "document.querySelector('[data-widget=collapse]').click();"
      runjs(jsCode)
      
      # get the user's rating data
      value_list <- reactiveValuesToList(input)
      value_list = value_list[startsWith(names(value_list),"select_")]
      user_ratings <- get_user_ratings(value_list)
      user_ratings_userId = rep('9999', length(user_ratings$MovieID))
      i = paste0('u', user_ratings_userId )
      j = paste0('m', user_ratings$MovieID)
      x = user_ratings$Rating
      tmp_new_user = data.frame(i , j, x, stringsAsFactors = T)
      
      # training the recommendation model
      set.seed(100)
      
      i = paste0('u', ratings$UserID)
      j = paste0('m', ratings$MovieID)
      x = ratings$Rating
      tmp = data.frame(i, j, x, stringsAsFactors = T)
      tmp = rbind(tmp,tmp_new_user)
      Rmat = sparseMatrix(as.integer(tmp$i), as.integer(tmp$j), x = tmp$x)
      rownames(Rmat) = levels(tmp$i)
      colnames(Rmat) = levels(tmp$j)
      Rmat = new('realRatingMatrix', data = Rmat)
      
      r1 = Recommender(Rmat, method = 'UBCF',parameter = list(normalize = 'center', method = 'Cosine', nn = 25))
      prediction_user = predict(r1, Rmat[6041,], type="ratings")
      final_list = as(prediction_user, "list")
      user_results <- sort(final_list$u9999, decreasing = TRUE)[1:10]
      user_predicted_ids = substring(names(user_results),2)
      
      user_predicted_ids = as.numeric(user_predicted_ids)
      print(user_predicted_ids)
      recom_results <- data.table(Rank = 1:10, 
                                  MovieID = user_predicted_ids, 
                                  Title = full_movies$Title[user_predicted_ids], 
                                  Predicted_rating =  user_predicted_ids)
      
    }) # still busy
    
  }) # clicked on button
  
  
  # display the System II recommendations
  output$results_system_II <- renderUI({
    num_rows <- 2
    num_movies <- 5
    recom_result <- df2()
    
    lapply(1:num_rows, function(i) {
      list(fluidRow(lapply(1:num_movies, function(j) {
        box(width = 2, status = "success", solidHeader = TRUE, title = paste0("Rank ", (i - 1) * num_movies + j),
            
            div(style = "text-align:center", 
                a(img(src = full_movies$image_url[recom_result$MovieID[(i - 1) * num_movies + j]], height = 150))
            ),
            div(style="text-align:center; font-size: 100%", 
                strong(full_movies$Title[recom_result$MovieID[(i - 1) * num_movies + j]])
            )
            
        )        
      }))) # columns
    }) # rows
    
  }) # renderUI function
  
}) # server function

