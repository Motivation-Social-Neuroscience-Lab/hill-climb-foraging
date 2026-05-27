# To add 'Intended For' field to fieldmap data for use in fmriPrep pipeline
# Created April 2025, Emma Scholey


import json
import os
import glob
bids = '/Volumes/appsmaj-motivation-social-neuro/Emma/aet_fMRI/raw/'
subs = glob.glob(bids+'sub*')

for sub in subs:
    func_niis = [x.replace(sub+'/','') for x in glob.glob(sub+'/func/*bold.nii*')]
    fmaps_func_jsons = glob.glob(sub+'/fmap/*magnitude*.json')
    for file in fmaps_func_jsons:
        with open(file) as f:
            data = json.load(f)
        IF = {"IntendedFor":func_niis}
        data.update(IF)
        with open(file, 'w') as outfile:
            json.dump(data, outfile,indent=2,sort_keys=True)

    fmaps_func_jsons = glob.glob(sub+'/fmap/*phasediff*.json')
    for file in fmaps_func_jsons:
        with open(file) as f:
            data = json.load(f)
        IF = {"IntendedFor":func_niis}
        data.update(IF)
        with open(file, 'w') as outfile:
            json.dump(data, outfile,indent=2,sort_keys=True)
