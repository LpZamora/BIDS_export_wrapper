This folder provides a template for data collection when planning a conversion of raw EEG, eye-tracking and behavioral data to [BIDS standard](https://bids.neuroimaging.io/) - based on EEGLAB.

### What your folder should contain

```
├── tasks.json                % needs to be filled
├── recordings.csv            % needs to be filled
├── participants.csv          % needs to be filled
├── bids_export_wrapper.m     % main function
├── removeCommentFields.m     % utility function
├── DEMO.m                    % demonstration of how to run the code
├── source_data/
│   ├── taskX_behavior/       % only eeg folders are mandatory. Folder names need to start with "task*_"
│   ├── taskX_eeg/
│   ├── taskX_eye/
│   ├── taskY_behavior/
│   ├── taskY_eye/
│   └── taskY_eeg/
├── stimuli/                 % optional
├── deanonymization.csv      % optional
```

### Steps
#### 1. Study Design
- Plan such that separate data files are generated for each task.
- Adapt the columns of `participants.csv` to your experiment: only "participant_id" is mandatory, you can record additional participants' informations by creating new columns
- Create empty folders inside `source_data` - one per task and type of data, named like taskStroop_eeg/
- Fill in tasks.json file to settle on a clear coding and triggers before data collection starts.

#### 2. During data collection :
- Save data files in the appropriate subfolders of `source_data`
- Add each participant to `participants.csv`
- Fill `recordings.csv` for *each recording*. Columns which name start with `opt_` can be left empty
- If you need to keep track of participants identity - for example if a second session is planned - fill `deanonymization_if_several_sessions.csv`.

    *Note : The deanonymization csv file isn't used by the bids wrapper script. Its purpose is to support subject's identifier retrieval in longitudinal experiments. It should never be shared.*

#### 3. When a full session has been collected
- First, make a backup of the raw data and metadata
- For each task (and optionally session), call the bids_export_wrapper function (see DEMO file).

    *Note : you can alternatively run it for all sessions at once, but you'll still need to create a bids_export_wrapper script per task.*

- Use a [BIDS validator](https://bids-standard.github.io/bids-validator/)

#### 4. Pre-processing the data
This part is out of the scope of this bids_export wrapper. In general, you would use pop_importbids() to read the raw BIDS data and, after pre-processing, pop_exportbids() to export the preprocessed data to a BIDS `derivatives` folder.
