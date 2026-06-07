%% runBmsDatabaseSimulator.m
% Data Center BMS Database Simulator for Ignition Perspective
% Simulates BMS points and writes them to CSV, SQLite, or SQL Server/MySQL/Postgres via JDBC/ODBC.
%
% Author: sample starter code
% Requirements:
% - Base MATLAB for CSV mode
% - Database Toolbox for JDBC/ODBC database mode
% - SQLite support depends on your MATLAB release/toolboxes

clear; clc;

%% CONFIGURATION
cfg.siteName        = "DC-01";
cfg.sampleTimeSec   = 5;        % simulator update interval
cfg.durationMinutes = 60;       % total run time
cfg.outputMode      = "csv";    % "csv", "sqlite", or "database"

% CSV output
cfg.csvFile = "bms_simulated_points.csv";

% SQLite output
cfg.sqliteFile = "bms_simulator.db";

% Generic database output using Database Toolbox
cfg.db.datasource = "IgnitionBMS";     % ODBC/JDBC datasource name
cfg.db.username   = "";
cfg.db.password   = "";
cfg.db.tableName  = "bms_point_history";

%% POINT DEFINITIONS
points = buildPointList(cfg.siteName);

%% INITIALIZE OUTPUT
writer = initWriter(cfg, points);

%% SIMULATION LOOP
fprintf("Starting BMS simulator for %s...\n", cfg.siteName);
fprintf("Mode: %s | Sample Time: %.1f sec | Duration: %.1f min\n", ...
    cfg.outputMode, cfg.sampleTimeSec, cfg.durationMinutes);

startTime = datetime("now", "TimeZone", "local");
numSteps = round((cfg.durationMinutes * 60) / cfg.sampleTimeSec);

for k = 1:numSteps
    tNow = datetime("now", "TimeZone", "local");
    simTimeSec = seconds(tNow - startTime);

    rows = simulateBmsSnapshot(points, simTimeSec, tNow);
    writeRows(writer, rows);

    if mod(k, 12) == 0
        fprintf("%s | Wrote %d points | Critical alarms: %d\n", ...
            string(tNow), height(rows), sum(rows.alarmPriority == "Critical"));
    end

    pause(cfg.sampleTimeSec);
end

closeWriter(writer);
fprintf("Simulator complete.\n");

%% ------------------------------------------------------------------------
function points = buildPointList(siteName)
% Creates simulated BMS point metadata.

names = [
    "Facility/Power/Utility_kW"
    "Facility/Power/IT_Load_kW"
    "Facility/Power/PUE"
    "Facility/UPS/UPS_A_Load_pct"
    "Facility/UPS/UPS_B_Load_pct"
    "Facility/UPS/Battery_Runtime_min"
    "Facility/Generator/GEN_1_Status"
    "Facility/Generator/GEN_1_Fuel_pct"
    "Facility/Cooling/Chiller_1_Status"
    "Facility/Cooling/Chiller_1_SupplyTemp_F"
    "Facility/Cooling/Chiller_1_ReturnTemp_F"
    "Facility/Cooling/CHW_Flow_gpm"
    "Facility/Cooling/CRAH_A01_Status"
    "Facility/Cooling/CRAH_A01_SupplyAirTemp_F"
    "Facility/Cooling/CRAH_A01_ReturnAirTemp_F"
    "Facility/Environment/DataHall_TempAvg_F"
    "Facility/Environment/DataHall_Humidity_pct"
    "Facility/Environment/DataHall_DewPoint_F"
    "Facility/Racks/A01/InletTemp_F"
    "Facility/Racks/A02/InletTemp_F"
    "Facility/Racks/A03/InletTemp_F"
    "Facility/Racks/A04/InletTemp_F"
    "Facility/Racks/A01/Load_kW"
    "Facility/Racks/A02/Load_kW"
    "Facility/Racks/A03/Load_kW"
    "Facility/Racks/A04/Load_kW"
];

