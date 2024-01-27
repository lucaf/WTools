classdef WTConditionsCfg < WTConfigStorage & matlab.mixin.Copyable

    properties(Constant,Access=private)
        FldConditions     = 'conditions'
        FldConditionsDiff = 'condiff'
    end

    properties
        ConditionsList cell {WTValidations.mustBeALinearCellArrayOfNonEmptyString} = {}
        ConditionsDiff cell {WTValidations.mustBeALinearCellArrayOfNonEmptyString} = {} 
    end
    
    methods
        function o = WTConditionsCfg(ioProc)
            o@WTConfigStorage(ioProc, 'cond.m');
            o.default();
        end

        function default(o) 
            o.ConditionsList = {};
        end

        function success = load(o) 
            [success, conds, diff] = o.read(o.FldConditions, o.FldConditionsDiff);
            if ~success
                return
            end
            try
                o.ConditionsList = conds;
                o.ConditionsDiff = diff;
            catch me
                WTLog().mexcpt(me);
                success = false;
            end 
        end

        function success = persist(o)
            txt1 = WTFormatter.StringCellsField(o.FldConditions, o.ConditionsList);
            txt2 = WTFormatter.StringCellsField(o.FldConditionsDiff, o.ConditionsDiff);
            success = ~isempty(txt1) && ~isempty(txt2) && o.write(txt1, txt2);
        end
    end
end
