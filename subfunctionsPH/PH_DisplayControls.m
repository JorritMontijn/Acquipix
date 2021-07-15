function PH_DisplayControls

% Print controls
CreateStruct.Interpreter = 'tex';
CreateStruct.WindowStyle = 'non-modal';
msgbox( ...
    {'\fontsize{12}' ...
    '\bf Probe: \rm' ...
    'Arrow keys : translate probe' ...
    'Alt/Option up/down : raise/lower probe' ...
    'Shift arrow keys : change probe angle' ...
    'm : set probe location manually', ...
    '\bf 3D brain areas: \rm' ...
    ' =/+ : add (list selector)' ...
    ' Alt/Option =/+ : add (search)' ...
    ' Shift =/+ : add (hierarchy selector)' ...
    ' - : remove', ...
    '\bf Visibility: \rm' ...
    's : atlas slice (toggle tv/av/off)' ...
    'b : brain outline' ...
    'p : probe' ...
    'a : 3D brain areas' ...
    '\bf Other: \rm' ...
    'r : toggle clickable rotation' ...
    'x : export probe coordinates to workspace' ...
    'h : load and plot histology-defined trajectory', ...
    'c : bring up controls box'}, ...
    'Controls',CreateStruct);

end


