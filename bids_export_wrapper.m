function bids_export_wrapper(task, ses)
    % Export joint EEG, behavior and Eye-tracking data to BIDS.
    %  INPUT :
    %           task - char : name of the task that should be exported 
    %           ses - numeric array : integer identifier(s) of the session(s) you want to export.
    %
    % Wraps EEG-BIDS export function based on three key files : participants.csv, recordings.csv and tasks.json, and a source_data folder. See readme for more informations.
    %
    % Adapted from Arnaud Delorme - May 2022 bids_export_example4 and December 2023 bids_export_eye_tracking_example5
    % Lea Zamora March 2026

    % TODO: Handle eye data

    % Read tasks.json
    json = jsondecode(fileread('tasks.json'));
    json = rm_comments_util(json);
    targetFolder = json.targetFolder;
    stimuli_folder = json.stimuli_folder;
    copy_sourcedata = json.copy_sourcedata;
    pInfoDesc = json.pInfoDesc;
    generalInfo = json.generalInfo;
    README = json.README;

    fieldName = ['task', task];
    tInfo = json.(fieldName).tInfo;
    eInfoDesc = json.(fieldName).eInfoDesc;

    eInfo = {'onset'         'latency';
            'value'         'type' }; 

    % Check that source_data folder names, tasks.json fields and task input match
    pattern = fullfile('source_data', sprintf('task%s_*', task));
    listing = dir(pattern);
    listing = listing([listing.isdir]);
    if numel(listing) < 1
        error('Mismatch between the task input to this function and the folder naming in source_folder.\n')
    end
    if ~ismember(sprintf("task%s", task),fields(json))
        error('task%s is not present in the fields of tasks.json', task)
    end

    % Name of the csv containing all recordings and participants infos
    recordings_csv = 'recordings.csv';
    sub_csv = 'participants.csv';

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
        'codefiles', {}, ...
        'trialtype', {}, ...
        'renametype', {}, ...
        'tInfo', tInfo, ...
        'individualEventsJson', 'on', ...
        'deleteExportDir', 'off', ...
        'forcesession', 'on', ...
        'writePInfoOnly', 'off');

    %% Add behavior folder 
    % % -----------------------------------   
    behav_rows = ~cellfun(@isempty, t.opt_file_behavior);
    tb = t(behav_rows,:);

    for i = 1:height(tb)
        % path in source_data
        op = tb.opt_file_behavior{i};
        if exist(op, 'file') == 2   
            [~,~,ext] = fileparts(op);
            tsk = tb.task{i};
            sss = tb.session(i);
            rn  = tb.run(i);
            s   = tb.participant_id{i};
            % target folder path
            np = fullfile(targetFolder, sprintf('sub-%s', s), sprintf('ses-%d', sss), 'beh');
            % BIDS file name
            name = sprintf('sub-%s_ses-%d_task-%s_run-%d_beh%s', s, sss, tsk, rn, ext);
            % copy the file
            if ~exist(np, 'dir')
                mkdir(np);
            end
            fp = fullfile(np, name);
            copyfile(op, fp);
        else
            warning('Behavioral file %s does not exist', op)
        end
    end

    %% Add phenotype folder 
    % % -----------------------------------  
    if json.phenotype_folder
        pheno_csv = 'phenotypes.csv';
        pPhenoDesc = json.pPhenoDesc ;
        opts = detectImportOptions(pheno_csv);
        opts = setvartype(opts, 'participant_id', 'string');
        pheno_i = readtable(pheno_csv, opts);

        rows = ismember(pheno_i.session, ses) ;
        pheno_i = pheno_i(rows,:);


        % List columns linking to measurement files
        all_phe_cols = pheno_i.Properties.VariableNames;
        exclude_cols = {'session', 'run', 'participant_id'};
        keep_cols = ~ismember(all_phe_cols, exclude_cols);
        cols = all_phe_cols(keep_cols);

        % Init structure for json infos
        for column = 1:numel(cols)
            col = string(cols(column));
            pheno_rows = ~cellfun(@isempty, pheno_i.(col));
            tb = pheno_i(pheno_rows,:);
            for i = 1:height(tb)
                % path in source_data
                op = tb.(col){i};
                op = fullfile('source_data', 'phenotype', op);
                if exist(op, 'file') == 2   
                    [~,~,ext] = fileparts(op);
                    tsk = col;
                    sss = tb.session(i);
                    rn  = tb.run(i);
                    s   = tb.participant_id{i};
                    % target folder path
                    np = fullfile(targetFolder, 'phenotype');
                    % BIDS file name
                    name = sprintf('sub-%s_ses-%d_task-%s_run-%d%s', s, sss, tsk, rn, ext);
                    % copy the file
                    if ~exist(np, 'dir')
                        mkdir(np);
                    end
                    fp = fullfile(np, name);
                    copyfile(op, fp);
                else
                    warning('Phenotype file %s does not exist', op)
                end
            end

            % Add json file with infos
            json_str = jsonencode(pPhenoDesc.(col), 'PrettyPrint', true);
            out_json = fullfile(targetFolder, 'phenotype', [char(col) '.json']);
            fid = fopen(out_json, 'w');
            if fid == -1
                error('Cannot open file %s for writing', out_json);
            end
            fwrite(fid, json_str, 'char');
            fclose(fid);
        end
    end

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

end
