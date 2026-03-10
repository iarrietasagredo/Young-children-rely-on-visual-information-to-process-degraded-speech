
---

## Eye-Tracking (ET) Signal Processing

This folder contains scripts for processing, analyzing, and visualizing eye-tracking (ET) data collected in the **Blablacara study**, which investigates visual attention to the **mouth vs. eyes** in different age groups (Young/Infants and Old/Toddlers) under various speech intelligibility conditions (**AV, AVdeg, V**).

### Workflow

1. **Data Import and Cleaning**  
2. **Trial and Participant Exclusion**  
3. **EyetrackingR Data Processing**  
4. **PTLT Calculation** (Proportion of Looking to the Mouth over Eyes)  
5. **Statistical Analysis** (LMER + Post-hoc tests)  
6. **Data Visualization**  
7. **Export of Cleaned Data and Results**

---

## NIRS Signal Processing

This folder contains scripts for preprocessing, analyzing, and visualizing **functional near-infrared spectroscopy (fNIRS)** data from the Blablacara study, investigating brain responses to audiovisual speech stimuli in **Young vs. Old participants**.

### Workflow

1. **Preprocessing NIRS signals**  
   - Quality assessment (QT module)  
   - Motion correction  
   - Filtering (low-pass and high-pass)  

2. **Epoch extraction** aligned to stimulus onset  
3. **Subject-level GLM modeling**  
   - FIR basis for time-resolved response  
   - Canonical HRF basis for beta values per condition  

4. **Group-level analysis** using mixed-effects modeling  
5. **Visualization** of activation patterns and statistical results  
6. **Exporting beta values** and statistical outputs for further analysis

---

## Required MATLAB Toolboxes & Paths

- **NIRS Toolbox:** `nirs-toolbox-master`  
- **NIRS GUI:** `NIRS-GUI-master`  
- **BrainWavelet:** `BrainWavelet`  
- **QT for NIRS:** `qt-nirs-master`  

> Make sure to add each path to MATLAB using `addpath(genpath(...))` before running the scripts.

---

## Notes

- Adjust **excluded participants** if necessary (`outYoung`, `outOld`).  
- Epoch length, pre/post-stimulus times, and thresholds may need fine-tuning depending on the dataset.  
- Statistical maps are thresholded at `p<0.05` and `q<0.05` (FDR-corrected).  
