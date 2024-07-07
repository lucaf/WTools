% Copyright (C) 2024 Eugenio Parise, Luca Filippin
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program. If not, see <https://www.gnu.org/licenses/>.

classdef WTStatisticsGUI

    methods(Static)

        function [success, subjectsList, conditionsList] = defineStatisticsSettings(statsPrms, subjectsGrandPrms, conditionsGrandPrms, evokFlag) 
            success = false;
            subjectsList = {};
            conditionsList = {};
            WTValidations.mustBe(statsPrms, ?WTStatisticsCfg);
            WTValidations.mustBe(subjectsGrandPrms, ?WTSubjectsGrandCfg);
            WTValidations.mustBe(conditionsGrandPrms, ?WTConditionsGrandCfg);
            wtLog = WTLog();

            subjects = subjectsGrandPrms.SubjectsList;
            if isempty(subjects)
                WTDialogUtils.errDlg('Bad parameter', 'There project subjects list is empty!');
                return
            end

            conditions = conditionsGrandPrms.ConditionsList;
            if isempty(conditions)
                WTDialogUtils.errDlg('Bad parameter', 'The project conditions list is empty!');
                return
            end

            evokFlag = WTCodingUtils.ifThenElse(evokFlag, 1, 0);
            enableEvok = 'off';

            answer = { ...
                num2str(statsPrms.TimeMin) ...
                num2str(statsPrms.TimeMax) ...
                num2str(statsPrms.FreqMin) ...
                num2str(statsPrms.FreqMax) ...
                statsPrms.IndividualFreqs ...
                evokFlag ...
                [], ...
                [], ... 
            };

            function params = setParameters(answer) 
                params = { ...
                    { 'style' 'text'     'string' 'Time (ms): From     ' } ...
                    { 'style' 'edit'     'string' answer{1,1} } ...
                    { 'style' 'text'     'string' 'To' } ...
                    { 'style' 'edit'     'string' answer{1,2} }...
                    { 'style' 'text'     'string' 'Frequency (Hz): From' } ...
                    { 'style' 'edit'     'string' answer{1,3} }...
                    { 'style' 'text'     'string' 'To' } ...
                    { 'style' 'edit'     'string' answer{1,4} }.....
                    { 'style' 'text'     'string' '' } ...
                    { 'style' 'checkbox' 'string' 'Retrieve individual frequencies' 'value'  answer{1,5} } ...
                    { 'style' 'checkbox' 'string' 'Retrieve evoked oscillations' 'value'  answer{1,6} 'enable' enableEvok } ...
                    { 'style' 'text'     'string' '' } ...
                    { 'style' 'text'     'string' 'Subjects (no selection = all)'   } ...
                    { 'style' 'text'     'string' 'Conditions (no selection = all)' } ...
                    { 'style' 'listbox'  'tag'  'subjs' 'string' subjects   'value' answer{1,7} 'min' 0 'max' length(subjects) }, ...
                    { 'style' 'listbox'  'tag'  'conds' 'string' conditions 'value' answer{1,8} 'min' 0 'max' length(conditions) }, ...
                };
            end

            geometry = { [0.25 0.15 0.15 0.15] [0.25 0.15 0.15 0.15] 1 1 1 1 [0.5 0.5] [0.5 0.5] };
            geomvert = [ 1 1 1 1 1 1 1 min(max(length(subjects), length(conditions)), 10) ];

            while ~success
                parameters = setParameters(answer);
                answer = WTEEGLabUtils.eeglabInputMask('geometry', geometry, 'geomvert', geomvert, 'uilist', parameters, 'title', 'Set statistics parameters');
                
                if isempty(answer)
                    wtLog.dbg('User quitted statistics configuration dialog');
                    return 
                end

                success = all([ ...
                    WTTryExec(@()set(statsPrms, 'TimeMin', WTNumUtils.str2double(answer{1,1}))).logWrn().displayWrn('Review parameter', 'Invalid TimeMin').run().Succeeded ...
                    WTTryExec(@()set(statsPrms, 'TimeMax', WTNumUtils.str2double(answer{1,2}))).logWrn().displayWrn('Review parameter', 'Invalid TimeMax').run().Succeeded ... 
                    WTTryExec(@()set(statsPrms, 'FreqMin', WTNumUtils.str2double(answer{1,3}))).logWrn().displayWrn('Review parameter', 'Invalid FreqMin').run().Succeeded ... 
                    WTTryExec(@()set(statsPrms, 'FreqMax', WTNumUtils.str2double(answer{1,4}))).logWrn().displayWrn('Review parameter', 'Invalid FreqMax').run().Succeeded ...
                    WTTryExec(@()set(statsPrms, 'IndividualFreqs', answer{1,5})).logWrn().displayWrn('Review parameter', 'Invalid IndividualFreqs').run().Succeeded ... 
                    WTTryExec(@()set(statsPrms, 'EvokedOscillations', answer{1,6})).logWrn().displayWrn('Review parameter', 'Invalid EvokedOscillations').run().Succeeded ... 
                    WTTryExec(@()subjects(answer{1,7})).logWrn().displayWrn('Review parameter', 'Invalid Subjects selection').run().Succeeded ... 
                    WTTryExec(@()conditions(answer{1,8})).logWrn().displayWrn('Review parameter', 'Invalid Conditions selection').run().Succeeded ... 
                ]);

                success = success && WTTryExec(@statsPrms.validate).logWrn().displayWrn('Review parameter', 'Validation failure').run().Succeeded; 

                if success
                    subjectsList = subjects(answer{1,7});
                    conditionsList = conditions(answer{1,8});
                end
            end
        end

    end
end