This folder provides a template for systematically collecting and converting raw EEG, eye-tracking and behavioral data to [BIDS standard](https://bids.neuroimaging.io/). Once the non-BIDS data are organized as described below, the bids_export_wrapper function converts the data to BIDS, alleviating the coding/GUI steps usually required.
The code is based on EEGLAB, see `requirements.txt`.

### What your folder should contain

```
├── tutorial.pdf              % slide presentation of BIDS and this export tool
├── tasks.json                % needs to be filled
├── recordings.csv            % needs to be filled
├── participants.csv          % needs to be filled
├── bids_export_wrapper.m     % main function
├── rm_comments_util.m        % utility function
├── requirements.txt          % list of required libraries
├── DEMO.m                    % demonstration of how to run the code
├── source_data/
│   ├── task_X_behavior/      % Folder names should be "task_..._*type*", where type = behavior or eeg or eye
│   ├── task_X_eeg/           % only eeg folders are mandatory.
│   ├── task_X_eye/
│   ├── task_Y_behavior/
│   ├── task_Y_eye/
│   |── task_Y_eeg/
│   └── phenotype/           % optional, to save non task related measures like validated scales
├── stimuli/                 % optional
└── phenotypes.csv           % optional, needs to be filled to save non task related measures like validated scales
```

### Steps
#### 1. Study Design
- Plan such that separate data files are generated for each task.
- If you plan on saving behavioral data in dedicated files, use .tsv format
- Adapt the columns of `participants.csv` to your experiment: only "participant_id" is mandatory, you can record additional participants' informations by creating new columns
- Optional: adapt the columns of `phenotypes.csv` to your experiment: : only "participant_id", "session" and "run" are mandatory, note that ALL other columns in `phenotypes.csv` should contain file names. Indeed, this file is made to map participants with separated phenotypic data files, not to store information directly. You can track additional participants' phenotypic files by creating new columns. Pick good column names, they will be used to name the files in the destination folder.
- Create empty folders inside `source_data` - one per task and type of data, named like *task_Stroop_eeg*
- Fill in `tasks.json` file to settle on a clear coding and triggers before data collection starts.

#### 2. During data collection :
- Save data files in the appropriate subfolders of `source_data`
- Add each participant to `participants.csv`
- Fill `recordings.csv` for *each recording*. Columns which name start with `opt_` can be left empty.

    *Note: if you record training blocks in separated files you should treat the training as an independent task, e.g. "trainingStroop"*

Optional:

- Fill `phenotypes.csv` for each measure you make

#### 3. When a full session has been collected : convert the raw source_data to BIDS
- First, make a backup of the raw data and metadata
- For each task (and optionally session), call the bids_export_wrapper function (see DEMO file).

    *Note : you can alternatively run it for all sessions at once, but you'll still need to call bids_export_wrapper per task.*

- Use a [BIDS validator](https://bids-standard.github.io/bids-validator/) and make sure you don't get many or important errors.

#### 4. Pre-processing the raw BIDS data
This part is out of the scope of this bids_export wrapper. In general, you would use EEGLAB's pop_importbids() to read the raw BIDS data and, after pre-processing, pop_exportbids() to export the preprocessed data to a BIDS `derivatives` folder.
