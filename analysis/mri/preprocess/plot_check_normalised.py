import gl
import os

sub = '12'
# Path to the MNI152 T1 template
template_path = "avg152T1"

# Directory containing participant EPI data
epi_path = "/Volumes/appsmaj-motivation-social-neuro/Emma/average-effort/data_derived/mri/processed/sub-" + sub + '/func/wu_sub-' + sub + '_task-aet_run-1_bold.nii'

# Set up the MRIcroGL environment
gl.resetdefaults()
gl.loadimage(template_path)

# Load the average MNI152 T1 template
gl.loadimage(template_path)
    
# Load the current participant's EPI data as an overlay
gl.overlayload(epi_path)
#gl.minmax(1, 2, 6)  # Adjust min/max intensity as needed
gl.colorname(1, "Inferno")  # Customize color map
gl.opacity(1, 40)


# Refresh the display
gl.orthoviewmm(0, 0, 0)  # Set the view to center (MNI coordinates)

