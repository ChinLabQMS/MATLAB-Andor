% Function for preserving hold behavior on exit
function preserveHold(was_hold_on,ax)
    if ~was_hold_on
        hold(ax,'off');
    end
end
