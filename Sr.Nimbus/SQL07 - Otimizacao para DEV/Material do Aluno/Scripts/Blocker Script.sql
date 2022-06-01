/*
Note: This script is meant to have 3 creations of the same stored procedure and two of them will fail
 with either 207 errors or a 2714 error.
*/

-- osql -E -Sserver -icheckblk.sql -ocheckblk.out -w2000

--WHILE 1=1
--BEGIN
--   EXEC master.dbo.sp_blocker_pss08   
--   WAITFOR DELAY '00:00:5'
--END
--GO

use master
GO

if exists (select * from sysobjects where id = object_id('dbo.sp_blocker_pss08') and sysstat & 0xf = 4)
   drop procedure dbo.sp_blocker_pss08
GO

create procedure dbo.sp_blocker_pss08 (@latch int = 1, @fast int = 1, @appname sysname='PSSDIAG')
as 
--version 19.2005 - 2005 or Later
if is_member('sysadmin')=0 
begin
  print 'Must be a member of the sysadmin group in order to run this procedure'
  return
end

set nocount on
SET LANGUAGE 'us_english'
declare @spid varchar(6)
declare @blocked varchar(6)
declare @time datetime
declare @time2 datetime
declare @dbname nvarchar(128)
declare @status sql_variant
declare @useraccess sql_variant
declare @request varchar(12)

set @time = getdate()
declare @probclients table(spid smallint, request_id int, ecid smallint, blocked smallint, waittype binary(2), dbid smallint,
   ignore_app tinyint, primary key (blocked, spid, request_id, ecid))
insert @probclients select spid, request_id, ecid, blocked, waittype, dbid,
   case when convert(varchar(128),hostname) = @appname then 1 else 0 end
   from master.dbo.sysprocesses where blocked!=0 or waittype != 0x0000

