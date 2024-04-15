function [event, tab_event] = PSILAUT_santiseRawEEGEvents(event)
% This tidies up the events that are recorded in brain vision recorder. Do
% two things: 
%
%   1. Remove unwanted events such as "boundary"
%   2. Convert numeric event values in 'toggle' format to numeric
%   events, e.g. 'T123' -> [123]
%
% The PSILAUT piplline expects event values to be in this format, so this
% function should be called early, ideally straight after loading the raw
% data for the first time. 
%
% For convenience, the second output argument is the event struct in table
% format

    % remove unwanted metadata events
    
        idx_eegEventType = strcmpi({event.type}, 'Toggle');
        event(~idx_eegEventType) = [];
        
    % check that there are some events remaining
    
        if isempty(event)
            tab_event = [];
            return
        end
        
    % reformat event struct as table, convert T123 format codes to integer
    
        tab_event = struct2table(event);
        tab_event.value = cell2mat(extractNumeric(tab_event.value));
        event = table2struct(tab_event);
        
end