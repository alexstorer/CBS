%% genArtBatches - a program for CBS to run art in batch mode, assuming SPM.mat as input.  
%        Usage: genArtBatches (base_dir, subjects 
%                 use_diff_global (1,0), ==> 1-Yes, 0-No
%                 use_diff_motion (1,0), ==> 1-Yes, 0-No
%                 use_norms (1,0),  ==> 1-Combine all movement dimensions, 0-Not combine
%                 global_threshold,  ==> Threshold for outlier detection
%                                        based on global signal(actual value or std)
%                 motion_threshold) ==> Threshold                       
%                                       for outlier detection based on
%                                       motion estimate (mm)
%                  genArtBatches('/ncf/snp/06/SPAA/CBS/MID_analysis_art',{'subject1','subject2','subject3'},0,1,0,4,3)
%         This will create a subdirectory called 'art_analysis' and place
%         in this directory a configuration file and matlab art run script.
function genArtBatches(base_dir,subjects, input_use_diff_global, input_use_diff_motion, input_use_norms, input_global_threshold, input_motion_threshold, input_global_mean, input_motion_file_type)
%addpath('/ncf/snp/11/tools/art');
addpath([ getenv('_HVD_APPS_DIR') filesep 'arch' filesep getenv('_HVD_PLATFORM') filesep 'art' filesep '2011_07'])
thisdir = pwd();
%%%%%%%%%%%% ART PARAMETERS (edit to desired values) %%%%%%%%%%%%
global_mean=input_global_mean;                   % global mean type (1: Standard 2: Every Voxel 3: User Mask 4: Auto)
motion_file_type=input_motion_file_type;         % motion file type (0: SPM .txt file 1: FSL .par file 2:Siemens .txt file) hard code for now
global_threshold=input_global_threshold;         % threshold for outlier detection based on global signal
motion_threshold=input_motion_threshold;         % threshold for outlier detection based on motion estimates
use_diff_global=input_use_diff_global;
use_diff_motion=input_use_diff_motion;
use_norms=input_use_norms;

dt = datestr(now,'yyyy_mm_dd_HHMM');

if ~iscell(subjects)
    subfile = subjects;
    fid = fopen(subfile,'r');
    if fid==-1
        error(['Subject list file does not exist:' 10 subfile])
    end
    subjects = {};
    while 1
        tline = fgetl(fid);
        if ~ischar(tline), break, end
        subjects{end+1} = tline;
    end
    fclose(fid);
end
    
for subInd = 1:length(subjects)
    subjectDir = [base_dir '/' subjects{subInd}];
    artDir = [subjectDir '/art_analysis'];
    files = [subjectDir '/analysis/SPM.mat'];
    % make the configuration files
    for n1=1:size(files,1),
        [filepath,filename,fileext]=fileparts(deblank(files(n1,:)));
        display(['Change to',filepath]);
        cd(filepath);
        if ~exist(artDir)
            mkcmd = ['mkdir ' artDir];
            disp('Making new directory as follows:')
            disp(mkcmd)
            [status,result] = system(mkcmd);
            
            if status~=0
                error(['mkdir command could not be run successfully!' 10 result])
            end
        end
        cfgfile=fullfile(artDir,['art_config',num2str(n1,'%03d'),'.cfg']);
        fid=fopen(cfgfile,'wt');
        %[filepath,filename,fileext]=fileparts(deblank(files(n1,:)));
        save_filename=[artDir,'/',filename,'_stats_file'];
        display('writing cfg file and load SPM');
        load(deblank(files(n1,:)),'SPM');
        
        fprintf(fid,'# Automatic script generated by %s\n',mfilename);
        fprintf(fid,'sessions: %d\n',length(SPM.Sess));
        fprintf(fid,'global_mean: %d\n',global_mean);
        fprintf(fid,'global_threshold: %f\n',global_threshold);
        fprintf(fid,'motion_threshold: %f\n',motion_threshold);
        fprintf(fid,'motion_file_type: %d\n',motion_file_type);
        fprintf(fid,'use_diff_global: %d\n',use_diff_global);
        fprintf(fid,'use_diff_motion: %d\n',use_diff_motion);
        fprintf(fid,'use_norms: %d\n', use_norms);
        fprintf(fid, 'comp_motion: 0\n');
        fprintf(fid,'motion_fname_from_image_fname: 1\n');
        fprintf(fid,'spm_file: %s\n',deblank(files(n1,:)));
        fprintf(fid,'end\n');
        
        for n2=1:length(SPM.Sess),
            temp=[SPM.xY.P(SPM.Sess(n2).row,:),repmat(' ',[length(SPM.Sess(n2).row),1])]';
            fprintf(fid,'session %d image %s\n',n2,temp(:)');
        end
        fprintf(fid,'end\n');
        fclose(fid);
    end

    % make the run file
    for n1=1:size(files,1)
        runfile=fullfile(artDir,['art_exec',num2str(n1,'%03d'),'.m']);
        disp([10 'Creating runfile: ' runfile 10])
        [fid,msg]=fopen(runfile,'wt');
        if fid==-1
            error(['Problem creating art executable: ' msg])
        end
        fprintf(fid,'%% Automatic script to run art generated by %s\n',mfilename);
        fprintf(fid,['try\n']);
        cfgfile=fullfile(artDir,['art_config',num2str(n1,'%03d'),'.cfg']);
        fprintf(fid,['cfgfile=''%s'';\n'],cfgfile);
        dispstr = ['''running subject ',num2str(n1),' using config file ',cfgfile,''''];
        fprintf(fid,['disp(%s)\n'],dispstr);
        %fprintf(fid,['addpath(' 39 '/ncf/snp/11/tools/art' 39 ');\n']);
	fprintf(fid,['addpath([getenv(' 39 '_HVD_APPS_DIR' 39 ') filesep ' 39 'arch' 39 ' filesep getenv(' 39 '_HVD_PLATFORM' 39 ') filesep ' 39 'art' 39 ' filesep ' 39 '2011_07' 39 ']);\n']);
        artstr = ['art(''sess_file'',''' cfgfile ''',''stats_file'',''' save_filename ''');'];
        fprintf(fid,'%s\n',artstr);
        % close the window after specified time
        fprintf(fid,'close(gcf);\n');
        fprintf(fid,'catch err\n');
        fprintf(fid,'m = err.message;\n');
        fprintf(fid,['error([10 datestr(now) 10 ' 39 ' Batch could not be run: ' 39 ' 10 mfilename(' 39 'fullpath' 39 ') 10 m 10]);\n']);
        fprintf(fid,'end\n');
        fclose(fid);
        disp([10 'Successfully created ' runfile 10])
        
        % and submit it!
        [filepath scriptname ext] = fileparts(runfile);
        bsubcmd = ['bsub -e ' base_dir '/errors_ART_' dt];
        bsubcmd = [bsubcmd ' -o ' subjectDir '/output_files/output_ART'];
        bsubcmd = [bsubcmd dt];
        bsubcmd = [bsubcmd ' -q ncf'];
        bsubcmd = [bsubcmd ' matlab -nodisplay -r ' 34 'cd ' filepath '; ' scriptname 34];
        system(bsubcmd);

    end
    
    
end


cd(thisdir)
return;
