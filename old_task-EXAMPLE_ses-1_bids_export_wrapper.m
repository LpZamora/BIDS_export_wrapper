% First version not based on json files and a fuction
% Example to export joint EEG, behavior and Eye-tracking data to BIDS

% Adapted from Arnaud Delorme - May 2022 bids_export_example4 and December 2023 bids_export_eye_tracking_example5
% Lea Zamora March 2026

% TODO: Handle >1 behav files

clear;
% ------------------------------------------------------------------------------------------------------------------------
% ------------------------------------------------------------------------------------------------------------------------
%% Section 1 : Adapt below
% ------------------------------------------------------------------------------------------------------------------------
% ------------------------------------------------------------------------------------------------------------------------

% Information constant across tasks: just copy paste between task scripts ________________________________________________
                                                                                                                         %|
                                                                                                                         %|                                                                                                                   
% % Path to the root of the bids wrapper folder (use absolute path to reduce errors) -- char
bids_wrapper_folder = 'toyset_bids_wrapper';    

% % Path to the folder where you want the bids data to be exported -- char
targetFolder = 'BIDS_export_toyset';

% % Does your data contain a 'stimuli' folder that you want to export as well -- bool
stimuli_folder = false ; 

% % Do you want to copy the source_data to the BIDS folder -- bool
copy_sourcedata = true ;

% % Here describe all the opt_sub_ columns that you added to the to_fill_recordings_infos.csv file                           
% % Example                                                                                                          
pInfoDesc.opt_sub_group.Description = 'Experimental group of the participant';                                     
pInfoDesc.opt_sub_group.Levels.c    = 'control group'; % Better avoid levels code that start with a number    
pInfoDesc.opt_sub_group.Levels.p    = 'clinical group';                                                       
                                                                                                                   
pInfoDesc.opt_sub_corrected_vision.Description = 'Vision of the participant';                                      
pInfoDesc.opt_sub_corrected_vision.Levels.N    = 'normal vision without correction';                               
pInfoDesc.opt_sub_corrected_vision.Levels.Y    = 'normal vision with correction';                                  

% % FYI mandatory columns (edition is not recommended)
% % participant_id is mandatory
pInfoDesc.participant_id.LongName    = 'Participant identifier'; 
pInfoDesc.participant_id.Description = 'Unique participant identifier';

pInfoDesc.sub_sex.Description = 'Biological sex of the participant';
pInfoDesc.sub_sex.Levels.M    = 'male';
pInfoDesc.sub_sex.Levels.F    = 'female';

pInfoDesc.sub_age.Description = 'Age of the participant at first session';
pInfoDesc.sub_age.Units       = 'years';

pInfoDesc.sub_handedness.Description = 'Manual laterality of the participant';
pInfoDesc.sub_handedness.Levels.R    = 'right-handed';
pInfoDesc.sub_handedness.Levels.L    = 'left-handed';
pInfoDesc.sub_handedness.Levels.A    = 'ambidextrous';

% %% general information for dataset_description.json file
% % -----------------------------------------------------
generalInfo.Name = 'toyset_bids_export_test';
generalInfo.ReferencesAndLinks = { 'No bibliographic reference other than the DOI for this dataset' };
generalInfo.BIDSVersion = 'v1.2.1';
generalInfo.License = '';
generalInfo.Authors = { 'Marge' 'Lisa' };

% %% Content for README file
% % -----------------------
README = [ 'TEMPLATE                                  ' 10 ...
''                                                      10 ...
'This dataset contains 3 different tasks.              ' 10 ...
'During the selective visual attention experiment,     ' 10 ...
'stimuli appeared briefly in any of five squares      ' 10 ...
'In each experimental block, one (target) box was     ' 10 ...
'the process of epoch extraction from continuous data.' ];


% Information to adapt to each task script ______________________________________________________________________________
                                                                                                                        %|
                                                                                                                        %|
%% Task to which this script corresponds -- char
task = 'EO';

%% Session(s) to which this script corresponds -- numeric array
ses = [1,2];

