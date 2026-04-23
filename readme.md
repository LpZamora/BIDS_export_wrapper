This folder provides a template for data collection when planning a conversion of raw EEG, eye-tracking and behavioral data to [BIDS standard](https://bids.neuroimaging.io/) - based on EEGLAB.


### What your folder should contain

```
├── tasks.json                % needs to be filled
├── recordings.csv            % needs to be filled
├── participants.csv          % needs to be filled
├── bids_export_wrapper.m     % main function
├── rm_comments_util.m        % utility function
├── requirements.txt          % list of required libraries
├── DEMO.m                    % demonstration of how to run the code
├── source_data/
│   |── phenotype/            % optional, to save non task related measures like validated scales
│   ├── taskX_behavior/       % only eeg folders are mandatory. Folder names should be "task*_*type*"
│   ├── taskX_eeg/
│   ├── taskX_eye/
│   ├── taskY_behavior/
│   ├── taskY_eye/
│   └── taskY_eeg/
├── stimuli/                 % optional
├── deanonymization.csv      % optional
└── phenotypes.csv           % optional, needs to be filled to save non task related measures like validated scales
```

### Steps
#### 1. Study Design
- Plan such that separate data files are generated for each task.
- Adapt the columns of `participants.csv` to your experiment: only "participant_id" is mandatory, you can record additional participants' informations by creating new columns
- Optional: adapt the columns of `phenotypes.csv` to your experiment: : only "participant_id", "session" and "run" are mandatory, note that ALL other columns in `phenotypes.csv` should contain file names. Indeed, this file is made to map participants with separated phenotypic data files, not to store information directly. You can track additional participants' phenotypic files by creating new columns. Pick good column names, they will be used to name the files in the destination folder.
- Create empty folders inside `source_data` - one per task and type of data, named like *taskStroop_eeg*
- Fill in `tasks.json` file to settle on a clear coding and triggers before data collection starts.

#### 2. During data collection :
- Save data files in the appropriate subfolders of `source_data`
- Add each participant to `participants.csv`
- Fill `recordings.csv` for *each recording*. Columns which name start with `opt_` can be left empty.

    *Note: if you record training blocks in separated files you should treat the training as an independent task, e.g. "trainingEO"*

Optional:

- Fill `phenotypes.csv` for each measure you make
- If you need to keep track of participants identity - for example if a second session is planned - fill `deanonymization_if_several_sessions.csv`.

    *Note : The deanonymization csv file isn't used by the bids wrapper script. Its purpose is to support subject's identifier retrieval in longitudinal experiments. It should never be shared.*

#### 3. When a full session has been collected
- First, make a backup of the raw data and metadata
- For each task (and optionally session), call the bids_export_wrapper function (see DEMO file).

    *Note : you can alternatively run it for all sessions at once, but you'll still need to call bids_export_wrapper per task.*

- Use a [BIDS validator](https://bids-standard.github.io/bids-validator/) and make sure you don't get errors.

#### 4. Pre-processing the data
This part is out of the scope of this bids_export wrapper. In general, you would use EEGLAB's pop_importbids() to read the raw BIDS data and, after pre-processing, pop_exportbids() to export the preprocessed data to a BIDS `derivatives` folder.