if exists (select spid from @probclients where ignore_app != 1)
begin
   set @time2 = getdate()
   print ''
   print '9.0 Start time: ' + convert(varchar(26), @time, 121) + ' ' + convert(varchar(12), datediff(ms,@time,@time2)) + ' 19.2005 '+ltrim(str(@latch))+' '+ltrim(str(@fast)) 

   insert @probclients select distinct blocked, 0, 0, 0, 0x0000, 0, 0 from @probclients
      where blocked not in (select spid from @probclients) and blocked != 0

   if (@fast = 1)
   begin
      print ''
      print 'SYSPROCESSES ' + ISNULL (@@servername,'(null)') + ' ' + str(@@microsoftversion)

      select spid, status, blocked, open_tran, waitresource, waittype, 
         waittime, cmd, lastwaittype, cpu, physical_io,
         memusage, last_batch=convert(varchar(26), last_batch,121),
         login_time=convert(varchar(26), login_time,121),net_address,
         net_library, dbid, ecid, kpid, hostname, hostprocess,
         loginame, program_name, nt_domain, nt_username, uid, sid,
         sql_handle, stmt_start, stmt_end, request_id
      from master.dbo.sysprocesses
      where blocked!=0 or waittype != 0x0000
         or spid in (select blocked from @probclients where blocked != 0)
         or spid in (select spid from @probclients where blocked != 0)

      print 'ESP ' + convert(varchar(12), datediff(ms,@time2,getdate())) 

      print ''
      print 'SYSPROC FIRST PASS'
      select spid, request_id, ecid, waittype from @probclients where waittype != 0x0000

      if exists(select blocked from @probclients where blocked != 0)
      begin
         print 'Blocking via locks at ' + convert(varchar(26), @time, 121)
         print ''
         print 'SPIDs at the head of blocking chains'
         select distinct spid from @probclients -- change: added distinct
            where blocked = 0 and spid in (select blocked from @probclients where spid != 0)
         if @latch = 0 and exists (select spid from @probclients where waittype between 0x0001 and 0x0017) -- Change: exists
         begin
            print 'SYSLOCKINFO'
            select @time2 = getdate()

            select spid = convert (smallint, req_spid),
               ecid = convert (smallint, req_ecid),
               rsc_dbid As dbid,
               rsc_objid As ObjId,
               rsc_indid As IndId,
               Type = case rsc_type when 1 then 'NUL'
                                    when 2 then 'DB'
                                    when 3 then 'FIL'
                                    when 4 then 'IDX'
                                    when 5 then 'TAB'
                                    when 6 then 'PAG'
                                    when 7 then 'KEY'
                                    when 8 then 'EXT'
                                    when 9 then 'RID'
                                    when 10 then 'APP' end,
               Resource = substring (rsc_text, 1, 16),
               Mode = case req_mode + 1 when 1 then NULL
                                        when 2 then 'Sch-S'
                                        when 3 then 'Sch-M'
                                        when 4 then 'S'
                                        when 5 then 'U'
                                        when 6 then 'X'
                                        when 7 then 'IS'
                                        when 8 then 'IU'
                                        when 9 then 'IX'
                                        when 10 then 'SIU'
                                        when 11 then 'SIX'
                                        when 12 then 'UIX'
                                        when 13 then 'BU'
                                        when 14 then 'RangeS-S'
                                        when 15 then 'RangeS-U'
                                        when 16 then 'RangeIn-Null'
                                        when 17 then 'RangeIn-S'
                                        when 18 then 'RangeIn-U'
                                        when 19 then 'RangeIn-X'
                                        when 20 then 'RangeX-S'
                                        when 21 then 'RangeX-U'
                                        when 22 then 'RangeX-X'end,
               Status = case req_status when 1 then 'GRANT'
                                        when 2 then 'CNVT'
                                        when 3 then 'WAIT' end,
               req_transactionID As TransID, req_transactionUOW As TransUOW
            from master.dbo.syslockinfo s,
               @probclients p
            where p.spid = s.req_spid
               --and ((p.waittype between 0x0001 and 0x0017) or ()) --change: added line

            print 'ESL ' + convert(varchar(12), datediff(ms,@time2,getdate())) 
         end -- latch not set
      end
      else
         print 'No blocking via locks at ' + convert(varchar(26), @time, 121)
      print ''
   end  -- fast set

   else  
   begin  -- Fast not set
      print ''
      print 'SYSPROCESSES ' + ISNULL (@@servername,'(null)') + ' ' + str(@@microsoftversion)

      select spid, status, blocked, open_tran, waitresource, waittype, 
         waittime, cmd, lastwaittype, cpu, physical_io,
         memusage, last_batch=convert(varchar(26), last_batch,121),
         login_time=convert(varchar(26), login_time,121),net_address,
         net_library, dbid, ecid, kpid, hostname, hostprocess,
         loginame, program_name, nt_domain, nt_username, uid, sid,
         sql_handle, stmt_start, stmt_end, request_id
      from master.dbo.sysprocesses

      print 'ESP ' + convert(varchar(12), datediff(ms,@time2,getdate())) 

      print ''
      print 'SYSPROC FIRST PASS'
      select spid, request_id, ecid, waittype from @probclients where waittype != 0x0000

      if exists(select blocked from @probclients where blocked != 0)
      begin
         print 'Blocking via locks at ' + convert(varchar(26), @time, 121)
         print ''
         print 'SPIDs at the head of blocking chains'
         select spid from @probclients
         where blocked = 0 and spid in (select blocked from @probclients where spid != 0)
         if @latch = 0
         begin
            print 'SYSLOCKINFO'
            select @time2 = getdate()

            select spid = convert (smallint, req_spid),
               ecid = convert (smallint, req_ecid),
               rsc_dbid As dbid,
               rsc_objid As ObjId,
               rsc_indid As IndId,
               Type = case rsc_type when 1 then 'NUL'
                                    when 2 then 'DB'
                                    when 3 then 'FIL'
                                    when 4 then 'IDX'
                                    when 5 then 'TAB'
                                    when 6 then 'PAG'
                                    when 7 then 'KEY'
                                    when 8 then 'EXT'
                                    when 9 then 'RID'
                                    when 10 then 'APP' end,
               Resource = substring (rsc_text, 1, 16),
               Mode = case req_mode + 1 when 1 then NULL
                                        when 2 then 'Sch-S'
                                        when 3 then 'Sch-M'
                                        when 4 then 'S'
                                        when 5 then 'U'
                                        when 6 then 'X'
                                        when 7 then 'IS'
                                        when 8 then 'IU'
                                        when 9 then 'IX'
                                        when 10 then 'SIU'
                                        when 11 then 'SIX'
                                        when 12 then 'UIX'
                                        when 13 then 'BU'
                                        when 14 then 'RangeS-S'
                                        when 15 then 'RangeS-U'
                                        when 16 then 'RangeIn-Null'
                                        when 17 then 'RangeIn-S'
                                        when 18 then 'RangeIn-U'
                                        when 19 then 'RangeIn-X'
                                        when 20 then 'RangeX-S'
                                        when 21 then 'RangeX-U'
                                        when 22 then 'RangeX-X'end,
               Status = case req_status when 1 then 'GRANT'
                                        when 2 then 'CNVT'
                                        when 3 then 'WAIT' end,
               req_transactionID As TransID, req_transactionUOW As TransUOW
            from master.dbo.syslockinfo

            print 'ESL ' + convert(varchar(12), datediff(ms,@time2,getdate())) 
         end -- latch not set
      end
      else
        print 'No blocking via locks at ' + convert(varchar(26), @time, 121)
      print ''
   end -- Fast not set

   print 'sys.dm_os_wait_stats'
   select * from sys.dm_os_wait_stats where waiting_tasks_count > 0
   print 'OWS'

   Print ''
   Print '*********************************************************************'
   Print 'Print out DBCC Input buffer for all blocked or blocking spids.'
   Print '*********************************************************************'

   declare ibuffer cursor fast_forward for
   select distinct cast (spid as varchar(6)) as spid, cast (request_id as varchar(12)) as request_id
   from @probclients
   where (spid <> @@spid) and (spid > 50) and
      ((blocked!=0 or (waittype != 0x0000 and ignore_app = 0))
      or spid in (select blocked from @probclients where blocked != 0))
   open ibuffer
   fetch next from ibuffer into @spid, @request
   while (@@fetch_status != -1)
   begin
      print ''
      print 'DBCC INPUTBUFFER FOR SPID ' + @spid +'('+@request+')'
      exec ('dbcc inputbuffer (' + @spid + ',' + @request +')')

      fetch next from ibuffer into @spid, @request
   end
   deallocate ibuffer

   Print ''
   Print '*******************************************************************************'
   Print 'Print out DBCC OPENTRAN for active databases for all blocked or blocking spids.'
   Print '*******************************************************************************'
   declare ibuffer cursor fast_forward for
   select distinct cast (dbid as varchar(6)) from @probclients
   where dbid != 0
   open ibuffer
   fetch next from ibuffer into @spid
   while (@@fetch_status != -1)
   begin
      print ''
      set @dbname = db_name(@spid)
      set @status = DATABASEPROPERTYEX(@dbname,'Status')
      set @useraccess = DATABASEPROPERTYEX(@dbname,'UserAccess')
      print 'DBCC OPENTRAN FOR DBID ' + @spid + ' ['+ @dbname + ']'
      if @status = N'ONLINE' and @useraccess != N'SINGLE_USER'
         dbcc opentran(@dbname)
      else
         print 'Skipped: Status=' + convert(nvarchar(128),@status)
            + ' UserAccess=' + convert(nvarchar(128),@useraccess)

      print ''
      if @spid = '2' select @blocked = 'Y'
      fetch next from ibuffer into @spid
   end
   deallocate ibuffer
   if @blocked != 'Y' 
   begin
      print ''
      print 'DBCC OPENTRAN FOR DBID  2 [tempdb]'
      dbcc opentran ('tempdb')
   end

   print 'End time: ' + convert(varchar(26), getdate(), 121)
