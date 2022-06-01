USE tempdb;
GO
DECLARE @current_snap_time DATETIME;
DECLARE @previous_snap_time DATETIME;
SET @current_snap_time = GETDATE();
IF NOT EXISTS
(
    SELECT name
    FROM tempdb.sys.sysobjects
    WHERE name LIKE '#_spin_waits%'
)
    CREATE TABLE #_spin_waits
    (
        lock_name VARCHAR(128),
        collisions BIGINT,
        spins BIGINT,
        sleep_time BIGINT,
        backoffs BIGINT,
        snap_time DATETIME
    );
--capture the current stats
INSERT INTO #_spin_waits
(
    lock_name,
    collisions,
    spins,
    sleep_time,
    backoffs,
    snap_time
)
SELECT name,
       collisions,
       spins,
       sleep_time,
       backoffs,
       @current_snap_time
FROM sys.dm_os_spinlock_stats;
SELECT TOP 1
       @previous_snap_time = snap_time
FROM #_spin_waits
WHERE snap_time <
(
    SELECT MAX(snap_time) FROM #_spin_waits
)
ORDER BY snap_time DESC;


--get delta in the spin locks stats
SELECT TOP 10
       spins_current.lock_name,
       (spins_current.collisions - spins_previous.collisions) AS collisions,
       (spins_current.spins - spins_previous.spins) AS spins,
       (spins_current.sleep_time - spins_previous.sleep_time) AS sleep_time,
       (spins_current.backoffs - spins_previous.backoffs) AS backoffs,
       spins_previous.snap_time AS [start_time],
       spins_current.snap_time AS [end_time],
       DATEDIFF(ss, @previous_snap_time, @current_snap_time) AS [seconds_in_sample]
FROM #_spin_waits spins_current
    INNER JOIN
    (
        SELECT *
        FROM #_spin_waits
        WHERE snap_time = @previous_snap_time
    ) spins_previous
        ON (spins_previous.lock_name = spins_current.lock_name)
WHERE spins_current.snap_time = @current_snap_time
      AND spins_previous.snap_time = @previous_snap_time
      AND spins_current.spins > 0
ORDER BY (spins_current.spins - spins_previous.spins) DESC;
--clean up table
DELETE FROM #_spin_waits
WHERE snap_time = @previous_snap_time;
WAITFOR DELAY '00:00:01.000'
GO 10