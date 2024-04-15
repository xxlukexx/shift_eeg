function [suc, oc, event, tab_ev] = PSILAUT_consat_editRawEEGMarkerValues(event)
% The consat task constructs event marker values through some combination
% of background and foreground contrast (details tbc). This ends up using
% values from across the 0-255 range allowed by brainvision, and throws up
% conflicts with other tasks that have predefined events. 
% 
% The PSILAUT implementation sends task onset (40) and offset (41) that
% bound the other markers the task sends. Read any event between (but not
% including) 40-41 and add numeric 300 to it. This shifts it to a higher
% range than would normally be used, but that limitation is imposed by the
% bit depth of the serial marker cable used to send events. In other words,
% things like fieldtrip will happily handle events >255, even if these
% couldn't have been sent originally in the stimulus presentation code.

    % defaults for unhandled error
    suc = false;
    oc = 'unknown error';

    % convert to table for easier indexing
    tab_ev = struct2table(event);
    
    % pull values from table 
    codes = tab_ev.value;    
    
    % ensure that event values are integer format
    if ~isnumeric(tab_ev.value)
        suc = false;
        oc = 'event values were not in numeric format';
        return
    end
    
    % find consat onset event
    idx_on = find(codes == 40, 1, 'first');
    if isempty(idx_on)
        suc = false;
        oc = 'consat onset event (40) not found in events';
        return
    end
    
    % blank events before consat onset to make sure the offset event we
    % find is after the onset (technically not needed but better safe than
    % sorry)
    codes(1:idx_on - 1) = 0;
    
    % now find offset
    idx_off = find(codes == 41, 1, 'first');
    if isempty(idx_off)
        suc = false;
        oc = 'consat offset event (41) not found in events';
        return
    end
    
    % ensure that there is at least one event between on and offset
    if idx_off - idx_on - 1 < 1
        suc = false;
        oc = 'found onset (41) and offset (42) markers, but no task markers in between';
        return
    end
    
    % increment event values by 300
    tab_ev.value(idx_on + 1:idx_off - 1) =...
        tab_ev.value(idx_on + 1:idx_off - 1) + 300;
    
    % recreate updated struct
    event = table2struct(tab_ev);
    
    suc = true;
    oc = sprintf('changed %d events', idx_off - idx_on - 2);
    
end
    
    