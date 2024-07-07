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

classdef WTBaselineChopGUI
    
    methods(Static)
        function success = defineBaselineChopParams(baselineChopParams, logFlag, evokFlag)
            success = false;
            WTValidations.mustBe(baselineChopParams, ?WTBaselineChopCfg);

            wtLog = WTLog();
            baselineChopParamsExist = baselineChopParams.exist();
            
            % EvokedOscillations can not be set: it reflects previous choices (wavelet tansformation)
            evokedOscillations = WTCodingUtils.ifThenElse(evokFlag, 1, 0);
            enableEvok = 'off';

            % Log10 can be set only if data have not been already log transformed
            enableLog = WTCodingUtils.ifThenElse(logFlag, 'off', 'on');
            enableBs = WTCodingUtils.ifThenElse(baselineChopParamsExist && baselineChopParams.NoBaselineCorrection, 'off', 'on');

            answer = { ...
                num2str(baselineChopParams.ChopTimeMin), ...
                num2str(baselineChopParams.ChopTimeMax), ...
                num2str(baselineChopParams.BaselineTimeMin), ...
                num2str(baselineChopParams.BaselineTimeMax), ...
                WTCodingUtils.ifThenElse(logFlag, 1, baselineChopParams.LogarithmicTransform), ...
                baselineChopParams.NoBaselineCorrection, ...
                evokedOscillations };
            
            cbEnableBs = ['set(findobj(gcbf, ''userdata'', ''NoBC''),' ...
                        '''enable'',' 'WTCodingUtils.ifThenElse(get(gcbo, ''value''), ''off'', ''on''));'];
            
            function params = setParameters(answer) 
                params = { ...
                    { 'style' 'text'     'string' 'Chop Ends:              Left' } ...
                    { 'style' 'edit'     'string' answer{1,1} } ...
                    { 'style' 'text'     'string' 'Right' } ...
                    { 'style' 'edit'     'string' answer{1,2} } ...
                    { 'style' 'text'     'string' 'Correct Baseline:    From' } ...
                    { 'style' 'edit'     'string' answer{1,3} 'userdata' 'NoBC' 'enable' enableBs } ...
                    { 'style' 'text'     'string' 'To' } ...
                    { 'style' 'edit'     'string' answer{1,4} 'userdata' 'NoBC' 'enable' enableBs } ...
                    { 'style' 'text'     'string' '' } ...
                    { 'style' 'text'     'string' '' } ...
                    { 'style' 'text'     'string' '' } ...
                    { 'style' 'text'     'string' '' } ...
                    { 'style' 'checkbox' 'value' answer{1,5} 'string' 'Log10-Transform' 'enable' enableLog } ...
                    { 'style' 'checkbox' 'value' answer{1,6} 'string' 'No Baseline Correction', 'callback', cbEnableBs } ...
                    { 'style' 'checkbox' 'value' answer{1,7} 'string' 'Evoked Oscillations' 'enable'  enableEvok } };
            end

            geometry = { [1 0.5 0.5 0.5] [1 0.5 0.5 0.5] [1 1 1 1] 1 1 1 };

            while ~success
                parameters = setParameters(answer);
                answer = WTEEGLabUtils.eeglabInputMask('geometry', geometry, 'uilist', parameters, 'title', 'Set baseline and edges chopping parameters');
                
                if isempty(answer)
                    wtLog.dbg('User quitted baseline and chopping configuration dialog');
                    return % quit on cancel button
                end

                success = all([ ...
                    WTTryExec(@()set(baselineChopParams, 'ChopTimeMin', WTNumUtils.str2double(answer{1,1}))).logWrn().displayWrn('Review parameter', 'Invalid ChopTimeMin').run().Succeeded ...
                    WTTryExec(@()set(baselineChopParams, 'ChopTimeMax', WTNumUtils.str2double(answer{1,2}))).logWrn().displayWrn('Review parameter', 'Invalid ChopTimeMax').run().Succeeded ... 
                    WTTryExec(@()set(baselineChopParams, 'LogarithmicTransform', answer{1,5})).logWrn().displayWrn('Review parameter', 'Invalid LogarithmicTransform').run().Succeeded ... 
                    WTTryExec(@()set(baselineChopParams, 'NoBaselineCorrection', answer{1,6})).logWrn().displayWrn('Review parameter', 'Invalid NoBaselineCorrection').run().Succeeded ... 
                    WTTryExec(@()set(baselineChopParams, 'EvokedOscillations', answer{1,7})).logWrn().displayWrn('Review parameter', 'Invalid EvokedOscillations').run().Succeeded ... 
                ]);

                if success
                    if baselineChopParams.NoBaselineCorrection
                        % Update baseline window only if baseline correction was selected, 
                        % otherwise retains previous values for convenience.
                        answer{1,3} = [];
                        answer{1,4} = [];
                    else
                        success = all([ ...
                            WTTryExec(@()set(baselineChopParams, 'BaselineTimeMin', WTNumUtils.str2double(answer{1,3}))).logWrn().displayWrn('Review parameter', 'Invalid BaselineTimeMin').run().Succeeded ...
                            WTTryExec(@()set(baselineChopParams, 'BaselineTimeMax', WTNumUtils.str2double(answer{1,4}))).logWrn().displayWrn('Review parameter', 'Invalid BaselineTimeMax').run().Succeeded ... 
                        ]);
                    end
                end

                success = success && WTTryExec(@()baselineChopParams.validate(true)).logWrn().displayWrn('Review parameter', 'Validation failure').run().Succeeded; 
            end
        end
    end
end