units = [
    "kW"; "kW"; "ratio"; "%"; "%"; "min"; "state"; "%"; "state"; "F"; "F"; "gpm"; ...
    "state"; "F"; "F"; "F"; "%"; "F"; "F"; "F"; "F"; "F"; "kW"; "kW"; "kW"; "kW"
];

equipment = extractBefore(names, "/", 'Boundaries','inclusive'); %#ok<NASGU>
points = table;
points.siteName = repmat(siteName, numel(names), 1);
points.pointName = names;
points.unit = units;
points.pointId = (1:numel(names))';
end

%% ------------------------------------------------------------------------
function rows = simulateBmsSnapshot(points, simTimeSec, timestamp)
% Generates one simulated timestamp of BMS values.

n = height(points);
value = zeros(n,1);
alarmPriority = repmat("Normal", n, 1);
alarmState = false(n,1);
quality = repmat("Good", n, 1);

% Base profiles
hourCycle = sin(2*pi*simTimeSec/(24*3600));
shortCycle = sin(2*pi*simTimeSec/(15*60));
noise = @(s) s .* randn();

itLoad = 4200 + 250*hourCycle + 80*shortCycle + noise(25);
coolingLoad = 900 + 80*hourCycle + noise(20);
facilityLoad = itLoad + coolingLoad + 250 + noise(30);
pue = facilityLoad / itLoad;

for i = 1:n
    p = points.pointName(i);

    switch p
        case "Facility/Power/Utility_kW"
            value(i) = facilityLoad;
        case "Facility/Power/IT_Load_kW"
            value(i) = itLoad;
        case "Facility/Power/PUE"
            value(i) = pue;
        case "Facility/UPS/UPS_A_Load_pct"
            value(i) = 58 + 4*shortCycle + noise(0.5);
        case "Facility/UPS/UPS_B_Load_pct"
            value(i) = 55 + 3*shortCycle + noise(0.5);
        case "Facility/UPS/Battery_Runtime_min"
            value(i) = 18 + noise(0.4);
        case "Facility/Generator/GEN_1_Status"
            value(i) = double(mod(floor(simTimeSec/1800), 12) == 1); % occasional test run
        case "Facility/Generator/GEN_1_Fuel_pct"
            value(i) = 92 - 0.01*simTimeSec/60 + noise(0.1);
        case "Facility/Cooling/Chiller_1_Status"
            value(i) = 1;
        case "Facility/Cooling/Chiller_1_SupplyTemp_F"
            value(i) = 45 + 0.8*shortCycle + noise(0.2);
        case "Facility/Cooling/Chiller_1_ReturnTemp_F"
            value(i) = 56 + 1.2*shortCycle + noise(0.3);
        case "Facility/Cooling/CHW_Flow_gpm"
            value(i) = 1850 + 90*shortCycle + noise(20);
        case "Facility/Cooling/CRAH_A01_Status"
            value(i) = 1;
        case "Facility/Cooling/CRAH_A01_SupplyAirTemp_F"
            value(i) = 63 + 1.5*shortCycle + noise(0.2);
        case "Facility/Cooling/CRAH_A01_ReturnAirTemp_F"
            value(i) = 82 + 2.0*shortCycle + noise(0.4);
        case "Facility/Environment/DataHall_TempAvg_F"
            value(i) = 72 + 2.0*shortCycle + noise(0.3);
        case "Facility/Environment/DataHall_Humidity_pct"
            value(i) = 44 + 3.0*hourCycle + noise(0.5);
        case "Facility/Environment/DataHall_DewPoint_F"
            value(i) = 50 + 1.5*hourCycle + noise(0.3);
        otherwise
            if contains(p, "InletTemp_F")
                rackBias = 2 * contains(p, "A03");
                value(i) = 72 + rackBias + 2.5*shortCycle + noise(0.5);
            elseif contains(p, "Load_kW")
                value(i) = 6.5 + 1.2*rand() + 0.3*shortCycle;
            else
                value(i) = noise(1);
            end
    end

    % Alarm logic
    [alarmState(i), alarmPriority(i)] = evaluateAlarm(p, value(i));

    % Random bad quality simulation
    if rand() < 0.002
        quality(i) = "Bad";
    end
