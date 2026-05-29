
 # Hill Climb task

This folder contains the scripts and data to run behavioural and modelling analysis for **Neural and computational mechanisms of adapting decisions to the effort of the landscape**.

## Datasets

- **Study 1**: 'mri' tag in the code. 
- **Study 2**: 'v3' tag
- **Study 3**: 'v1' tag

## Folder Structure

```
root
  ├─ behavioural_analysis     # R code to run generalised linear mixed model (GLMM) analysis, and plot Figures 2, 3 B-C, Supplementary Figure S3, and generate Tables S1-4.
       ├─ glmm_output  # GLMM objects for models underlying each Table S1-4. 
  ├─ data  
       ├─ behavioural  # behavioural dataframes for each study
           ├─ mri 
           ├─ v1
           ├─ v3           
       ├─ fit          # model fits and simulated data for each study
           ├─ mri
           ├─ v1
           ├─ v3            
  ├─ figures  # MATLAB code to generate Figure 1 (panels B-D, task structure and model predictions) Figure 3A (model comparison) and Supplementary Figure 2 (parameter recovery and model identifiability)
       ├─ functions    # make plots look nice
  ├─ fmri  # MATLAB code used for fMRI first/second level/PPI analysis. Code forms basis of Figures 4-7.
       ├─ first-level  # Run first level GLM for each subject using parametric modulation of model decision variables
       ├─ PPI          # Extract PPI variables and run first/second-level seed-to-voxel analysis
       ├─ preprocess   # Additional preprocessing code (smoothing and deriving nuisance regressors). Preprocessing was run with fMRIprep. 
       ├─ second-level # Run second level GLM at group-level and extract contrast estimates for significant clusters.  
  ├─ modelling  # MATLAB code used for computational modelling.
       ├─ helperFunctions   

```

**Note:** fMRI T-maps for the three main group-level contrasts at the time of offer (subjective value, average effort, effort PE), and PPI seed-to-voxel group-level contrasts, will be uploaded on Neurovault. 

## Software

- **MATLAB (2025a)**: Compoutational model code and fMRI analysis (SPM25). 
- **R**: Linear mixed models and publication figures. Package versions can be found in behavioural_analysis/session_info_R.txt.

---

For questions, contact: **escholey1@gmail.com**\
