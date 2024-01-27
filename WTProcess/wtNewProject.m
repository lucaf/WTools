% wtNewProject.m
% Created by Eugenio Parise
% CDC CEU 2011
% Create a new project/folder for a WTools project. Subfolders Config and
% Import are created as well; exported.m and filenm.m stored in Config folder.
% A variable called PROJECTPATH is created in the 'base' Wokspace.
%
% Usage: wtNewProject()

function success = wtNewProject
    success = false;
    wtProject = WTProject();
    prjName = '';

    while true 
        prms = { { 'style' 'text' 'string' 'New project name:' } ...
                 { 'style' 'edit' 'string' prjName } };
        answer = WTUtils.eeglabInputMask( 'geometry', { [1 2] }, 'uilist', prms, 'title', '[WTools] Set project name');

        if isempty(answer)
            return 
        end

        prjName = strip(answer{1});
        if wtProject.checkIsValidName(prjName, true)
            break;
        end
    end

    prjParentDir = WTUtils.uiGetDir('.', 'Select the project parent directory...');
    if ~ischar(prjParentDir)
        return
    end

    prjPath = fullfile(prjParentDir, prjName);
    if  WTUtils.dirExist(prjPath)
        if ~WTUtils.eeglabYesNoDlg('Warning', ['Project directory already exists!\n' ...
            'Directory: %s\n' ...
            'Do you want to overwrite it?'], prjPath)
            return;
        end            
    end

    if ~wtProject.new(prjPath)
        return
    end

    wtProject.notifyInf('Project created','As next step you should choose the files to import...');

    wtImportData()
    success = true;
end