end

rows = table;
rows.event_time = repmat(timestamp, n, 1);
rows.site_name = points.siteName;
rows.point_id = points.pointId;
rows.point_name = points.pointName;
rows.point_value = value;
rows.unit = points.unit;
rows.quality = quality;
rows.alarm_state = alarmState;
rows.alarmPriority = alarmPriority;
end

%% ------------------------------------------------------------------------
function [state, priority] = evaluateAlarm(pointName, value)
state = false;
priority = "Normal";

if contains(pointName, "InletTemp_F") || contains(pointName, "DataHall_TempAvg_F")
    if value >= 85
        state = true; priority = "Critical";
    elseif value >= 80
        state = true; priority = "Major";
    elseif value >= 76
        state = true; priority = "Minor";
    end
elseif contains(pointName, "Humidity_pct")
    if value < 35 || value > 60
        state = true; priority = "Major";
    elseif value < 40 || value > 55
        state = true; priority = "Minor";
    end
elseif contains(pointName, "UPS") && contains(pointName, "Load_pct")
    if value > 90
        state = true; priority = "Critical";
    elseif value > 80
        state = true; priority = "Major";
    end
elseif contains(pointName, "Battery_Runtime_min")
    if value < 10
        state = true; priority = "Critical";
    elseif value < 15
        state = true; priority = "Major";
    end
elseif contains(pointName, "PUE")
    if value > 1.7
        state = true; priority = "Major";
    elseif value > 1.5
        state = true; priority = "Minor";
    end
end
end

%% ------------------------------------------------------------------------
function writer = initWriter(cfg, points)
writer.cfg = cfg;
writer.conn = [];
writer.tableName = cfg.db.tableName;

schema = points(:, {'pointId','siteName','pointName','unit'});
writetable(schema, "bms_point_metadata.csv");

switch lower(cfg.outputMode)
    case "csv"
        if isfile(cfg.csvFile)
            delete(cfg.csvFile);
        end
        writer.mode = "csv";

    case "sqlite"
        writer.mode = "sqlite";
        writer.conn = sqlite(cfg.sqliteFile, "create");
        createBmsTable(writer.conn, writer.tableName);

    case "database"
        writer.mode = "database";
        writer.conn = database(cfg.db.datasource, cfg.db.username, cfg.db.password);
        createBmsTable(writer.conn, writer.tableName);

    otherwise
        error("Unsupported outputMode: %s", cfg.outputMode);
end
end

%% ------------------------------------------------------------------------
function createBmsTable(conn, tableName)
sql = sprintf([ ...
    "CREATE TABLE IF NOT EXISTS %s (" + ...
    "event_time VARCHAR(40), " + ...
    "site_name VARCHAR(80), " + ...
    "point_id INTEGER, " + ...
    "point_name VARCHAR(255), " + ...
    "point_value DOUBLE, " + ...
    "unit VARCHAR(40), " + ...
    "quality VARCHAR(40), " + ...
    "alarm_state BOOLEAN, " + ...
    "alarm_priority VARCHAR(40))"], tableName);
exec(conn, sql);
end

%% ------------------------------------------------------------------------
function writeRows(writer, rows)
% Normalize variable names for database table.
dbRows = rows;
dbRows.alarm_priority = dbRows.alarmPriority;
dbRows.alarmPriority = [];
dbRows.event_time = string(dbRows.event_time, "yyyy-MM-dd HH:mm:ss.SSS");

switch writer.mode
    case "csv"
        if isfile(writer.cfg.csvFile)
            writetable(dbRows, writer.cfg.csvFile, "WriteMode", "append", "WriteVariableNames", false);
        else
            writetable(dbRows, writer.cfg.csvFile);
        end

    case {"sqlite", "database"}
        sqlwrite(writer.conn, writer.tableName, dbRows);
end
end

%% ------------------------------------------------------------------------
function closeWriter(writer)
if ~isempty(writer.conn)
    close(writer.conn);
end
end
