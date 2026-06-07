# Data Center BMS MATLAB/Simulink Database Simulator

## Files
- `runBmsDatabaseSimulator.m` — Main MATLAB simulator that writes BMS points to CSV, SQLite, or a SQL database.
- `buildBmsSimulinkModel.m` — Creates a starter Simulink model for IT load, facility load, and PUE.

## Quick Start
1. Open MATLAB.
2. Put these files on your MATLAB path.
3. Run:
   ```matlab
   runBmsDatabaseSimulator
   ```
4. In CSV mode, the script creates:
   - `bms_simulated_points.csv`
   - `bms_point_metadata.csv`

## Ignition Integration
For Ignition Perspective, point a SQL Query Binding or Named Query at the generated database table:

```sql
SELECT point_name, point_value, unit, quality, alarm_state, alarm_priority, event_time
FROM bms_point_history
WHERE site_name = 'DC-01'
ORDER BY event_time DESC;
```

For CSV testing, import the CSV into a database table or use it as a development data source.
