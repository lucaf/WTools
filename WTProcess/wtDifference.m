% wtDifference.m
% Created by Eugenio Parise
% CDC CEU 2010 - 2011
% Calculate the wtDifference between two conditions (e.g. cA-cB C3-C4);
% Store the resulting files in the subject folder.
% IMPORTANT! Define the condition you want to subtract by editing the variable 'condiff'
% in the file 'cond.m' ('cfg' folder).
% To set this script to process the whole final sample of subjects in a study,
% edit 'subj.m' in the 'cfg' folder and  digit wtDifference([]) at the console prompt.
% Add evoked = true  as last argument to compute conditions wtDifference of evoked
% oscillations (of course, if they have been previously computed).
%
% Usage:
%
% wtDifference('01');
% wtDifference([]);
% wtDifference([], true);

% By Luca
% Input params are now:
%  - subjects (cells array of strings) [optional] or if undefined, wtProject.Config.Subjects.SubjectsList
%  - wtProject.Config.Difference 
%  if the project is interactive (wtProject.Interactive = true), both can be modified via the GUI

function wtDifference(subjects)
    wtProject = WTProject();
    wtLog = WTLog();

    if ~wtProject.checkIsOpen() 
        return
    end

    if ~wtProject.Config.SubjectsGrand.exist() || ...
       ~wtProject.Config.WaveletTransform.exist()
        wtProject.notifyInf([], 'Wavelet transformation needs to be performed first!');
        return
    end

    % TODO: clarify why we get subjects from wtProject.Config.Subjects and not from wtProject.Config.SubjectsGrand?
    if nargin == 0 
        subjects = wtProject.Config.Subjects.SubjectsList;
    elseif ischar(subjects)
        subjects = {subjects};
    elseif ~WTValidations.isALinearCellArrayOfNonEmptyString(subjects)
        wtProject.notifyErr([], 'Bad argument format: subjects must be a string or must be a linear cell array of non empty strings!');
        return
    end
    
    if isempty(subjects)
        wtProject.notifyWrn([], 'No subjects defined!');
        return
    end

    if length(wtProject.Config.ConditionsGrand.ConditionsList) < 2
        wtProject.notifyWrn([], 'There is only one condition, so no conditions diff can be performed!');
        return
    end

    if wtProject.Interactive
        subjects = WTUtils.stringsSelectDlg('Select subjects\nfor difference:', subjects);
        if isempty(subjects) || ~setDifferencePrms()
            return
        end
    end

    % Note: setDifferencePrms() updates both condsGrandPrms, differencePrms
    condsGrandPrms = wtProject.Config.ConditionsGrand;
    differencePrms = wtProject.Config.Difference;
    ioProc = wtProject.Config.IOProc;
    conditions = condsGrandPrms.ConditionsList;
    condiff = condsGrandPrms.ConditionsDiff;
    nSubjects = length(subjects);
    nConditions = length(conditions);
    nCondiff = length(condiff);
    condsToSubtract = [];

    % Find the conditions to subtract and put them in condsToSubtract array
    for i = 1:nCondiff
        j = 1;
        temp = zeros(1,2);

        while j <= nConditions
            [~,~,~,matchString] = regexp(condiff(i),conditions(j));

            if ~isempty(matchString{1,1})
                minusPos = strfind(char(condiff(i)), '-');
                condPos = strfind(char(condiff(i)), char(matchString{1,1}{1,1}));
                
                % condPos is 1 in length = 1 match found in the condition difference array.
                if length(condPos) == 1
                    if ~(condPos(1) == 1 || condPos(1) == minusPos+1) % fake match found
                        matchString{1,1} = [];
                    end
                end
                
                % condPos is 2 in length = 2 matchs found in the condition difference array.
                if length(condPos) > 1
                    if condPos(1) == 1 && condPos(2) == minusPos + 1
                        % do nothing: the user want to subtract a condition from itself
                    elseif condPos(1) ~= 1 && condPos(2) ~= minusPos + 1 % fake match found
                        matchString{1,1} = [];
                    elseif condPos(1) ~= 1
                        condPos = condPos(2); % this is the only true match
                        matchString{1,1} = {conditions(j)};
                    elseif condPos(1) == 1
                        condPos = condPos(1); % this is the only true match
                        matchString{1,1} = {conditions(j)};
                    end
                end
            end
            
            % Both conditions not found in the difference string
            if isempty(matchString{1,1}) && temp(1) == 0 && temp(2) == 0 && j == nConditions
                wtProject.notifyErr([], ['Both conditions in the pair %s do not match any experimental condition!\n' ...
                    'Edit %s in the configuration folder and correct your setting'], ...
                    condiff{i}, condsGrandPrms.getFileName());
                return
            % One condition found in the difference string
            elseif ~isempty(matchString{1,1}) && length(matchString{1,1}) == 1
                actualCond = strfind(conditions,char(matchString{1,1}{1,1}));
                for k = 1:length(actualCond)
                    if ~isempty(actualCond{k}) && actualCond{k}>1
                        actualCond{k}=[];
                    end
                end
                notemptyCells = ~cellfun(@isempty, actualCond);
                if minusPos < condPos
                    temp(2) = find(notemptyCells == 1);
                else
                    temp(1) = find(notemptyCells == 1);
                end
                if temp(1) ~= 0 && temp(2) ~= 0
                    j = nConditions;
                end    
            % Two equal conditions found in the difference string
            elseif ~isempty(matchString{1,1}) && length(matchString{1,1}) == 2
                actualCond = strfind(conditions,char(matchString{1,1}{1,1}));
                for k = 1:length(actualCond)
                    if ~isempty(actualCond{k}) && actualCond{k} > 1
                        actualCond{k} = [];
                    end
                end
                notemptyCells = ~cellfun(@isempty,actualCond);
                temp(:) = find(notemptyCells == 1);
                j = nConditions;

                wtProject.notifyWrn([], ['Condition %s will be subtracted from itself!\n' ...
                    'Consider to edit %s in the configuration folder and correct your setting.'], ...
                    conditions{temp(1)}, condsGrandPrms.getFileName());
            end
            
            j = j+1;
        end
        
        % One condition not found in the difference string
        if temp(1) == 0 || temp(2) == 0
            wtProject.notifyErr([], ['One condition in the pair %s do not match any experimental condition!\n' ...
                'Edit %s in the configuration folder and correct your setting'], condiff{i}, condsGrandPrms.getFileName());
            return
        else
            condsToSubtract = cat(2,condsToSubtract,temp);
        end
    end

    nCondsToSubtract = length(condsToSubtract);
    measure = WTUtils.ifThenElseSet(differencePrms.EvokedOscillations, ...
                WTIOProcessor.WaveletsAnalisys_evWT, ...
                WTIOProcessor.WaveletsAnalisys_avWT);

    wtLog.info('Computing difference between conditions...');
    wtLog.pushStatus().ctxOn();

    for s = 1:nSubjects
        correction = 0;

        for cnd = 1:nCondsToSubtract/2
            % load first datasets
            cA = conditions{condsToSubtract(cnd + correction)};

            [success, data1] = ioProc.loadBaselineCorrection(subjects{s}, cA, measure);
            if ~success 
                wtProject.notifyErr([],'Failed to load dataset for subject ''%s'', condition: ''%s''', subjects{s}, cA);
                wtLog.popStatus();
                return
            end

            cB = conditions{condsToSubtract(cnd + correction + 1)};

            [success, data2] = ioProc.loadBaselineCorrection(subjects{s}, cB, measure);
            if ~success 
                wtProject.notifyErr([],'Failed to load dataset for subject ''%s'', condition: ''%s''', subjects{s}, cB);
                wtLog.popStatus();
                return
            end

            data2.WT = data1.WT - data2.WT;

            [success, filePath] = ioProc.writeDifference(subjects{s}, cA, cB, measure, '-struct', 'data2');
            if ~success 
                wtProject.notifyErr([], 'Failed to save difference data to ''%s''', filePath);
                wtLog.popStatus();
                return
            else
                wtLog.info('Difference (%s - %s) saved in subject %s folder.', cA, cB, subjects{s});  
            end

            correction = correction + 1;          
        end
    end

    wtLog.popStatus();
    wtProject.notifyInf([], 'Difference computation completed!');
end

function success = setDifferencePrms()   
    success = false;  
    wtProject = WTProject();
    wtLog = WTLog();

    condsGrandPrms = copy(wtProject.Config.ConditionsGrand);
    differencePrms = copy(wtProject.Config.Difference);
    [logFlag, wtEvok] = wtCheckEvokLog();

    if ~WTDifferenceGUI.differenceParams(differencePrms, condsGrandPrms, logFlag, wtEvok)
        return
    end
    if ~condsGrandPrms.persist() 
        wtProject.notifyErr([], 'Failed to save conditions grand params');
        return
    end

    wtProject.Config.ConditionsGrand = condsGrandPrms;

    if ~differencePrms.persist()
        wtProject.notifyErr([], 'Failed to save difference params');
        return
    end

    wtProject.Config.Difference = differencePrms;
    success = true;
end