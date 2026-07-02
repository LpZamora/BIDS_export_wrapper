% Once your data is properly organized in the source data folder, and participants.csv, recordings.csv and tasks.json are filled
% (for detailed information, please refer to the readme file), you can use this wrapper to export your data to BIDS.

% Make sure that your current working directory is the folder containing this script
pwd

% Define the session(s) that you want to export
% When all the sessions are already collected, call the function on all the sessions, eg: ses = [1,2]; 
ses = [1]; 

%% However, a dedicated call must be made for each task in the data
% For example, there are two tasks in the provided toysetcd.
task1 = 'rest';
task2 = 'memory';

bids_export_wrapper(task1, ses)
bids_export_wrapper(task2, ses)
% Done!

% Bonus
% In longitudinal settings, you might want to export the sessions you already collected before the follow-up. 
% In this situation you would make a call per session like below
% ses1 = [1];
% ses2 = [2];
% bids_export_wrapper(task1, ses1)
% bids_export_wrapper(task2, ses1)
% bids_export_wrapper(task1, ses2)
% bids_export_wrapper(task2, ses2)