end -- All
else
  print '8 No Waittypes: ' + convert(varchar(26), @time, 121) + ' ' 
     + convert(varchar(12), datediff(ms,@time,getdate())) + ' ' + ISNULL (@@servername,'(null)') + ' 19.2005'
GO    

/*
create procedure dbo.sp_blocker_pss08 (@latch int = 1, @fast int = 1, @appname sysname='PSSDIAG')
as 
--version 19.20003 --2000 SP3 or Later
if is_member('sysadmin')=0 
begin
  print 'Must be a member of the sysadmin group in order to run this procedure'
  return
end

set nocount on
SET LANGUAGE 'us_english'
declare @spid varchar(6)
declare @blocked varchar(6)
declare @time datetime
declare @time2 datetime
declare @dbname nvarchar(128)
declare @status sql_variant
declare @useraccess sql_variant

set @time = getdate()
declare @probclients table(spid smallint, ecid smallint, blocked smallint, waittype binary(2), dbid smallint,
   ignore_app tinyint, primary key (blocked, spid, ecid))
insert @probclients select spid, ecid, blocked, waittype, dbid,
   case when convert(varchar(128),hostname) = @appname then 1 else 0 end
   from master.dbo.sysprocesses where blocked!=0 or waittype != 0x0000

if exists (select spid from @probclients where ignore_app != 1 or waittype != 0x020B)
begin
   set @time2 = getdate()
   print ''
   print '8.2 Start time: ' + convert(varchar(26), @time, 121) + ' ' + convert(varchar(12), datediff(ms,@time,@time2)) + ' 19.20003 ' +ltrim(str(@latch))+' '+ltrim(str(@fast)) 

   insert @probclients select distinct blocked, 0, 0, 0x0000, 0, 0 from @probclients
      where blocked not in (select spid from @probclients) and blocked != 0

   if (@fast = 1)
   begin
      print ''
      print 'SYSPROCESSES ' + ISNULL (@@servername,'(null)') + ' ' + str(@@microsoftversion)

      select spid, status, blocked, open_tran, waitresource, waittype, 
         waittime, cmd, lastwaittype, cpu, physical_io,
         memusage, last_batch=convert(varchar(26), last_batch,121),
         login_time=convert(varchar(26), login_time,121),net_address,
         net_library, dbid, ecid, kpid, hostname, hostprocess,
         loginame, program_name, nt_domain, nt_username, uid, sid,
         sql_handle, stmt_start, stmt_end
      from master.dbo.sysprocesses
      where blocked!=0 or waittype != 0x0000
         or spid in (select blocked from @probclients where blocked != 0)
         or spid in (select spid from @probclients where blocked != 0)

      print 'ESP ' + convert(varchar(12), datediff(ms,@time2,getdate())) 

      print ''
      print 'SYSPROC FIRST PASS'
      select spid, ecid, waittype from @probclients where waittype != 0x0000

      if exists(select blocked from @probclients where blocked != 0)
      begin
         print 'Blocking via locks at ' + convert(varchar(26), @time, 121)
         print ''
         print 'SPIDs at the head of blocking chains'
         select spid from @probclients
            where blocked = 0 and spid in (select blocked from @probclients where spid != 0)
         if @latch = 0
         begin
            print 'SYSLOCKINFO'
            select @time2 = getdate()

            select spid = convert (smallint, req_spid),
               ecid = convert (smallint, req_ecid),
               rsc_dbid As dbid,
               rsc_objid As ObjId,
               rsc_indid As IndId,
               Type = case rsc_type when 1 then 'NUL'
                                    when 2 then 'DB'
                                    when 3 then 'FIL'
                                    when 4 then 'IDX'
                                    when 5 then 'TAB'
                                    when 6 then 'PAG'
                                    when 7 then 'KEY'
                                    when 8 then 'EXT'
                                    when 9 then 'RID'
                                    when 10 then 'APP' end,
               Resource = substring (rsc_text, 1, 16),
               Mode = case req_mode + 1 when 1 then NULL
                                        when 2 then 'Sch-S'
                                        when 3 then 'Sch-M'
                                        when 4 then 'S'
                                        when 5 then 'U'
                                        when 6 then 'X'
                                        when 7 then 'IS'
                                        when 8 then 'IU'
                                        when 9 then 'IX'
                                        when 10 then 'SIU'
                                        when 11 then 'SIX'
                                        when 12 then 'UIX'
                                        when 13 then 'BU'
                                        when 14 then 'RangeS-S'
                                        when 15 then 'RangeS-U'
                                        when 16 then 'RangeIn-Null'
                                        when 17 then 'RangeIn-S'
                                        when 18 then 'RangeIn-U'
                                        when 19 then 'RangeIn-X'
                                        when 20 then 'RangeX-S'
                                        when 21 then 'RangeX-U'
                                        when 22 then 'RangeX-X'end,
               Status = case req_status when 1 then 'GRANT'
                                        when 2 then 'CNVT'
                                        when 3 then 'WAIT' end,
               req_transactionID As TransID, req_transactionUOW As TransUOW
            from master.dbo.syslockinfo s,
               @probclients p
            where p.spid = s.req_spid

            print 'ESL ' + convert(varchar(12), datediff(ms,@time2,getdate())) 
         end -- latch not set
      end
      else
         print 'No blocking via locks at ' + convert(varchar(26), @time, 121)
      print ''
   end  -- fast set

   else  
   begin  -- Fast not set
      print ''
      print 'SYSPROCESSES ' + ISNULL (@@servername,'(null)') + ' ' + str(@@microsoftversion)

      select spid, status, blocked, open_tran, waitresource, waittype, 
         waittime, cmd, lastwaittype, cpu, physical_io,
         memusage, last_batch=convert(varchar(26), last_batch,121),
         login_time=convert(varchar(26), login_time,121),net_address,
         net_library, dbid, ecid, kpid, hostname, hostprocess,
         loginame, program_name, nt_domain, nt_username, uid, sid,
         sql_handle, stmt_start, stmt_end
      from master.dbo.sysprocesses

      print 'ESP ' + convert(varchar(12), datediff(ms,@time2,getdate())) 

      print ''
      print 'SYSPROC FIRST PASS'
      select spid, ecid, waittype from @probclients where waittype != 0x0000

      if exists(select blocked from @probclients where blocked != 0)
      begin
         print 'Blocking via locks at ' + convert(varchar(26), @time, 121)
         print ''
         print 'SPIDs at the head of blocking chains'
         select spid from @probclients
         where blocked = 0 and spid in (select blocked from @probclients where spid != 0)
         if @latch = 0
         begin
            print 'SYSLOCKINFO'
            select @time2 = getdate()

            select spid = convert (smallint, req_spid),
               ecid = convert (smallint, req_ecid),
               rsc_dbid As dbid,
               rsc_objid As ObjId,
               rsc_indid As IndId,
               Type = case rsc_type when 1 then 'NUL'
                                    when 2 then 'DB'
                                    when 3 then 'FIL'
                                    when 4 then 'IDX'
                                    when 5 then 'TAB'
                                    when 6 then 'PAG'
                                    when 7 then 'KEY'
                                    when 8 then 'EXT'
                                    when 9 then 'RID'
                                    when 10 then 'APP' end,
               Resource = substring (rsc_text, 1, 16),
               Mode = case req_mode + 1 when 1 then NULL
                                        when 2 then 'Sch-S'
                                        when 3 then 'Sch-M'
                                        when 4 then 'S'
                                        when 5 then 'U'
                                        when 6 then 'X'
                                        when 7 then 'IS'
                                        when 8 then 'IU'
                                        when 9 then 'IX'
                                        when 10 then 'SIU'
                                        when 11 then 'SIX'
                                        when 12 then 'UIX'
                                        when 13 then 'BU'
                                        when 14 then 'RangeS-S'
                                        when 15 then 'RangeS-U'
                                        when 16 then 'RangeIn-Null'
                                        when 17 then 'RangeIn-S'
                                        when 18 then 'RangeIn-U'
                                        when 19 then 'RangeIn-X'
                                        when 20 then 'RangeX-S'
                                        when 21 then 'RangeX-U'
                                        when 22 then 'RangeX-X'end,
               Status = case req_status when 1 then 'GRANT'
                                        when 2 then 'CNVT'
                                        when 3 then 'WAIT' end,
               req_transactionID As TransID, req_transactionUOW As TransUOW
            from master.dbo.syslockinfo

            print 'ESL ' + convert(varchar(12), datediff(ms,@time2,getdate())) 
         end -- latch not set
      end
      else
        print 'No blocking via locks at ' + convert(varchar(26), @time, 121)
      print ''
   end -- Fast not set

   print 'DBCC SQLPERF(WAITSTATS)'
   dbcc sqlperf(waitstats)

   Print ''
   Print '*********************************************************************'
   Print 'Print out DBCC Input buffer for all blocked or blocking spids.'
   Print '*********************************************************************'

   declare ibuffer cursor fast_forward for
   select distinct cast (spid as varchar(6)) as spid
   from @probclients
   where (spid <> @@spid) and 
      ((blocked!=0 or (waittype != 0x0000 and ignore_app = 0))
      or spid in (select blocked from @probclients where blocked != 0))
   open ibuffer
   fetch next from ibuffer into @spid
   while (@@fetch_status != -1)
   begin
      print ''
      print 'DBCC INPUTBUFFER FOR SPID ' + @spid
      exec ('dbcc inputbuffer (' + @spid + ')')

      fetch next from ibuffer into @spid
   end
   deallocate ibuffer

   Print ''
   Print '*******************************************************************************'
   Print 'Print out DBCC OPENTRAN for active databases for all blocked or blocking spids.'
   Print '*******************************************************************************'
   declare ibuffer cursor fast_forward for
   select distinct cast (dbid as varchar(6)) from @probclients
   where dbid != 0
   open ibuffer
   fetch next from ibuffer into @spid
   while (@@fetch_status != -1)
   begin
      print ''
      set @dbname = db_name(@spid)
      set @status = DATABASEPROPERTYEX(@dbname,'Status')
      set @useraccess = DATABASEPROPERTYEX(@dbname,'UserAccess')
      print 'DBCC OPENTRAN FOR DBID ' + @spid + ' ['+ @dbname + ']'
      if @status = N'ONLINE' and @useraccess != N'SINGLE_USER'
         dbcc opentran(@dbname)
      else
         print 'Skipped: Status=' + convert(nvarchar(128),@status)
            + ' UserAccess=' + convert(nvarchar(128),@useraccess)

      print ''
      if @spid = '2' select @blocked = 'Y'
      fetch next from ibuffer into @spid
   end
   deallocate ibuffer
   if @blocked != 'Y' 
   begin
      print ''
      print 'DBCC OPENTRAN FOR DBID  2 [tempdb]'
      dbcc opentran ('tempdb')
   end

   print 'End time: ' + convert(varchar(26), getdate(), 121)
end -- All
else
  print '8 No Waittypes: ' + convert(varchar(26), @time, 121) + ' ' 
     + convert(varchar(12), datediff(ms,@time,getdate())) + ' ' + ISNULL (@@servername,'(null)') + ' 19.20003'
GO    

create procedure dbo.sp_blocker_pss08 (@latch int = 1, @fast int = 1, @appname sysname='PSSDIAG')
as 
--version 19.2000 -- 2000 before SP3
if is_member('sysadmin')=0
begin
  print 'Must be a member of the sysadmin group in order to run this procedure'
  return
end

set nocount on
declare @spid varchar(6)
declare @blocked varchar(6)
declare @time datetime
declare @time2 datetime
declare @dbname nvarchar(128)
declare @status sql_variant
declare @useraccess sql_variant

set @time = getdate()
declare @probclients table(spid smallint, ecid smallint, blocked smallint, waittype binary(2), dbid smallint,
   ignore_app tinyint, primary key (blocked, spid, ecid))
insert @probclients select spid, ecid, blocked, waittype, dbid,
   case when convert(varchar(128),hostname) = @appname then 1 else 0 end
   from master.dbo.sysprocesses where blocked!=0 or waittype != 0x0000

if exists (select spid from @probclients where ignore_app != 1 or waittype != 0x020B)
begin
   set @time2 = getdate()
   print ''
   print '8 Start time: ' + convert(varchar(26), @time, 121) + ' ' + convert(varchar(12), datediff(ms,@time,@time2)) + ' 19.2000 '+ltrim(str(@latch))+' '+ltrim(str(@fast)) 

   insert @probclients select distinct blocked, 0, 0, 0x0000, 0, 0 from @probclients
      where blocked not in (select spid from @probclients) and blocked != 0

   if (@fast = 1)
   begin
      print ''
      print 'SYSPROCESSES ' + ISNULL (@@servername,'(null)') + ' ' + str(@@microsoftversion)

      select spid, status, blocked, open_tran, waitresource, waittype, 
         waittime, cmd, lastwaittype, cpu, physical_io,
         memusage,last_batch=convert(varchar(26), last_batch,121),
         login_time=convert(varchar(26), login_time,121), net_address,
         net_library, dbid, ecid, kpid, hostname, hostprocess,
         loginame, program_name, nt_domain, nt_username, uid, sid
      from master.dbo.sysprocesses
      where blocked!=0 or waittype != 0x0000
         or spid in (select blocked from @probclients where blocked != 0)
         or spid in (select spid from @probclients where waittype != 0x0000)

      print 'ESP ' + convert(varchar(12), datediff(ms,@time2,getdate())) 

      print ''
      print 'SYSPROC FIRST PASS'
      select spid, ecid, waittype from @probclients where waittype != 0x0000

      if exists(select blocked from @probclients where blocked != 0)
      begin
         print 'Blocking via locks at ' + convert(varchar(26), @time, 121)
         print ''
         print 'SPIDs at the head of blocking chains'
         select spid from @probclients
            where blocked = 0 and spid in (select blocked from @probclients where spid != 0)
         if @latch = 0
         begin
            print 'SYSLOCKINFO'
            select @time2 = getdate()

            select spid = convert (smallint, req_spid),
               ecid = convert (smallint, req_ecid),
               rsc_dbid As dbid,
               rsc_objid As ObjId,
               rsc_indid As IndId,
               Type = case rsc_type when 1 then 'NUL'
                                    when 2 then 'DB'
                                    when 3 then 'FIL'
                                    when 4 then 'IDX'
                                    when 5 then 'TAB'
                                    when 6 then 'PAG'
                                    when 7 then 'KEY'
                                    when 8 then 'EXT'
                                    when 9 then 'RID'
                                    when 10 then 'APP' end,
               Resource = substring (rsc_text, 1, 16),
               Mode = case req_mode + 1 when 1 then NULL
                                        when 2 then 'Sch-S'
                                        when 3 then 'Sch-M'
                                        when 4 then 'S'
                                        when 5 then 'U'
                                        when 6 then 'X'
                                        when 7 then 'IS'
                                        when 8 then 'IU'
                                        when 9 then 'IX'
                                        when 10 then 'SIU'
                                        when 11 then 'SIX'
                                        when 12 then 'UIX'
                                        when 13 then 'BU'
                                        when 14 then 'RangeS-S'
                                        when 15 then 'RangeS-U'
                                        when 16 then 'RangeIn-Null'
                                        when 17 then 'RangeIn-S'
                                        when 18 then 'RangeIn-U'
                                        when 19 then 'RangeIn-X'
                                        when 20 then 'RangeX-S'
                                        when 21 then 'RangeX-U'
                                        when 22 then 'RangeX-X'end,
               Status = case req_status when 1 then 'GRANT'
                                        when 2 then 'CNVT'
                                        when 3 then 'WAIT' end,
               req_transactionID As TransID, req_transactionUOW As TransUOW
            from master.dbo.syslockinfo s,
               @probclients p
            where p.spid = s.req_spid

            print 'ESL ' + convert(varchar(12), datediff(ms,@time2,getdate())) 
         end -- latch not set
      end
      else
         print 'No blocking via locks at ' + convert(varchar(26), @time, 121)
      print ''
   end  -- fast set

   else  
   begin  -- Fast not set
      print ''
      print 'SYSPROCESSES ' + ISNULL (@@servername,'(null)') + ' ' + str(@@microsoftversion)

      select spid, status, blocked, open_tran, waitresource, waittype, 
         waittime, cmd, lastwaittype, cpu, physical_io,
         memusage,last_batch=convert(varchar(26), last_batch,121),
         login_time=convert(varchar(26), login_time,121), net_address,
         net_library, dbid, ecid, kpid, hostname, hostprocess,
         loginame, program_name, nt_domain, nt_username, uid, sid
      from master.dbo.sysprocesses

      print 'ESP ' + convert(varchar(12), datediff(ms,@time2,getdate())) 

      print ''
      print 'SYSPROC FIRST PASS'
      select spid, ecid, waittype from @probclients where waittype != 0x0000

      if exists(select blocked from @probclients where blocked != 0)
      begin
         print 'Blocking via locks at ' + convert(varchar(26), @time, 121)
         print ''
         print 'SPIDs at the head of blocking chains'
         select spid from @probclients
         where blocked = 0 and spid in (select blocked from @probclients where spid != 0)
         if @latch = 0
         begin
            print 'SYSLOCKINFO'
            select @time2 = getdate()

            select spid = convert (smallint, req_spid),
               ecid = convert (smallint, req_ecid),
               rsc_dbid As dbid,
               rsc_objid As ObjId,
               rsc_indid As IndId,
               Type = case rsc_type when 1 then 'NUL'
                                    when 2 then 'DB'
                                    when 3 then 'FIL'
                                    when 4 then 'IDX'
                                    when 5 then 'TAB'
                                    when 6 then 'PAG'
                                    when 7 then 'KEY'
                                    when 8 then 'EXT'
                                    when 9 then 'RID'
                                    when 10 then 'APP' end,
               Resource = substring (rsc_text, 1, 16),
               Mode = case req_mode + 1 when 1 then NULL
                                        when 2 then 'Sch-S'
                                        when 3 then 'Sch-M'
                                        when 4 then 'S'
                                        when 5 then 'U'
                                        when 6 then 'X'
                                        when 7 then 'IS'
                                        when 8 then 'IU'
                                        when 9 then 'IX'
                                        when 10 then 'SIU'
                                        when 11 then 'SIX'
                                        when 12 then 'UIX'
                                        when 13 then 'BU'
                                        when 14 then 'RangeS-S'
                                        when 15 then 'RangeS-U'
                                        when 16 then 'RangeIn-Null'
                                        when 17 then 'RangeIn-S'
                                        when 18 then 'RangeIn-U'
                                        when 19 then 'RangeIn-X'
                                        when 20 then 'RangeX-S'
                                        when 21 then 'RangeX-U'
                                        when 22 then 'RangeX-X'end,
               Status = case req_status when 1 then 'GRANT'
                                        when 2 then 'CNVT'
                                        when 3 then 'WAIT' end,
               req_transactionID As TransID, req_transactionUOW As TransUOW
            from master.dbo.syslockinfo

            print 'ESL ' + convert(varchar(12), datediff(ms,@time2,getdate())) 
         end -- latch not set
      end
      else
        print 'No blocking via locks at ' + convert(varchar(26), @time, 121)
      print ''
   end -- Fast not set

   print 'DBCC SQLPERF(WAITSTATS)'
   dbcc sqlperf(waitstats)

   Print ''
   Print '*********************************************************************'
   Print 'Print out DBCC Input buffer for all blocked or blocking spids.'
   Print '*********************************************************************'

   declare ibuffer cursor fast_forward for
   select distinct cast (spid as varchar(6)) as spid
   from @probclients
   where (spid <> @@spid) and 
      ((blocked!=0 or (waittype != 0x0000 and ignore_app = 0))
      or spid in (select blocked from @probclients where blocked != 0))
   open ibuffer
   fetch next from ibuffer into @spid
   while (@@fetch_status != -1)
   begin
      print ''
      print 'DBCC INPUTBUFFER FOR SPID ' + @spid
      exec ('dbcc inputbuffer (' + @spid + ')')

      fetch next from ibuffer into @spid
   end
   deallocate ibuffer

   Print ''
   Print '*******************************************************************************'
   Print 'Print out DBCC OPENTRAN for active databases for all blocked or blocking spids.'
   Print '*******************************************************************************'
   declare ibuffer cursor fast_forward for
   select distinct cast (dbid as varchar(6)) from @probclients
   where dbid != 0
   open ibuffer
   fetch next from ibuffer into @spid
   while (@@fetch_status != -1)
   begin
      print ''
      set @dbname = db_name(@spid)
      set @status = DATABASEPROPERTYEX(@dbname,'Status')
      set @useraccess = DATABASEPROPERTYEX(@dbname,'UserAccess')
      print 'DBCC OPENTRAN FOR DBID ' + @spid + ' ['+ @dbname + ']'
      if @status = N'ONLINE' and @useraccess != N'SINGLE_USER'
         dbcc opentran(@dbname)
      else
         print 'Skipped: Status=' + convert(nvarchar(128),@status)
            + ' UserAccess=' + convert(nvarchar(128),@useraccess)

      print ''
      if @spid = '2' select @blocked = 'Y'
      fetch next from ibuffer into @spid
   end
   deallocate ibuffer
   if @blocked != 'Y' 
   begin
      print ''
      print 'DBCC OPENTRAN FOR DBID  2 [tempdb]'
      dbcc opentran ('tempdb')
   end

   print 'End time: ' + convert(varchar(26), getdate(), 121)
end -- All
else
  print '8 No Waittypes: ' + convert(varchar(26), @time, 121) + ' '
     + convert(varchar(12), datediff(ms,@time,getdate())) + ' ' + ISNULL (@@servername,'(null)') + ' 19.2000'
GO 
*/