% %% Task information for xxxx-eeg.json file
% % ---------------------------------------
tInfo.PowerLineFrequency = 50;
tInfo.CapManufacturer = 'n/a';
tInfo.RecordingType = 'continuous';
tInfo.ManufacturersModelName = 'n/a';
tInfo.SoftwareFilters = 'n/a'; 
tInfo.Instructions = 'n/a';
tInfo.InstitutionAddress = 'n/a';
tInfo.InstitutionName = 'n/a';
tInfo.InstitutionalDepartmentName = 'n/a';

% %% event column description for xxx-events.json file (only one such file)
% % ---------------------------------------
% % Map EEGLAB fields to BIDS columns
eInfo = {'onset'         'latency';
         'value'         'type' }; 

% % Describe columns for *_events.json
eInfoDesc = struct();
eInfoDesc.onset.Description = 'Event onset';
eInfoDesc.onset.Units = 'second';
eInfoDesc.duration.Description = 'Event duration';
eInfoDesc.duration.Units = 'second';
eInfoDesc.value.Description = 'Trigger codes from EEG system';

% % Edit based on the task triggers
% % Eg. if the triggers are 11,21, 31, 41 and 99
eInfoDesc.value.Levels = struct();
eInfoDesc.value.Levels.x11 = 'Start of trial';
eInfoDesc.value.Levels.x21= 'Congruent stimulus onset';
eInfoDesc.value.Levels.x31 = 'Incongruent stimulus onset';
eInfoDesc.value.Levels.x41 = 'Left response';
eInfoDesc.value.Levels.x99 = 'Right response';


% json = struct();
% json.bids_wrapper_folder = bids_wrapper_folder;
% json.targetFolder = targetFolder;
% json.stimuli_folder = stimuli_folder;
% json.copy_sourcedata = copy_sourcedata;
% json.pInfoDesc = pInfoDesc;
% json.generalInfo = generalInfo;
% json.README = README;
% json.taskEC.tInfo = tInfo;
% json.taskEC.eInfo = eInfo;
% json.taskEC.eInfoDesc = eInfoDesc;
% json.taskEO.tInfo = tInfo;
% json.taskEO.eInfo = eInfo;
% json.taskEO.eInfoDesc = eInfoDesc;
% jsonwrite('tasks.json', json, 'PrettyPrint', true);
% json = jsondecode(fileread('tasks.json'));
% json = removeCommentFields(json);
% bids_wrapper_folder = json.bids_wrapper_folder;
% targetFolder = json.targetFolder;
% stimuli_folder = json.stimuli_folder;
% copy_sourcedata = json.copy_sourcedata;
% pInfoDesc = json.pInfoDesc;
% generalInfo = json.generalInfo;
% README = json.README;

% fieldName = ['task', task];
% tInfo = json.(fieldName).tInfo;
% eInfo = json.(fieldName).eInfo;
% eInfoDesc = json.(fieldName).eInfoDesc;

% ------------------------------------------------------------------------------------------------------------------------
% ------------------------------------------------------------------------------------------------------------------------
%% Section 2 : No editing required below - see readme.md for the next steps
% ------------------------------------------------------------------------------------------------------------------------
% ------------------------------------------------------------------------------------------------------------------------

% Name of the csv containing all recordings and participants infos
recordings_csv = 'recordings.csv';
sub_csv = 'participants.csv';

% Set working directory to bids_wrapper root
start_dir = pwd;
[~, start_dir_name, ~] = fileparts(start_dir);
if ~strcmp(start_dir_name, bids_wrapper_folder)
    cd(bids_wrapper_folder);
    disp(['Changed directory to: ' pwd]);
end

% Read infos
opts = detectImportOptions(recordings_csv);
opts = setvartype(opts, 'participant_id', 'string');
recs_i = readtable(recordings_csv, opts);

opts = detectImportOptions(sub_csv);
opts = setvartype(opts, 'participant_id', 'string');
subs_i = readtable(sub_csv, opts);

infos = innerjoin(recs_i, subs_i, 'Keys', 'participant_id');

% Convert columns session and run to double, and others to string
t = varfun(@string, infos, 'InputVariables', infos.Properties.VariableNames, 'OutputFormat', 'table');
t.Properties.VariableNames = infos.Properties.VariableNames;
t.session = str2double(t.session);
t.run     = str2double(t.run);
% change to char for EEGLAB
for c = 1:width(t)
    if isstring(t.(c))
        t.(c) = cellstr(t.(c));
    end
end

% List sub info columns
all_sub_cols = subs_i.Properties.VariableNames;

