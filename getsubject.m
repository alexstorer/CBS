function [] = getsubject(subjectid,boldruns,structrun,fmruns,destpath)
%GETSUBJECT   Get subject data from the network and convert to spm. 
%   GETSUBJECT(subjectid, boldruns, structrun,fmruns,destpath) downloads
%   data using cbsget, processes it with spm and renames the files and
%   puts them in an ordered directory structure.
%
%   subjectid:  the name of the subject in CBSCentral (in single quotes, e.g. 'my_subj_name')
%   boldruns:   the run numbers for the BOLD scans (in brackets if more than one run, e.g. 1 or [1,2])
%   structrun:  the run number for the structural scan (same as boldruns)
%   fmruns:     the run numbers for the fieldmap scan (same as boldruns)
%               The fieldmap is optional. If you don't have one, put empty brackets, e.g. []
%
%   destpath:   the path where this data will go after conversion (in signle quotes, e.g. '/users/me/data')

%% Do error checking on the inputs

% in my test - delete this eventually!
% structrun = [4];
% boldruns = [5];
% fmruns = [6 7];
% subjectid = '120418_spmtest';
% destpath = '/tmp';

% Has this been run before?
blah = dir([destpath '/' subjectid]);

if length(blah)~=0
    error([destpath '/' subjectid ' appears to have contents.  Please pull data to a location with no contents to avoid file collisions.'])
end

% Get current wd
startingwd = pwd;

%% Construct the call to cbs_get
% An example call is:
% cbsget -r 4,5,6,7 -s 120418_spmtest

allruns = [boldruns structrun fmruns];

runstr = '';
for runnum = 1:length(allruns)
    runstr = [runstr num2str(allruns(runnum)) ','];
end

% remove the last extraneous comma
runstr = runstr(1:end-1);

cbscmd = ['cbsget -r ' runstr ' -s ' subjectid];

disp('Running cbsget as follows:')
disp(cbscmd)

[status,result] = system(cbscmd);

if status~=0
   error(['cbsget could not be run successfully!' 10 result])
end

%%  Unzip the files to the specified directory

unzipcmd = ['unzip ' subjectid '.zip -d ' destpath];
disp('Unzipping data as follows:')
disp(unzipcmd)

[status,result] = system(unzipcmd);

if status~=0
   error(['DICOM archive could not be unzipped successfully!' 10 result])
end

disp('...complete!')

%% Create the directory structure 

dirnames = {'analysis','batch','preproc'};

for d = 1:length(dirnames)
    
    mkcmd = ['mkdir ' destpath '/' subjectid '/' dirnames{d}];
    
    disp('Making new directory as follows:')
    disp(mkcmd)
    [status,result] = system(mkcmd);
    
    if status~=0
        error(['mkdir command could not be run successfully!' 10 result])
    end
    
end

%% Run spm convert on the files

disp('Converting files to SPM format...')
cd(fullfile(destpath,subjectid,'RAW'))
dicom_files = spm_select('list',fullfile(destpath,subjectid,'RAW'),'.dcm');
disp(['Number of DICOMs: ' num2str(length(dicom_files))])
hdrs = spm_dicom_headers(dicom_files);
spm_dicom_convert(hdrs,'all');
disp('...complete!')

%% Rename hdr and img files to smaller pathnames

for b = 1:length(boldruns)
    disp('Moving Bold Runs...')
    runstr = sprintf('%04d',boldruns(b));
    newrunstr = sprintf('%03d',b);
    bruns = dir([destpath '/' subjectid '/RAW/*' runstr '-*-*-*']);
    for br = 1:length(bruns)
        brname = bruns(br).name;
        parsed = regexp(brname,'-','split');
        newname = ['f-run' newrunstr '-' sprintf('%03d',str2num(parsed{3})) brname(end-3:end)];
        cmdname = ['mv ' destpath '/' subjectid '/RAW/' brname ' ' destpath '/' subjectid '/preproc/' newname];
        [status,result] = system(cmdname);
    
        if status~=0
            error(['File could not be moved!' 10 result])
        end
        
    end
end

disp('...complete!')


disp('Moving Structural Run...')
runstr = sprintf('%03d',structrun(1));
srun = dir([destpath '/' subjectid '/RAW/*' runstr '-*-*-*']);
for sr = 1:length(srun)
    srname = srun(sr).name;
    newname = ['s-struct' srname(end-3:end)];
    cmdname = ['mv ' destpath '/' subjectid '/RAW/' srname ' ' destpath '/' subjectid '/preproc/' newname];
    [status,result] = system(cmdname);
    
    if status~=0
        error(['File could not be moved!' 10 result])
    end
end

disp('...complete!')

if length(fmruns)==2
    disp('Moving Field Maps...')
    % magnitude
    runstr = sprintf('%03d',fmruns(1));
    mrun = dir([destpath '/' subjectid '/RAW/*' runstr '-*-*-*']);
    for mr = 1:length(mrun)
        mrname = mrun(mr).name;
        newname = ['s-fieldmap_mag-' mrname(end-5:end)];
        cmdname = ['mv ' destpath '/' subjectid '/RAW/' mrname ' ' destpath '/' subjectid '/preproc/' newname];
        [status,result] = system(cmdname);
        
        if status~=0
            error(['File could not be moved!' 10 result])
        end
    end
    % phase
    runstr = sprintf('%03d',fmruns(2));
    mrun = dir([destpath '/' subjectid '/RAW/*' runstr '-*-*-*']);
    for mr = 1:length(mrun)
        mrname = mrun(mr).name;
        newname = ['s-fieldmap_phase' mrname(end-3:end)];
        cmdname = ['mv ' destpath '/' subjectid '/RAW/' mrname ' ' destpath '/' subjectid '/preproc/' newname];
        [status,result] = system(cmdname);
        
        if status~=0
            error(['File could not be moved!' 10 result])
        end
    end    
    disp('...complete!')
end

%% Archive the original files

origfiles = dir([destpath '/' subjectid '/RAW/*']);

thisdir = pwd();
cd([destpath '/' subjectid '/RAW/']);
tgzcmd = ['tar -cvzf ' destpath '/' subjectid '/RAW/' subjectid '.tar.gz '  '*'];


disp('Rearchiving data as follows:')
disp(tgzcmd)
[status,result] = system(tgzcmd);

if status~=0
   error(['DICOM archive could not be created successfully!' 10 result])
end

disp('Complete!')

cd(thisdir)

disp('Removing uncompressed files...')

rmcmd = ['rm ' destpath '/' subjectid '/RAW/*.gif'];

[status,result] = system(rmcmd);

if status~=0
   warning(['.gif files could not removed!' 10 result])
end

rmcmd = ['rm ' destpath '/' subjectid '/RAW/*.dcm'];

[status,result] = system(rmcmd);

if status~=0
   error(['DICOM files could not be removed!' 10 result])
end

disp('Removing zip file from CBS...')

cd(startingwd)

rmcmd = ['rm ' subjectid '.zip'];

[status,result] = system(rmcmd);

if status~=0
   error(['Original zip file could not be removed!' 10 result])
end


disp('...Complete!')


disp('********************************************************')
disp('*                    Thank You!                        *')
disp('********************************************************')