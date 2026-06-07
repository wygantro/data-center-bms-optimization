%% buildBmsSimulinkModel.m
% Programmatically builds a simple Simulink model that generates BMS signals.
% The generated model logs signals to the MATLAB workspace. Use the companion
% script runBmsDatabaseSimulator.m for direct database/CSV writing.

model = 'BMS_DataCenter_Simulator';
new_system(model);
open_system(model);

set_param(model, 'StopTime', '3600');
set_param(model, 'Solver', 'FixedStepDiscrete');
set_param(model, 'FixedStep', '5');

% Add signal sources
add_block('simulink/Sources/Sine Wave', [model '/IT_Load_Profile']);
set_param([model '/IT_Load_Profile'], 'Amplitude', '250', 'Bias', '4200', 'Frequency', '0.0007');

add_block('simulink/Sources/Sine Wave', [model '/Cooling_Load_Profile']);
set_param([model '/Cooling_Load_Profile'], 'Amplitude', '80', 'Bias', '900', 'Frequency', '0.0009');

add_block('simulink/Math Operations/Sum', [model '/Facility_Load_Sum']);
set_param([model '/Facility_Load_Sum'], 'Inputs', '++');

add_block('simulink/Math Operations/Divide', [model '/PUE_Calc']);

add_block('simulink/Sinks/To Workspace', [model '/IT_Load_kW']);
set_param([model '/IT_Load_kW'], 'VariableName', 'IT_Load_kW', 'SaveFormat', 'StructureWithTime');

add_block('simulink/Sinks/To Workspace', [model '/Facility_Load_kW']);
set_param([model '/Facility_Load_kW'], 'VariableName', 'Facility_Load_kW', 'SaveFormat', 'StructureWithTime');

add_block('simulink/Sinks/To Workspace', [model '/PUE']);
set_param([model '/PUE'], 'VariableName', 'PUE', 'SaveFormat', 'StructureWithTime');

% Layout positions
set_param([model '/IT_Load_Profile'], 'Position', [100 100 200 140]);
set_param([model '/Cooling_Load_Profile'], 'Position', [100 220 200 260]);
set_param([model '/Facility_Load_Sum'], 'Position', [300 150 340 210]);
set_param([model '/PUE_Calc'], 'Position', [460 145 510 215]);
set_param([model '/IT_Load_kW'], 'Position', [620 80 730 120]);
set_param([model '/Facility_Load_kW'], 'Position', [620 150 760 190]);
set_param([model '/PUE'], 'Position', [620 230 730 270]);

% Connections
add_line(model, 'IT_Load_Profile/1', 'Facility_Load_Sum/1');
add_line(model, 'Cooling_Load_Profile/1', 'Facility_Load_Sum/2');
add_line(model, 'Facility_Load_Sum/1', 'PUE_Calc/1');
add_line(model, 'IT_Load_Profile/1', 'PUE_Calc/2');
add_line(model, 'IT_Load_Profile/1', 'IT_Load_kW/1');
add_line(model, 'Facility_Load_Sum/1', 'Facility_Load_kW/1');
add_line(model, 'PUE_Calc/1', 'PUE/1');

save_system(model);
fprintf('Created Simulink model: %s.slx\n', model);
