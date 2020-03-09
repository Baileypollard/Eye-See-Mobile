# Eye See Mobile
This project was completed as part of COMP4583 Mobile/Ubiquitous Computing course at Acadia University that required students complete a sizable project using Flutter, Google's cross-platform programming language. 


# Our Roles
My group consisted of 3 group memebers: Myself, Casson Smith and Justin Hiltz. Our responsibilities were divded as follows:
  - Bailey Pollard (Myself): Mobile Developer, Data collector
  - Casson Smith: Data Cleaner
  - Justin Hiltz: Tensor Flow/Tensor Flow Lite


# Inspiration
The application that we designed and developed was called Eye See Mobile. The idea stemmed from the idea of making shopping an idependant activity for the visually imparied. After scanning through the currently available solutions, it was apparent that none of them offer a long term affordable solution for the visually impaired. Our goal was to use the power of Artificial Intelligence to train a model which could accurately identify popular products from a Canadian grocery store, more specifically Walmart. 


# How we did it?
## Finding Data Labels
Our group first needed a list of popular grocery items which can be found in the majority of Canadian grocery stores. I began with a google search for popular grocery items which yielded no results. I then resorted to using a webscraper to scrape roughly 18,000 publicly available item descriptions from Walmart.ca. These descriptions were then saved to a .csv file which divided them into product categories. 
Unfortunately, 18,000 product labels was too much to handle provided the resources we had to work with. Therefore, we decided that the best course of action would be to focus on the produce category. This resulted in roughly 300 labels which was a more managable amount provided our resources. 


## Fetching The Images
Both Tensor Flow and Google ML Vision Edge documentation recommended a minimum of 100 images per label, meaning that we would have to fetch roughly 30,000 images. I managed to find a python program on github which scraped Google Images for the first X amount of images for any given description. We split up the image fetching tasks between 7 threads which resulted in a completion time of roughly 2 hours. After we had all ~30,000 images downloaded, the real fun began.


## Data Cleaning
Casson was given the task to clean all the images, removing unrelated images from each dataset. As you can imagine, this was a rather time consuming process with took roughly 1 week to complete. We ended up removing many labels which we predicted would affect our models predictions negatively (i.e removing organic produce variants and similiar looking produce). As a result, we had 93 labels left which is what we used to develop our final model.


## TensorFlow/TensorFlow Lite
The image classifier consists of a convolutional neural network with an architecture similar to the popular VGG16 network. The model was initially built and trained on our cleaned dataset using tf.Keras. Performance was tested using a 70-15-15 split  of the data for training, validation, and testing sets. Our best model achieved approximately 60% top-5 accuracy on test data. After testing, the final model was saved using TensorFlow’s SavedModel format which was later converted to a FlatBuffer for use with TensorFlow Lite. While converting, quantization of the network’s weights optimized the model for mobile platforms.


## Flutter Implementation
Developing with cross-platform technology will always come with additional issues that will need to be sorted due to the difference between the native side of each operating system. We quickly realized that the native camera units in both IOS and Android encode their camera images differently. As a result, we needed to handle both operating systems differently which *kind of* defeats the purpose of cross-plateform design. Other than the camera encoding issues, the application is fairly straight forward. On application startup, a camera stream is started which will feed a frame of data to the model any time the screen is double tapped. The model then returns an array of confidence values sorted from highest -> lowest. The value at position 0 in the array is then fed to an external speaking package which reads the label to the user. 


## Results
As a result of the lack of resources available (computing power/accurate trainning data), we did not reach the goals that we originally set out to achieve, and that is okay! In an ideal world, we would have liked to have taken all the images ourselves in the actual store environment. If this was the case, we believe that our model would have been much more accurate. In the end we achieved approximately 60% top 5 accuracy and 24% top 1 accuracy from our models predictions. We were happy with this result and ended the project with a mark of 100% due to the time and effort we invested.
