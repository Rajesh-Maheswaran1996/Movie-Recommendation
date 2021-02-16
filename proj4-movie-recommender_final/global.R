library(data.table)

# read in movies and image data
myurl = "https://liangfgithub.github.io/MovieData/"
full_movies = readLines(paste0(myurl, 'movies.dat?raw=true'))
full_movies = strsplit(full_movies, split = "::", fixed = TRUE, useBytes = TRUE)
full_movies = matrix(unlist(full_movies), ncol = 3, byrow = TRUE)
full_movies = data.frame(full_movies, stringsAsFactors = FALSE)
colnames(full_movies) = c('MovieID', 'Title', 'Genres')
full_movies$MovieID = as.integer(full_movies$MovieID)
full_movies$Title = iconv(full_movies$Title, "latin1", "UTF-8")
full_movies$Year = as.numeric(unlist(
  lapply(full_movies$Title, function(x) substr(x, nchar(x)-4, nchar(x)-1))))

small_image_url = "https://liangfgithub.github.io/MovieImages/"
full_movies$image_url = sapply(full_movies$MovieID, 
                          function(x) paste0(small_image_url, x, '.jpg?raw=true'))
full_movies$Image <- sapply(full_movies$MovieID,
                       function(x) paste0('<img src="', small_image_url, x, '.jpg?raw=true"></img>'))

# bring in ratings data
ratings = read.csv(paste0(myurl, 'ratings.dat?raw=true'), 
                   sep = ':',
                   colClasses = c('integer', 'NULL'), 
                   header = FALSE)
colnames(ratings) = c('UserID', 'MovieID', 'Rating', 'Timestamp')


# bring in users data
users = read.csv(paste0(myurl, 'users.dat?raw=true'),
                 sep = ':', header = FALSE)
users = users[, -c(2,4,6,8)] # skip columns
colnames(users) = c('UserID', 'Gender', 'Age', 'Occupation', 'Zip-code')

# add summary ratings stat columns to movies data set
summary_ratings <- setDT(ratings)[,list(Mean_Rating=mean(Rating), Max_Rating=max(Rating), Min_Rating=min(Rating), Median_Rating=as.numeric(median(Rating)), Std_Rating=sd(Rating)), by=MovieID]
movies <- merge(full_movies,summary_ratings,by="MovieID")

# add review count to movies data set for determining popularity by genre
count_ratings <- setDT(ratings)[, .(Count_of_Ratings = .N), by = MovieID][order(-Count_of_Ratings)]
movies <- merge(movies,count_ratings,by="MovieID")
