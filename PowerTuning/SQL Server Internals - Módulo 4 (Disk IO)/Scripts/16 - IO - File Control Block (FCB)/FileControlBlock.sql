----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
/*
  Treinamento SQL Server Internals Parte 4 - Disk I/O
  Fabiano Neves Amorim - fabianonevesamorim@hotmail.com
  http://blogfabiano.com
*/
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

USE [master]
GO

-- Criar banco de teste
if exists (select * from sysdatabases where name='Test1')
BEGIN
  ALTER DATABASE Test1 SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		DROP DATABASE Test1
END
GO
CREATE DATABASE [Test1]
 ON  PRIMARY 
( NAME = N'Test1', FILENAME = N'E:\Test1.mdf' , SIZE = 51200KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'Test1_log', FILENAME = N'E:\Test1_log.ldf' , SIZE = 1MB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO

-- Verificar qual o ID do banco
-- Ver os dados do File Control Block via DBCC DBTABLE(<dbname>)
DBCC TRACEON(3604)
DBCC DBTABLE('Test1') --WITH TABLERESULTS
GO

/*
  Algumas informações interessantes

  FileMgr @0x0000025D08C3E440
  fcb_hdl = 0x0000000000000984 -- Deve bater com o file_handle na sys.dm_io_virtual_file_stats
  m_FormattedSectorSize = 512
  m_ActualSectorSize = 512
  m_numOfLongIOsSinceLastWarning = 0

  LogMgr @0x0000025D170A0080
  m_rowsSinceLastCkpt = 12

  StartupPhase = FCBOpenTime 	            1 ms                             
  StartupPhase = FCBHeaderReadTime 	      13 ms                       
  StartupPhase = FileMgrPreRecoveryTime 	 7 ms                  
  StartupPhase = SysFiles1ScanTime 	      3 ms                       
  StartupPhase = LogMgrPreRecoveryTime 	  7 ms                   
  StartupPhase = AnalysisRecTime 	        47 ms                         
  StartupPhase = FGCBProportionsTime 	    6 ms                     
  StartupPhase = PhysicalRecoveryTime 	   50 ms                    
  StartupPhase = PhysicalCompletionTime 	 337 ms                  
  StartupPhase = RecoveryCompletionTime 	 12 ms                  
  StartupPhase = StartupInDatabaseTime 	  257 ms                   
  StartupPhase = RemapSysfiles1Time 	     252 ms       

*/


-- Ver functions na classe FCB... 
-- Abrir windbg e rodar o seguinte:

x sqlmin!FCB::*

/*
0:148> x sqlmin!FCB::*
00007ff8`f4132c60 sqlmin!FCB::MakeFileSparse (<no parameter info>)
00007ff8`f41b2400 sqlmin!FCB::SetFileName (<no parameter info>)
00007ff8`f414fb10 sqlmin!FCB::GetInfiniteLeaseIds (<no parameter info>)
00007ff8`f3030410 sqlmin!FCB::PostRead (<no parameter info>)
00007ff8`f303ec30 sqlmin!FCB::AsyncReadInternal (<no parameter info>)
00007ff8`f41515c0 sqlmin!FCB::GetRootPath (<no parameter info>)
00007ff8`f3030670 sqlmin!FCB::ScatterRead (<no parameter info>)
00007ff8`f414f8e0 sqlmin!FCB::IsPMMDevice (<no parameter info>)
00007ff8`f415cb90 sqlmin!FCB::WriteMisaligned (<no parameter info>)
00007ff8`f4157680 sqlmin!FCB::RemoveAlternateStreamsByName (<no parameter info>)
00007ff8`f412f6a0 sqlmin!FCB::`vector deleting destructor' (<no parameter info>)
00007ff8`f414c820 sqlmin!FCB::CloseDEK (<no parameter info>)
00007ff8`f412f740 sqlmin!FCB::~FCB (<no parameter info>)
00007ff8`f412f260 sqlmin!FCB::FCB (<no parameter info>)
00007ff8`f415a6e0 sqlmin!FCB::GetLastBackupForeignRedoLsn (<no parameter info>)
00007ff8`f414def0 sqlmin!FCB::WriteDifferentialBase (<no parameter info>)
00007ff8`f415b2e0 sqlmin!FCB::SetInitialVlfCount (<no parameter info>)
00007ff8`f415a770 sqlmin!FCB::SetForeignRedoOldestBeginLsn (<no parameter info>)
00007ff8`f415b2c0 sqlmin!FCB::SetInitialVlf (<no parameter info>)
00007ff8`f415b130 sqlmin!FCB::SetForeignRedoLsn (<no parameter info>)
00007ff8`f415b420 sqlmin!FCB::PersistForeignRedoTime (<no parameter info>)
00007ff8`f2ffca50 sqlmin!FCB::IsSpaceInitializationNeeded (<no parameter info>)
00007ff8`f415dc00 sqlmin!FCB::ScatterRead (<no parameter info>)
00007ff8`f41514e0 sqlmin!FCB::IsCDROM (<no parameter info>)
00007ff8`f415b920 sqlmin!FCB::SetRbpexFCBInfo (<no parameter info>)
00007ff8`f4160ed0 sqlmin!FCB::SetMetadata (<no parameter info>)
00007ff8`f4151d30 sqlmin!FCB::PageRead (<no parameter info>)
00007ff8`f41358e0 sqlmin!FCB::OpenForStartup (<no parameter info>)
00007ff8`f414fb90 sqlmin!FCB::SetAllocEnd (<no parameter info>)
00007ff8`f415a5b0 sqlmin!FCB::PauseWriteDispenser (<no parameter info>)
00007ff8`f310ac80 sqlmin!FCB::SyncWrite (<no parameter info>)
00007ff8`f415f3f0 sqlmin!FCB::CreateAndGatherWriteInternal (<no parameter info>)
00007ff8`f415f3b0 sqlmin!FCB::CreateAndGatherWriteInternal (<no parameter info>)
00007ff8`f4158160 sqlmin!FCB::RemoveAlternateStreamsByHandle (<no parameter info>)
00007ff8`f415b840 sqlmin!FCB::GetLogicalDatabaseId (<no parameter info>)
00007ff8`f415f6b0 sqlmin!FCB::SyncRead (<no parameter info>)
00007ff8`f4156d00 sqlmin!FCB::DoParallelReplicaWrite (<no parameter info>)
00007ff8`f4157530 sqlmin!FCB::IsPageInSparseFile (<no parameter info>)
00007ff8`f4131510 sqlmin!FCB::BytesToPages (<no parameter info>)
00007ff8`f415a5a0 sqlmin!FCB::HasSnapshots (<no parameter info>)
00007ff8`f310f9f0 sqlmin!FCB::ShouldTrackFileSize (<no parameter info>)
00007ff8`f414a9d0 sqlmin!FCB::Map (<no parameter info>)
00007ff8`f414c770 sqlmin!FCB::EnsureBuffersFlushedForClose (<no parameter info>)
00007ff8`f412c900 sqlmin!FCB::PmmPrefaulterFunction (<no parameter info>)
00007ff8`f3169c40 sqlmin!FCB::GatherWriteInternal (<no parameter info>)
00007ff8`f2ff35a0 sqlmin!FCB::GetRequestType (<no parameter info>)
00007ff8`f318e5e0 sqlmin!FCB::GetPreferredIOSize (<no parameter info>)
00007ff8`f4c00620 sqlmin!FCB::`vftable' = <no type information>
00007ff8`f412f6a0 sqlmin!FCB::`scalar deleting destructor' (<no parameter info>)
00007ff8`f3d48f90 sqlmin!FCB::MakePreviousWritesDurable (<no parameter info>)
00007ff8`f415b500 sqlmin!FCB::PersistForeignRedoOldestBeginLsn (<no parameter info>)
00007ff8`f415b310 sqlmin!FCB::PersistForeignRedoLsn (<no parameter info>)
00007ff8`f414c870 sqlmin!FCB::Restart (<no parameter info>)
00007ff8`f415cfe0 sqlmin!FCB::GetMaxOffsetForIO (<no parameter info>)
00007ff8`f415d7b0 sqlmin!FCB::ScatterReadWithRbpex (<no parameter info>)
00007ff8`f304a640 sqlmin!FCB::GetAutoLatch (<no parameter info>)
00007ff8`f2ff3590 sqlmin!FCB::IsReadOnlyMediaInternal (<no parameter info>)
00007ff8`f4148fe0 sqlmin!FCB::HasDEKChanged (<no parameter info>)
00007ff8`f412f910 sqlmin!FCB::Dump (<no parameter info>)
00007ff8`f310bc90 sqlmin!FCB::InitializeSpace (<no parameter info>)
00007ff8`f4156190 sqlmin!FCB::CopyPageToReplicas (<no parameter info>)
00007ff8`f415c460 sqlmin!FCB::AsyncReadWithoutCopy (<no parameter info>)
00007ff8`f2ff1880 sqlmin!FCB::ReleaseLeaseForShutdown (<no parameter info>)
00007ff8`f415c030 sqlmin!FCB::AsyncReadWithRbpex (<no parameter info>)
00007ff8`f302f420 sqlmin!FCB::IsTrackedInRbpex (<no parameter info>)
00007ff8`f2ff3590 sqlmin!FCB::RbIoIsAcceptLogMode (<no parameter info>)
00007ff8`f415ad10 sqlmin!FCB::SnapshotSafeRestoreGate (<no parameter info>)
00007ff8`f4150980 sqlmin!FCB::GetActualSectorSize (<no parameter info>)
00007ff8`f415ab20 sqlmin!FCB::PersistedSafeRestoreGate (<no parameter info>)
00007ff8`f4130fe0 sqlmin!FCB::Init (<no parameter info>)
00007ff8`f2ff35e0 sqlmin!FCB::PrepareWriteIOReq (<no parameter info>)
00007ff8`f4135e80 sqlmin!FCB::CheckSectorSizes (<no parameter info>)
00007ff8`f3d818e0 sqlmin!FCB::IsSbsFlatFile (<no parameter info>)
00007ff8`f415b2b0 sqlmin!FCB::GetInitialVlf (<no parameter info>)
00007ff8`f4155520 sqlmin!FCB::UnlinkAllReplicas (<no parameter info>)
00007ff8`f310f8e0 sqlmin!FCB::SetSize (<no parameter info>)
00007ff8`f4157050 sqlmin!FCB::QueueParallelWrite (<no parameter info>)
00007ff8`f2ff35e0 sqlmin!FCB::CanBeCached (<no parameter info>)
00007ff8`f2ff35a0 sqlmin!FCB::GetFCBType (<no parameter info>)
00007ff8`f437d934 sqlmin!FCB::`vcall'{368}' (<no parameter info>)
00007ff8`f414bf00 sqlmin!FCB::Close (<no parameter info>)
00007ff8`f4160f80 sqlmin!FCB::GetMetadata (<no parameter info>)
00007ff8`f4157970 sqlmin!FCB::RemoveDBCCReplicaFile (<no parameter info>)
00007ff8`f4152d60 sqlmin!FCB::EncryptPageInFile (<no parameter info>)
00007ff8`f302f6b0 sqlmin!FCB::QueueIORequest (<no parameter info>)
00007ff8`f414f4b0 sqlmin!FCB::GetVolumeNameFromPath (<no parameter info>)
00007ff8`f3110520 sqlmin!FCB::FlushFileBuffersByHandle (<no parameter info>)
00007ff8`f41b24b0 sqlmin!FCB::SetName (<no parameter info>)
00007ff8`f415b2f0 sqlmin!FCB::GetFixedVlfSizeInPages (<no parameter info>)
00007ff8`f415f230 sqlmin!FCB::GatherWriteInternal (<no parameter info>)
00007ff8`f4155e50 sqlmin!FCB::PullPageToReplica (<no parameter info>)
00007ff8`f41574f0 sqlmin!FCB::ShouldPageBeCopied (<no parameter info>)
00007ff8`f415e340 sqlmin!FCB::IssuePendingIO (<no parameter info>)
00007ff8`f4130f80 sqlmin!FCB::GetFFValidationCtxt (<no parameter info>)
00007ff8`f415a900 sqlmin!FCB::GetPersistedSafeRestoreGate (<no parameter info>)
00007ff8`f414d630 sqlmin!FCB::ZeroFile (<no parameter info>)
00007ff8`f302ee80 sqlmin!FCB::IoCompletion (<no parameter info>)
00007ff8`f41521a0 sqlmin!FCB::RemoveDEKFromHeader (<no parameter info>)
00007ff8`f4131670 sqlmin!FCB::InitStats (<no parameter info>)
00007ff8`f4162f20 sqlmin!FCB::GetBackupLsn (<no parameter info>)
00007ff8`f3158cb0 sqlmin!FCB::WouldBlockOnIssueIO (<no parameter info>)
00007ff8`f414b870 sqlmin!FCB::OpenForRestore (<no parameter info>)
00007ff8`f414eef0 sqlmin!FCB::IsReadOnlyMedia (<no parameter info>)
00007ff8`f4152160 sqlmin!FCB::ClearPreviousDEK (<no parameter info>)
00007ff8`f415a690 sqlmin!FCB::GetForeignRedoTime (<no parameter info>)
00007ff8`f4130dd0 sqlmin!FCB::StartWriteTracking (<no parameter info>)
00007ff8`f4152330 sqlmin!FCB::UpdateDEKFromDbTable (<no parameter info>)
00007ff8`f4135070 sqlmin!FCB::ValidateFile (<no parameter info>)
00007ff8`f310b9e0 sqlmin!FCB::ChangeFileSize (<no parameter info>)
00007ff8`f414ede0 sqlmin!FCB::SetReadOnly (<no parameter info>)
00007ff8`f364a870 sqlmin!FCB::GetGroupId (<no parameter info>)
00007ff8`f414f700 sqlmin!FCB::IsPathOnPmmVolume (<no parameter info>)
00007ff8`f4151550 sqlmin!FCB::ShouldForceGrowCloudLifterFile (<no parameter info>)
00007ff8`f41356d0 sqlmin!FCB::Startup (<no parameter info>)
00007ff8`f3030380 sqlmin!FCB::GetPostReadOption (<no parameter info>)
00007ff8`f302eb90 sqlmin!FCB::GetRecoveryUnit (<no parameter info>)
00007ff8`f2ff35e0 sqlmin!FCB::ShouldCheckPathLength (<no parameter info>)
00007ff8`f41554f0 sqlmin!FCB::AssociateAsReplica (<no parameter info>)
00007ff8`f4118c00 sqlmin!FCB::SetGroupId (<no parameter info>)
00007ff8`f3169940 sqlmin!FCB::GatherWrite (<no parameter info>)
00007ff8`f414ca20 sqlmin!FCB::Shutdown (<no parameter info>)
00007ff8`f3030620 sqlmin!FCB::CheckPageId (<no parameter info>)
00007ff8`f329de80 sqlmin!FCB::IsLogFile (<no parameter info>)
00007ff8`f4135c00 sqlmin!FCB::Startup (<no parameter info>)
00007ff8`f2ff35e0 sqlmin!FCB::IsTransientReplicaAllowed (<no parameter info>)
00007ff8`f302f910 sqlmin!FCB::IsExternalFile (<no parameter info>)
00007ff8`f41520e0 sqlmin!FCB::SetDEK (<no parameter info>)
00007ff8`f412c560 sqlmin!FCB::StartPmemPrefaulter (<no parameter info>)
00007ff8`f316a880 sqlmin!FCB::IsOpen (<no parameter info>)
00007ff8`f310ec30 sqlmin!FCB::NumPagesToGrowFile (<no parameter info>)
00007ff8`f415b610 sqlmin!FCB::GetPersistedForeignRedoInfo (<no parameter info>)
00007ff8`f318e5f0 sqlmin!FCB::GetVariableScatterGatherMemoryAligment (<no parameter info>)
00007ff8`f4131e90 sqlmin!FCB::CreatePhysicalFile (<no parameter info>)
00007ff8`f414e030 sqlmin!FCB::SetProxyFileId (<no parameter info>)
00007ff8`f3169840 sqlmin!FCB::GetPageProtectionOption (<no parameter info>)
00007ff8`f41520d0 sqlmin!FCB::SetParent (<no parameter info>)
00007ff8`f415a2f0 sqlmin!FCB::BuildMetadataDescription (<no parameter info>)
00007ff8`f4314960 sqlmin!FCB::OpenAzureFileMetadataAccess (<no parameter info>)
00007ff8`f414ef90 sqlmin!FCB::ReadVolumeAttributes (<no parameter info>)
00007ff8`f2ff1880 sqlmin!FCB::RbIoSetAllowZeroWrites (<no parameter info>)
00007ff8`f4152060 sqlmin!FCB::GetDbt (<no parameter info>)
00007ff8`f414ad00 sqlmin!FCB::Open (<no parameter info>)
00007ff8`f415b770 sqlmin!FCB::GetStorageType (<no parameter info>)
00007ff8`f310b970 sqlmin!FCB::PostWrite (<no parameter info>)
00007ff8`f414dd50 sqlmin!FCB::SetDifferentialBitmapState (<no parameter info>)
00007ff8`f415c710 sqlmin!FCB::ReadMisaligned (<no parameter info>)
00007ff8`f304a720 sqlmin!FCB::AsyncWriteInternal (<no parameter info>)
00007ff8`f302e540 sqlmin!FCB::GetActualSectorSize (<no parameter info>)
00007ff8`f415e680 sqlmin!FCB::OnThrottlePendingIO (<no parameter info>)
00007ff8`f414f910 sqlmin!FCB::MakePreviousWritesDurableInternal (<no parameter info>)
00007ff8`f3030a50 sqlmin!FCB::ScatterReadInternal (<no parameter info>)
00007ff8`f415b300 sqlmin!FCB::SetFixedVlfSizeInPages (<no parameter info>)
00007ff8`f4314b30 sqlmin!FCB::SetLeaseOrderId (<no parameter info>)
00007ff8`f303e830 sqlmin!FCB::AsyncReadWithOptionalBuffer (<no parameter info>)
00007ff8`f4160ff0 sqlmin!FCB::ShouldRetryStaleRead (<no parameter info>)
00007ff8`f41572d0 sqlmin!FCB::PageDoesNotNeedReplicaCopy (<no parameter info>)
00007ff8`f415a6b0 sqlmin!FCB::GetCheckpointForeignRedoLsn (<no parameter info>)
00007ff8`f3169f70 sqlmin!FCB::PreWrite (<no parameter info>)
00007ff8`f415ebe0 sqlmin!FCB::CreateAndGatherWrite (<no parameter info>)
00007ff8`f41541b0 sqlmin!FCB::ReencryptFile (<no parameter info>)
00007ff8`f415b010 sqlmin!FCB::GetForeignRedoInfo (<no parameter info>)
00007ff8`f415ef40 sqlmin!FCB::CreateAndGatherWrite (<no parameter info>)
00007ff8`f4153300 sqlmin!FCB::ReencryptPage (<no parameter info>)
00007ff8`f4132e40 sqlmin!FCB::CreatePageFile (<no parameter info>)
00007ff8`f414bd70 sqlmin!FCB::RaiseOpenError (<no parameter info>)
00007ff8`f4135610 sqlmin!FCB::SimpleStartup (<no parameter info>)
00007ff8`f415b240 sqlmin!FCB::SetForeignRedoTime (<no parameter info>)
00007ff8`f4151740 sqlmin!FCB::SyncWriteDirtyHeaderFromBufferPool (<no parameter info>)
00007ff8`f4050330 sqlmin!FCB::IsOffline (<no parameter info>)
00007ff8`f4131d80 sqlmin!FCB::CanHonorForceFlush (<no parameter info>)
00007ff8`f304ab40 sqlmin!FCB::AsyncWrite (<no parameter info>)
00007ff8`f415a710 sqlmin!FCB::SetLastBackupForeignRedoLsn (<no parameter info>)
00007ff8`f4155590 sqlmin!FCB::UnAssociateReplica (<no parameter info>)
00007ff8`f415a5d0 sqlmin!FCB::ResumeWriteDispenser (<no parameter info>)
00007ff8`f41318b0 sqlmin!FCB::Init (<no parameter info>)
00007ff8`f2ffca50 sqlmin!FCB::AllowFillAggressively (<no parameter info>)
00007ff8`f4155a50 sqlmin!FCB::CopyAllocatedPagesFromPrimary (<no parameter info>)
00007ff8`f4155730 sqlmin!FCB::CopyAllocationPagesFromPrimary (<no parameter info>)
00007ff8`f414c740 sqlmin!FCB::CloseForWritePage (<no parameter info>)
00007ff8`f414f200 sqlmin!FCB::IncursSeekPenalty (<no parameter info>)
00007ff8`f4160490 sqlmin!FCB::PostReadL2BPool (<no parameter info>)
00007ff8`f4131500 sqlmin!FCB::PagesToBytes (<no parameter info>)
00007ff8`f310b8d0 sqlmin!FCB::PageWriteInternal (<no parameter info>)
00007ff8`f414a010 sqlmin!FCB::RefreshHeaderFields (<no parameter info>)
00007ff8`f4133760 sqlmin!FCB::TryReadWrite (<no parameter info>)
00007ff8`f2ff1880 sqlmin!FCB::HintPhysicalSize (<no parameter info>)
00007ff8`f415a560 sqlmin!FCB::CreateSnapshot (<no parameter info>)
00007ff8`f414e470 sqlmin!FCB::SetFreeExtentCount (<no parameter info>)
00007ff8`f414cf70 sqlmin!FCB::PopulateRecoveryInfo (<no parameter info>)
00007ff8`f303e7c0 sqlmin!FCB::AsyncRead (<no parameter info>)
00007ff8`f302f810 sqlmin!FCB::IsIOGoverned (<no parameter info>)
00007ff8`f415a4d0 sqlmin!FCB::GetVolumeEntityForIOAccounting (<no parameter info>)
00007ff8`f414caf0 sqlmin!FCB::UpdateBindingId (<no parameter info>)
00007ff8`f4158c20 sqlmin!FCB::FillSidePageTable (<no parameter info>)
00007ff8`f41553d0 sqlmin!FCB::SetReplica (<no parameter info>)
00007ff8`f41360a0 sqlmin!FCB::RefreshHeaderFieldsFromBuffer (<no parameter info>)
00007ff8`f2ff35a0 sqlmin!FCB::GetBlockReadAlign (<no parameter info>)
00007ff8`f4150010 sqlmin!FCB::GetRawActualSectorSize (<no parameter info>)
00007ff8`f415df10 sqlmin!FCB::ScatterReadInternal (<no parameter info>)
00007ff8`f414e180 sqlmin!FCB::ReplaceFileHeader (<no parameter info>)
00007ff8`f4161080 sqlmin!FCB::GetPhysicalFileSizeInPages (<no parameter info>)
00007ff8`f415a520 sqlmin!FCB::CopySnapshotFile (<no parameter info>)
00007ff8`f414e4e0 sqlmin!FCB::NewSetFreeExtentCount (<no parameter info>)
00007ff8`f43148d0 sqlmin!FCB::InitAzureFileMetadataAccess (<no parameter info>)
00007ff8`f4314c30 sqlmin!FCB::AcquireLease (<no parameter info>)
00007ff8`f4158650 sqlmin!FCB::DumpSidePageTable (<no parameter info>)
00007ff8`f415b2d0 sqlmin!FCB::GetInitialVlfCount (<no parameter info>)
00007ff8`f415fc90 sqlmin!FCB::SyncWritePreemptive (<no parameter info>)
00007ff8`f414eb40 sqlmin!FCB::OldSetFreeExtentCount (<no parameter info>)
00007ff8`f414dca0 sqlmin!FCB::TrimFile (<no parameter info>)
00007ff8`f4131520 sqlmin!FCB::InitBasicParams (<no parameter info>)
00007ff8`f310ac30 sqlmin!FCB::GetAdjustedPageId (<no parameter info>)
00007ff8`f414fbc0 sqlmin!FCB::PrepareReplicasForShrink (<no parameter info>)
00007ff8`f4152ba0 sqlmin!FCB::NoteReencryptionScanComplete (<no parameter info>)
00007ff8`f414e240 sqlmin!FCB::InitHeaderPage (<no parameter info>)
00007ff8`f415a740 sqlmin!FCB::GetForeignRedoOldestBeginLsn (<no parameter info>)
00007ff8`f4161220 sqlmin!FCB::GetSparseSizePages (<no parameter info>)
00007ff8`f319f280 sqlmin!FCB::GetStorageAccountName (<no parameter info>)
00007ff8`f4160620 sqlmin!FCB::IoErrorString (<no parameter info>)
00007ff8`f4152960 sqlmin!FCB::InitializeReencryptionScan (<no parameter info>)
00007ff8`f4134f00 sqlmin!FCB::StartPrimaryFile (<no parameter info>)
00007ff8`f4149550 sqlmin!FCB::RefreshDEK (<no parameter info>)
00007ff8`f415e8d0 sqlmin!FCB::GatherWrite (<no parameter info>)
00007ff8`f2ff1880 sqlmin!FCB::RbIoSetAcceptLogMode (<no parameter info>)
00007ff8`f415a5f0 sqlmin!FCB::GetForeignRedoLsn (<no parameter info>)
00007ff8`f415fa80 sqlmin!FCB::SyncReadWithoutCopy (<no parameter info>)
00007ff8`f2ff35e0 sqlmin!FCB::PrepareReadIOReq (<no parameter info>)
00007ff8`f41588b0 sqlmin!FCB::UncompressFile (<no parameter info>)
00007ff8`f31104c0 sqlmin!FCB::FCBFlushFileBuffers (<no parameter info>)
00007ff8`f302f3d0 sqlmin!FCB::IsRbpexSupported (<no parameter info>)
*/


-- sys.dm_io_virtual_file_stats é um dump 
-- dos dados nessa estrura FCB...
SELECT * FROM sys.dm_io_virtual_file_stats(DB_ID('Test1'), null)
GO