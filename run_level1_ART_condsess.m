% 
% CBS SPM preprocessing batch package -- Wrapper Script
% Created by Caitlin Carey
%
% This script is a wrapper for the entire preprocessing batch package.
% Edit anything that says CHANGE (just the template script generated by the
% SPM GUI).  
%
% Input is: run_preproc_package('TEXTFILENAME.txt', 'JOB_FILE', 
%       'DIRECTORY_PREFIX', 'TASK_FOLDER', 'TYPE')
%   TEXTFILENAME.txt is a text file with a list of your subjects in one 
%           group separated by spaces, e.g. 'szsubs.txt'
%   JOB_FILE is the name of the .m job file that got spit out of the batch
%           editor in SPM, e.g. 'preproc_word_task_job'
%   DIRECTORY_PREFIX is the path to the directory that contains all of the
%           subjects, e.g. '/ncf/snp/04/SCORE/'
%   TASK_FOLDER is the name of the individual directory where the run files
%           for your task are located, e.g. 'word_task/'
%   TYPE is the name of the group folder for your subjects, or "NONE" if
%           all subjects are in one group, e.g. 'SZ'
% 
% The subject text file must be only a list of subjects in one group
% separated by spaces, e.g. "27140 27208b 27216b"
%
%--------------------------------------------------------------------------

function run_preproc_package(varargin)
    
    % check input
    if (length(varargin) ~= 6)
           fprintf(['There is a problem with your input!\n',...
               'Input is: run_level1_package("TEXTFILENAME.txt","JOB_FILE", "DIRECTORY_PREFIX", "TASK_FOLDER", "OUTPUT_FOLDER", "TYPE")\n',...
               '\t TEXTFILENAME.txt is a text file with a list of your subjects in one group separated by spaces, e.g. "szsubs.txt"\n',...
               '\t JOB_FILE is the name of the .m job file that got spit out of the batch editor in SPM, e.g. "preproc_word_task_job"\n',...
               '\t DIRECTORY_PREFIX is the path to the directory that contains all of the subjects, e.g. "/ncf/snp/04/SCORE/"\n',...
               '\t TASK_FOLDER is the name of the individual directory where the run files for your task are located, e.g. "word_task/"\n',...
               '\t OUTPUT_FOLDER is where you would like your results to be placed (final folder doesnt have to exist yet), e.g. "word_task_analsis/standard_space/"\n',...
               '\t TYPE is the name of the group folder for your subjects, or "NONE" if all subjects are in one group, e.g. "SZ"\n']);
    end
   
    % read subject list
    myfile = varargin{1};
    try
        fid = fopen(myfile);
        C = textscan(fid, '%s');
        fclose(fid);
    catch
        fprintf('There was a problem reading your text file!');
    end
        
    % define input vars
    job = varargin{2};
    directory = varargin{3};
    task = varargin{4};
    outfold = varargin{5};
    type = varargin{6};
    
    % add path to defaults
    addpath('/ncf/snp/04/spm_tailored_code/');
    
    % initialize spm
    fprintf('Initializing SPM\n');
    spm('Defaults','fMRI');
    spm_jobman('initcfg');
    
    % for every subject:
    for i=1:size(C{1})
        
        % clears any prior matlabbatch
        clear matlabbatch;
        
        % define subject var
        subject = char(C{1,1}(i,1));

        % create matlabbatch and subjectDir output vars
        % using template script
        try
            % template script
            eval([job,'();']);
        catch
            fprintf(['Unable to create the batch!\n\n',...
                'To debug, look at the following exception:\n\n']);
            rethrow(lasterror());
        end
        
        % overwrite template variables
        try
            overwrite_script_level1_ART_condsess();
        catch
            fprintf(['Unable to create the batch!\n\n',...
                'To debug, look at the following exception:\n\n']);
            rethrow(lasterror());
        end 
        
        % save current directory and change to subject directory
        scriptDir=pwd();
        cd(subjectDir);
        
        fprintf('Running batch for %s\n', subject); 
        
        % run job
        try
            spm_jobman('run', matlabbatch);
        catch
            cd(scriptDir);
            fprintf(['Unable to create the batch!\n\n',...
                'To debug, look at the following exception:\n\n']);
            rethrow(lasterror());
        end
        
        % change back to script directory
        cd(scriptDir);
        
    end
end

