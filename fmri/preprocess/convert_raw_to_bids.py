# To convert raw data for average effort tracking (AET) task to BIDS format 
# Created May 2024, Payman Roghani 
# Edited January 2025, Emma Scholey, for batch editing

import os
import subprocess

def create_subject_dirs(base_path, subject_number):
    subject_dir = os.path.join(base_path, f"sub-{subject_number:02d}")
    os.makedirs(subject_dir, exist_ok=True)
    os.makedirs(os.path.join(subject_dir, 'func'), exist_ok=True)
    os.makedirs(os.path.join(subject_dir, 'anat'), exist_ok=True)
    os.makedirs(os.path.join(subject_dir, 'fmap'), exist_ok=True)
    os.makedirs(os.path.join(subject_dir, 'excluded'), exist_ok=True)
    return subject_dir

# Function to rename, move, and decompress files
def rename_move_decompress_files(raw_data_path, subject_dir, subject_number):
    file_mapping = {
        "gre_fieldmap_9_e2_ph.nii.gz": f"{subject_dir}/fmap/sub-{subject_number:02d}_phasediff.nii.gz",
        "gre_fieldmap_9_e2_ph.json": f"{subject_dir}/fmap/sub-{subject_number:02d}_phasediff.json",
        "gre_fieldmap_8_e1.nii.gz": f"{subject_dir}/fmap/sub-{subject_number:02d}_magnitude1.nii.gz",
        "gre_fieldmap_8_e2.json": f"{subject_dir}/fmap/sub-{subject_number:02d}_magnitude2.json",
        "gre_fieldmap_8_e1.json": f"{subject_dir}/fmap/sub-{subject_number:02d}_magnitude1.json",
        "gre_fieldmap_8_e2.nii.gz": f"{subject_dir}/fmap/sub-{subject_number:02d}_magnitude2.nii.gz",
        "localiser_32ch_1.nii.gz": f"{subject_dir}/excluded/sub-{subject_number:02d}_desc-localiser32ch_excluded.nii.gz",
        "localiser_32ch_1.json": f"{subject_dir}/excluded/sub-{subject_number:02d}_desc-localiser32ch_excluded.json",
        "T1_vol_v1_5.nii.gz": f"{subject_dir}/anat/sub-{subject_number:02d}_T1w.nii.gz",
        "T1_vol_v1_5.json": f"{subject_dir}/anat/sub-{subject_number:02d}_T1w.json",
        "bold_mbep2d_TE30_MB3P2_AP_2.4iso_PM_Task_6.json": f"{subject_dir}/func/sub-{subject_number:02d}_task-aet_run-1_sbref.json",
        "bold_mbep2d_TE30_MB3P2_AP_2.4iso_PM_Task_6.nii.gz": f"{subject_dir}/func/sub-{subject_number:02d}_task-aet_run-1_sbref.nii.gz",
        "bold_mbep2d_TE30_MB3P2_AP_2.4iso_PM_Task_7.json": f"{subject_dir}/func/sub-{subject_number:02d}_task-aet_run-1_bold.json",
        "bold_mbep2d_TE30_MB3P2_AP_2.4iso_PM_Task_7.nii.gz": f"{subject_dir}/func/sub-{subject_number:02d}_task-aet_run-1_bold.nii.gz"
    }

    for raw_file, new_file in file_mapping.items():
        raw_file_path = os.path.join(raw_data_path, raw_file)
        if os.path.exists(raw_file_path):

            if os.path.exists(new_file):
                print(f"File already exists and will not be overwritten: {new_file}")
                continue

            try:
                # Using rsync for copying files
                subprocess.run(['rsync', '-a', raw_file_path, new_file], check=True)
                print(f"Copied: {raw_file_path} to {new_file}")
                
                # Decompress if the file is a .gz file
                if new_file.endswith('.gz'):
                    subprocess.run(['gunzip', new_file], check=True)
                    print(f"Decompressed: {new_file}")
            except subprocess.CalledProcessError as e:
                print(f"Error copying {raw_file_path} to {new_file}: {e}")
            except PermissionError as e:
                print(f"Permission error: {e}")
        else:
            print(f"File not found: {raw_file_path}")

# Main script
    # Ask for subject number
subject_array = list(range(101, 105)) + list(range(106, 111)) + list(range(112, 132)) + list(range(133, 142))
#subject_array = list((119, 123, 128)) # these participants had manual renaming of files, since MRI crashed and we redid runs

    # Define the base path
base_path = "/Users/exs165/Dropbox/average-effort/data_derived/mri/raw/" 

for subject_number in subject_array:
# Function to create directories for the subject
    print(subject_number)

        # Create directories for the subject
    subject_dir = create_subject_dirs(base_path, subject_number-100)

    raw_data_path = '/Users/exs165/Dropbox/average-effort/data_raw/mri/mri_scans/%s/' % subject_number
    searchstring = 'nifti'

    directory = os.listdir(raw_data_path)
    for fname in directory:
        if fname.endswith(searchstring):
            subj_raw_data_path = os.path.join(raw_data_path, fname)

    # Rename, move, and decompress the files
    rename_move_decompress_files(subj_raw_data_path, subject_dir, subject_number-100)

    print("Files have been organized successfully.")
