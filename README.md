File Structure
EyeTracking/
-processing_ET.R         # Main ET data processing scripts
-statistics_ET.R         # Cleaned analysis script with LMER and plots
Blablacara_NIRS/
-pre-processing_NIRS_submission.m         # Preprocessing & epoch extraction
-grouping_quantifying-nirs_submission.m   # Subject-level GLM (FIR and canonical)
-group-level-stats-NIRS_submission.m          # Group-level mixed-effects modeling
README.md                     # Documentation (this file)

For the Eye-Tracking signal processing, I include scripts for processing, analyzing, and visualizing eye-tracking (ET) data collected in the Blablacara study, which investigates visual attention to the mouth versus eyes in different age groups (Young/Infants and Old/Toddlers) under various speech intelligibility conditions (AV, AVdeg, V).

The workflow includes:

Data Import and Cleaning

Trial and Participant Exclusion

EyetrackingR Data Processing

PTLT (Proportion of Looking to the Mouth over Eyes) Calculation

Statistical Analysis (LMER + Post-hoc tests)

Data Visualization

Export of Cleaned Data and Results


For the NIRS signal processing, This repository contains scripts for preprocessing, analyzing, and visualizing functional near-infrared spectroscopy (fNIRS) data from the Blablacara study, which investigates brain responses to audiovisual speech stimuli in different age groups (Young vs. Old participants).

The workflow covers:

Preprocessing NIRS signals (quality assessment, motion correction, filtering).

Epoch extraction aligned to stimulus onset.

Subject-level GLM modeling (FIR and canonical HRF).

Group-level analysis using mixed-effects modeling.

Visualization of activation patterns and statistical results.

Exporting beta values and statistical outputs for further analysis.

Required MATLAB Toolboxes & Paths

NIRS Toolbox: nirs-toolbox-master

NIRS GUI: NIRS-GUI-master

BrainWavelet: BrainWavelet

QT for NIRS: qt-nirs-master

Make sure to add each path to MATLAB using addpath(genpath(...)) before running the scripts.