% List subjects
subs = unique(t.participant_id);

% Check that source_data folder names, tasks.json fields and task input match

% Check pInfoDesc completeness
if ~isequal(sort(fields(pInfoDesc)), sort(cellstr(all_sub_cols(:))))
    error('The columns of %s and the fields of pInfoDesc in tasks.json do not match' , sub_csv);
end

% Check that all required infos are filled in the csv
mandat_cols = ["participant_id","session","run","file_eeg", "task"];
fprintf('Checking information completeness ..\n');
T = t(:, mandat_cols);
bad = false(1, width(T));
for i = 1:width(T)
    x = T{:, i};
    if isstring(x)
        bad(i) = any(ismissing(x) | x == "");
    elseif iscellstr(x)
        bad(i) = any(cellfun(@isempty, x) | ismissing(x));
    elseif ischar(x)
        xc = cellstr(x);
        bad(i) = any(cellfun(@isempty, xc));
    elseif isnumeric(x)
        bad(i) = any(ismissing(x)); 
    else
        bad(i) = any(ismissing(x));
    end
end

if any(bad)
    error('Missing or empty values found in columns: %s', ...
        strjoin(T.Properties.VariableNames(bad), ', '));
end
disp('...completeness check done\n');


%% Participant information for participants.tsv file 
% -------------------------------------------------
pInfo = cellstr(all_sub_cols);
for i = 1:numel(subs)
    s = subs(i);
    ts = t(string(t.participant_id) == string(s), all_sub_cols);
    
    % Get participant's info
    row = cell(1, numel(all_sub_cols));
    for j = 1:numel(all_sub_cols)
        col = ts.(all_sub_cols{j});
        if isempty(col)
            row{j} = "";
        else
            row{j} = char(col(1)); 
        end
    end
    % Append to pInfo
    pInfo(end+1, :) = row;
end

% Select task and session(s)
rows = ismember(t.session, ses) & string(t.task) == task ;
if sum(rows) == 0
    error("No row from recordings.csv matches task %s and session %s", ...
      task, strjoin(string(ses), ", "))
end
t = t(rows,:);

% Complete files paths - Eye and behavior files are not mandatory
t.file_eeg = fullfile('source_data', sprintf('task%s_eeg', task), t.file_eeg);
mask = t.opt_file_behavior ~= "";
t.opt_file_behavior(mask) = cellstr(fullfile('source_data', sprintf('task%s_behavior', task), string(t.opt_file_behavior(mask))));
mask = t.opt_file_eye ~= "";
t.opt_file_eye(mask) = cellstr(fullfile('source_data', sprintf('task%s_eye', task), string(t.opt_file_eye(mask))));


%% Build data input object
% -------------------------------------------------
data = struct();

for i = 1:numel(subs)
    s = subs(i);
    ts = t(string(t.participant_id) == string(s), :);

    data(i).file = cellstr(ts.file_eeg);
    %data(i).eyefile = cellstr(ts.opt_file_eye);
    data(i).session = ts.session;
    data(i).run     = ts.run;
    data(i).task = cellstr(ts.task);
    data(i).notes = cellstr(ts.opt_notes);
end

% call to the export function
% ---------------------------

bids_export(data, ...
    'targetdir', targetFolder, ...
    'gInfo', generalInfo, ...
    'pInfo', pInfo, ...
    'pInfoDesc', pInfoDesc, ...
    'eInfo', eInfo, ...
    'eInfoDesc', eInfoDesc, ...
    'README', README, ...
    'CHANGES', {}, ...
    'codefiles', {}, ...
    'trialtype', {}, ...
    'renametype', {}, ...
    'tInfo', tInfo, ...
    'deleteExportDir', 'off', ...
    'forcesession', 'on', ...
    'writePInfoOnly', 'off');

%% copy stimuli and source data folders
% % -----------------------------------
if stimuli_folder
    copyfile('stimuli', fullfile(targetFolder, 'stimuli'), 'f');
end
if copy_sourcedata
    copyfile('source_data', fullfile(targetFolder, 'sourcedata'), 'f');
end

fprintf(2, 'WHAT TO DO NEXT?\n')
fprintf(2, ' -> upload the %s folder to a BIDS validator\nA link and more informations are in the readme\n', targetFolder);

