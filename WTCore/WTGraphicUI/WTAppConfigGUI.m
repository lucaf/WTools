classdef WTAppConfigGUI

    methods(Static)
        function wtAppConfig = configureApplication(updateCurrent, persist, warnReload)
            updateCurrent = nargin > 0 && updateCurrent;
            persist = nargin > 1 && persist;
            warnReload =  nargin > 2 && warnReload;
            wtLog = WTLog();
            wtAppConfig = [];

            if updateCurrent
                wtAppConfigCrnt = WTAppConfig();
            else
                [wtAppConfigCrnt, success] = WTAppConfig(false).load(false);
                if ~success
                    WTDialogUtils.errDlg('Application configuration', 'Failed load the application configuration!');
                    return
                end
            end

            wtAppConfig = copy(wtAppConfigCrnt);
            
            cbPrjLog = [ ...
                'status = ''off'';' ...
                'if get(findobj(gcbf, ''tag'', ''kPrjLog''), ''value''),' ... 
                '  status = ''on'';' ...
                'end;' ...
                'set(findobj(gcbf, ''-regexp'', ''tag'', ''prjLog.*''), ''enable'', status);' ];
            cbMuteStdLog = [ ...
                'status = ''on'';' ...
                'if get(findobj(gcbf, ''tag'', ''kStdLogMute''), ''value''),' ... 
                '  status = ''off'';' ...
                'end;' ...
                'set(findobj(gcbf, ''-regexp'', ''tag'', ''stdLog.*''), ''enable'', status);' ];

            logLvlStrs = WTLog.LevelStrs;   
            colorMaps = WTGraphicUtils.getColorMaps();
            selectedColorMapIdx = find(strcmp(colorMaps, wtAppConfig.PlotsColorMap));
            selectedColorMapIdx = WTCodingUtils.ifThenElse(isempty(selectedColorMapIdx), 1, selectedColorMapIdx);

            answer = { ...
                wtAppConfig.ShowSplashScreen ...
                wtAppConfig.DangerWarnings ...
                selectedColorMapIdx ...
                wtAppConfig.ProjectLog ...
                wtAppConfig.ProjectLogLevel ...
                wtAppConfig.MuteStdLog ...
                wtAppConfig.ColorizedLog ...
                wtAppConfig.DefaultStdLogLevel ...
            };

            function parameters = setParameters(answer)
                enablePrjLogOpt = WTCodingUtils.ifThenElse(wtAppConfig.ProjectLog, 'on', 'off');
                enableStdLogOpt = WTCodingUtils.ifThenElse(wtAppConfig.MuteStdLog, 'off', 'on');

                parameters = { ...
                    { 'style' 'text'      'string' 'Show splash screen' } ...
                    { 'style' 'checkbox'  'value'  answer{1,1} } ...
                    { 'style' 'text'      'string' 'Warn about possibly dangerous operations' } ...
                    { 'style' 'checkbox'  'value'  answer{1,2} } ...
                    { 'style' 'text'      'string' 'Plots color map' } ...
                    { 'style' 'popupmenu' 'string' colorMaps 'value' answer{1,3} }...
                    { 'style' 'text'      'string' 'Project log' } ...
                    { 'style' 'checkbox'  'value'  answer{1,4} 'tag' 'kPrjLog' 'callback' cbPrjLog } ...
                    { 'style' 'text'      'string' 'Project log level' 'tag' 'prjLogLvlTxt' 'enable' enablePrjLogOpt } ...
                    { 'style' 'popupmenu' 'string' logLvlStrs 'value' answer{1,5} 'tag' 'prjLogLvl' 'enable' enablePrjLogOpt }...
                    { 'style' 'text'      'string' 'Mute standard log'  } ...
                    { 'style' 'checkbox'  'value'  answer{1,6} 'tag' 'kStdLogMute' 'callback' cbMuteStdLog } ...
                    { 'style' 'text'      'string' 'Colorised standard log' 'tag' 'stdLogColorTxt' } ...
                    { 'style' 'checkbox'  'value'  answer{1,7} 'tag' 'stdLogColor' 'enable' enableStdLogOpt } ...
                    { 'style' 'text'      'string' 'Default standard log level' 'tag' 'stdLogLvlTxt' 'enable' enableStdLogOpt } ...
                    { 'style' 'popupmenu' 'string' logLvlStrs 'value' answer{1,8} 'tag' 'stdLogLvl' 'enable' enableStdLogOpt } ...
                };
            end
            
            geometry = { [0.6 0.4] [0.6 0.4] [0.6 0.4] [0.6 0.4] [0.6 0.4] [0.6 0.4] [0.6 0.4] [0.6 0.4] };
            success = false;
            anyChange = false;

            while ~success
                parameters = setParameters(answer);
                answer = WTEEGLabUtils.eeglabInputMask('geometry', geometry, 'uilist', parameters, 'title', 'Configuration');
                
                if isempty(answer)
                    wtAppConfig = [];
                    return 
                end

                try
                    wtAppConfig.PlotsColorMap = colorMaps{answer{1,3}};
                    wtAppConfig.ShowSplashScreen = answer{1,1};
                    wtAppConfig.DangerWarnings = answer{1,2};
                    wtAppConfig.ProjectLog = answer{1,4};
                    wtAppConfig.ProjectLogLevel = answer{1,5};
                    wtAppConfig.MuteStdLog = answer{1,6};
                    wtAppConfig.ColorizedLog = answer{1,7};
                    wtAppConfig.DefaultStdLogLevel = answer{1,8};
                    anyChange = ~wtAppConfigCrnt.equalTo(wtAppConfig);
                    success = true;
                catch me
                    wtLog.except(me);
                end

                if ~success
                    WTDialogUtils.wrnDlg('Review parameter', 'Invalid parameters: check the log for details');
                elseif ~wtAppConfigCrnt.MuteStdLog && wtAppConfig.MuteStdLog && ...
                       ~WTEEGLabUtils.eeglabYesNoDlg('Confirm application configuration', ...
                            'Muting standard log might hide important information! Continue?')
                    success = false;
                    anyChange = false;
                elseif wtAppConfigCrnt.DangerWarnings && ~wtAppConfig.DangerWarnings && ...
                       ~WTEEGLabUtils.eeglabYesNoDlg('Confirm application configuration', ...
                        'Disabling warnings on possibly dangerous operations is generally not a good idea! Continue?')
                    success = false;
                    anyChange = false;
                end
            end

            if ~anyChange
                return
            end

            if updateCurrent
                wtAppConfig.copyTo(WTAppConfig());
            end

            if persist && ~wtAppConfig.persist()
                WTDialogUtils.errDlg('Application configuration', 'Failed to save the application configuration!');
                wtAppConfig = [];
            elseif warnReload && WTSession().IsOpen
                WTDialogUtils.wrnDlg('Application configuration', 'Quit and open again wtools to load the updated configuration');
            end
        end
    end
end