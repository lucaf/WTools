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

classdef WTAppConfig < WTClass & matlab.mixin.Copyable & matlab.mixin.SetGet

    properties(Constant)
        ClassUUID = 'c6848e73-fb3c-48c6-a542-695ac2225339'
    end

    properties (Constant,Hidden)
        ConfigFileName = 'wtools.json'

        FldShowSplashScreen = "ShowSplashScreen"
        FldDangerWarnings = "DangerWarnings"
        FldDefaultStdLogLevel = 'DefaultStdLogLevel'
        FldProjectLogLevel = 'ProjectLogLevel'
        FldProjectLog = 'ProjectLog'
        FldMuteStdLog = 'MuteStdLog'
        FldColorizedLog = 'ColorizedLog'
        FldPlotsColorMap = 'PlotsColorMap'
    end

    properties (SetAccess=private, GetAccess=public)
        ConfigFile
    end

    properties(Access=public)
        ShowSplashScreen(1,1) logical
        DangerWarnings(1,1) logical
        DefaultStdLogLevel(1,1) uint8
        ProjectLogLevel(1,1) uint8
        ProjectLog(1,1) logical
        MuteStdLog(1,1) logical     % effective only when ProjectLog = true
        ColorizedLog(1,1) logical   % apply only to standard log
        PlotsColorMap char
    end 

    methods(Static, Access=private)
        function [level, valid] = validLogLevel(level, levelType, throwExcpt)
            valid = false;
            if ischar(level) 
                code = WTLog.logLevelCode(level);
                valid = ~isempty(code);
                if ~valid
                    excp = WTException.badValue('Not a valid %s log level: ''%s''', levelType, level);
                else
                    level = code;
                end
            elseif WTValidations.isInt(level) 
                valid = ~isempty(WTLog.logLevelStr(level));
                if ~valid
                    excp = WTException.badValue('Not a valid %s log level: ''%d''', levelType, level);
                end
            else 
                excp = WTException.badValue('Not a valid %s log level type: ''%s''', levelType, class(level));
            end
            if ~valid
                WTCodingUtils.throwOrLog(excp, ~throwExcpt);
            end
        end

        function [colorMap, valid] = validColorMap(colorMap, throwExcpt)
            if ~WTGraphicUtils.isValidColorMap(colorMap)
                excp = WTException.badValue('Not a valid colormap: ''%s''', colorMap);
                WTCodingUtils.throwOrLog(excp, ~throwExcpt);
            end
        end
    end

    methods
        function o = WTAppConfig(singleton)
            singleton = nargin < 1 || singleton;
            o = o@WTClass(singleton, true);
            if ~o.InstanceInitialised
                o.ConfigFile = fullfile(WTLayout.getAppConfigDir(), o.ConfigFileName);
                o.default();
                o.load();
            end
        end

        function copyFrom(o, oo)
            WTValidations.mustBe(oo, ?WTAppConfig);
            o.ShowSplashScreen = oo.ShowSplashScreen;
            o.DangerWarnings = oo.DangerWarnings;
            o.DefaultStdLogLevel = oo.DefaultStdLogLevel;
            o.ProjectLogLevel = oo.ProjectLogLevel;
            o.MuteStdLog = oo.MuteStdLog;
            o.ProjectLog = oo.ProjectLog;
            o.ColorizedLog = oo.ColorizedLog;
            o.PlotsColorMap = oo.PlotsColorMap;
        end 

        function copyTo(o, oo)
            WTValidations.mustBe(oo, ?WTAppConfig); 
            oo.copyFrom(o)
        end

        function same = equalTo(o, oo)
            WTValidations.mustBe(oo, ?WTAppConfig); 
            same = o.ShowSplashScreen == oo.ShowSplashScreen && ...
                o.DangerWarnings == oo.DangerWarnings && ...
                o.DefaultStdLogLevel == oo.DefaultStdLogLevel && ...
                o.ProjectLogLevel == oo.ProjectLogLevel && ...
                o.MuteStdLog == oo.MuteStdLog && ...
                o.ProjectLog == oo.ProjectLog && ...
                o.ColorizedLog == oo.ColorizedLog && ...
                strcmp(o.PlotsColorMap, oo.PlotsColorMap);
        end

        function o = default(o)
            o.ShowSplashScreen = false;
            o.DangerWarnings = true;
            o.DefaultStdLogLevel = WTLog.LevelInf;
            o.ProjectLogLevel = WTLog.LevelInf;
            o.ProjectLog = false;
            o.MuteStdLog = false;
            o.ColorizedLog = true;
            o.PlotsColorMap = 'parula';
        end
        
        function set.ProjectLogLevel(o, level)
            o.ProjectLogLevel = WTAppConfig.validLogLevel(level, 'project', true);
        end

        function set.DefaultStdLogLevel(o, level)
            o.DefaultStdLogLevel = WTAppConfig.validLogLevel(level, 'standard', true);
        end

        function set.PlotsColorMap(o, colorMap)
            o.PlotsColorMap = WTAppConfig.validColorMap(strip(colorMap), true);
        end

        function [o, success] = load(o, throwExcpt)
            throwExcpt = nargin > 1 && throwExcpt;
            success = true;
            try
                [jsonText, success] = WTIOUtils.readTxtFile([], o.ConfigFile, 'UTF-8');
                if ~success 
                    WTException.ioErr('Failed to read application configuration').throw();
                end

                data = jsondecode(jsonText);
                c = copy(o);

                if isfield(data, o.FldShowSplashScreen)
                    c.ShowSplashScreen = data.(o.FldShowSplashScreen);
                end
                if isfield(data, o.FldDangerWarnings)
                    c.DangerWarnings = data.(o.FldDangerWarnings);
                end
                if isfield(data, o.FldDefaultStdLogLevel)
                    logLevelStr = char(data.(o.FldDefaultStdLogLevel));
                    c.DefaultStdLogLevel = WTAppConfig.validLogLevel(logLevelStr, 'standard', true);
                end
                if isfield(data, o.FldProjectLogLevel)
                    logLevelStr = char(data.(o.FldProjectLogLevel));
                    c.ProjectLogLevel = WTAppConfig.validLogLevel(logLevelStr, 'project', true);
                end
                if isfield(data, o.FldMuteStdLog)
                    c.MuteStdLog = data.(o.FldMuteStdLog);
                end
                if isfield(data, o.FldProjectLog)
                    c.ProjectLog = data.(o.FldProjectLog);
                end
                if isfield(data, o.FldColorizedLog)
                    c.ColorizedLog = data.(o.FldColorizedLog);
                end
                if isfield(data, o.FldPlotsColorMap)
                    colorMap = data.(o.FldPlotsColorMap);
                    c.PlotsColorMap = WTAppConfig.validColorMap(colorMap, true);
                end
            catch me
                success = false;
                WTCodingUtils.throwOrLog(me, ~throwExcpt);
            end
            if success
                o.copyFrom(c);
            end
        end
 
        function success = persist(o)
            success = false;
            try
                data = struct(); 
                data.(o.FldShowSplashScreen) = o.ShowSplashScreen;
                data.(o.FldDangerWarnings) = o.DangerWarnings;
                data.(o.FldPlotsColorMap) = o.PlotsColorMap;
                data.(o.FldDefaultStdLogLevel) = WTLog.logLevelStr(o.DefaultStdLogLevel);
                data.(o.FldProjectLogLevel) = WTLog.logLevelStr(o.ProjectLogLevel);
                data.(o.FldMuteStdLog) = o.MuteStdLog;
                data.(o.FldProjectLog) = o.ProjectLog;
                data.(o.FldColorizedLog) = o.ColorizedLog;
                jsonText = WTIOUtils.jsonEncodePrettyPrint(data);
                if ~WTIOUtils.writeTxtFile([], o.ConfigFile, 'wt', 'UTF-8', jsonText)
                    WTException.ioErr('Failed to write application configuration').throw();
                end
                success = true;
            catch me
                WTLog().except(me);
            end
        end
    end
end
