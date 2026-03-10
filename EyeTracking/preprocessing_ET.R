# Load required libraries
library("eyetrackingR")
library("eyelinker")
library("Matrix")
library("lme4")
library("stringr")

# Initialize datasets for both groups
dataset_all_young <- data.frame()
dataset_all_old <- data.frame()

# Define subjects to exclude
outYoung <- c('BB01','BB02','BB08','BB09','BB10','BB12','BB16','BB18','BB20','BB21','BB26','BB29','BB31','BB34')
outOld <- c('BBOLD02','BBOLD08','BBOLD11','BBOLD14','BBOLD17','BBOLD20','BBOLD24','BBOLD25','BBOLD28','BBOLD29')

# Loop over both groups: Young (1) and Old (2)
for (grr in 1:2) {
  
  # Set group label
  group <- ifelse(grr == 1, "Young", "Old")
  
  # Set root directory and list subjects
  directory_root <- paste("/Users/irenearrietasagredo/Desktop/BCBL/Thesis-blablacara/Blablacara-data/data.nosync/", group, sep = "")
  directory_subj <- list.files(directory_root)
  
  # Loop over subjects
  for (k in 1:length(directory_subj)) {
    
    # Process Young group starting from 3rd subject, all Old subjects
    if(((group == "Young") & k > 2) | group == "Old") {
      
      subject_n <- k
      directory_list <- paste(directory_root, directory_subj[subject_n], "ET", sep="/")
      directory_exp <- list.files(directory_list)
      
      if(length(directory_exp) == 0) next  # Skip subjects without ET data
      
      # Load .asc files
      files_asc <- list.files(directory_list, pattern = "\\.asc")
      if(length(files_asc) == 0) next
      
      name_file <- gsub("\\.asc$", "", files_asc[1])
      outAll <- c(outYoung, outOld)
      
      # Skip excluded subjects
      if(length(grep(name_file, outAll)) != 0) next
      
      name <- directory_subj[subject_n]
      Data <- read.asc(file.path(directory_list, files_asc[1]), samples = TRUE, events = TRUE, parse_all = FALSE)
      
      # Load condition table and standardize labels
      cond <- list.files(directory_list, pattern = ".dat")
      cond_table <- read.table(paste(directory_list, cond, sep = "/"))
      cond_list <- cond_table$V5
      cond_list[cond_list %in% c("AVc","Avc")] <- "AV"
      cond_list[cond_list %in% c("AVd","Avd")] <- "AVdeg"
      
      participant_column <- rep(name, length(Data$raw$time))
      trackloss <- rep(0, length(Data$raw$time))
      cond_list_by_trial <- Data$raw$block
      
      # Identify stimulus onset times (all conditions)
      stim_files <- c("eguerdion_720x.wav","eguerdion_vocoder_720x.wav","eguerdion_silence_720x.wav",
                      "arratsaldeon_720x.wav","arratsaldeon_vocoder_760x.wav","arratsaldeon_silence_760x.wav",
                      "egunon_720x.wav","egunon_vocoder_720x.wav","egunon_silence_720x.wav")
      
      cond_tmp <- c()
      for(f in stim_files){
        idx <- grep(paste0("library/audio/", f), Data$msg$text)
        if(length(idx) != 0){
          time_stim <- Data$msg$time[idx]
          cond_val <- switch(f,
                             "eguerdion_silence_720x.wav"=1,
                             "eguerdion_720x.wav"=2,
                             "eguerdion_vocoder_720x.wav"=3,
                             "arratsaldeon_silence_760x.wav"=1,
                             "arratsaldeon_720x.wav"=2,
                             "arratsaldeon_vocoder_760x.wav"=3,
                             "egunon_silence_720x.wav"=1,
                             "egunon_720x.wav"=2,
                             "egunon_vocoder_720x.wav"=3)
          cond_tmp <- c(cond_tmp, rep(cond_val, length(time_stim)))
        }
      }
      
      # Adjust cond_list for known subject-specific trial issues
      if(name == "BBOLD04") cond_list <- cond_list[-c(14,16,17)]
      if(name == "BBOLD13") cond_list <- cond_list[-c(14:18)]
      if(name == "BBOLD30") cond_list <- cond_list[-c(11:18)]
      if(name == "BBOLD31") cond_list <- cond_list[-c(9:18)]
      
      # Combine raw data with participant info and conditions
      Data_Raw_participant <- cbind(participant_column, Data$raw, trackloss, cond_list_by_trial)
      colnames(Data_Raw_participant)[2] <- "trial"
      
      # Remove false events based on trial indices
      time_all <- sort(Data$msg$time[grep("720x|760x", Data$msg$text)])
      a <- match(time_all, Data_Raw_participant$time)
      if(!any(is.na(a))){
        idx_to_delete <- setdiff(1:max(Data_Raw_participant$trial), Data_Raw_participant$trial[a])
        if(length(idx_to_delete)!=0){
          for(l in idx_to_delete){
            st <- match(l, Data_Raw_participant$trial)
            e <- if(l < max(Data_Raw_participant$trial)) match(l+1, Data_Raw_participant$trial) else nrow(Data_Raw_participant)
            Data_Raw_participant <- Data_Raw_participant[-c(st:(e-1)),]
          }
        }
      }
      
      # Update trial conditions after cleaning
      for(j in 1:length(unique(Data_Raw_participant$trial))){
        cond_list_by_trial[Data_Raw_participant$trial==j] <- cond_list[j]
      }
      
      # Add AOI: Screen
      screen_aoi <- data.frame(
        trial = unique(Data_Raw_participant$trial),
        x_min_col_screen = 0,
        y_min_col_screen = 0,
        x_max_col_screen = Data$info$screen.x,
        y_max_col_screen = Data$info$screen.y
      )
      
      data_tmp0 <- add_aoi(
        data = Data_Raw_participant,
        aoi_dataframe = screen_aoi,
        x_col = "xp", y_col = "yp",
        aoi_name = "screen",
        x_min_col = "x_min_col_screen", x_max_col = "x_max_col_screen",
        y_min_col = "y_min_col_screen", y_max_col = "y_max_col_screen"
      )
      
      # Normalize trial times
      trial_idx <- unique(data_tmp0$trial)
      onset_idxx <- match(trial_idx, data_tmp0$trial)
      vec <- c()
      for(i in 1:length(trial_idx)){
        vec[which(data_tmp0$trial==trial_idx[i])] <- onset_idxx[i]
      }
      data_tmp0$onset_w <- vec
      time_0 <- data_tmp0$time
      for(i in 1:length(trial_idx)){
        start <- onset_idxx[i]
        end <- if(i==length(trial_idx)) length(time_0) else onset_idxx[i+1]
        time_0[start:end] <- time_0[start:end]-start
      }
      data_tmp0$TimeFromStartTrial <- time_0
      data_tmp0 <- data_tmp0[, -3]
      
      # Create eyetrackingr data
      my_data_trial <- make_eyetrackingr_data(
        data_tmp0,
        participant_column = "participant_column",
        trial_column = "trial",
        time_column = "TimeFromStartTrial",
        trackloss_column = "trackloss",
        aoi_columns = c("screen"),
        treat_non_aoi_looks_as_missing = TRUE
      )
      
      # Windowed subset (time from trial start)
      data_tmp_window <- subset_by_window(my_data_trial, window_start_time = 0, rezero = TRUE, remove = FALSE)
      
      # Trackloss calculation
      trackloss <- trackloss_analysis(data = data_tmp_window)
      trackloss$cond <- cond_list
      loss_thresh <- trackloss
      loss_thresh$bad <- trackloss$TracklossForTrial > 0.4
      
      # Remove bad trials
      trackloss_clean <- trackloss[trackloss$TracklossForTrial <= 0.4, ]
      
      # Add cleaned data to group dataset
      if(group == "Young"){
        dataset_all_young <- rbind(dataset_all_young, trackloss_clean)
      } else{
        dataset_all_old <- rbind(dataset_all_old, trackloss_clean)
      }
      
    } # End of subject loop
  } # End of k loop
} # End of group loop

# Combine both groups into a single dataset
dataset_all_young$group <- 1
dataset_all_old$group <- 2
dataset_all <- rbind(dataset_all_young, dataset_all_old)

# Save cleaned data
write.table(dataset_all, file = "/Users/irenearrietasagredo/Desktop/BCBL/Thesis-blablacara/Blablacara-data/data_analysis/dataset_all_ET_blablacara_clean.csv", row.names = TRUE)