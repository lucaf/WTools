classdef WTDynObject < dynamicprops 
    methods
        function o = addProp(o, name)
            addprop(o, name)
        end
    end
end