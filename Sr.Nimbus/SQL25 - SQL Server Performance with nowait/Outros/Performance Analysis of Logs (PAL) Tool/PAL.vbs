'//
'// Performance Analysis of Logs (PAL)
'//  PAL.vbs
'//
'//   CScript PAL.vbs [/?] /LOG:PerfmonLog [OPTIONS]
'//
'//   [/?]                          Optional. Show this help text.
'//   /LOG:[FileName[;FileName...]]Required. Perfmon log(s) to analyze
'//                                   separated by semicolons. Merging log files
'//                                   is a time consuming process. Try to limit
'//                                   to one Perfmon log at a time.
'//   OPTIONAL:
'//   /INTERVAL:[Seconds]           Optional. Interval in seconds to
'//                                  analyze.
'//   /THRESHOLDFILE:[XMLFilePath]  Optional. XML document containing PAL
'//                                  thresholds.
'//                                  If omitted, SystemOverview.xml will
'//                                  be used.
'//   THRESHOLD SPECIFIC ARGUMENTS:
'//   For example:
'//   /NUMOFPROCESSORS:[integer]    Optional. The number of processors of the
'//                                  computer the log was captured.
'//                                  If omitted, you will be prompted.
'//   /TOTALMEMORY:[integer]        Optional. The amount of total physical
'//                                  memory in gigabytes of the computer
'//                                  the log was captured.
'//                                  If omitted, you will be prompted.
'//   /3GB:[True|False]             Optional. True or false if the /3GB switch
'//                                  was used on the computer the log was
'//                                  captured.
'//                                  If omitted, you will be prompted.
'//   /64BIT:[True|False]            Optional. True or false if the computer
'//                                   where the log was captured is 64-bit.
'//                                   If omitted, you will be prompted.
'//
'// Description: PAL reads in a performance monitor counter log (any known
'//  format) and analyzes it for known thresholds (provided). Charts and alerts
'//  are reported in HTML for exceeded thresholds. This is a VBScript and
'//  requires Microsoft LogParser (free download).
'//
'// Requirements:
'//   - Windows XP or Windows Vista
'//   - Requires LogParser.exe to be installed.
'//     - LogParser.exe can be downloaded for free from:
'//     - http://www.microsoft.com/downloads/details.aspx?FamilyID=890cd06b-abf8-4c25-91b2-f8d975cf8c07&displaylang=en
'//     - LogParser.exe is part of the IIS Diagnostics Toolkit.
'// 
'// Written by: Clint Huffman (clinth@microsoft.com)
'//
'// Version: 1.3.4.3
'// Last Modified: 12/16/2008
'//

'******************************************************
'* <Global State Variables> - DO NOT EDIT
'******************************************************
Option Explicit
Const VERSION = "v1.3.4.3"

''''''''''''''''''''''''''''''''''
' Constants and Global Variables
''''''''''''''''''''''''''''''''''
Const ONE_HOUR = "3600"
Const ONE_MINUTE = "60"
Const AUTO_DETECT_INTERVAL = 30

Const gc_FilteredPerfmonLogCounterListFile = "_FilteredPerfmonLogCounterList.txt"
Const gc_FilteredPerfmonLogFile = "_FilteredPerfmonLog.csv"
Const gc_MergedPerfmonLogFile = "_MergedPerfmonLog.blg"
Const gc_OriginalRealCounterList = "_OriginalCounterList.txt"
Const NO_EXCLUSIONS = "No Exclusions"

Dim g_FilteredPerfmonLogCounterListFile, g_FilteredPerfmonLogFile, g_MergedPerfmonLogFile, g_OriginalRealCounterList, g_sFileDebugLogPath
Const gc_sFileDebugLogPath = "PAL.log"
Dim g_OriginalPerfmonLogArg, g_PerfmonLog, g_Interval, g_XMLThresholdFile ' Arguments to the script
Dim g_IntervalDescription ' Description of the specified interval
Dim g_DateTimeStamp, g_DateReport ' General use DateTimeStamp to be consistent on time generated.
Dim g_ReportResourceDir, g_ReportResourceDirNoSpaces ' The resource directory for the report.
Dim g_ReportFile, g_ReportFilePath, g_XMLOutputFile, g_XMLOutputFilePath, g_aTime, g_PALReportsDirectory, g_PALReportsDirectoryNoSpaces, g_UserTempDirectory, g_WorkingDirectory, g_GUID
Dim g_aRules() ' The analysis rules structure.
Dim g_XMLRoot ' The XML Root of the threshold rules XML file.
Dim g_aRealCounterList ' An array of each of the real counters in the filtered perfmon log.
Dim g_aData ' Main data structure
Dim aChartOutputFiles(), iChartCounter
Dim dQ ' literal double quotes
Dim g_AutoDetectedLogSampleInterval, g_IsAutoDetectOn, g_NumOfSamplesInLog, g_LogBeginTime, g_LogEndTime, g_DurationOfLogInSeconds
Dim g_DateColumnNameInCSVLog
' Environment variables
'Dim NumberOfProcessors, ThreeGBSwitch, OperatingSystem, TotalMemory, SixtyFourBit
Dim g_dctQuestions
Dim g_ScriptStartTime
Dim g_oFileDebugLog
Dim IsMinThresholdBroken, IsAvgThresholdBroken, IsMaxThresholdBroken, IsTrendThresholdBroken
Dim g_XMLInputFilePath, g_IsInputXML, g_IsOutputXML, g_IsOutputHTML
Dim g_iBeginFunctionTime, g_iEndFunctionTime, g_iDurationOfFunctionTime
Dim g_iNullDataCount
Dim g_dBeginTime, g_dEndTime

'******************************************************
'* </Global State Variables> - DO NOT EDIT
'******************************************************

'***************************
'* <MAIN>
'***************************

Main

Sub Main()
    GenerateUniqueGUID
    GetUserTempDirectory
    SetTempFilesToTempDirectoryPath
    StartDebugLogFile
    OutputToConsoleAndLog "PAL.vbs " & VERSION
    OutputToConsoleAndLog ""
    BeginTimer
    DetectExeType    
    'PreCleanUp    
    SetGlobalVariables
    ReadRulesXMLIntoMemory
    CheckToSeeIfLogParserIsInstalled        
    DetermineIfCountersAreInThePerfmonLog
    FilterPerfmonLog
    AnalyzeTheInterval
    AdjustLogParserRegKeys
    CreateCounterListFromFilteredPerfmonLog
    GenerateXMLData
    ProcessStatistics
    PostCleanUp
    EndingOutput
    EndTimer
    EndDebugLogFile
    'DeletePALLogFile
End Sub

'***************************
'* </MAIN>
'***************************

Sub PALErrHandler()
'        Select Case Err.Description
'            Case "Error parsing query: Log row too long"
'                WScript.Echo "ERROR: Log Parser's row buffer is too small. Run the PAL tool with elevated permissions (under administrator privileges), so PAL can automatically adjust this buffer using the CSVInMaxRowSize registry key."
'                WScript.Quit
'        End Select
End Sub

Function FixLogParserEscapeSequences(sQuery)
    Dim sNewQuery, sPattern, sReplacement, bIsMatch
    sPattern = "(\\u\d{4})"
    sReplacement = "\$1"
    sNewQuery = RegExpReplace(sQuery, sPattern, sReplacement)
    FixLogParserEscapeSequences = sNewQuery
End Function

Function RegExpReplace(sString, sPattern, sReplacement)
    Dim regEx, Match, Matches   ' Create variable.
    Dim bFound
    Set regEx = New RegExp   ' Create a regular expression.
    regEx.Pattern = sPattern   ' Set pattern.
    regEx.IgnoreCase = True   ' Set case insensitivity.
    regEx.Global = False   ' Set global applicability.
    RegExpReplace = regEx.Replace(sString, sReplacement)   ' Execute search.
End Function

Sub AdjustLogParserRegKeys()
    '// This subroutine will silently fail unless it is ran with elevated permissions in Windows Vista.
'    Dim WshShell, iRowSize
'    Set WshShell = WScript.CreateObject("WScript.Shell")
'    iRowSize = GetLengthInBytesOfTheCounterLogCSVHeaders(g_FilteredPerfmonLogFile)
'    OutputToConsoleAndLog "CSVInMaxRowSize: " & iRowSize
'    iRowSize = iRowSize + 1024
'    If iRowSize > 80000 Then
'        ' Removed in v1.3.4.1. The setup sets this to the maximum setting.
'        ON ERROR RESUME NEXT
'        WshShell.RegWrite "HKLM\SOFTWARE\Microsoft\Log Parser\CSVInMaxRowSize", iRowSize, "REG_DWORD"
'        ON ERROR GOTO 0
'    End If   
End Sub

Function GetLengthInBytesOfTheCounterLogCSVHeaders(sFilePath)
    Const ForReading = 1
    Dim oFSO, oFile, sLine
    Set oFSO = CreateObject("Scripting.FileSystemObject")
    Set oFile = oFSO.OpenTextFile(sFilePath, ForReading)
    sLine = oFile.Readline
    GetLengthInBytesOfTheCounterLogCSVHeaders = LenB(sLine)
End Function

Sub BeginTimer()
    g_ScriptStartTime = Round(Timer())
End Sub

Sub EndTimer()
    Dim dEndTime, dDuration
    dEndTime = Round(Timer())
    dDuration = dEndTime - g_ScriptStartTime
    If dDuration < 60 Then
        OutputToConsoleAndLog "Total Script Execution Time: " & dDuration & " seconds(s)"
    Else
        dDuration = Round(dDuration / 60)
        OutputToConsoleAndLog "Total Script Execution Time: " & dDuration & " minute(s)"    
    End If
End Sub

Sub AutoDetectTheBestAnalysisInterval
    g_DateColumnNameInCSVLog = GetFirstColumnFromCSV(g_FilteredPerfmonLogFile)
    AutoDetectTheIntervalOfThePerfmonLog g_PerfmonLog, g_DateColumnNameInCSVLog
End Sub

Sub AutoDetectTheIntervalOfThePerfmonLog(sPerfmonLog, sDateTimeFieldName)
'Function GenerateArrayOfTimeIntervals(sPerfmonLog, sDateTimeFieldName, iInterval)
    'g_AutoDetectedLogSampleInterval, g_IsAutoDetectOn
    
    g_AutoDetectedLogSampleInterval = 0
    Dim oLogQuery, oCSVFormat,oRecordSet, oRecord
    Dim aTime(), sQuery, i
    Dim dQ
    
    CheckToSeeIfLogParserIsInstalled   
    
    Set oLogQuery = CreateObject("MSUtil.LogQuery")
    Set oCSVFormat = CreateObject("MSUtil.LogQuery.CSVInputFormat")
    oCSVFormat.iTsFormat = "MM/dd/yyyy hh:mm:ss.lll"
    
    dQ = chr(34)    
    sQuery = "SELECT [" & sDateTimeFieldName & "] AS Time FROM " & g_FilteredPerfmonLogFile
    sQuery = FixLogParserEscapeSequences(sQuery)
    OutputToConsoleAndLog sQuery
    ON ERROR RESUME NEXT
    Set oRecordSet = oLogQuery.Execute(sQuery, oCSVFormat)
    If Err.number <> 0 Then
        OutputToConsoleAndLog "[AutoDetectTheIntervalOfThePerfmonLog] ERROR Number: " & Err.number
        OutputToConsoleAndLog "[AutoDetectTheIntervalOfThePerfmonLog] ERROR Description: " & Err.Description
        PALErrHandler Err
        Err.Clear
        Exit Sub
    End If
    ON ERROR GOTO 0
    i = 0
    Do Until oRecordSet.atEnd
        Set oRecord = oRecordSet.getRecord        
        ReDim Preserve aTime(i)
        aTime(i) = CDate(oRecord.GetValue("Time"))
        i = i + 1        
        oRecordSet.MoveNext
    Loop
    
    g_AutoDetectedLogSampleInterval = DateDiff("s",aTime(0),aTime(1))
    g_NumOfSamplesInLog = i - 1
    g_LogBeginTime = aTime(0)
    g_LogEndTime = aTime(UBound(aTime))
    g_DurationOfLogInSeconds = DateDiff("s",g_LogBeginTime,g_LogEndTime)
    If g_Interval = "AUTO" OR g_Interval = "" Then        
        g_Interval = Int(g_DurationOfLogInSeconds / AUTO_DETECT_INTERVAL)
        If g_Interval < g_AutoDetectedLogSampleInterval Then
            g_Interval = g_AutoDetectedLogSampleInterval
        End If
    End If
    
    If g_Interval = "ALL" Then
        g_Interval = Int(g_DurationOfLogInSeconds / g_NumOfSamplesInLog)
        g_oFileDebugLog.WriteLine "[DEBUG] g_Interval: " & g_Interval
    End If
    
End Sub

Sub GetTimeIntervals   
    g_aTime = GenerateArrayOfTimeIntervals(g_PerfmonLog, GetFirstColumnFromCSV(g_FilteredPerfmonLogFile), g_Interval)
End Sub

Sub MergePerfmonLogs
    Dim bMergeSuccess    
    If IsArray(g_PerfmonLog) = False Then
        Exit Sub
    End If    
    bMergeSuccess = UseReLogToMergePerfmonLogs(g_PerfmonLog, g_MergedPerfmonLogFile, 60)
    If bMergeSuccess = False Then
        OutputToConsoleAndLog "[MergePerfmonLogs] Failed to merge perfmon logs."
        WScript.Quit
    End If
    g_PerfmonLog = g_MergedPerfmonLogFile
End Sub

Function UseReLogToMergePerfmonLogs(aPerfmonLogs, sOutputFile, iTimeoutInSeconds)
	Dim WshShell, oExec, oFSO, oFile, sCMD, strText, iTimeOutCount, sPerfmonLogForRelog, i
	Dim dQ
	Set WshShell = CreateObject("WScript.Shell")
    Const ForReading = 1, ForWriting = 2, ForAppending = 8
    Set oFSO = CreateObject("Scripting.FileSystemObject")
    
    dQ = chr(34)
    ' Create a file to read into ReLog for filtering.
    
    If IsArray(aPerfmonLogs) = False Then
        UseReLogToMergePerfmonLogs = True
        Exit Function
    End If
    
    OutputToConsoleAndLog "Merging perfmon logs together. This can be a time consuming process..."
    
    ' Check for spaces in the path. If spaces are in the path, then add doublequotes around it.
    For i = 0 to UBound(aPerfmonLogs)
        If Instr(aPerfmonLogs(i), " ") > 0 Then
            aPerfmonLogs(i) = chr(34) & aPerfmonLogs(i) & chr(34)
        End If
    Next
    
    sPerfmonLogForRelog = Join(aPerfmonLogs, " ")
    
    sCMD = "ReLog.exe " & sPerfmonLogForRelog & " -f BIN -o " & sOutputFile
    
	OutputToConsoleAndLog "Executing: " & sCMD
	Set oExec = WshShell.Exec(sCMD)	
    strText = oExec.StdOut.ReadAll()
	OutputToConsoleAndLog strText
    
    If InStr(1, strText, "The command completed successfully", 1) > 0 Then
        UseReLogToMergePerfmonLogs = True
    Else
        UseReLogToMergePerfmonLogs = False                
    End If
    
    iTimeOutCount = 0
    OutputToConsoleAndLog "Waiting for " & sOutputFile & " to be created..."
    Do 
        If iTimeOutCount >= iTimeoutInSeconds Then
            UseReLogToMergePerfmonLogs = False
            Exit Do
        Else
            UseReLogToMergePerfmonLogs = True
        End If       
        WScript.Sleep 1000
        iTimeOutCount = iTimeOutCount + 1
    Loop Until oFSO.FileExists(sOutputFile) = True

    If UseReLogToMergePerfmonLogs = True Then
        OutputToConsoleAndLog "Found " & sOutputFile
    End If            
    
    Set oFSO = CreateObject("Scripting.FileSystemObject")
    Set oFile = oFSO.GetFile(sOutputFile)
    If oFile.Size = 0 Then
        OutputToConsoleAndLog "===============================ERROR========================================"
        OutputToConsoleAndLog "[UseReLogToMergePerfmonLogs]"
        OutputToConsoleAndLog " No data was merged or a failure occurred in ReLog.exe."       
        OutputToConsoleAndLog "============================================================================"
        WScript.Quit    
    End If
End Function

Function AskForInterval()
    Dim iInterval
    iInterval = InputBox("Named Argument: Interval" & vbNewLine & vbNewLine & "At what interval (in seconds) shall we analyze this log? For example, if the perfmon log only captured 1 hour of data, then a 60 second interval is recommended." & vbNewLine & vbNewLine & "If " & chr(34) & "AUTO" & chr(34) & " is used, then the appropriate interval will be autodetected.", "PAL.vbs", "AUTO")
    If iInterval <> "AUTO" Then
        If IsNumeric(iInterval) = True Then
            If iInterval > 0 Then
                iInterval = CInt(iInterval)
            Else
                If iInterval = "" Then
                    '// Cancel was selected.
                    OutputToConsoleAndLog "Ending execution. User initiated cancel."
                    WScript.Quit
                End If
                Msgbox "An integer value greater than 0 must be entered.", vbOKOnly, "PAL.vbs"                
                iInterval = AskForInterval()            
            End If
        Else
            Msgbox "An integer value must be entered.", vbOKOnly, "PAL.vbs"
            iInterval = AskForInterval()    
        End If    
    End If
    AskForInterval = iInterval
End Function

Sub AskUserForEnvironmentVariables
    Dim retVal
    
    g_IsAutoDetectOn = False
	If g_Interval = "" Then
	    g_Interval = AskForInterval()
	    If g_Interval = "AUTO" Then
	        g_IsAutoDetectOn = True   
	    End If       
	End If
        
'    If NumberOfProcessors = "" Then
'        NumberOfProcessors = AskForNumberOfProcessors()
'    End If
'    
'    If LCase(ThreeGBSwitch) = "true" OR LCase(ThreeGBSwitch) = "false" Then
'        ThreeGBSwitch = ConvertStringTrueFalseToTrueOrFalse(ThreeGBSwitch)
'    End If      
'    
'    If ThreeGBSwitch = "" Then
'        ThreeGBSwitch = MsgBox("Was the /3GB switch being used on the server?", vbYesNo + vbDefaultButton2, "PAL.vbs")
'        If ThreeGBSwitch = vbYes Then
'            ThreeGBSwitch = True
'        Else
'            ThreeGBSwitch = False
'        End If    
'    End If    

'    If LCase(SixtyFourBit) = "true" OR LCase(SixtyFourBit) = "false" Then
'        SixtyFourBit = ConvertStringTrueFalseToTrueOrFalse(SixtyFourBit)
'    End If      

'    If SixtyFourBit = "" Then
'        SixtyFourBit = MsgBox("Was the computer 64-bit?", vbYesNo + vbDefaultButton2, "PAL.vbs")
'        If SixtyFourBit = vbYes Then
'            SixtyFourBit = True
'        Else
'            SixtyFourBit = False
'        End If    
'    End If    

'    If TotalMemory = "" Then
'        TotalMemory = AskForTotalMemory()
'    End If            
'    
'    
''    OperatingSystem = MsgBox("Was the operating system Windows 2003 Server?", vbYesNo, "Operating System")
''    If OperatingSystem = vbYes Then
'        OperatingSystem = "Win2003"
''    Else
''        OperatingSystem = False
''    End If    
'    
''    OutputToConsoleAndLog "NumberOfProcessors: " & NumberOfProcessors
''    OutputToConsoleAndLog "ThreeGBSwitch: " & ThreeGBSwitch
''    OutputToConsoleAndLog "TotalMemory: " & TotalMemory
''    OutputToConsoleAndLog "OperatingSystem: " & OperatingSystem
End Sub

Function AskForNumberOfProcessors()
    Dim iNumOfProcs
    iNumOfProcs = InputBox("How many processors (physical and virtual) did the server have?", "PAL.vbs", 2)
    If IsNumeric(iNumOfProcs) = True Then
        If iNumOfProcs > 0 Then
            iNumOfProcs = CInt(iNumOfProcs)
        Else
            Msgbox "An integer value greater than 0 must be entered.", vbOKOnly, "PAL.vbs"
            iNumOfProcs = AskForNumberOfProcessors()            
        End If
    Else
        Msgbox "An integer value must be entered.", vbOKOnly, "PAL.vbs"
        iNumOfProcs = AskForNumberOfProcessors()    
    End If
    AskForNumberOfProcessors = iNumOfProcs
End Function

Function AskForTotalMemory()
    Dim iTotalMemory
    iTotalMemory = InputBox("How much memory did the server have in gigabytes?", "PAL.vbs", 2)
    If IsNumeric(iTotalMemory) = True AND iTotalMemory > 0 Then
        iTotalMemory = CInt(iTotalMemory)
    Else
        Msgbox "An integer value must be entered.", vbOKOnly, "PAL.vbs"
        iTotalMemory = AskForTotalMemory()
    End If
    AskForTotalMemory = iTotalMemory
End Function

Sub ZeroFillNullsInPerfmonLog
    Dim oFSO, oFile, sCSV
    Const ForReading = 1
    Const ForWriting = 2
    Const ForAppending = 8
    
    Set oFSO = CreateObject("Scripting.FileSystemObject")
    Set oFile = oFSO.OpenTextFile(g_FilteredPerfmonLogFile, ForReading)
    sCSV = oFile.ReadAll
    oFile.Close
    sCSV = Replace(sCSV, chr(34) & " " & chr(34), "0")
    Set oFile = oFSO.OpenTextFile(g_FilteredPerfmonLogFile, ForWriting)
    oFile.Write sCSV
    oFile.Close    
End Sub

'Sub ReadEnvironmentVariablesIntoMemory
'    Dim xmldoc, XMLRoot, oNodeList, oXMLEnvironmentVariables, oXMLVariables, oXMLVariable, sNodeName 
'  	Set xmldoc = CreateObject("Msxml2.DOMDocument")
'    xmldoc.async = False
'    xmldoc.Load g_XMLThresholdFile
'    Set g_XMLRoot = xmldoc.documentElement
'	Set oNodeList = g_XMLRoot.selectNodes("//ENVIRONMENTVARIABLES")
'	For Each oXMLEnvironmentVariables In oNodeList
'	    Set oXMLVariables = oXMLEnvironmentVariables.selectNodes("./VARIABLE")
'	    For Each oXMLVariable in oXMLVariables
'            sNodeName = oXMLVariable.GetAttribute("NAME")
'            SELECT CASE sNodeName
'                CASE "NumberOfProcessors"
'                    NumberOfProcessors = ConvertToDataType(oXMLVariable.GetAttribute("VALUE"), "integer")
'                CASE "ThreeGBSwitch"
'                    ThreeGBSwitch = ConvertStringTrueFalseToTrueOrFalse(oXMLVariable.GetAttribute("VALUE"))
'                CASE "OperatingSystem"
'                    OperatingSystem = oXMLVariable.GetAttribute("VALUE")
'                CASE "TotalMemory"
'                    TotalMemory = ConvertToDataType(oXMLVariable.GetAttribute("VALUE"), "integer")
'            END SELECT	        
'	    Next
'	Next    
'End Sub

Sub DetermineIfCountersAreInThePerfmonLog()
    Dim bRetVal
    Dim oFSO, oFile, sLine, aFile()
    Dim l, oAnalysis, oCounter, bFound, a, bChartFound, aMatchCounter, m
    Dim oChart, oCounterNotFound, IsAnalysisCounter
    Dim bCounterObjectsMatch, bCounterNamesMatch, bCounterInstancesMatch, aMatchedCounters(), oMatchedCounter
    Const ForReading = 1    
    OutputToConsoleAndLog "Determining if counters are in the Perfmon log... "
    OutputToConsoleAndLog " Using Relog to create a counter list..."
    bRetVal = GetCounterListFromBLG(g_PerfmonLog, g_OriginalRealCounterList)
    OutputToConsoleAndLog " Done using Relog to create a counter list."
    If bRetVal = 0 Then
        OutputToConsoleAndLog "ERROR: [DetermineIfCountersAreInThePerfmonLog] Unable to create a counter list from " & g_FilteredPerfmonLogFile
        WScript.Quit
    End If
    OutputToConsoleAndLog " Reading counter list file..."
    Set oFSO = CreateObject("Scripting.FileSystemObject")
    Set oFile = oFSO.OpenTextFile(g_OriginalRealCounterList, ForReading)
    l = 0
    Do Until oFile.AtEndOfStream
        sLine = oFile.ReadLine
        ReDim Preserve aFile(l)
        aFile(l) = sLine
        l = l + 1
    Loop
    OutputToConsoleAndLog " Done reading counter list file."
    OutputToConsoleAndLog " Determining if all counters needed in each analysis is in the perfmon log..."
      
    For Each oAnalysis in g_aData
        m = 0 ' Set the matched counter array counter to 0
        ReDim aMatchedCounters(0)
        Set oMatchedCounter = New MatchedCounterObject
        oMatchedCounter.FullPath = "PlaceHolder"
        Set aMatchedCounters(0) = oMatchedCounter
        oAnalysis.AllCountersFound = True ' setting to true unless not found.
        'ON ERROR RESUME NEXT
        OutputToConsoleAndLog "  Checking " & chr(34) & oAnalysis.Name & chr(34) & "..."
        For Each oCounter in oAnalysis.Counters            
            bFound = False            
            If LCase(oAnalysis.AnalyzeCounter) = LCase(oCounter.Name) Then
                IsAnalysisCounter = True
            Else
                IsAnalysisCounter = False
            End If
            m = 0
            ReDim aMatchedCounters(0)
            Set oMatchedCounter = New MatchedCounterObject
            oMatchedCounter.FullPath = "PlaceHolder"
            Set aMatchedCounters(0) = oMatchedCounter                
            For a = 0 to UBound(aFile)
                '// Match the counter paths to counter patterns
                bCounterObjectsMatch = False
                bCounterNamesMatch = False
                bCounterInstancesMatch = False
                If oCounter.IsCounterObjectRegularExpression = True Then
                    bCounterObjectsMatch = CompareCounterPathToExpression(aFile(a), oCounter.RegularExpressionCounterPath, "COUNTER_OBJECT", oCounter.IsCounterObjectRegularExpression)
                Else
                    bCounterObjectsMatch = CompareCounterPathToExpression(aFile(a), oCounter.Name, "COUNTER_OBJECT", oCounter.IsCounterObjectRegularExpression)
                End If                
                If bCounterObjectsMatch = True Then
                    If oCounter.IsCounterNameRegularExpression = True Then
                        bCounterNamesMatch = CompareCounterPathToExpression(aFile(a), oCounter.RegularExpressionCounterPath, "COUNTER_NAME", oCounter.IsCounterNameRegularExpression)
                    Else
                        bCounterNamesMatch = CompareCounterPathToExpression(aFile(a), oCounter.Name, "COUNTER_NAME", oCounter.IsCounterNameRegularExpression)
                    End If                    
                    If bCounterNamesMatch = True Then
                        If oCounter.IsCounterInstanceRegularExpression = True Then
                            bCounterInstancesMatch = CompareCounterPathToExpression(aFile(a), oCounter.RegularExpressionCounterPath, "COUNTER_INSTANCE", oCounter.IsCounterInstanceRegularExpression)
                        Else
                            bCounterInstancesMatch = CompareCounterPathToExpression(aFile(a), oCounter.Name, "COUNTER_INSTANCE", oCounter.IsCounterInstanceRegularExpression)
                        End If                        
                    End If
                End If                                
                If bCounterObjectsMatch = True AND bCounterNamesMatch = True AND bCounterInstancesMatch = True Then
                    bFound = True
                    OutputToConsoleAndLog "   Matched: " & chr(34) & aFile(a) & chr(34)
                    ReDim Preserve aMatchedCounters(m)
                    Set aMatchedCounters(m) = ConstructMatchedCounterObject(aFile(a))
                    m = m + 1          
                    'Exit For                
                End If                        
            Next
            If bFound = False Then
                oAnalysis.AllCountersFound = False
                OutputToConsoleAndLog "   [DetermineIfCountersAreInThePerfmonLog] The following Analysis is unable to process due to missing counters: "
                OutputToConsoleAndLog "    Analysis Name: " & oAnalysis.Name
                OutputToConsoleAndLog "     The following counter was not found in the perfmon log:"
                OutputToConsoleAndLog "      " & oCounter.Name
            End If
            If aMatchedCounters(0).FullPath <> "PlaceHolder" Then
                oCounter.MatchedCounters = aMatchedCounters
            End If            
        Next
        If oAnalysis.Charts(0).ChartTitle <> "NO CHARTS" Then
            For Each oChart in oAnalysis.Charts
                m = 0
                ReDim aMatchedCounters(0)
                Set oMatchedCounter = New MatchedCounterObject
                oMatchedCounter.FullPath = "PlaceHolder"
                Set aMatchedCounters(0) = oMatchedCounter                
                bChartFound = False
                For a = 0 to UBound(aFile)
                    '// Match the counter paths to counter patterns
                    bCounterObjectsMatch = False
                    bCounterNamesMatch = False
                    bCounterInstancesMatch = False
                    If oChart.IsCounterObjectRegularExpression = True Then
                        bCounterObjectsMatch = CompareCounterPathToExpression(aFile(a), oChart.RegularExpressionCounterPath, "COUNTER_OBJECT", oChart.IsCounterObjectRegularExpression)
                    Else
                        bCounterObjectsMatch = CompareCounterPathToExpression(aFile(a), oChart.DataSource, "COUNTER_OBJECT", oChart.IsCounterObjectRegularExpression)
                    End If                    
                    If bCounterObjectsMatch = True Then
                        If oChart.IsCounterNameRegularExpression = True Then
                            bCounterObjectsMatch = CompareCounterPathToExpression(aFile(a), oChart.RegularExpressionCounterPath, "COUNTER_NAME", oChart.IsCounterNameRegularExpression)
                        Else                            
                            bCounterNamesMatch = CompareCounterPathToExpression(aFile(a), oChart.DataSource, "COUNTER_NAME", oChart.IsCounterNameRegularExpression)
                        End If                        
                        If bCounterNamesMatch = True Then
                            If oChart.IsCounterInstanceRegularExpression = True Then                                
                                bCounterInstancesMatch = CompareCounterPathToExpression(aFile(a), oChart.RegularExpressionCounterPath, "COUNTER_INSTANCE", oChart.IsCounterInstanceRegularExpression)
                            Else                            
                                bCounterInstancesMatch = CompareCounterPathToExpression(aFile(a), oChart.DataSource, "COUNTER_INSTANCE", oChart.IsCounterInstanceRegularExpression)
                            End If
                        End If
                    End If
                    If bCounterObjectsMatch = True AND bCounterNamesMatch = True AND bCounterInstancesMatch = True Then
                        bChartFound = True
                        ReDim Preserve aMatchedCounters(m)
                        Set aMatchedCounters(m) = ConstructMatchedCounterObject(aFile(a))
                        m = m + 1
                    End If                
                Next
                If bChartFound = False Then
                    oAnalysis.AllCountersFound = False
'                    OutputToConsoleAndLog "   [DetermineIfCountersAreInThePerfmonLog] The following Analysis is unable to process due to missing counters: "
'                    OutputToConsoleAndLog "    Analysis Name: " & oAnalysis.Name
'                    OutputToConsoleAndLog "     The following chart data source counter was not found in the perfmon log:"
'                    OutputToConsoleAndLog "      " & oChart.DataSource                
                End If
                If aMatchedCounters(0).FullPath <> "PlaceHolder" Then
                    oChart.MatchedCounters = aMatchedCounters
                End If
            Next
        End If
        If Err.number <> 0 Then
            oAnalysis.AllCountersFound = False
            OutputToConsoleAndLog "[DetermineIfCountersAreInThePerfmonLog] An error occured:"
            OutputToConsoleAndLog " Error Number: " & err.number
            OutputToConsoleAndLog " Error Description: " & err.Description     
        Else
            OutputToConsoleAndLog "  All counters for " & chr(34) & oAnalysis.Name & chr(34) & " found."   
        End If
        'ON ERROR GOTO 0              
    Next
    OutputToConsoleAndLog " Done determining if all counters needed in each analysis is in the perfmon log..."
    OutputToConsoleAndLog "Done determining if counters are in the Perfmon log."
End Sub

Sub CreateCounterListFromFilteredPerfmonLog
    Dim bRetVal
    bRetVal = GetCounterListFromBLG(g_FilteredPerfmonLogFile, g_FilteredPerfmonLogCounterListFile)
    If bRetVal = 0 Then
        OutputToConsoleAndLog "ERROR: [CreateCounterListFromFilteredPerfmonLog] Unable to create a counter list from " & g_FilteredPerfmonLogFile
        WScript.Quit
    End If
    LoadCounterListIntoMemory g_FilteredPerfmonLogCounterListFile    
End Sub

'Function UseRelogToCreateCounterListFromPerfmonLog(sPerfmonLog,sOutputFile, iTimeoutInSeconds)
'	Dim WshShell, oExec, oFSO, oFile, sCMD, strText, iTimeOutCount
'	Dim dQ
'	Set WshShell = CreateObject("WScript.Shell")
'    Const ForReading = 1, ForWriting = 2, ForAppending = 8
'    Set oFSO = CreateObject("Scripting.FileSystemObject")
'    
'    dQ = chr(34)
'    ' Create a file to read into ReLog for filtering.
'   
'    If oFSO.FileExists(sPerfmonLog) = False Then
'        OutputToConsoleAndLog "===============================ERROR========================================"
'        OutputToConsoleAndLog "[UseRelogToCreateCounterListFromPerfmonLog]"
'        OutputToConsoleAndLog "File " & sPerfmonLog & " doesn't exist"        
'        OutputToConsoleAndLog "============================================================================"
'        WScript.Quit
'    End If

''    If oFSO.FileExists("relog.exe") = False Then
''        Dim objShell, strCommand, sHTMLOutputPath
''        OutputToConsoleAndLog "===============================ERROR========================================"
''        OutputToConsoleAndLog "Microsoft Relog.exe is required."
''        OutputToConsoleAndLog " Please place Relog.exe in the local directory and try again."
''        OutputToConsoleAndLog " Currently Relog.exe is shipped with this tool until another installation"
''        OutputToConsoleAndLog "  for Windows XP can be found. If you figure this out, then email me at"
''        OutputToConsoleAndLog "  clinth@microsoft.com."
''        OutputToConsoleAndLog " Relog can be downloaded this location, but I can't get it to install"
''        OutputToConsoleAndLog "  on Windows XP:"
''        sHTMLOutputPath = "http://www.microsoft.com/downloads/details.aspx?FamilyID=f043c2f5-2a48-41ed-951b-ba7f62cf51d6&displaylang=en"
''        OutputToConsoleAndLog " " & sHTMLOutputPath          
''        OutputToConsoleAndLog "============================================================================"
''        Set objShell = createobject("Wscript.shell")		
''        strCommand = sHTMLOutputPath
''        objShell.Run strCommand
''        WScript.Quit
''    End If
'    
'    Dim sPerfmonLogForRelog
'    sPerfmonLogForRelog = sPerfmonLog
'    ' If there are spaces, then surround it in doublequotes.
'    If InStr(1, sPerfmonLogForRelog, " ") > 0 Then        
'        sPerfmonLogForRelog = chr(34) & sPerfmonLogForRelog & chr(34)
'    End If
'    
'    If Instr(1, sPerfmonLogForRelog, chr(34), 1) > 0 Then
'        sCMD = "ReLog.exe " & sPerfmonLogForRelog & " -q -y -o " & sOutputFile
'    Else
'        sCMD = "ReLog.exe " & chr(34) & sPerfmonLogForRelog & chr(34) & " -q -y -o " & sOutputFile
'    End If
'    
'	OutputToConsoleAndLog "Executing: " & sCMD
'	Set oExec = WshShell.Exec(sCMD)	
'    strText = oExec.StdOut.ReadAll()
'	OutputToConsoleAndLog strText
'    
'    If InStr(1, strText, "successful", 1) > 0 Then
'	    iTimeOutCount = 0
'        Do 
'            If iTimeOutCount >= iTimeoutInSeconds Then
'                UseRelogToCreateCounterListFromPerfmonLog = False
'                Exit Do
'            Else
'                UseRelogToCreateCounterListFromPerfmonLog = True
'            End If
'            OutputToConsoleAndLog "Waiting for " & sOutputFile & " to be created..."
'            WScript.Sleep 1000
'            iTimeOutCount = iTimeOutCount + 1
'        Loop Until oFSO.FileExists(sOutputFile) = True
'        If UseRelogToCreateCounterListFromPerfmonLog = True Then
'            OutputToConsoleAndLog "Found " & sOutputFile
'        End If
'    Else
'        UseRelogToCreateCounterListFromPerfmonLog = False     
'    End If
'    
'    Set oFSO = CreateObject("Scripting.FileSystemObject")
'    Set oFile = oFSO.GetFile(sOutputFile)
'    If oFile.Size = 0 Then
'        OutputToConsoleAndLog "===============================ERROR========================================"
'        OutputToConsoleAndLog "[UseRelogToCreateCounterListFromPerfmonLog]"
'        OutputToConsoleAndLog " No counters in the counter list of the filtered perfmon log."       
'        OutputToConsoleAndLog "============================================================================"
'        WScript.Quit    
'    End If    
'End Function

Sub LoadCounterListIntoMemory(sCountersToProcessFile)
    g_aRealCounterList = FileToArray(sCountersToProcessFile)
End Sub

Function FileToArray(sFile)
	Const ForReading = 1, ForWriting = 2, ForAppending = 8
	Dim aFile()
	Dim fso, oFile, iLineCount
	Set fso = CreateObject("Scripting.FileSystemObject")
	
	Set oFile = fso.OpenTextFile(sFile, ForReading, False)    
    iLineCount = 0
    Do Until oFile.AtEndOfStream
        oFile.ReadLine
        iLineCount = iLineCount + 1
    Loop
    oFile.Close
    
    ReDim aFile(iLineCount - 1)
	Set oFile = fso.OpenTextFile(sFile, ForReading, False)    
    iLineCount = 0
    Do Until oFile.AtEndOfStream
        aFile(iLineCount) = oFile.ReadLine
        iLineCount = iLineCount + 1
    Loop
    oFile.Close
    FileToArray = aFile
End Function

Sub PreCleanUp
    Dim WshShell, objFSO, objFolder, colFiles, objFile, sFile
    Set WshShell = WScript.CreateObject("WScript.Shell")
    Set objFSO = CreateObject("Scripting.FileSystemObject")    
    Set objFolder = objFSO.GetFolder(g_UserTempDirectory)
    Set colFiles = objFolder.Files
    For Each objFile in colFiles
        If LCase(Right(objFile.Name, 7)) = "pal.log" Then
            sFile = objFile.Name
            OutputToConsoleAndLog "Deleting " & sFile & "..."
            ON ERROR RESUME NEXT
            objFile.Delete(True)
            If Err.number <> 0 Then
                OutputToConsoleAndLog "Unable to delete file " & sFile
                OutputToConsoleAndLog "ERROR: " & err.number & ", " & err.Description
                WScript.Quit
            Else
                OutputToConsoleAndLog sFile & " deleted."
            End If            
        End If
    Next
End Sub

Sub PostCleanUp
    Dim WshShell, objFSO, objFolder, colFiles, objFile, sFile
    Set WshShell = WScript.CreateObject("WScript.Shell")
    Set objFSO = CreateObject("Scripting.FileSystemObject")
    If objFSO.FolderExists(g_WorkingDirectory) = True Then
        Set objFolder = objFSO.GetFolder(g_WorkingDirectory)
        objFolder.Delete(True)
    End If
    
'    Set objFolder = objFSO.GetFolder(g_UserTempDirectory)
'    Set colFiles = objFolder.Files
'    For Each objFile in colFiles
'        If objFile.Name = g_MergedPerfmonLogFile OR objFile.Name = "_CountersToFilter.txt" OR objFile.Name = g_FilteredPerfmonLogCounterListFile OR objFile.Name = g_FilteredPerfmonLogFile OR objFile.Name = g_OriginalRealCounterList Then
'            sFile = objFile.Name
'            OutputToConsoleAndLog "Deleting " & sFile & "..."
'            ON ERROR RESUME NEXT
'            objFile.Delete
'            If Err.number <> 0 Then
'                OutputToConsoleAndLog "Unable to delete file " & sFile
'                OutputToConsoleAndLog "ERROR: " & err.number & ", " & err.Description
'                WScript.Quit
'            Else
'                OutputToConsoleAndLog sFile & " deleted."
'            End If            
'        End If
'    Next
End Sub

Sub FilterPerfmonLog
    Dim aCountersToFilter, bFilterWorked
    OutputToConsoleAndLog "Organizing data structures. Please wait..."
    aCountersToFilter = GetCountersNeededForAnalysis
    OutputToConsoleAndLog "Done organizing data structures."
    ' Use ReLog to remove any excess counter data that we don't need.
    OutputToConsoleAndLog "Using Relog.exe to create a temporary perfmon log with only counters being analyzed..."
    'OutputToConsoleAndLog "[DEBUG] g_dBeginTime: " & g_dBeginTime
    'OutputToConsoleAndLog "[DEBUG] g_dBeginTime: " & g_dEndTime
    If g_dBeginTime <> "" AND g_dEndTime <> "" Then
        OutputToConsoleAndLog "Processing with Begin and End Times"
        bFilterWorked = UseRelogToFilterCounters(g_PerfmonLog, aCountersToFilter, g_FilteredPerfmonLogFile, 60, g_dBeginTime, g_dEndTime)
    Else
        bFilterWorked = UseRelogToFilterCounters(g_PerfmonLog, aCountersToFilter, g_FilteredPerfmonLogFile, 60, "", "")    
    End If

    If bFilterWorked = False Then
        OutputToConsoleAndLog "Failed to filter the counter list from the " & chr(34) & g_PerfmonLog & chr(34) & " document."
        WScript.Quit
    Else
        OutputToConsoleAndLog "Done using Relog.exe to create a temporary perfmon log with only counters being analyzed."
    End If
End Sub

Function UseRelogToFilterCounters(sPerfmonLog,aCountersToFilter,sNewCounterLog, iTimeoutInSeconds, dBeginTime, dEndTime)
	Dim WshShell, oExec
	Dim dQ, i, sCMD, strText
	Dim oFSO, oFile
    Const ForReading = 1, ForWriting = 2, ForAppending = 8
    Dim sCountersToFilterFile, iTimeOutCount
    dQ = chr(34)
        
    If Instr(1, aCountersToFilter(0), "PlaceHolder", 1) > 0 Then
        OutputToConsoleAndLog "[UseRelogToFilterCounters] There are no counters to filter."
        WScript.Quit
    End If    
    
    ' Create a file to read into ReLog for filtering.
    sCountersToFilterFile = g_WorkingDirectory & "\" & "_CountersToFilter.txt"
    Set oFSO = CreateObject("Scripting.FileSystemObject")
    Set oFile = oFSO.CreateTextFile(sCountersToFilterFile, True)
    For i = 0 To UBound(aCountersToFilter)
        oFile.WriteLine aCountersToFilter(i)
    Next
    oFile.Close
    WScript.Sleep 1000 ' Allowing the file handle to release before executing ReLog.exe

    Dim sPerfmonLogForRelog
    sPerfmonLogForRelog = sPerfmonLog
    ' If there are spaces, then surround it in doublequotes.
    If InStr(1, sPerfmonLogForRelog, " ") > 0 Then        
        sPerfmonLogForRelog = chr(34) & sPerfmonLogForRelog & chr(34)
    End If    

    Set WshShell = CreateObject("WScript.Shell")
        
    If dBeginTime <> "" AND dEndTime <> "" Then    
        OutputToConsoleAndLog "BeginTime: " & dBeginTime & ", EndTime: " & dEndTime
        dBeginTime = ConvertToTwentyFourHourTime(dBeginTime)
        dEndTime = ConvertToTwentyFourHourTime(dEndTime)        
        If Instr(1, sPerfmonLogForRelog, chr(34), 1) > 0 Then
            sCMD = "ReLog.exe " & sPerfmonLogForRelog & " -cf " & sCountersToFilterFile & " -b " & chr(34) & dBeginTime & chr(34) & " -e " & chr(34) & dEndTime & chr(34) & " -f CSV -y -o " & sNewCounterLog
        Else
            sCMD = "ReLog.exe " & chr(34) & sPerfmonLogForRelog & chr(34) & " -cf " & sCountersToFilterFile & " -b " & chr(34) & dBeginTime & chr(34) & " -e " & chr(34) & dEndTime & chr(34) & " -f CSV -y -o " & sNewCounterLog
        End If    
    Else
        'OutputToConsoleAndLog "[DEBUG] dBeginTime = "" AND dEndTime = """
        If Instr(1, sPerfmonLogForRelog, chr(34), 1) > 0 Then
            sCMD = "ReLog.exe " & sPerfmonLogForRelog & " -cf " & sCountersToFilterFile & " -f CSV -y -o " & sNewCounterLog
        Else
            sCMD = "ReLog.exe " & chr(34) & sPerfmonLogForRelog & chr(34) & " -cf " & sCountersToFilterFile & " -f CSV -y -o " & sNewCounterLog
        End If    
    End If
        
	OutputToConsoleAndLog "Executing: " & sCMD
	Set oExec = WshShell.Exec(sCMD)
	
    'Do Until oExec.StdOut.AtEndOfStream
        strText = oExec.StdOut.ReadAll()
    	OutputToConsoleAndLog strText
    'Loop
    
    If InStr(1, strText, "successful", 1) > 0 Then
	    iTimeOutCount = 0
        Do 
            If iTimeOutCount >= iTimeoutInSeconds Then
                UseRelogToFilterCounters = False
                Exit Do
            Else
                UseRelogToFilterCounters = True
            End If
            OutputToConsoleAndLog "Waiting for " & sNewCounterLog & " to be created..."
            WScript.Sleep 1000
            iTimeOutCount = iTimeOutCount + 1
        Loop Until oFSO.FileExists(sNewCounterLog) = True
        If UseRelogToFilterCounters = True Then
            OutputToConsoleAndLog "Found " & sNewCounterLog
        End If
    Else
        UseRelogToFilterCounters = False          
    End If
    
    ' Check to see if nothing was produced.
    Set oFile = oFSO.GetFile(sNewCounterLog)
    If oFile.Size = 0 Then
        OutputToConsoleAndLog "===============================ERROR========================================"
        OutputToConsoleAndLog "[UseRelogToFilterCounters]"
        OutputToConsoleAndLog " No counters in the filtered perfmon log after filtering."       
        OutputToConsoleAndLog " This typically means that none of the counters needed"       
        OutputToConsoleAndLog "  to perform an analysis are present in the perfmon log."       
        OutputToConsoleAndLog "============================================================================"
        WScript.Quit    
    End If    
    
    ' Clean up    
    Set oFile = oFSO.GetFile(sCountersToFilterFile)
    oFile.Delete
End Function

Sub RBF_EnumerateRules
    Dim i, oThreshold, oCounters, oCharts
    For i = 0 To UBound(g_aRules)
        ' <ANALYSIS NAME="Processor\% Processor Time"  ENABLED="True" ANALYZECOUNTER="\Processor(*)\% Processor Time" CATEGORY="Processor">
        OutputToConsoleAndLog "Name: " & g_aRules(i)("Name")
        OutputToConsoleAndLog "Enabled: " & g_aRules(i)("Enabled")
        OutputToConsoleAndLog "AnalyzeCounter: " & g_aRules(i)("AnalyzeCounter")
        OutputToConsoleAndLog " Counters: " & g_aRules(i)("CounterCount")
        OutputToConsoleAndLog ""
        For Each oCounters in g_aRules(i)("Counters")
            OutputToConsoleAndLog "  Name: " & oCounters("Name")
            OutputToConsoleAndLog "  VarName: " & oCounters("VarName")
            OutputToConsoleAndLog ""
        Next
        OutputToConsoleAndLog " Thresholds: " & g_aRules(i)("ThresholdCount")
        OutputToConsoleAndLog ""
        For Each oThreshold in g_aRules(i)("Thresholds")
            OutputToConsoleAndLog "  Condition: " & oThreshold("Condition")
            OutputToConsoleAndLog "  Operator: " & oThreshold("Operator")
            OutputToConsoleAndLog "  Level: " & oThreshold("Level")
            OutputToConsoleAndLog "  Text: " & oThreshold("Text")
            OutputToConsoleAndLog ""
        Next
        OutputToConsoleAndLog " Charts: " & g_aRules(i)("ChartCount")
        OutputToConsoleAndLog ""
        For Each oCharts in g_aRules(i)("Charts")
            OutputToConsoleAndLog "  ChartType: " & oCharts("ChartType")
            OutputToConsoleAndLog "  Categories: " & oCharts("Categories")
            OutputToConsoleAndLog "  GroupSize: " & oCharts("GroupSize") 
            OutputToConsoleAndLog "  ChartTitle: " & oCharts("ChartTitle")
            OutputToConsoleAndLog "  MaxCategoryLabels: " & oCharts("MaxCategoryLabels")
            OutputToConsoleAndLog "  Legend: " & oCharts("Legend") 
            OutputToConsoleAndLog "  Values: " & oCharts("Values")
            OutputToConsoleAndLog "  oTsFormat: " & oCharts("oTsFormat")
            OutputToConsoleAndLog "  Text: " & oCharts("Text")
            OutputToConsoleAndLog ""                            
        Next              
    Next
    OutputToConsoleAndLog "===================="
End Sub


Sub ReadRulesXMLIntoMemory
    Dim xmldoc, XMLRoot
    Dim oAnalysis
    Dim oXMLAnalysis, oXMLAnalysisChildNode, objNodeList
    Dim iCount, bEnabled, iNumOfCounters, iNumOfThresholds, iNumOfCharts
    Dim aCounters(), aThresholds(), aCharts()
    Dim oCounter, oThreshold, oChart, oCode, oCodes
    Dim oExclusions, oExclude, e, aExclusions()
    Dim oDescriptions, oDescription
    
  	Set xmldoc = CreateObject("Msxml2.DOMDocument")
    xmldoc.async = False
    xmldoc.Load g_XMLThresholdFile
    Set g_XMLRoot = xmldoc.documentElement

    '// Questions
	Set g_dctQuestions = CreateObject("Scripting.Dictionary")
	g_dctQuestions.RemoveAll
	Dim oQuestion, oXmlNode 	    
    For Each oXmlNode in g_XMLRoot.SelectNodes("//QUESTION")
        Set oQuestion = New QuestionObject
        oQuestion.QuestionVarName = oXmlNode.GetAttribute("QUESTIONVARNAME")
        oQuestion.DataType = oXmlNode.GetAttribute("DATATYPE")
        oQuestion.DefaultValue = oXmlNode.GetAttribute("DEFAULTVALUE")
        oQuestion.Question = oXmlNode.Text
        oQuestion.Answer = ""
        g_dctQuestions.Add oXmlNode.GetAttribute("QUESTIONVARNAME"), oQuestion
    Next    
    
    '// Check for pre-answered questions		   
    Dim sAnswer, bArgFound, sArg, oNamedArgs, sQuestionVarname, sDataType, sXMLInputAnswer
    Set oNamedArgs = WScript.Arguments.Named
    For Each sQuestionVarname in g_dctQuestions.Keys
        bArgFound = False
        '// Check the XML Input file first
        g_dctQuestions(sQuestionVarname).Answer = GetValueFromXMLInputFile(g_XMLInputFilePath, sQuestionVarname)
        If g_dctQuestions(sQuestionVarname).Answer <> "" Then
            bArgFound = True
        End If
        '// Check the arguments next. If an argument is found, then it will override the XMLInput.        
        For Each sArg in oNamedArgs
            If LCase(sArg) = LCase(sQuestionVarname) Then
                sAnswer = oNamedArgs(sArg)
                sDataType = LCase(g_dctQuestions(sQuestionVarname).DataType)
                SELECT CASE sDataType
                    CASE "boolean"
                        If LCase(sAnswer) = "true" Then
                            g_dctQuestions(sQuestionVarname).Answer = True                            
                        Else
                            g_dctQuestions(sQuestionVarname).Answer = False
                        End If
                    CASE Else
                        g_dctQuestions(sQuestionVarname).Answer = sAnswer                        
                END SELECT
                bArgFound = True
            End If            
        Next
        '// If not pre-answered/found, then ask the user.
        If bArgFound = False Then
            Set g_dctQuestions(sQuestionVarname) = AskAQuestion(g_dctQuestions(sQuestionVarname))
        End If
    Next    
    
    '<ANALYSIS NAME="Processor\% Processor Time"  ENABLED="True" ANALYZECOUNTER="\Processor(*)\% Processor Time">
    iCount = 0
	Set objNodeList = g_XMLRoot.selectNodes("//ANALYSIS")
	For Each oXMLAnalysis In objNodeList
	    bEnabled = ConvertStringTrueFalseToTrueOrFalse(oXMLAnalysis.GetAttribute("ENABLED"))
	    If bEnabled = True Then 
		    iCount = iCount + 1
		End If
	Next
	If iCount = 0 Then
	    OutputToConsoleAndLog "[ReadRulesXMLIntoMemory] ERROR: There are no either no ANALYSIS nodes in the threshold XML file or all ANALYSIS nodes are disabled. Please fix and try again."
	    WScript.Quit
	End If
	ReDim g_aData(iCount - 1)
	iCount = 0
	For Each oXMLAnalysis In objNodeList
	    If oXMLAnalysis.NodeName = "ANALYSIS" Then
	        bEnabled = ConvertStringTrueFalseToTrueOrFalse(oXMLAnalysis.GetAttribute("ENABLED"))
	        If bEnabled = True Then
            	iNumOfCounters = 0
	            iNumOfThresholds = 0
	            iNumOfCharts = 0
                Set oAnalysis = New AnalysisDataObject          	            	           
                oAnalysis.Name = oXMLAnalysis.GetAttribute("NAME")
                oAnalysis.AnalyzeCounter = oXMLAnalysis.GetAttribute("ANALYZECOUNTER")
                oAnalysis.Enabled = ConvertStringTrueFalseToTrueOrFalse(oXMLAnalysis.GetAttribute("ENABLED"))
                oAnalysis.Category = oXMLAnalysis.GetAttribute("CATEGORY")
                oAnalysis.IsCounterObjectRegularExpression = ConvertStringTrueFalseToTrueOrFalse(oXMLAnalysis.GetAttribute("ISCOUNTEROBJECTREGULAREXPRESSION"))
                oAnalysis.IsCounterNameRegularExpression = ConvertStringTrueFalseToTrueOrFalse(oXMLAnalysis.GetAttribute("ISCOUNTERNAMEREGULAREXPRESSION"))
                oAnalysis.IsCounterInstanceRegularExpression = ConvertStringTrueFalseToTrueOrFalse(oXMLAnalysis.GetAttribute("ISCOUNTERINSTANCEREGULAREXPRESSION"))
                oAnalysis.RegularExpressionCounterPath = oXMLAnalysis.GetAttribute("REGULAREXPRESSIONCOUNTERPATH")
                oAnalysis.CounterPath = oAnalysis.AnalyzeCounter
                oAnalysis.CounterComputer = GetCounterComputer(oAnalysis.AnalyzeCounter)
                oAnalysis.CounterObject = GetCounterObject(oAnalysis.AnalyzeCounter)
                oAnalysis.CounterName = GetCounterName(oAnalysis.AnalyzeCounter)
                oAnalysis.CounterInstance = GetCounterInstance(oAnalysis.AnalyzeCounter)
                ReDim aCharts(0)
		            Set oChart = New ChartDataObject
		            oChart.ChartTitle = "NO CHARTS"		            
		            Set aCharts(0) = oChart
                ReDim aThresholds(0)
		        For Each oXMLAnalysisChildNode in oXMLAnalysis.childNodes
		            SELECT CASE oXMLAnalysisChildNode.NodeName
		                CASE "DESCRIPTION"
		                    oAnalysis.Description = oXMLAnalysisChildNode.Text
		                CASE "COUNTER"
		                    Set oCounter = New CounterDataObject
		                    oCounter.Name = oXMLAnalysisChildNode.GetAttribute("NAME")
		                    oCounter.MinVarName = oXMLAnalysisChildNode.GetAttribute("MINVARNAME")
		                    oCounter.AvgVarName = oXMLAnalysisChildNode.GetAttribute("AVGVARNAME")
		                    oCounter.MaxVarName = oXMLAnalysisChildNode.GetAttribute("MAXVARNAME")
		                    oCounter.TrendVarname = oXMLAnalysisChildNode.GetAttribute("TRENDVARNAME")
		                    oCounter.DataType = oXMLAnalysisChildNode.GetAttribute("DATATYPE")
		                    oCounter.RegularExpressionCounterPath = oXMLAnalysisChildNode.GetAttribute("REGULAREXPRESSIONCOUNTERPATH")
                            oCounter.IsCounterObjectRegularExpression = ConvertStringTrueFalseToTrueOrFalse(oXMLAnalysisChildNode.GetAttribute("ISCOUNTEROBJECTREGULAREXPRESSION"))
                            oCounter.IsCounterNameRegularExpression = ConvertStringTrueFalseToTrueOrFalse(oXMLAnalysisChildNode.GetAttribute("ISCOUNTERNAMEREGULAREXPRESSION"))
                            oCounter.IsCounterInstanceRegularExpression = ConvertStringTrueFalseToTrueOrFalse(oXMLAnalysisChildNode.GetAttribute("ISCOUNTERINSTANCEREGULAREXPRESSION"))
                            oCounter.CounterPath = oCounter.Name
                            oCounter.CounterComputer = GetCounterComputer(oCounter.Name)
                            oCounter.CounterObject = GetCounterObject(oCounter.Name)
                            oCounter.CounterName = GetCounterName(oCounter.Name)
                            oCounter.CounterInstance = GetCounterInstance(oCounter.Name)
		                    Set oExclusions = oXMLAnalysisChildNode.selectNodes("./EXCLUDE")
		                    ReDim aExclusions(0)
		                    aExclusions(0) = NO_EXCLUSIONS		                    
		                    e = 0		                    
		                    For Each oExclude in oExclusions
		                        ReDim Preserve aExclusions(e)
		                        aExclusions(e) = oExclude.GetAttribute("INSTANCE")
		                        e = e + 1
		                    Next
		                    oCounter.Exclusions = aExclusions
		                    ReDim Preserve aCounters(iNumOfCounters)
		                    Set aCounters(iNumOfCounters) = oCounter
		                    iNumOfCounters = iNumOfCounters + 1
		                CASE "THRESHOLD"
		                    Set oThreshold = New ThresholdDataObject
		                    oThreshold.Name = oXMLAnalysisChildNode.GetAttribute("NAME")
		                    oThreshold.Condition = oXMLAnalysisChildNode.GetAttribute("CONDITION")
		                    oThreshold.Color = oXMLAnalysisChildNode.GetAttribute("COLOR")
		                    oThreshold.Priority = oXMLAnalysisChildNode.GetAttribute("PRIORITY")
		                    Set oCodes = oXMLAnalysisChildNode.SelectNodes("./CODE")
		                    For Each oCode in oCodes
		                        oThreshold.Code = oCode.Text
		                    Next		                    		                    
		                    Set oDescriptions = oXMLAnalysisChildNode.SelectNodes("./DESCRIPTION")
		                    For Each oDescription in oDescriptions
		                        oThreshold.Description = oDescription.Text
		                    Next
		                    ReDim Preserve aThresholds(iNumOfThresholds)
		                    Set aThresholds(iNumOfThresholds) = oThreshold
		                    iNumOfThresholds = iNumOfThresholds + 1
		                CASE "CHART"
		                    Set oChart = New ChartDataObject
		                    oChart.ChartType = oXMLAnalysisChildNode.GetAttribute("CHARTTYPE")
		                    oChart.Categories = oXMLAnalysisChildNode.GetAttribute("CATEGORIES")
		                    oChart.MaxCategoryLabels = oXMLAnalysisChildNode.GetAttribute("MAXCATEGORYLABELS")
		                    oChart.Legend = oXMLAnalysisChildNode.GetAttribute("LEGEND")
		                    oChart.Values = oXMLAnalysisChildNode.GetAttribute("VALUES")
		                    oChart.GroupSize = oXMLAnalysisChildNode.GetAttribute("GROUPSIZE")
		                    oChart.ChartTitle = oXMLAnalysisChildNode.GetAttribute("CHARTTITLE")
		                    oChart.OTSFormat = oXMLAnalysisChildNode.GetAttribute("OTSFORMAT")
		                    oChart.DataSource = oXMLAnalysisChildNode.GetAttribute("DATASOURCE")
		                    oChart.DataType = oXMLAnalysisChildNode.GetAttribute("DATATYPE")
		                    oChart.OrderBy = oXMLAnalysisChildNode.GetAttribute("ORDERBY")
                            oChart.IsCounterObjectRegularExpression = ConvertStringTrueFalseToTrueOrFalse(oXMLAnalysisChildNode.GetAttribute("ISCOUNTEROBJECTREGULAREXPRESSION"))
                            oChart.IsCounterNameRegularExpression = ConvertStringTrueFalseToTrueOrFalse(oXMLAnalysisChildNode.GetAttribute("ISCOUNTERNAMEREGULAREXPRESSION"))
                            oChart.IsCounterInstanceRegularExpression = ConvertStringTrueFalseToTrueOrFalse(oXMLAnalysisChildNode.GetAttribute("ISCOUNTERINSTANCEREGULAREXPRESSION"))
                            oChart.RegularExpressionCounterPath = oXMLAnalysisChildNode.GetAttribute("REGULAREXPRESSIONCOUNTERPATH")
                            oChart.CounterPath = oChart.DataSource
                            oChart.CounterComputer = GetCounterComputer(oChart.DataSource)
                            oChart.CounterObject = GetCounterObject(oChart.DataSource)
                            oChart.CounterName = GetCounterName(oChart.DataSource)
                            oChart.CounterInstance = GetCounterInstance(oChart.DataSource)                            
		                    Set oExclusions = oXMLAnalysisChildNode.selectNodes("./EXCLUDE")
		                    ReDim aExclusions(0)
		                    aExclusions(0) = NO_EXCLUSIONS		                    
		                    e = 0		                    
		                    For Each oExclude in oExclusions
		                        ReDim Preserve aExclusions(e)
		                        aExclusions(e) = oExclude.GetAttribute("INSTANCE")
		                        e = e + 1
		                    Next
		                    oChart.Exclusions = aExclusions
		                    ReDim Preserve aCharts(iNumOfCharts)
		                    Set aCharts(iNumOfCharts) = oChart
		                    iNumOfCharts = iNumOfCharts + 1
		            END SELECT
		        Next
		        oAnalysis.CounterCount = iNumOfCounters
		        oAnalysis.ThresholdCount = iNumOfThresholds
		        oAnalysis.ChartCount = iNumOfCharts
		        oAnalysis.Counters = aCounters
		        oAnalysis.Thresholds = aThresholds
		        oAnalysis.Charts = aCharts
		        Set g_aData(iCount) = oAnalysis
		        iCount = iCount + 1		        
	        End If	    
	    End If
	Next
End Sub

Function ConvertStringTrueFalseToTrueOrFalse(sTF)
    If LCase(sTF) = LCase("True") Then
        ConvertStringTrueFalseToTrueOrFalse = True
    Else
        ConvertStringTrueFalseToTrueOrFalse = False        
    End If
End Function

Function ReadAnalysisXMLIntoDictionary(oXMLAnalysis)
    Set oAnalysis = CreateObject("Scripting.Dictionary")
    oAnalysis.Add "Name", oXMLAnalysis.GetAttribute("NAME")
    oAnalysis.Add "Enabled", oXMLAnalysis.GetAttribute("ENABLED")
    oAnalysis.Add "Category", oXMLAnalysis.GetAttribute("CATEGORY")
    For Each oXMLNode in oXMLAnalysis.childNodes
        SELECT CASE oXMLNode.NodeName
            CASE "WHYBEINGVALIDATED"
                oAnalysis.Add "WHYBEINGVALIDATED", oXMLNode.Text
            CASE "HOWTOVALIDATE"
                oAnalysis.Add "HOWTOVALIDATE", oXMLNode.Text
            CASE "MOREINFO"
                oAnalysis.Add "MOREINFO", oXMLNode.Text
            CASE "REFERENCES"
                oAnalysis.Add "REFERENCES", oXMLNode.Text      
        End SELECT
    Next
    Set ReadAnalysisXMLIntoDictionary = oAnalysis
End Function

Sub SetGlobalVariables
    ' Sets the global variables values
    Dim aPath, sPerfmonLogName
    ProcessArguments
    MergePerfmonLogs
    SetIntervalDescription
    GetDateTimeStamp
    ResolvePALStringVariablesForPALArguments
    CreateOutputDirectory
    CreateReportResourceDirectory    
    g_ReportResourceDirNoSpaces = GetDirectoryShortName(g_ReportResourceDir)    
    dQ = chr(34) ' literal double quote
End Sub

Sub ResolvePALStringVariablesForPALArguments
    g_PALReportsDirectory = ResolvePALStringVariables(g_PALReportsDirectory)
    g_ReportFile = ResolvePALStringVariables(g_ReportFile)
    g_ReportFilePath = g_PALReportsDirectory & "\" & g_ReportFile
    g_XMLOutputFile = ResolvePALStringVariables(g_XMLOutputFile)
    g_XMLOutputFilePath = g_PALReportsDirectory & "\" & g_XMLOutputFile
    g_ReportResourceDir = RemoveFileExtension(g_ReportFilePath)
End Sub

Sub CreateOutputDirectory
    Dim oFSO, bRetVal
    Set oFSO = CreateObject("Scripting.FileSystemObject")
    If oFSO.FolderExists(g_PALReportsDirectory) = False Then
        '// Check if the directory exists. If not, then create it.
        OutputToConsoleAndLog "Creating user defined output directory: " & chr(34) & g_PALReportsDirectory & chr(34) & "..."
        bRetVal = CreateDirectory(g_PALReportsDirectory, 10)
        If bRetVal = False Then
            OutputToConsoleAndLog "Unable to create the output directory " & chr(34) & g_PALReportsDirectory & chr(34) & ". Ensure you have the permissions to create this directory. On Windows Vista computer, this tool does not have sufficient rights to write to file system locations other than your TEMP directory and My Documents folders. In order to write to file system locations try elevating the security of this tool."
            WScript.Quit
        Else
            OutputToConsoleAndLog "Created user defined output directory: " & chr(34) & g_PALReportsDirectory & chr(34)
        End If
    End If
End Sub

Sub CreateReportResourceDirectory
'    Dim bRetVal, oWshShell, sUserProfilePath, oFSO, aPath, sPerfmonLogName
'    Dim sMyDocs, sPALReportsDir, sPALReportsDirDoubleSlash, oShell, oFS, oDir, WQL
'    Dim sPALReportsDirInEightDotThreeFormat

    Dim oFSO, bRetVal
    Set oFSO = CreateObject("Scripting.FileSystemObject")
    If oFSO.FolderExists(g_ReportResourceDir) = False Then
        '// Check if the directory exists. If not, then create it.
        OutputToConsoleAndLog "Creating the resource directory: " & chr(34) & g_ReportResourceDir & chr(34) & "..."
        bRetVal = CreateDirectory(g_ReportResourceDir, 10)
        If bRetVal = False Then
            OutputToConsoleAndLog "Unable to create the resource directory " & chr(34) & g_ReportResourceDir & chr(34) & ". This directory is based on the output directory location, therefore ensure you have the permissions to create this directory. On Windows Vista computer, this tool does not have sufficient rights to write to file system locations other than your TEMP directory and My Documents folders. In order to write to file system locations try elevating the security of this tool."
            WScript.Quit
        Else
            OutputToConsoleAndLog "Created user defined resource directory: " & chr(34) & g_ReportResourceDir & chr(34)
        End If
    End If
               
'    If g_PALReportsDirectory <> "" Then
'        'If Instr(1, g_PALReportsDirectory, "[My Documents]", 1) > 0 Then
'            'g_PALReportsDirectory = Replace(g_PALReportsDirectory, "[My Documents]", sMyDocs)
'            g_PALReportsDirectory = ResolvePALStringVariables(g_PALReportsDirectory)
'        'End If
'        '// The user specified an output directory
'        If oFSO.FolderExists(g_PALReportsDirectory) = False Then
'            '// Check if the directory exists. If not, then create it.
'            OutputToConsoleAndLog "Creating user defined output directory: " & chr(34) & g_PALReportsDirectory & chr(34) & "..."
'            bRetVal = CreateDirectory(g_PALReportsDirectory, 10)
'            If bRetVal = False Then
'                OutputToConsoleAndLog "Unable to create the output directory " & chr(34) & g_PALReportsDirectory & chr(34) & ". Ensure you have the permissions to create this directory. On Windows Vista computer, this tool does not have sufficient rights to write to file system locations other than your TEMP directory and My Documents folders. In order to write to file system locations try elevating the security of this tool."
'                WScript.Quit
'            Else
'                OutputToConsoleAndLog "Created user defined output directory: " & chr(34) & g_PALReportsDirectory & chr(34)
'            End If
'        End If
'    Else
'        '// Use the default location of "My Documents\PAL Reports"        
'        sPALReportsDir = sMyDocs & "\PAL Reports"
'        g_PALReportsDirectory = sPALReportsDir
'        If oFSO.FolderExists(g_PALReportsDirectory) = False Then
'            OutputToConsoleAndLog "Creating default output directory: " & chr(34) & g_PALReportsDirectory & chr(34) & "..."
'            bRetVal = CreateDirectory(g_PALReportsDirectory, 10)
'            If bRetVal = False Then
'                OutputToConsoleAndLog "Unable to create default output directory " & chr(34) & g_PALReportsDirectory & chr(34) & ". Ensure you have the permissions to create this directory."
'                WScript.Quit
'            Else
'                OutputToConsoleAndLog "Created default output directory: " & chr(34) & g_PALReportsDirectory & chr(34)
'            End If        
'        End If        
'    End If
'      
'    'sPALReportsDirInEightDotThreeFormat = GetDirectoryShortName(g_PALReportsDirectory)
'    'g_PALReportsDirectoryNoSpaces = sPALReportsDirInEightDotThreeFormat
'    
'    'aPath = Split(g_PerfmonLog, "\")
'    'sPerfmonLogName = aPath(UBound(aPath))
'    'sPerfmonLogName = Mid(sPerfmonLogName, 1, Len(sPerfmonLogName) - 4)
'    'g_ReportResourceDir = g_PALReportsDirectory & "\" & Replace(sPerfmonLogName, " ", "_") & "_PAL_ANALYSIS_" & g_DateTimeStamp & "_" & RemoveCurlyBrackets(g_GUID)
'    g_ReportResourceDir = RemoveFileExtension(g_ReportFilePath)
'    'g_ReportResourceDirNoSpaces = g_PALReportsDirectoryNoSpaces & "\" & Replace(sPerfmonLogName, " ", "_") & "_PAL_ANALYSIS_" & g_DateTimeStamp & "_" & RemoveCurlyBrackets(g_GUID)
'    g_ReportResourceDirNoSpaces = GetDirectoryShortName(g_ReportResourceDir)
'    OutputToConsoleAndLog "Creating report resource directory: " & chr(34) & g_ReportResourceDir & chr(34) & "..."
'    bRetVal = CreateDirectory(g_ReportResourceDir, 10)
'    If bRetVal = False Then        
'        OutputToConsoleAndLog "Unable to create the report resource directory " & chr(34) & g_ReportResourceDir & chr(34) & ". Ensure you have the permissions to create this directory. On Windows Vista computer, this tool does not have sufficient rights to write to file system locations other than your TEMP directory and My Documents folders. In order to write to file system locations try elevating the security of this tool."
'        WScript.Quit
'    Else
'        OutputToConsoleAndLog "Created report resource directory: " & chr(34) & g_ReportResourceDir & chr(34) & "..."
'    End If      
End Sub

Function CreateDirectory(sDir, iTimeoutInSeconds)
    Dim objFSO, objFolder
    Dim iTimeoutCounter, bTimedOut
    
    Set objFSO = CreateObject("Scripting.FileSystemObject")
    Set objFolder = objFSO.CreateFolder(sDir)
    
	iTimeoutCounter = 0
	bTimedOut = False
	Do Until objFSO.FolderExists(sDir) = True
	    OutputToConsoleAndLog "Waiting for folder " & sDir & " to be created..."
	    WScript.Sleep 1000
	    iTimeoutCounter = iTimeoutCounter + 1
	    If iTimeoutCounter => iTimeoutInSeconds Then
	        bTimedOut = True
	        Exit Do
	    End If
	Loop
	If bTimedOut = False Then
	    CreateDirectory = True
	Else
	    CreateDirectory = False
	End If
End Function

Sub GetDateTimeStamp()
	
	Dim AMorPM
	Dim Seconds
	Dim Minutes
	Dim Hours
	Dim theDay
	Dim theMonth

	Hours = Hour(Now)
	Minutes = Minute(Now)
	Seconds = Second(Now)
	theDay = Day(Now)
	theMonth = Month(Now)
	AMorPM = Right(Now(),2)
	
	If Len(Hours) = 1 Then Hours = "0" & Hours
	If Len(Minutes) = 1 Then Minutes = "0" & Minutes
	If Len(Seconds) = 1 Then Seconds = "0" & Seconds
	If Len(theDay) = 1 Then theDay = "0" & theDay
	If Len(theMonth) = 1 Then theMonth = "0" & theMonth
	
	'g_DateTimeStamp = "Date_" & theMonth & "-" & theDay & "-" & Year(Now) & "_" & Hours & "-" & Minutes & "-" & Seconds & AMorPM
	g_DateTimeStamp = Year(Now) & "-" & theMonth & "-" & theDay & "_" & Hours & "-" & Minutes & "-" & Seconds & AMorPM
	g_DateReport = Year(Now) & "-" & theMonth & "-" & theDay & " " & Hours & ":" & Minutes 
		
End Sub

Sub SetIntervalDescription
    SELECT CASE g_Interval
        CASE ONE_HOUR
            g_IntervalDescription = "Hour"
        CASE ONE_MINUTE
            g_IntervalDescription = "Minute"
        CASE Else
            g_IntervalDescription = "Interval"     
    END SELECT
End Sub

Sub ProcessArguments()
    Dim Syntax, objArgs, i, oFSO, oNamedArgs, sPerfmonLog
        '===============================================================================
	    Syntax = "" & _
		" Syntax:" & chr(10) & chr(10) & _
		"   CScript PAL.vbs [/?] /LOG:PerfmonLog [OPTIONS]" & Chr(10) & Chr(10) & _
		"   [/?]                           Optional. Show this help text." & Chr(10) & _
		"   /LOG:[FileName[;FileName...]]  Required. Perfmon log(s) to analyze" & Chr(10) & _
		"                                   separated by semicolons. Merging log files" & Chr(10) & _
		"                                   is a time consuming process. Try to limit" & Chr(10) & _
		"                                   to one Perfmon log at a time." & Chr(10) & _
		"   OPTIONS:                       " & chr(10) & _
		"   /INTERVAL:[Seconds]            Optional. Interval in seconds to " & Chr(10) & _
		"                                   analyze."& Chr(10) & _
		"   /THRESHOLDFILE:[XMLFilePath]   Optional. XML document containing PAL" & Chr(10) & _
		"                                   thresholds." & Chr(10) & _
		"                                   If omitted, SystemOverview.xml will" & Chr(10) & _
		"                                   be used." & Chr(10) & _
		"   /OUTPUTDIR                      Optional. The output directory of the HTML report." & Chr(10) & _
		"                                   " & Chr(10) & _
		"   THRESHOLD SPECIFIC ARGUMENTS:   " & Chr(10) & _
		"   For example:		            " & Chr(10) & _
		"   /NUMOFPROCESSORS:[integer]     Optional. The number of processors of the" & Chr(10) & _
		"                                   computer the log was captured." & Chr(10) & _
		"                                   If omitted, you will be prompted." & Chr(10) & _
		"   /TOTALMEMORY:[integer]         Optional. The amount of total physical" & Chr(10) & _
		"                                   memory in gigabytes of the computer " & Chr(10) & _
		"                                   the log was captured." & Chr(10) & _
		"                                   If omitted, you will be prompted." & Chr(10) & _
		"   /3GB:[True|False]              Optional. True or false if the /3GB switch" & Chr(10) & _
		"                                   was used on the computer the log was" & Chr(10) & _
		"                                   captured." & Chr(10) & _
		"                                   If omitted, you will be prompted." & Chr(10) & _
		"   /64BIT:[True|False]            Optional. True or false if the computer" & Chr(10) & _
		"                                   where the log was captured is 64-bit." & Chr(10) & _
		"                                   If omitted, you will be prompted." & Chr(10) & _		
		"" & Chr(10) & _			
        " Description: PAL reads in a performance monitor counter log (any known "  & Chr(10) & _
        "  format) and analyzes it for known thresholds (provided). Charts and alerts"  & Chr(10) & _
        "  are reported in HTML for exceeded thresholds. This is a VBScript and"  & Chr(10) & _
        "  requires Microsoft LogParser (free download) and Microsoft ReLog (shipped"  & Chr(10) & _
        "  with PAL) to be installed."  & Chr(10) & _
        "" & Chr(10) & _
        " Requirements:"  & Chr(10) & _
        "   - Windows XP or Vista"  & Chr(10) & _
        "   - Microsoft ReLog (part of the operating system)"  & Chr(10) & _
        "   - Microsoft LogParser"  & Chr(10) & _
        " "  & Chr(10) & _
        " Written by: Clint Huffman (clinth@microsoft.com) "  & Chr(10) & _
        " Version: " & VERSION  & Chr(10) & _
        ""  & Chr(10) & _
        " Examples: "  & Chr(10) & _
        "   This example will analyze the System_Overview.blg at a 1" & Chr(10) & _
        "    hour interval and will attempt to use SystemOverview.xml "  & Chr(10) & _
        "    as the threshold file:"  & Chr(10) & _
        "    CScript PAL.vbs /LOG:System_Overview.blg"  & Chr(10) & _
        ""  & Chr(10) & _        
        "   This example will analyze the System_Overview.blg at a 60" & Chr(10) & _
        "    second intervals and will attempt to use SystemOverview.xml "  & Chr(10) & _
        "    as the threshold file:"  & Chr(10) & _
        "   CScript PAL.vbs /LOG:System_Overview.blg /INTERVAL:60 /THRESHOLDFILE:MyRules.xml"  & Chr(10) & _
        ""  & Chr(10)        
	Set objArgs = WScript.Arguments

	If objArgs.Count = 0 Then
		OutputToConsoleAndLog Syntax
		OutputToConsoleAndLog ""
		WScript.Quit
	Else
	    Set oNamedArgs = WScript.Arguments.Named
		For i = 0 to objArgs.Count -1
			If InStr(1, objArgs(i), "?") > 0 Then
				OutputToConsoleAndLog Syntax
				OutputToConsoleAndLog ""
				WScript.Quit
			Else
			    g_PerfmonLog = ""
			    g_OriginalPerfmonLogArg = ""
			    g_XMLThresholdFile = ""
			    g_Interval = ""
			    g_IsOutputXML = ""
			    g_IsOutputHTML = ""
			    If oNamedArgs("XMLINPUT") <> "" Then
			        g_IsInputXML = True
			        g_XMLInputFilePath = oNamedArgs("XMLINPUT")
			        ProcessInputXML g_XMLInputFilePath
			    End If
			    If g_PerfmonLog = "" Then
			        g_PerfmonLog = oNamedArgs("LOG")
			    End If
                If g_OriginalPerfmonLogArg = "" Then
                    g_OriginalPerfmonLogArg = g_PerfmonLog
                End If                			    
			    If g_Interval = "" Then
			        g_Interval = oNamedArgs("INTERVAL")
			        If g_Interval = "" Then
			            g_Interval = "AUTO"
			        End If
			    End If
			    If g_XMLThresholdFile = "" Then
			        g_XMLThresholdFile = oNamedArgs("THRESHOLDFILE")
			    End If
			    If g_IsOutputXML = "" Then
			        g_IsOutputXML = oNamedArgs("ISOUTPUTXML")
			        If g_IsOutputXML = "" Then
			            g_IsOutputXML = "False"
			        End If
			    End If
			    If g_IsOutputHTML = "" Then
			        g_IsOutputHTML = oNamedArgs("ISOUTPUTHTML")
			        If g_IsOutputHTML = "" Then
			            g_IsOutputHTML = "True"
			        End If
			    End If
			    If g_PALReportsDirectory = "" Then
			        g_PALReportsDirectory = oNamedArgs("OUTPUTDIR")
			        If g_PALReportsDirectory = "" Then
			            '// Set to default
			            g_PALReportsDirectory = "[My Documents]\PAL Reports"
			        End If
			    End If
			    If g_ReportFile = "" Then
			        g_ReportFile = oNamedArgs("HTMLOUTPUTFILENAME")
			        If g_ReportFile = "" Then
			            g_ReportFile = "[LogFileName]_PAL_ANALYSIS_[DateTimeStamp]_[GUID].htm"
			        End If
			    End If
			    If g_XMLOutputFile = "" Then
			        g_XMLOutputFile = oNamedArgs("XMLOUTPUTFILENAME")
			        If g_XMLOutputFile = "" Then
			            g_XMLOutputFile = "[LogFileName]_PAL_ANALYSIS_[DateTimeStamp]_[GUID].xml"
			        End If
			    End If
			    
			    'If g_dBeginTime = "" Then
			        g_dBeginTime = oNamedArgs("BEGINTIME")	        
			    'End If
			    
			    'If g_dEndTime = "" Then
			        g_dEndTime = oNamedArgs("ENDTIME")
			    'End If			    
		    
'			    NumberOfProcessors = oNamedArgs("NUMOFPROCESSORS")
'			    TotalMemory = oNamedArgs("TOTALMEMORY")
'			    ThreeGBSwitch = oNamedArgs("3GB")
'			    SixtyFourBit = oNamedArgs("64BIT")
'			    SELECT CASE objArgs.Count
'			        CASE 1
'			            g_PerfmonLog = objArgs("LOG")
'			            g_Interval = ONE_HOUR
'			            g_XMLThresholdFile = "SystemOverview.xml"
'			        CASE 2        
'				        g_PerfmonLog = objArgs(0)
'			            g_Interval = objArgs(1)
'    			        g_XMLThresholdFile = "SystemOverview.xml"
'			        CASE 3        
'				        g_PerfmonLog = objArgs(0)
'				        g_Interval = objArgs(1)
'				        g_XMLThresholdFile = objArgs(2)
'				    CASE Else
'				        OutputToConsoleAndLog Syntax
'				        OutputToConsoleAndLog ""
'				        WScript.Quit		        
'			    END SELECT
			End If 
		Next	
	End If
	
	If g_PerfmonLog = "" Then
	    OutputToConsoleAndLog "ERROR: The PerfmonLog argument is required."
	    OutputToConsoleAndLog syntax
	    WScript.Quit
	End If
	
	' Changed to prompt the user if not added as an argument.
'	If g_Interval = "" Then
'	    g_Interval = ONE_HOUR
'	End If
	
	If g_XMLThresholdFile = "" Then
	    g_XMLThresholdFile = "SystemOverview.xml"
	End If
	
	'// XML Output
	If LCase(g_IsOutputXML) = "true" Then
	    g_IsOutputXML = True
	Else
	    g_IsOutputXML = False
	End If
	
	If LCase(g_IsOutputHTML) = "false" Then
	    g_IsOutputHTML = False
	Else
	    g_IsOutputHTML = True
	End If	
	
    If IsNumeric(g_PerfmonLog) = True Then
        OutputToConsoleAndLog "ERROR: The PerfmonLog argument is not a string."
        WScript.Quit
    End If
    If IsNumeric(g_Interval) = False AND UCase(g_Interval) <> "AUTO" AND UCase(g_Interval) <> "ALL" Then
        OutputToConsoleAndLog "ERROR: The interval argument is not numeric."
        WScript.Quit
    End If
    If LCase(Right(g_XMLThresholdFile,4)) <> ".xml" Then
        OutputToConsoleAndLog "ERROR: The ThresholdsFile argument is not an XML document."
        WScript.Quit
    End If
    
    If Instr(1, g_PerfmonLog, ";") > 0 Then
        g_PerfmonLog = Split(g_PerfmonLog, ";")
    End If
    
    Set oFSO = CreateObject("Scripting.FileSystemObject")    
    If IsArray(g_PerfmonLog) = False Then				
        If oFSO.FileExists(g_PerfmonLog) = False Then
            OutputToConsoleAndLog "===============================ERROR========================================"
            OutputToConsoleAndLog "[ProcessArguments]"
            OutputToConsoleAndLog " File(s) " & chr(34) & Join(g_PerfmonLog, ";") & chr(34) & " doesn't exist."
            OutputToConsoleAndLog " Check the file path and try again."       
            OutputToConsoleAndLog "============================================================================"
            WScript.Quit
        End If
    Else
        For Each sPerfmonLog in g_PerfmonLog
            If oFSO.FileExists(sPerfmonLog) = False Then
                OutputToConsoleAndLog "===============================ERROR========================================"
                OutputToConsoleAndLog "[ProcessArguments]"
                OutputToConsoleAndLog " File(s) " & chr(34) & Join(g_PerfmonLog, ";") & chr(34) & " doesn't exist."
                OutputToConsoleAndLog " Check the file path and try again."       
                OutputToConsoleAndLog "============================================================================"
                WScript.Quit
            End If        
        Next
    End If
    
    If oFSO.FileExists(g_XMLThresholdFile) = False Then
        OutputToConsoleAndLog "===============================ERROR========================================"
        OutputToConsoleAndLog "[ProcessArguments]"
        OutputToConsoleAndLog " File " & chr(34) & g_XMLThresholdFile & chr(34) & " doesn't exist."
        OutputToConsoleAndLog " Check the file path and try again."
        OutputToConsoleAndLog "============================================================================"
        WScript.Quit
    End If     
    AskUserForEnvironmentVariables
End Sub

'Function FilterForCounterInstances(aCounters,sCounter)
'    'Returns an array of counter instances
'    ' Filter by same counter object               
'    
'    Dim bCounterObjectsMatch, bCounterNamesMatch, bCounterInstancesMatch
'    Dim aSameCounters(), sInstance, iCounter, a    
'    iCounter = 0
'    For a = 0 to UBound(aCounters)
'        bCounterObjectsMatch = False
'        bCounterNamesMatch = False
'        bCounterInstancesMatch = False
'        bCounterObjectsMatch = CompareCounterPathToExpression(aCounters(a), sCounter, "COUNTER_OBJECT")
'        If bCounterObjectsMatch = True Then
'            bCounterNamesMatch = CompareCounterPathToExpression(aCounters(a), sCounter, "COUNTER_NAME")
'            If bCounterNamesMatch = True Then
'                bCounterInstancesMatch = CompareCounterPathToExpression(aCounters(a), sCounter, "COUNTER_INSTANCE")                    
'            End If
'        End If                                
'        If bCounterObjectsMatch = True AND bCounterNamesMatch = True AND bCounterInstancesMatch = True Then
'            ReDim Preserve aSameCounters(iCounter)
'            aSameCounters(iCounter) = aCounters(a)
'            iCounter = iCounter + 1               
'        End If
'    Next    
'    
''    Dim aSameCounters(), sInstance, iCounter, a    
''    iCounter = 0
''    For a = 0 to UBound(aCounters)
''        ' Counter Object
''        If LCase(GetCounterObject(aCounters(a))) = LCase(GetCounterObject(sCounter)) Then
''            If LCase(GetCounterName(aCounters(a))) = LCase(GetCounterName(sCounter)) Then
''                If GetCounterInstance(sCounter) = "*" OR LCase(GetCounterInstance(aCounters(a))) = LCase(GetCounterInstance(sCounter)) Then                                
''                    ReDim Preserve aSameCounters(iCounter)
''                    aSameCounters(iCounter) = aCounters(a)
''                    iCounter = iCounter + 1
''                End If
''            End If
''        End If
''    Next
''        'aSameCounters = Filter(aCounters,GetCounterObject(sCounter), True, 1)    
''    ' Filter by same counter name
''    aSameCounters = Filter(aSameCounters,GetCounterName(sCounter), True, 1)
''    ' Filter by same instance
''    sInstance = GetCounterInstance(sCounter)
''    If sInstance <> "*" Then
''        iTempCounter = 0
''        For a = 0 to UBound(aSameCounters)
''            ' If the instance is the same then add them to the temp array.
''            If LCase(GetCounterInstance(aSameCounters(a))) = LCase(sInstance) Then                        
''                ReDim aTemp(iTempCounter)
''                aTemp(iTempCounter) = aSameCounters(a)
''                iTempCounter = iTempCounter + 1
''            End If
''        Next    
''        'aSameCounters = Filter(aSameCounters,sInstance, True, 1)
''        aSameCounters = aTemp
''    End If
'    FilterForCounterInstances = aSameCounters
'End Function

Function CreateCounterDataObjectArrayOutOfXMLAnalysis(oXMLAnalysis)
        ' aCounters(0,y) = varName
        ' aCounters(1,y) = CounterName
    Dim oCounterData
    Dim oXMLCounter, y
    Dim aCounterData()
    
    y = 0
    For Each oXMLCounter in oXMLAnalysis.SelectNodes(".//COUNTER")
        Set oCounterData = New CounterDataObject
        oCounterData.VarName = oXMLCounter.GetAttribute("VARNAME")
        oCounterData.Name = oXMLCounter.GetAttribute("NAME")
        ReDim Preserve aCounterData(y)
        Set aCounterData(y) = oCounterData
        y = y + 1
    Next
    CreateCounterDataObjectArrayOutOfXMLAnalysis = aCounterData
End Function

Function InterpretVariable()
    Dim aTemp(2,2)
    aTemp(0,0) = 0
    aTemp(1,0) = 1
    aTemp(2,0) = 2
    aTemp(0,1) = 4
    aTemp(1,1) = 5
    aTemp(2,1) = 6
    aTemp(0,2) = 7
    aTemp(1,2) = 8
    aTemp(2,2) = 9

    Dim aCounters(1,0)
    aCounters(0,0) = "NetworkInterfaceBytesTotalPerSec"
    aCounters(1,0) = aTemp

    Const MIN = 0
    Const AVG = 1
    Const MAX = 2
    Const NAME = 0
    Const VALUEARRAY = 1
    iInterval = 0
    Const COUNTER = 0
    x = 0
    y = 2


    OutputToConsoleAndLog aCounters(NAME,x)
    OutputToConsoleAndLog aCounters(VALUEARRAY,x)(AVG,y)

    OutputToConsoleAndLog "All Done"
End Function

Function GetFirstColumnFromCSV(sCSVFile)
    ' Returns the first column name in a CSV based Perfmon Log.
    Const ForReading = 1
    Const ForWriting = 2
    Const ForAppending = 8
    Dim oFSO, oFile, sLine, iLoc

    Set oFSO = CreateObject("Scripting.FileSystemObject")
    Set oFile = oFSO.OpenTextFile(sCSVFile, ForReading)
    
    sLine = oFile.Readline
    iLoc = Instr(sLine,",")
    GetFirstColumnFromCSV = Mid(sLine, 2, iLoc - 3) 
End Function

''''''''''''''''''''''''''''''''''''''''''
' String functions for counter paths
''''''''''''''''''''''''''''''''''''''''''
Function RemoveCounterComputer(sCounter)
    '\\IDCWEB1\Processor(_Total)\% Processor Time"
    '\\IDCWEB1\Processor\% Processor Time"
    '\Processor(_Total)\% Processor Time"
    '\Processor\% Processor Time"
    'Processor(_Total)\% Processor Time"
    'Processor\% Processor Time"
    Dim sNewCounter, iLocThirdBackSlash
    sNewCounter = sCounter
    ' Removes the counter computer name
    If Left(sNewCounter, 2) <> "\\" Then
        RemoveCounterComputer = sNewCounter
        Exit Function
    End If
    iLocThirdBackSlash = Instr(3,sNewCounter,"\")
    RemoveCounterComputer = Mid(sNewCounter, iLocThirdBackSlash)
End Function

Function RemoveCounterInstance(sCounter)
    '\\IDCWEB1\Processor(_Total)\% Processor Time"
    ' Removes the counter instance name
    Dim sNewCounter, iLocFirstParen, iLocSecondParen, iLen, sLeftPart, sRightPart
    sNewCounter = sCounter
    iLocFirstParen = Instr(sNewCounter,"(")
    If iLocFirstParen = 0 Then
        RemoveCounterInstance = sNewCounter
        Exit Function
    End If
    iLocSecondParen = Instr(sNewCounter,")")
    iLen = iLocSecondParen - iLocFirstParen - 1
    sLeftPart = Left(sNewCounter,iLocFirstParen - 1)
    sRightPart = Mid(sNewCounter,iLocSecondParen + 1)
    RemoveCounterInstance = sLeftPart & sRightPart
End Function

Function GetCounterComputer(sCounter)
    '\\IDCWEB1\Processor(_Total)\% Processor Time"
    ' Returns the counter computer name
    Dim sCounterComputer, iLocThirdBackSlash
    sCounterComputer = sCounter
    If Left(sCounterComputer,2) <> "\\" Then
        GetCounterComputer = ""
        Exit Function
    End If
    iLocThirdBackSlash = Instr(3,sCounterComputer,"\")
    GetCounterComputer = Trim(Mid(sCounterComputer, 3, iLocThirdBackSlash - 3))
End Function

Function GetCounterObject(ByVal sCounter)
    '"\\demoserver\SQLServer:Latches\Latch Waits/sec (ms)"
    'WScript.Echo GetCounterObject("\(MSSQL|SQLServer).*:Locks(_Total)\Lock Requests/sec") & " = (MSSQL|SQLServer).*:Locks"
    'WScript.Echo GetCounterObject("\\IDCWEB1\Processor(_Total)\% Processor Time") & " = Processor"
    'WScript.Echo GetCounterObject("\Processor(_Total)\% Processor Time") & " = Processor"
    'WScript.Echo GetCounterObject("\Category\Counter") & " = Category"
    'WScript.Echo GetCounterObject("\Category\Counter(x)") & " = Category"
    'WScript.Echo GetCounterObject("\\BLACKVISE\Paging File(\??\C:\pagefile.sys)\% Usage Peak") & " = Paging File"
    'WScript.Echo GetCounterObject("\Category(Instance(x))\Counter (x)") & " = Category"
    'WScript.Echo GetCounterObject("\(MSSQL|SQLServer).*:Memory Manager\Total Server Memory (KB)") & " = (MSSQL|SQLServer).*:Memory Manager"
    Dim sCounterObject, iLocParen,iLocThirdBackSlash,iLocBackSlash, sOriginalCounterPath
    sOriginalCounterPath = sCounter
    sCounterObject = sCounter
    ' Returns the counter object           
    If Left(sCounterObject, 2) = "\\" Then
        '\\IDCWEB1\Processor(_Total)\% Processor Time
        '\\IDCWEB1\Processor\% Processor Time
        iLocThirdBackSlash = Instr(3, sCounterObject, "\")
        sCounterObject = Mid(sCounterObject, iLocThirdBackSlash + 1)
        'Processor(_Total)\% Processor Time
        'Processor\% Processor Time
    ElseIf Left(sCounterObject,1) = "\" Then
        '\Processor\% Processor Time
        '\(MSSQL|SQLServer).*:Locks(_Total)\Lock Requests/sec
        sCounterObject = Mid(sCounterObject, 2)
        'Processor\% Processor Time
    Else        
        GetCounterObject = ""
        Exit Function
    End If
    'SQLServer:Latches\Latch Waits/sec (ms)
    iLocBackSlash = Instr(sCounterObject,"\")
    sCounterObject = StripCounterNameFromCounterString(sCounterObject)
    If Right(sCounterObject, 1) = ")" Then
        Dim aChar, iRightParenCount, bInstanceFound, i, iLocLeftParen
        aChar = ConvertStringToArray(sCounterObject)
        iRightParenCount = 0
        For i = UBound(aChar) to 0 Step -1
            If aChar(i) = ")" Then
                iRightParenCount = iRightParenCount + 1
            End If
            If aChar(i) = "(" Then
                iLocLeftParen = i+1
                If iRightParenCount = 1 Then                
                    Exit For
                Else
                    iRightParenCount = iRightParenCount - 1
                End If            
            End If
        Next
        iLocLeftParen = iLocLeftParen - 1
        GetCounterObject = Left(sCounterObject, iLocLeftParen)
    Else
        ' Category\Counter
        GetCounterObject = sCounterObject
    End If
End Function

Function GetCounterName(sCounter)
    '\\IDCWEB1\Processor(_Total)\% Processor Time"
    '\Processor(_Total)\% Processor Time"
    '\\BLACKVISE\Paging File(\??\C:\pagefile.sys)\% Usage Peak
    '\Category(Instance(x))\Counter (x)
    ' Returns the counter name
    Dim sCounterName, aBackSlashes
    sCounterName = sCounter
    aBackSlashes = Split(sCounterName,"\")
    GetCounterName = aBackSlashes(UBound(aBackSlashes))          
End Function

Function StripCounterNameFromCounterString(ByVal sCounter)
    Dim sCounterName, iLenCounterName
    If Instr(sCounter, "\") = 0 Then
        StripCounterNameFromCounterString = sCounter
        Exit Function
    End If    
    sCounterName = sCounter
    iLenCounterName = Len(GetCounterName(sCounterName)) + 1
    If iLenCounterName > 0 Then
        StripCounterNameFromCounterString = Mid(sCounterName, 1, Len(sCounterName)-iLenCounterName)
    End If    
End Function

Function StripComputerNameFromCounterString(ByVal sCounter)
    Dim sCounterName, iLocThirdBackSlash
    sCounterName = sCounter
    If Left(sCounterName, 2) = "\\" Then
        iLocThirdBackSlash = Instr(3, sCounterName, "\")
        sCounterName = Mid(sCounterName, iLocThirdBackSlash)
    End If    
    StripComputerNameFromCounterString = sCounterName
End Function

Function GetCounterInstance(ByVal sCounter)
    '\\BLACKVISE\Paging File(\??\C:\pagefile.sys)\% Usage Peak
    '\Category(Instance(x))\Counter (x)
    '\SQLServer:Latches\Latch Waits/sec (ms)
    '\(MSSQL|SQLServer).*:Locks(_Total)\Lock Requests/sec
    '\(MSSQL|SQLServer).*:Memory Manager\Total Server Memory (KB)
    Dim iLocLeftParen, iRightParenCount, sCounterName, i, aChar, sInstanceLength, bInstanceFound
    sCounterName = sCounter
    sCounterName = StripComputerNameFromCounterString(sCounterName)
    sCounterName = StripCounterNameFromCounterString(sCounterName)
    If Instr(sCounter, ")\") = 0 Then
        GetCounterInstance = ""
        Exit Function
    End If
    aChar = ConvertStringToArray(sCounterName)
    iRightParenCount = 0
    bInstanceFound = False
    For i = UBound(aChar) to 0 Step -1
        If aChar(i) = ")" Then
            iRightParenCount = iRightParenCount + 1
            bInstanceFound = True
        End If
        If aChar(i) = "(" Then
            iLocLeftParen = i+1
            If iRightParenCount = 1 Then                
                Exit For
            Else
                iRightParenCount = iRightParenCount - 1
            End If            
        End If
    Next
    If bInstanceFound = False Then
        GetCounterInstance = ""
        Exit Function
    Else
        sInstanceLength = Len(sCounterName) - iLocLeftParen - 1
        GetCounterInstance = Mid(sCounterName, iLocLeftParen+1, sInstanceLength)    
    End If
End Function

'Function GetCounterInstance(ByVal sCounter)
'    '\\BLACKVISE\Paging File(\??\C:\pagefile.sys)\% Usage Peak
'    '\Category(Instance(x))\Counter (x)
'    '\SQLServer:Latches\Latch Waits/sec (ms)
'    '\(MSSQL|SQLServer).*:Locks(_Total)\Lock Requests/sec
'    '\(MSSQL|SQLServer).*:Memory Manager\Total Server Memory (KB)
'    ' // Written by Geoffrey DeFilippi (gedefili@microsoft.com)
'    dim oRgx, sInstance
'    set oRgx = new RegExp
'    oRgx.Pattern = "^(\\\(.*\((.*)\)\\.*)|(.*\((.*\(.*\))\).*)|(\\.*\((.*)\)\\.*)$"
'    sInstance = oRgx.Replace(sCounter, "$2$4$6")
'    if ( Len(sInstance) = Len(sCounter)) Then
'        GetCounterInstance = ""
'    Else
'        GetCounterInstance = sInstance
'    End If
'End Function

Sub QueryCounterInstanceData(oInstance, sDataType)
    Dim oLogQuery, oCSVFormat,oRecordSet, oRecord
    Dim tTime, iAvg, iMin, iMax
    Dim aTime(), aAvg(), aMin(), aMax(), i
    Dim dQ
    
    Set oLogQuery = CreateObject("MSUtil.LogQuery")
    Set oCSVFormat = CreateObject("MSUtil.LogQuery.CSVInputFormat")
    oCSVFormat.iTsFormat = "MM/dd/yyyy hh:mm:ss.lll"
    
    dQ = chr(34)
    oInstance.Query = FixLogParserEscapeSequences(oInstance.Query)
    OutputToConsoleAndLog oInstance.Query
    ON ERROR RESUME NEXT
    Set oRecordSet = oLogQuery.Execute(oInstance.Query, oCSVFormat)
    If Err.number <> 0 Then
        If Err.Description <> "Error parsing query: SELECT clause: Syntax Error: unknown field" Then
            OutputToConsoleAndLog "[QueryCounterInstanceData] ERROR Number: " & Err.number
            OutputToConsoleAndLog "[QueryCounterInstanceData] ERROR Description: " & Err.Description                
        End If                
        Err.Clear
        Exit Sub
    End If
    ON ERROR GOTO 0
    i = 0
    Do Until oRecordSet.atEnd
        Set oRecord = oRecordSet.getRecord        
        'OutputToConsoleAndLog "[QueryCounterInstanceData] Raw Data: " & oRecord.GetValue("avg")
        ReDim Preserve aTime(i)
        ReDim Preserve aMin(i)
        ReDim Preserve aAvg(i)
        ReDim Preserve aMax(i)
        aTime(i) = CDate(oRecord.GetValue(g_IntervalDescription))
        aMin(i) = oRecord.GetValue("min")
        aAvg(i) = oRecord.GetValue("avg")
        aMax(i) = oRecord.GetValue("max")
        i = i + 1        
        oRecordSet.MoveNext
    Loop    
    oInstance.Time = aTime
    oInstance.Min = aMin
    oInstance.Avg = aAvg
    oInstance.Max = aMax
End Sub

Function ConvertToDataType(iVal, sDataType)
    If IsNumeric(iVal) = False Then
        'ConvertToDataType = iVal
        ConvertToDataType = "-"
        Exit Function
    End If
    SELECT CASE LCase(sDataType)
        CASE "absolute"
            ConvertToDataType = Abs(iVal)
        CASE "byte"
            ConvertToDataType = CByte(iVal)
        CASE "double"
            ConvertToDataType = CDbl(iVal)
        CASE "integer"
            ON ERROR RESUME NEXT
            ConvertToDataType = CInt(iVal)
            If Err.number <> 0 Then
                ConvertToDataType = Round(iVal)
            End If
            ON ERROR GOTO 0
        CASE "long"
            ConvertToDataType = CLng(iVal)
        CASE "single"
            ConvertToDataType = CSng(iVal)
        CASE "round1"
            ConvertToDataType = Round(iVal,1)
        CASE "round2"
            ConvertToDataType = Round(iVal,2)
        CASE "round3"
            ConvertToDataType = Round(iVal,3)
        CASE "round4"
            ConvertToDataType = Round(iVal,4)
        CASE "round5"
            ConvertToDataType = Round(iVal,5)
        CASE "round6"
            ConvertToDataType = Round(iVal,6)                                                                        
        CASE Else
            ConvertToDataType = CDbl(iVal)
    END SELECT
End Function


'''''''''''''''''''''''''''''''''
'   Class definintions SCHEMA
'''''''''''''''''''''''''''''''''
Class AnalysisDataObject
    Public Name
    Public Enabled
    Public AnalyzeCounter
    Public Category
    Public Description
    Public Counters
    Public Thresholds
    Public Charts
    Public CounterCount
    Public ThresholdCount
    Public ChartCount
    Public Alerts
    Public AlertCount
    Public AllCountersFound
    Public AnalyzedCounterStats
    Public MatchedCounters
    Public IsCounterObjectRegularExpression
    Public IsCounterNameRegularExpression
    Public IsCounterInstanceRegularExpression
    Public RegularExpressionCounterPath
    Public CounterPath
    Public CounterComputer
    Public CounterObject
    Public CounterName
    Public CounterInstance
End Class

Class CounterDataObject
    Public Name         ' Generic counter name
    Public CounterPath
    Public CounterComputer
    Public CounterObject
    Public CounterName
    Public CounterInstance
    Public MinVarName
    Public AvgVarName
    Public MaxVarName
    Public TrendVarname
    Public Instances    ' array of CounterInstanceValuesObjects
    Public DataType
    Public Exclusions
    Public MatchedCounters ' Full counter path of matched counters in perfmon log
    Public IsCounterObjectRegularExpression
    Public IsCounterNameRegularExpression
    Public IsCounterInstanceRegularExpression
    Public RegularExpressionCounterPath
End Class

Class ThresholdDataObject
    Public Name         ' Counter name including specific instance
    Public Condition    ' The text shown as the condition
    Public Color        ' HTML Color to use in report
    Public Priority        ' The higher the level the more important the threshold
    Public Code         ' The code executed to determine if the threshold is broken.
    Public Description    
End Class

Class ChartDataObject
    Public ChartType
    Public Categories
    Public MaxCategoryLabels
    Public Legend
    Public Values
    Public GroupSize
    Public OTSFormat
    Public ChartTitle
    Public DataSource
    Public DataType
    Public ImageFilePaths
    Public Exclusions
    Public OrderBy
    Public MatchedCounters
    Public IsCounterObjectRegularExpression
    Public IsCounterNameRegularExpression
    Public IsCounterInstanceRegularExpression
    Public RegularExpressionCounterPath
    Public CounterPath
    Public CounterComputer
    Public CounterObject
    Public CounterName
    Public CounterInstance    
End Class

Class AlertDataObject
    Public Time
    Public ConditionColor
    Public Condition
    Public ConditionName
    Public ConditionPriority
    Public Counter
    Public MinColor
    Public Min
    Public MinPriority
    Public MinCondition
    Public AvgColor
    Public Avg
    Public AvgPriority
    Public AvgCondition
    Public MaxColor
    Public Max
    Public MaxPriority
    Public MaxCondition
    Public TrendColor
    Public Trend
    Public TrendPriority
    Public TrendCondition
End Class

Class CounterInstanceDataObject
    Public Name     ' Counter name including specific instance
    Public Query    ' LogParser Query
    Public Time
    Public Min      ' array of min values
    Public MinEvaluated
    Public Avg      ' array of avg values
    Public AvgEvaluated
    Public Max      ' array of max values
    Public MaxEvaluated
    Public Trend
    Public TrendEvaluated
    Public Stats
    Public Excluded
    Public CounterPath
    Public CounterComputer
    Public CounterObject
    Public CounterName
    Public CounterInstance
End Class

Class StatsDataObject
    Public Min
    Public Avg
    Public Max
    Public Trend
    Public StandardDeviation
    Public NinetyithPercentile
    Public EightyithPercentile
    Public SeventyithPercentile
End Class

Class QuestionObject
    Public QuestionVarName
    Public DataType
    Public DefaultValue
    Public Question
    Public Answer
End Class

Class MatchedCounterObject
    Public FullPath
    Public CounterServerName
    Public CounterObject
    Public CounterName
    Public CounterInstance
End Class

Function GenerateTrend(oInstance)
    Dim a, b, c, t, iLoopCount
    Dim aTrend(), aValuesToProcessForTrendAnalysis()
    
    t = 0
    ReDim Preserve aTrend(t)
    aTrend(t) = 0
    t = t + 1
    iLoopCount = 0
    On Error Resume Next
    If IsArray(oInstance.Avg) = False Then
        GenerateTrend = "-"
        On Error Goto 0
        Exit Function
    End if
    For a = 1 To UBound(oInstance.Avg)
        For b = 0 to a
            If IsNull(oInstance.Avg(b)) = False AND IsNumeric(oInstance.Avg(b)) = True Then
                ReDim Preserve aValuesToProcessForTrendAnalysis(b)
                aValuesToProcessForTrendAnalysis(b) = oInstance.Avg(b)
                iLoopCount = iLoopCount + 1
            End If
        Next
        If iLoopCount > 0 Then
            ReDim Preserve aTrend(t)
            aTrend(t) = CalculateTrend(aValuesToProcessForTrendAnalysis)
            t = t + 1
        Else
            ReDim Preserve aTrend(t)
            aTrend(t) = "-"
            t = t + 1            
        End If
    Next
    GenerateTrend = aTrend
    On Error Goto 0
End Function

Function CalculateTrend(aValues)
    Dim aDiff()
    Dim a, d, iDiff, iLoopCount, iSum

    If TestForInitializedArray(aValues) = False Then
        CalculateTrend = "-"
        Exit Function
    End If    
    d = 0
    iLoopCount = 0
    For a = 1 to UBound(aValues)
        If IsNull(aValues(a)) = False AND IsNumeric(aValues(a)) = True Then
            iDiff = aValues(a) - aValues(a-1)
            ReDim Preserve aDiff(d)
            aDiff(d) = iDiff
            d = d + 1
            iLoopCount = iLoopCount + 1
        End If
    Next
    
    If iLoopCount = 0 Then
        CalculateTrend = "-"
        Exit Function
    End If
    
    iLoopCount = 0
    For a = 0 to UBound(aDiff)
        iSum = iSum + aDiff(a)
        iLoopCount = iLoopCount + 1
    Next    
    CalculateTrend = CalculateHourlyTrend(iSum / iLoopCount)
End Function

Function CalculateHourlyTrend(iTrend)
    Dim IntervalAdjustment
    
    If g_Interval < 3600 Then
        IntervalAdjustment = 3600 / g_Interval 
        CalculateHourlyTrend = iTrend * IntervalAdjustment
    End If

    If g_Interval > 3600 Then
        IntervalAdjustment = g_Interval / 3600
        CalculateHourlyTrend = iTrend / IntervalAdjustment
    End If

    If g_Interval = 3600 Then
        CalculateHourlyTrend = iTrend
    End If    
End Function


Function CalculateTrend1(aValues)
    Dim aTrend()
    Dim iCount, iHalfCount, iSum, iLoopCount, i, iFirstHalfAvg, iSecondHalfAvg, iDiff 
    ' Get the total number of items in the array
    iCount = UBound(aValues) + 1
    iHalfCount = CInt(iCount / 2)
    
    SELECT CASE iCount
        CASE 0,1
            CalculateTrend = 0
            Exit Function
        CASE 2
            CalculateTrend = aValues(1) - aValues(0)
            Exit Function
    END SELECT
    ' The array has at least 3 values
    
    ' Avg the first half of the array    
    iSum = 0
    iLoopCount = 0
    For i = 0 to iHalfCount - 1
        iSum = iSum + aValues(i)
        iLoopCount = iLoopCount + 1
    Next
    iFirstHalfAvg = iSum / iLoopCount

    ' Avg the second half of the array
    iSum = 0
    iLoopCount = 0
    For i = iHalfCount to UBound(aValues)
        iSum = iSum + aValues(i)
        iLoopCount = iLoopCount + 1
    Next
    iSecondHalfAvg = iSum / iLoopCount
    
    ' Subtract the first half from the second half
    iDiff = iSecondHalfAvg - iFirstHalfAvg
    
    ' Return the result of the difference
    CalculateTrend = iDiff        
End Function

Sub Analyze(sPerfmonLog, oAnalysis)
    'Returns an XML object containing alerts
    Dim oXMLAlerts
    Dim aLPQueries(), iLPQueriesCount, c, i, aRealCounterInstances, sCounter, sQuery
    Dim oCounterData, oCounterInstanceValues
    Dim aCounterInstanceValues()
    Dim oCounter, oInstance
    Dim oChart
    
    ' Populate main counter object structure with real counter names and their instances
    '  and generate the LogParser queries for each instance.
    iLPQueriesCount = 0
    For c = 0 to UBound(oAnalysis.Counters)
        'aRealCounterInstances = FilterForCounterInstances(g_aRealCounterList,oAnalysis.Counters(c).Name)
        aRealCounterInstances = oAnalysis.Counters(c).MatchedCounters
            'Test the array
            ON ERROR RESUME NEXT
            i = UBound(aRealCounterInstances)
            If Err.number <> 0 Then
                oAnalysis.AllCountersFound = False
                OutputToConsoleAndLog "================ERROR================"
                OutputToConsoleAndLog "[Analyze] "
                OutputToConsoleAndLog "The counters needed for analysis " & chr(34) & oAnalysis.Name & chr(34) & " are not there."
                OutputToConsoleAndLog "Error Number: " & Err.number
                OutputToConsoleAndLog "Error Description: " & Err.Description
                OutputToConsoleAndLog "====================================="
                Exit Sub
                Err.Clear
            End If
                
            ON ERROR GOTO 0
        For i = 0 To UBound(aRealCounterInstances)
            Set oCounterInstanceValues = New CounterInstanceDataObject
            sCounter = aRealCounterInstances(i).FullPath
            oCounterInstanceValues.Name = sCounter
            oCounterInstanceValues.CounterPath = sCounter
            oCounterInstanceValues.CounterComputer = GetCounterComputer(sCounter)
            oCounterInstanceValues.CounterObject = GetCounterObject(sCounter)
            oCounterInstanceValues.CounterName = GetCounterName(sCounter)
            oCounterInstanceValues.CounterInstance = GetCounterInstance(sCounter)            
            oCounterInstanceValues.Query = FixLogParserEscapeSequences("SELECT QUANTIZE([" & GetFirstColumnFromCSV(sPerfmonLog) & "], " & g_Interval & ") AS " & g_IntervalDescription & ", MIN(TO_REAL([" & sCounter &"])) AS min, AVG(TO_REAL([" & sCounter &"])) AS avg, MAX(TO_REAL([" & sCounter &"])) AS max FROM " & sPerfmonLog & " GROUP BY " & g_IntervalDescription)
            ReDim Preserve aCounterInstanceValues(i)
            Set aCounterInstanceValues(i) = oCounterInstanceValues
        Next
        oAnalysis.Counters(c).Instances = aCounterInstanceValues
    Next
    
    ' Populate chart data
    If oAnalysis.Charts(0).ChartTitle <> "NO CHARTS" Then
        For Each oChart in oAnalysis.Charts
            iChartCounter = 0
            GenerateChart sPerfmonLog, oChart, g_aRealCounterList 
        Next    
    End If
        
    ' Populate counter instance object structure with counter value data.
    For Each oCounter in oAnalysis.Counters
        For Each oInstance in oCounter.Instances
            Call QueryCounterInstanceData(oInstance, oCounter.DataType)
        Next
    Next
    
    ' Analyze counter value data against thresholds.
    oAnalysis.Alerts = AnalyzeCounterValuesAgainstThresholds(oAnalysis)
End Sub

Function AnalyzeCounterValuesAgainstThresholds(oAnalysis)
    ' Enumerate each interval
    Const COLOR_GREEN = "#00FF00"
    Const COLOR_YELLOW = "#FFFF00"
    Const COLOR_RED = "#FF0000"
    Dim oCounter, oInstance, i, dctVariables, oThreshold, oStats
    Dim sCode, sOriginalCode, bThreshold, bConditionHit
    Dim aAlerts(), a, b, r, oAlert, iThresholdPriority
    Dim aSI(), iSameInstancesCount, s
    Dim oExclude, bExclude
    Dim sAnalyzeCounterInstance, sCounterInstance
    Dim sKey, sTest, bIsNullData
    Dim u
    r = 0   
    
    bConditionHit = False
    If IsThereIllegalCounterInstanceAssignment(oAnalysis) = True Then
        OutputToConsoleAndLog "Illegal assignment of instances for " & oAnalysis.Name
        Exit Function
    End If
    
    ' Check to see if we have detected all of the counters are in the perfmon log or not.
    ' If all of the counters needed for the analysis to work are not found, then do not run this function.
    If oAnalysis.AllCountersFound = False Then
        OutputToConsoleAndLog "[AnalyzeCounterValuesAgainstThresholds] All of the counters needed to perform this analysis are not found."
        OutputToConsoleAndLog " Analysis Name: " & oAnalysis.Name
        For Each oCounter in oAnalysis.Counters
            OutputToConsoleAndLog " Counter: " & oCounter.Name
        Next
        If oAnalysis.Charts(0).ChartTitle <> "NO CHARTS" Then
            For Each oChart in oAnalysis.Charts
                OutputToConsoleAndLog " Counter: " & oChart.DataSource
            Next        
        End If
        Exit Function
    End If

    ' Calculate the trends for each of the counters and their instances.    
    For Each oCounter in oAnalysis.Counters
        'Generate the trend values
        For Each oInstance in oCounter.Instances
            oInstance.Trend = GenerateTrend(oInstance)
        Next        
    Next

    ' Look for Analysis Counter
    For a = 0 to UBound(oAnalysis.Counters)
        If oAnalysis.Counters(a).Name = oAnalysis.AnalyzeCounter Then
            Set oCounter = oAnalysis.Counters(a)
            Exit For
        End If
    Next    

    ON ERROR RESUME NEXT
    ' Testing oCounter as being valid
    a = UBound(oCounter.Instances)
    If Err.number <> 0 Then
        OutputToConsoleAndLog "=================================================="
        OutputToConsoleAndLog "[AnalyzeCounterValuesAgainstThresholds]"
        OutputToConsoleAndLog " Analysis Name: " & oAnalysis.Name
        OutputToConsoleAndLog " Analysis Counter: " & chr(34) & oAnalysis.AnalyzeCounter & chr(34)
        OutputToConsoleAndLog " DataSource Counters:"
        For a = 0 to UBound(oAnalysis.Counters)
            OutputToConsoleAndLog " " & chr(34) & oAnalysis.Counters(a).Name & chr(34)
        Next        
        OutputToConsoleAndLog " ERROR: None of the data source counters match the primary analysis counter."
        OutputToConsoleAndLog "  Ensure the counter paths are exact matches."
        OutputToConsoleAndLog "=================================================="
        AnalyzeCounterValuesAgainstThresholds = ""
        Exit Function
    End If
    ON ERROR GOTO 0
    
    For Each oInstance in oCounter.Instances
        ' Calculate statistics
        Set oStats = New StatsDataObject            
        oStats.Min = ConvertToDataType(CalculateMinimum(oInstance.Min), oCounter.DataType)
        oStats.Avg = ConvertToDataType(CalculateAverage(oInstance.Avg), oCounter.DataType)                
        oStats.Max = ConvertToDataType(CalculateMaximum(oInstance.Max), oCounter.DataType)
        If TestForInitializedArray(oInstance.Trend) = True Then
            u = UBound(oInstance.Trend)
            oStats.Trend = ConvertToDataType(oInstance.Trend(u), oCounter.DataType)
        Else
            oStats.Trend = "-"          
        End If
        oStats.StandardDeviation = ConvertToDataType(CalculateStdDeviation(oInstance.Avg), oCounter.DataType)
        oStats.NinetyithPercentile = ConvertToDataType(CalculatePercentile(oInstance.Avg, 90), oCounter.DataType)
        oStats.EightyithPercentile = ConvertToDataType(CalculatePercentile(oInstance.Avg, 80), oCounter.DataType)
        oStats.SeventyithPercentile = ConvertToDataType(CalculatePercentile(oInstance.Avg, 70), oCounter.DataType)
        Set oInstance.Stats = oStats
                
        ' Check for Instance exclusions.
        bExclude = False
        For Each oExclude in oCounter.Exclusions
            If LCase(GetCounterInstance(oInstance.Name)) = LCase(oExclude) Then
                'bExclude = True
                oInstance.Excluded = True
                Exit For
            End If
        Next
        If oInstance.Excluded = False Then
            ' Create the custom variables.
            Set dctVariables = CreateObject("Scripting.Dictionary")
            dctVariables.Add oCounter.MinVarName, ""
            dctVariables.Add oCounter.AvgVarName, ""
            dctVariables.Add oCounter.MaxVarName, ""
            dctVariables.Add oCounter.TrendVarname, ""
            dctVariables.Add "CounterPath", ""
            dctVariables.Add "CounterComputer", ""
            dctVariables.Add "CounterObject", ""
            dctVariables.Add "CounterName", ""
            dctVariables.Add "CounterInstance", ""            
            If oAnalysis.CounterCount > 1 Then
                ' Create an array of coordinantes to counter instances to use against this instance.
                iSameInstancesCount = 0
                For a = 0 to UBound(oAnalysis.Counters)
                    ' If the counter name is the same as the counter in the collection, then skip.
                    ' We only want to add counters to the array that are in addition to the analyze counter.
                    If LCase(GetCounterName(oCounter.Name)) <> LCase(GetCounterName(oAnalysis.Counters(a).Name)) Then                        
                        For b = 0 to UBound(oAnalysis.Counters(a).Instances)                        
                            'If oAnalysis.Counters(a).Instances(b).Name <> oInstance.Name AND ((LCase(GetCounterInstance(oAnalysis.Counters(a).Instances(b).Name)) = LCase(GetCounterInstance(oInstance.Name))) OR GetCounterInstance(oInstance.Name) = "") Then
                            sAnalyzeCounterInstance = LCase(GetCounterInstance(oInstance.Name))
                            sCounterInstance = LCase(GetCounterInstance(oAnalysis.Counters(a).Instances(b).Name))
                            ' Match up the counter instances.
                            ' If one of the instances is blank, then use it.
                            ' If one of the instances is blank, then add all of the other counter instances. 
                            ' Should only be one instance for the other counters.                            
                            If sAnalyzeCounterInstance = sCounterInstance OR sCounterInstance = "" OR sAnalyzeCounterInstance = "" OR UBound(oAnalysis.Counters(a).Instances) = 0 Then
                                ReDim Preserve aSI(1,iSameInstancesCount)
                                aSI(0,iSameInstancesCount) = a
                                aSI(1,iSameInstancesCount) = b
                                iSameInstancesCount = iSameInstancesCount + 1
                                Exit For
                            End If
                        Next
                    End If
                Next
                For s = 0 to UBound(aSI,2)
                    dctVariables.Add oAnalysis.Counters(aSI(0,s)).MinVarName, ""
                    dctVariables.Add oAnalysis.Counters(aSI(0,s)).AvgVarName, ""
                    dctVariables.Add oAnalysis.Counters(aSI(0,s)).MaxVarName, ""
                    dctVariables.Add oAnalysis.Counters(aSI(0,s)).TrendVarname, ""
                Next   
            End If
            
            ON ERROR RESUME NEXT
            For i = 0 to UBound(oInstance.Time) ' data in arrays
                If Err.number <> 0 Then
                    Exit For
                End If
                ON ERROR GOTO 0
                dctVariables(oCounter.MinVarName) = ConvertToDataType(oInstance.Min(i), oCounter.DataType)
                dctVariables(oCounter.AvgVarName) = ConvertToDataType(oInstance.Avg(i), oCounter.DataType)
                dctVariables(oCounter.MaxVarName) = ConvertToDataType(oInstance.Max(i), oCounter.DataType)
                dctVariables(oCounter.TrendVarname) = oInstance.Trend(i)
                dctVariables("CounterPath") = oInstance.CounterPath
                dctVariables("CounterComputer") = oInstance.CounterComputer
                dctVariables("CounterObject") = oInstance.CounterObject
                dctVariables("CounterName") = oInstance.CounterName
                dctVariables("CounterInstance") = oInstance.CounterInstance
                
                If oAnalysis.CounterCount > 1 Then
                    For s = 0 to UBound(aSI,2)
                        dctVariables(oAnalysis.Counters(aSI(0,s)).MinVarName) = ConvertToDataType(oAnalysis.Counters(aSI(0,s)).Instances(aSI(1,s)).Min(i), oCounter.DataType)
                        dctVariables(oAnalysis.Counters(aSI(0,s)).AvgVarName) = ConvertToDataType(oAnalysis.Counters(aSI(0,s)).Instances(aSI(1,s)).Avg(i), oCounter.DataType)
                        dctVariables(oAnalysis.Counters(aSI(0,s)).MaxVarName) = ConvertToDataType(oAnalysis.Counters(aSI(0,s)).Instances(aSI(1,s)).Max(i), oCounter.DataType)
                        dctVariables(oAnalysis.Counters(aSI(0,s)).TrendVarName) = ConvertToDataType(oAnalysis.Counters(aSI(0,s)).Instances(aSI(1,s)).Trend(i), "integer")
                        dctVariables("CounterPath") = oInstance.CounterPath
                        dctVariables("CounterComputer") = oInstance.CounterComputer
                        dctVariables("CounterObject") = oInstance.CounterObject
                        dctVariables("CounterName") = oInstance.CounterName
                        dctVariables("CounterInstance") = oInstance.CounterInstance                        
                    Next
                End If            

                If oAnalysis.ThresholdCount > 0 Then
                    ' Go through the thresholds.
                    Set oAlert = New AlertDataObject
                    oAlert.Counter = oInstance.Name
                    oAlert.Time = oInstance.Time(i)
                    oAlert.Condition = "-"
                    oAlert.ConditionName = ""
                    oAlert.ConditionPriority = 0
                    oAlert.ConditionColor = COLOR_GREEN
                    oAlert.MinPriority = 0
                    oAlert.AvgPriority = 0
                    oAlert.MaxPriority = 0
                    oAlert.Min = ConvertToDataType(oInstance.Min(i), oCounter.DataType)
                    oAlert.Avg = ConvertToDataType(oInstance.Avg(i), oCounter.DataType)
                    oAlert.Max = ConvertToDataType(oInstance.Max(i), oCounter.DataType)
                    oAlert.Trend = ConvertToDataType(oInstance.Trend(i), oCounter.DataType)
                    'oAlert.Trend = "-"
                    oAlert.MinColor = ""
                    oAlert.AvgColor = ""
                    oAlert.MaxColor = ""
                    oAlert.TrendColor = ""
                    oAlert.MinCondition = "OK"
                    oAlert.AvgCondition = "OK"
                    oAlert.MaxCondition = "OK"
                    oAlert.TrendCondition = "OK"                                       
                End If
                
                For Each oThreshold in oAnalysis.Thresholds
                    ' Detect which values are being evaluated.
                    If oAnalysis.ThresholdCount = 0 Then
                        Exit For
                    End If

                    sCode = oThreshold.Code
                    sOriginalCode = oThreshold.Code            
                    If Instr(1, sCode, oCounter.MinVarName, 1) > 0 Then
                        oInstance.MinEvaluated = True
                        oAlert.MinColor = COLOR_GREEN
                        oAlert.MinCondition = "OK"
                    Else
                        oInstance.MinEvaluated = False
                        oAlert.MinColor = ""
                    End If

                    If Instr(1, sCode, oCounter.AvgVarName, 1) > 0 Then
                        oInstance.AvgEvaluated = True
                        oAlert.AvgColor = COLOR_GREEN
                        oAlert.AvgCondition = "OK"
                    Else
                        oInstance.AvgEvaluated = False
                        oAlert.AvgColor = ""
                    End If

                    If Instr(1, sCode, oCounter.MaxVarName, 1) > 0 Then
                        oInstance.MaxEvaluated = True
                        oAlert.MaxColor = COLOR_GREEN
                        oAlert.MaxCondition = "OK"
                    Else
                        oInstance.MaxEvaluated = False
                        oAlert.MaxColor = ""
                    End If
                    
                    If Instr(1, sCode, oCounter.TrendVarname, 1) > 0 Then
                        oInstance.TrendEvaluated = True
                        oAlert.TrendColor = COLOR_GREEN
                         oAlert.TrendCondition = "OK"
                    Else
                        oInstance.TrendEvaluated = False
                        oAlert.TrendColor = ""
                    End If    
                Next                                                                        
                
                For Each oThreshold in oAnalysis.Thresholds
                    ' Replace the code
                    If oAnalysis.ThresholdCount = 0 Then
                        Exit For
                    End If
                    sCode = oThreshold.Code
                    sOriginalCode = oThreshold.Code

                    '// Replace named question variables in the code with the dictionary object version.
                    For Each sKey in g_dctQuestions.Keys
                        sCode = Replace(sCode, sKey, g_dctQuestions(sKey).Answer)
                    Next                    
                    
                    'OutputToConsoleAndLog "Before code: " & vbNewLine & sCode
                    sCode = Replace(sCode, oCounter.MinVarName, "dctVariables(oCounter.MinVarName)")
                    sCode = Replace(sCode, oCounter.AvgVarName, "dctVariables(oCounter.AvgVarName)")
                    sCode = Replace(sCode, oCounter.MaxVarName, "dctVariables(oCounter.MaxVarName)")
                    sCode = Replace(sCode, oCounter.TrendVarname, "dctVariables(oCounter.TrendVarname)")
                    sCode = Replace(sCode, "CounterPath", "dctVariables(" & chr(34) & "CounterPath" & chr(34) & ")")
                    sCode = Replace(sCode, "CounterComputer", "dctVariables(" & chr(34) & "CounterComputer" & chr(34) & ")")
                    sCode = Replace(sCode, "CounterObject", "dctVariables(" & chr(34) & "CounterObject" & chr(34) & ")")
                    sCode = Replace(sCode, "CounterName", "dctVariables(" & chr(34) & "CounterName" & chr(34) & ")")
                    sCode = Replace(sCode, "CounterInstance", "dctVariables(" & chr(34) & "CounterInstance" & chr(34) & ")")                    
                    'OutputToConsoleAndLog "After code: " & vbNewLine & sCode
                    If oAnalysis.CounterCount > 1 Then
                        For s = 0 to UBound(aSI,2)
                            sCode = Replace(sCode, oAnalysis.Counters(aSI(0,s)).MinVarName, "dctVariables(oAnalysis.Counters(aSI(0," & s & ")).MinVarName)")
                            sCode = Replace(sCode, oAnalysis.Counters(aSI(0,s)).AvgVarName, "dctVariables(oAnalysis.Counters(aSI(0," & s & ")).AvgVarName)")
                            sCode = Replace(sCode, oAnalysis.Counters(aSI(0,s)).MaxVarName, "dctVariables(oAnalysis.Counters(aSI(0," & s & ")).MaxVarName)")
                            sCode = Replace(sCode, oAnalysis.Counters(aSI(0,s)).TrendVarName, "dctVariables(oAnalysis.Counters(aSI(0," & s & ")).TrendVarName)")
                            sCode = Replace(sCode, "CounterPath", "dctVariables(" & chr(34) & "CounterPath" & chr(34) & ")")
                            sCode = Replace(sCode, "CounterComputer", "dctVariables(" & chr(34) & "CounterComputer" & chr(34) & ")")
                            sCode = Replace(sCode, "CounterObject", "dctVariables(" & chr(34) & "CounterObject" & chr(34) & ")")
                            sCode = Replace(sCode, "CounterName", "dctVariables(" & chr(34) & "CounterName" & chr(34) & ")")
                            sCode = Replace(sCode, "CounterInstance", "dctVariables(" & chr(34) & "CounterInstance" & chr(34) & ")")
                        Next               
                    End If

                        '// Execute Threshold code                    
                        ExecuteThresholdCode oAnalysis, sCode, sOriginalCode, dctVariables, oCounter, oThreshold, aSI
                    
                                                                       
                    If IsMinThresholdBroken = True OR IsAvgThresholdBroken = True OR IsMaxThresholdBroken = True OR IsTrendThresholdBroken = True Then                       
                        iThresholdPriority = CInt(oThreshold.Priority)
                        bConditionHit = True
                        If iThresholdPriority > oAlert.ConditionPriority Then                        
                            oAlert.Condition = oThreshold.Condition
                            oAlert.ConditionName = oThreshold.Name
                            oAlert.ConditionColor = oThreshold.Color
                            oAlert.ConditionPriority = iThresholdPriority
                        End If
                        If IsMinThresholdBroken = True AND iThresholdPriority > oAlert.MinPriority Then
                            'oAlert.Min = ConvertToDataType(oInstance.Min(i), oCounter.DataType)
                            oAlert.MinColor = oThreshold.Color
                            oAlert.MinPriority = iThresholdPriority
                            oAlert.MinCondition = oThreshold.Condition
                        End If
                        If IsAvgThresholdBroken = True AND iThresholdPriority > oAlert.AvgPriority Then
                            'oAlert.Avg = ConvertToDataType(oInstance.Avg(i), oCounter.DataType)
                            oAlert.AvgColor = oThreshold.Color
                            oAlert.AvgPriority = iThresholdPriority
                            oAlert.AvgCondition = oThreshold.Condition                      
                        End If                     
                        If IsMaxThresholdBroken = True AND iThresholdPriority > oAlert.MaxPriority Then
                            'oAlert.Max = ConvertToDataType(oInstance.Max(i), oCounter.DataType)
                            oAlert.MaxColor = oThreshold.Color
                            oAlert.MaxPriority = iThresholdPriority
                            oAlert.MaxCondition = oThreshold.Condition                   
                        End If
                        If IsTrendThresholdBroken = True AND iThresholdPriority > oAlert.TrendPriority Then
                            oAlert.Trend = oInstance.Trend(i)
                            oAlert.TrendColor = oThreshold.Color
                            oAlert.TrendPriority = iThresholdPriority
                            oAlert.TrendCondition = oThreshold.Condition               
                        End If                                                                        
                    End If
                Next
                ON ERROR RESUME NEXT
                If oAlert.Condition <> "-" Then
                    If Err.number = 0 Then
                        ReDim Preserve aAlerts(r)
                        Set aAlerts(r) = oAlert
                        r = r + 1
                    End If
                End If
                ON ERROR GOTO 0
            Next ' For i = 0 to UBound(oInstance.Time)
            ON ERROR GOTO 0
            
            If bConditionHit = False Then
                ' Create an OK alert showing the counter instance was analyzed and did not break any thresholds.
                For Each oThreshold in oAnalysis.Thresholds
                    ON ERROR RESUME NEXT
                    If oThreshold.Code = "" Then
                        ON ERROR GOTO 0
                        Exit For
                    End If
                    ON ERROR GOTO 0                
                    ' Detect which values are being evaluated.
                    sCode = oThreshold.Code
                    sOriginalCode = oThreshold.Code            
                    If Instr(1, sCode, oCounter.MinVarName, 1) > 0 OR oInstance.MinEvaluated = True Then
                        oInstance.MinEvaluated = True
                        oAlert.MinColor = COLOR_GREEN
                        oAlert.MinCondition = "OK"
                    Else
                        oInstance.MinEvaluated = False
                        oAlert.MinColor = ""
                    End If

                    If Instr(1, sCode, oCounter.AvgVarName, 1) > 0 OR oInstance.AvgEvaluated = True Then
                        oInstance.AvgEvaluated = True
                        oAlert.AvgColor = COLOR_GREEN
                        oAlert.AvgCondition = "OK"
                    Else
                        oInstance.AvgEvaluated = False
                        oAlert.AvgColor = ""
                    End If

                    If Instr(1, sCode, oCounter.MaxVarName, 1) > 0 OR oInstance.MaxEvaluated = True Then
                        oInstance.MaxEvaluated = True
                        oAlert.MaxColor = COLOR_GREEN
                        oAlert.MaxCondition = "OK"
                    Else
                        oInstance.MaxEvaluated = False
                        oAlert.MaxColor = ""
                    End If
                    
                    If Instr(1, sCode, oCounter.TrendVarname, 1) > 0 OR oInstance.TrendEvaluated = True Then
                        oInstance.TrendEvaluated = True
                        oAlert.TrendColor = COLOR_GREEN
                         oAlert.TrendCondition = "OK"
                    Else
                        oInstance.TrendEvaluated = False
                        oAlert.TrendColor = ""
                    End If    
                Next        
                ON ERROR RESUME NEXT
                oAlert.Time = ""
                sTest = UBound(oInstance.Trend)
                iErrNum = Err.number
                ON ERROR GOTO 0
                Dim iErrNum                
                If iErrNum = 0 Then
                    oAlert.Time = "*"
                    oAlert.Condition = "OK"
                    oAlert.ConditionName = "OK"
                    oAlert.Min = ConvertToDataType(CalculateMinimum(oInstance.Min), oCounter.DataType)
                    oAlert.Avg = ConvertToDataType(CalculateAverage(oInstance.Avg), oCounter.DataType)                
                    oAlert.Max = ConvertToDataType(CalculateMaximum(oInstance.Max), oCounter.DataType)
                    oAlert.Trend = ConvertToDataType(oInstance.Trend(UBound(oInstance.Trend)), oCounter.DataType)
                    If IsNull(oAlert.Trend) = True Then
                        oAlert.Trend = "-"
                    End If
                    If oInstance.MinEvaluated = True Then
                        oAlert.MinColor = COLOR_GREEN
                    Else
                        oAlert.MinColor = ""    
                    End If
                    If oInstance.AvgEvaluated = True Then
                        oAlert.AvgColor = COLOR_GREEN
                    Else
                        oAlert.AvgColor = ""    
                    End If            
                    If oInstance.MaxEvaluated = True Then
                        oAlert.MaxColor = COLOR_GREEN
                    Else
                        oAlert.MaxColor = ""    
                    End If
                    If oInstance.TrendEvaluated = True Then
                        oAlert.TrendColor = COLOR_GREEN
                    Else
                        oAlert.TrendColor = ""    
                    End If            
                    ReDim Preserve aAlerts(r)
                    Set aAlerts(r) = oAlert
                    r = r + 1                
                End If
            End If
        End If        
    Next ' For Each oInstance in oCounter.Instances    
    AnalyzeCounterValuesAgainstThresholds = ReverseAlertsArrayOrder(aAlerts)
End Function

Function CalculateMinimum(aValues)
    Dim i, iMin
    ' Set iMin to the first real value
    iMin = "-"
    If TestForInitializedArray(aValues) = False Then
        CalculateMinimum = "-"
        Exit Function
    End If
    For i = 0 to UBound(aValues)
        If IsNumeric(aValues(i)) = True AND IsNull(aValues(i)) = False Then
            iMin = aValues(i)
            Exit For
        End If
    Next

    If iMin = "-" Then
        CalculateMinimum = iMin
        Exit Function
    End If
    ' Check all of the values to see if any of them are less than the first value
    For i = 0 to UBound(aValues)
        If IsNull(aValues(i)) = False Then
            If aValues(i) < iMin Then
                iMin = aValues(i)
            End If
        End If
    Next    
    CalculateMinimum = iMin
End Function

Function TestForInitializedArray(aArray)
    Dim i
    Err.Clear
    ON ERROR RESUME NEXT
    i = UBound(aArray)
    If Err.number <> 0 Then
        TestForInitializedArray = False
    Else
        TestForInitializedArray = True    
    End If
    ON ERROR GOTO 0    
End Function

Function CalculateMaximum(aValues)
    Dim i, iMax
    iMax = "-"
    If TestForInitializedArray(aValues) = False Then
        CalculateMaximum = "-"
        Exit Function
    End If        
    For i = 0 to UBound(aValues)
        If IsNumeric(aValues(i)) = True AND IsNull(aValues(i)) = False Then
            iMax = aValues(i)
            Exit For
        End If
    Next
    If iMax = "-" Then
        CalculateMaximum = iMax
        Exit Function
    End If
    For i = 0 to UBound(aValues)
        If IsNull(aValues(i)) = False Then
            If aValues(i) > iMax Then
                iMax = aValues(i)
            End If
        End If
    Next    
    CalculateMaximum = iMax
End Function

Function CalculateAverage(aValues)
    Dim i, iCount, iSum
    iSum = 0
    iCount = 0    
    If TestForInitializedArray(aValues) = False Then
        CalculateAverage = "-"
        Exit Function
    End If    
    For i = 0 to UBound(aValues)
        If IsNull(aValues(i)) = False Then
            iSum = iSum + aValues(i)
            iCount = iCount + 1
        End If        
    Next
    If Abs(iSum) > 0 AND iCount > 0 Then
        CalculateAverage = iSum / iCount
    Else
        CalculateAverage = "-"
    End If
End Function

Function ArrayStdDev(arr, bbSampleStdDev, bIgnoreEmpty) ' As Double
    Dim sum 'As Double
    Dim sumSquare 'As Double
    Dim value 'As Double
    Dim count 'As Long
    Dim index 'As Long

    ' evaluate sum of values
    ' if arr isn't an array, the following statement raises an error
    For index = LBound(arr) To UBound(arr)
        value = arr(index)
        ' skip over non-numeric values
        If IsNumeric(value) Then
            ' skip over empty values, if requested
            If Not (IgnoreEmpty And IsEmpty(value)) Then
                ' add to the running total
                count = count + 1
                sum = sum + value
                sumSquare = sumSquare + value * value
            End If
         End If
    Next

    ' evaluate the result
    ' use (Count-1) if evaluating the standard deviation of a sample
    If bSampleStdDev Then
        ArrayStdDev = Sqr((sumSquare - (sum * sum / count)) / (count - 1))
    Else
        ArrayStdDev = Sqr((sumSquare - (sum * sum / count)) / count)
    End If

End Function


'''''''''''''''''''''''
' <XML Helper Routines> '
'''''''''''''''''''''''

Function LoadXMLRoot(strXMLFilePath)
	Dim objXMLDoc
	Dim objXMLRoot
	
	Set objXMLDoc = CreateObject("Msxml2.DOMDocument")
	objXMLDoc.async = False
	objXMLDoc.Load strXMLFilePath
	Set objXMLRoot = objXMLDoc.documentElement
	CreateXMLRoot = objXMLRoot
End Function

Function FindAndSetNodeInXML(objXMLNodeCollection, strNodeName, strXMLAttribute, strSearchString)
	Set objNodeList = objXMLNodeCollection.selectNodes("./" & strNodeName)
	For Each objNode In objNodeList
		If LCase(objNode.getAttribute(strXMLAttribute)) = LCase(strSearchString) Then
			Set FindAndSetNodeInXML = objNode
			Exit Function
		End If
	Next
	Set FindAndSetNodeInXML = Nothing
End Function

Sub DeleteXMLNodes(objXMLNodeCollection, strNodeName, strXMLAttribute, strSearchString)
	Set objExistingNode = FindAndSetNodeInXML(objXMLNodeCollection, strNodeName, strXMLAttribute, strSearchString)
	Do Until objExistingNode is Nothing
		objXMLNodeCollection.removeChild(objExistingNode)
		Set objExistingNode = FindAndSetNodeInXML(objXMLNodeCollection, strNodeName, strXMLAttribute, strSearchString)
	Loop
End Sub

'''''''''''''''''''''''
' </XML Helper Routines> '
'''''''''''''''''''''''

Function bDoesStringExistInSingleDimensionArray(aValues, sValueToSearchFor)
    Dim i, bFound   
    bFound = False
    ON ERROR RESUME NEXT
    If IsEmpty(UBound(aValues)) = True Then
        bDoesStringExistInSingleDimensionArray = False
        Exit Function
    End If
    For i = 0 To UBound(aValues)
        If LCase(aValues(i)) = LCase(sValueToSearchFor) Then
            bFound = True
            Exit For
        End If
    Next
    If bFound = True Then
        bDoesStringExistInSingleDimensionArray = True
    Else
        bDoesStringExistInSingleDimensionArray = False
    End If
    ON ERROR GOTO 0
End Function


Sub GenerateXMLData()
    Dim oXMLAlerts, oAnalysis
    
    OutputToConsoleAndLog "Generating XML data..."
    
    ' Generate analysis data
	For Each oAnalysis In g_aData
        '  Generate graph <= returns a file path to the graph
        '   Set oXMLGraph = GenerateGraph(g_FilteredPerfmonLogFile, oXMLAnalysis)
        '  Generate Alerts
        If oAnalysis.AllCountersFound = True Then
            OutputToConsoleAndLog "Analyzing " & chr(34) & oAnalysis.Name & chr(34) & "..."
            Call Analyze(g_FilteredPerfmonLogFile, oAnalysis)
        End If
        '  Add to outbound XML document
        ' Next	        	        
	Next	
        
    ' Create XML document
    Dim xmlDoc, XMLRoot, newNode
    Set xmlDoc = CreateObject("Msxml2.DOMDocument")
    xmlDoc.async = False
    xmlDoc.loadXML "<PAL></PAL>"
    Set XMLRoot = xmlDoc.documentElement

    
    Dim oXMLNode, oXMLCategory, oXMLCategories, oAlert, oChart, oThreshold, oCounter, oInstance, oStats
    Dim XMLAnalysisNode, XMLAlertNode, XMLChartNode, XMLThresholdNode, XMLStatisticsNode
    Dim aCategories(), a, bFound, sCategory, bExclude, oExclude
    
    ' Get content owner and contact email
    XMLRoot.SetAttribute "CONTENTOWNERS", g_XMLRoot.GetAttribute("CONTENTOWNERS")
    XMLRoot.SetAttribute "FEEDBACKEMAILADDRESS", g_XMLRoot.GetAttribute("FEEDBACKEMAILADDRESS")
    
    ' Get all of the category nodes needed to be created.
    a = 0
    For Each oAnalysis In g_aData
        If oAnalysis.AllCountersFound = True Then
            bFound = bDoesStringExistInSingleDimensionArray(aCategories, oAnalysis.Category)
            If bFound = False Then
                ReDim Preserve aCategories(a)
                aCategories(a) = oAnalysis.Category
                a = a + 1            
            End If
        End If
    Next
        
    ' Create the category nodes
    For Each sCategory in aCategories
        Set newNode = xmldoc.createNode(1, "CATEGORY", "")
        newNode.SetAttribute "NAME", sCategory
        XMLRoot.appendChild newNode      
    Next
  
    For Each oAnalysis In g_aData
        If oAnalysis.AllCountersFound = True Then            
        ' Assign the Analysis node to it's respective category
            Set oXMLCategories = XMLRoot.SelectNodes("./CATEGORY")
            For Each oXMLNode in oXMLCategories
                If LCase(oXMLNode.GetAttribute("NAME")) = LCase(oAnalysis.Category) Then
                    Set oXMLCategory = oXMLNode
                    Exit For
                End If
            Next             
            Set XMLAnalysisNode = xmldoc.createNode(1, "ANALYSIS", "")            	            
            XMLAnalysisNode.SetAttribute "NAME", oAnalysis.Name
            XMLAnalysisNode.SetAttribute "ANALYZECOUNTER", oAnalysis.AnalyzeCounter
            XMLAnalysisNode.SetAttribute "CATEGORY", oAnalysis.Category
            XMLAnalysisNode.SetAttribute "COUNTERCOUNT", oAnalysis.CounterCount
            XMLAnalysisNode.SetAttribute "THRESHOLDCOUNT", oAnalysis.ThresholdCount
            XMLAnalysisNode.SetAttribute "ALERTCOUNT", oAnalysis.AlertCount
            XMLAnalysisNode.SetAttribute "DESCRIPTION", oAnalysis.Description
            oXMLCategory.appendChild XMLAnalysisNode            
            ' Stats
            For Each oCounter in oAnalysis.Counters
                If LCase(oCounter.Name) = LCase(oAnalysis.AnalyzeCounter) Then
                    For Each oInstance in oCounter.Instances
                        Set oStats = oInstance.Stats
                        Set XMLStatisticsNode = xmldoc.createNode(1, "STATISTIC", "")
                        XMLStatisticsNode.SetAttribute "NAME", oInstance.Name
                        XMLStatisticsNode.SetAttribute "MIN", oStats.Min
                        XMLStatisticsNode.SetAttribute "AVG", oStats.Avg
                        XMLStatisticsNode.SetAttribute "MAX", oStats.Max
                        XMLStatisticsNode.SetAttribute "TREND", oStats.Trend
                        XMLStatisticsNode.SetAttribute "STANDARDDEVIATION", oStats.StandardDeviation
                        XMLStatisticsNode.SetAttribute "NINETYITHPERCENTILE", oStats.NinetyithPercentile
                        XMLStatisticsNode.SetAttribute "EIGHTYITHPERCENTILE", oStats.EightyithPercentile
                        XMLStatisticsNode.SetAttribute "SEVENTYITHPERCENTILE", oStats.SeventyithPercentile
                        XMLAnalysisNode.appendChild XMLStatisticsNode
                    Next
                    Exit For
                End If
            Next
            
            ' Chart
            If oAnalysis.Charts(0).ChartTitle <> "NO CHARTS" Then
                For Each oChart in oAnalysis.Charts
                    Set XMLChartNode = xmldoc.createNode(1, "CHART", "")               	            
                    XMLChartNode.SetAttribute "CHARTTITLE", oChart.ChartTitle
                    XMLChartNode.SetAttribute "IMAGEFILEPATHS", Join(oChart.ImageFilePaths,";")
                    XMLAnalysisNode.appendChild XMLChartNode            
                Next
            End If
            
            ' Threshold descriptions
            For Each oThreshold in oAnalysis.Thresholds
                ON ERROR RESUME NEXT
                If oThreshold.Name = "" Then
                    Exit For
                End If
                ON ERROR GOTO 0
                Set XMLThresholdNode = xmldoc.createNode(1, "THRESHOLD", "")               	            
                XMLThresholdNode.SetAttribute "NAME", oThreshold.Name
                XMLThresholdNode.SetAttribute "DESCRIPTION", oThreshold.Description
                XMLThresholdNode.SetAttribute "COLOR", oThreshold.Color
                XMLThresholdNode.SetAttribute "CONDITION", oThreshold.Condition
                XMLThresholdNode.SetAttribute "PRIORITY", oThreshold.Priority
                XMLAnalysisNode.appendChild XMLThresholdNode            
            Next            
            
'                Public Name
'                Public Enabled
'                Public AnalyzeCounter
'                Public Category
'                Public Counters
'                Public Thresholds
'                Public Charts
'                Public CounterCount
'                Public ThresholdCount
'                Public ChartCount
'                Public Alerts
'                Public AlertCount
'                Public AllCountersFound            
            
            For Each oAlert in oAnalysis.Alerts
                ON ERROR RESUME NEXT
                If oAlert.Time = "" Then
                    Exit For
                End If
                ON ERROR GOTO 0            
                Set XMLAlertNode = xmldoc.createNode(1, "ALERT", "")
                XMLAlertNode.SetAttribute "ANALYSISNAME", oAnalysis.Name
	            XMLAlertNode.SetAttribute "TIME", oAlert.Time
	            XMLAlertNode.SetAttribute "CONDITION", oAlert.Condition
	            XMLAlertNode.SetAttribute "CONDITIONNAME", oAlert.ConditionName
	            XMLAlertNode.SetAttribute "CONDITIONCOLOR", oAlert.ConditionColor
	            XMLAlertNode.SetAttribute "CONDITIONPRIORITY", oAlert.ConditionPriority
	            XMLAlertNode.SetAttribute "COUNTER", oAlert.Counter
	            XMLAlertNode.SetAttribute "MIN", oAlert.Min
	            XMLAlertNode.SetAttribute "MINCOLOR", oAlert.MinColor
	            XMLAlertNode.SetAttribute "MINCONDITION", oAlert.MinCondition
	            XMLAlertNode.SetAttribute "MINPRIORITY", oAlert.MinPriority
	            XMLAlertNode.SetAttribute "AVGCOLOR", oAlert.AvgColor
	            XMLAlertNode.SetAttribute "AVG", oAlert.Avg
	            XMLAlertNode.SetAttribute "AVGCONDITION", oAlert.AvgCondition
	            XMLAlertNode.SetAttribute "AVGPRIORITY", oAlert.AvgPriority
	            XMLAlertNode.SetAttribute "MAX", oAlert.Max
	            XMLAlertNode.SetAttribute "MAXCOLOR", oAlert.MaxColor
	            XMLAlertNode.SetAttribute "MAXCONDITION", oAlert.MaxCondition
	            XMLAlertNode.SetAttribute "MAXPRIORITY", oAlert.MaxPriority
	            XMLAlertNode.SetAttribute "TREND", oAlert.Trend
	            XMLAlertNode.SetAttribute "TRENDCOLOR", oAlert.TrendColor
	            XMLAlertNode.SetAttribute "TRENDCONDITION", oAlert.TrendCondition
	            XMLAlertNode.SetAttribute "TRENDPRIORITY", oAlert.TrendPriority	            
                XMLAnalysisNode.appendChild XMLAlertNode               
                
'                    Public Time
'                    Public ConditionColor
'                    Public Condition
'                    Public ConditionPriority
'                    Public Counter
'                    Public MinColor
'                    Public Min
'                    Public MinPriority
'                    Public MinCondition
'                    Public AvgColor
'                    Public Avg
'                    Public AvgPriority
'                    Public AvgCondition
'                    Public MaxColor
'                    Public Max
'                    Public MaxPriority
'                    Public MaxCondition
'                    Public TrendColor
'                    Public Trend
'                    Public TrendPriority
'                    Public TrendCondition                 
            Next
        End If
    Next
    If g_IsOutputXML = True Then
        OutputToConsoleAndLog "g_PALReportsDirectory: " & g_PALReportsDirectory
        Dim aPath, sPerfmonLogName    
        aPath = Split(g_PerfmonLog, "\")
        sPerfmonLogName = aPath(UBound(aPath))
        sPerfmonLogName = Mid(sPerfmonLogName, 1, Len(sPerfmonLogName) - 4)      
        'xmldoc.save g_PALReportsDirectory & "\" & Replace(sPerfmonLogName, " ", "_") & "_PAL_ANALYSIS_" & g_DateTimeStamp & "_" & RemoveCurlyBrackets(g_GUID) & ".xml"
        xmldoc.save g_XMLOutputFilePath
    End If
    
    If g_IsOutputHTML = True Then
        GenerateHTML XMLRoot, g_ReportFilePath
    End If
    
End Sub

Sub GenerateHTML(oXML, sHTMLOutputPath)
    'Header
    'TOC
    'Processor
    'Memory
    'Disk
    'Network
    'Footer
    OutputToConsoleAndLog "Generating HTML report..."
    Dim oFSO, oFile
    Dim sOutput, sDQ
    Dim oXMLCategory, oXMLCategories, oXMLAnalysis, oXMLAnalysi, oXMLAlert, oXMLAlerts, oXMLChart, oXMLCharts, oXMLThresholds, oXMLThreshold, oXMLStatistics, oXMLStatistic
    Dim aImagePaths, sImagePath, sHrefName, a, tTime
    Dim sInterval, iCount, sAnalysisInterval
    Dim bNoAlerts, iAlertCount, bOKAlertsExist
    Dim sHeaderOutput, sTOCOutput, sToolParameterOutput, sChronoOrderOutput, sAnalysisOutput, sAllAnalysisOutput, sFooterOutput, sDisclaimer
    sDQ = chr(34)
    
    '=========================
    ' HTML Report 
    '=========================
    'Header
    sHeaderOutput = sHeaderOutput & "<HTML>" & vbNewLine & _
    "<HEAD>" & vbNewLine & _
    "<TITLE>" & GetFileNameFromPath(g_OriginalPerfmonLogArg) & " PERFMON LOG ANALYSIS REPORT</TITLE>" & vbNewLine & _
    "<STYLE TYPE=""text/css"" TITLE=""currentStyle"" MEDIA=""screen"">" & vbNewLine & _
    "body {" & vbNewLine & _
    "   font: normal 8pt/16pt Verdana;" & vbNewLine & _
    "   color: #000000;" & vbNewLine & _
    "   margin: 10px;" & vbNewLine & _
    "   }" & vbNewLine & _
    "p {font: 8pt/16pt Verdana;margin-top: 0px;}" & vbNewLine & _
    "h1 {font: 20pt Verdana;margin-bottom: 0px;color: #000000;}" & vbNewLine & _
    "h2 {font: 15pt Verdana;margin-bottom: 0px;color: #000000;}" & vbNewLine & _
    "h3 {font: 13pt Verdana;margin-bottom: 0px;color: #000000;}" & vbNewLine & _
    "td {font: normal 8pt Verdana;}" & vbNewLine & _
    "th {font: bold 10pt Verdana;}" & vbNewLine & _
    "blockquote {font: normal 8pt Verdana;}" & vbNewLine & _
    "</STYLE>" & vbNewLine & _    
    "</HEAD>" & vbNewLine & _    
    "<BODY LINK=""Black"" VLINK=""Black"">" & vbNewLine
    
    Dim sContentOwner, sContentOwnerEmail
    sContentOwner = oXML.GetAttribute("CONTENTOWNERS")
    sContentOwnerEmail = oXML.GetAttribute("FEEDBACKEMAILADDRESS")
    sHeaderOutput = sHeaderOutput & _
    "<TABLE CELLPADDING=10 WIDTH=""100%""><TR><TD BGCOLOR=""#000000"">" & vbNewLine & _
    "<FONT COLOR=""#FFFFFF"" FACE=""Tahoma"" SIZE=""5""><STRONG>Analysis of " & chr(34) & GetFileNameFromPath(g_OriginalPerfmonLogArg) & chr(34) & "</STRONG></FONT><BR><BR>" & vbNewLine & _
    "<FONT COLOR=""#FFFFFF"" FACE=""Tahoma"" SIZE=""2""><STRONG>Report Generated at: " & Now() & "</STRONG>" & vbNewLine & _
    "</TD><TD><A HREF=""http://www.codeplex.com/PAL""><FONT COLOR=""#000000"" FACE=""Tahoma"" SIZE=""10"">PAL</FONT></A>" & vbNewLine & _    
    "</TD></TR></TABLE>" & vbNewLine & _
    "<BR>" & vbNewLine
    
    '''''''''''
    ' Table of contents
    '''''''''''
    sTOCOutput = "<H4>On This Page</H4>" & vbNewLine & _
    "<UL>" & vbNewLine  & _
    "<LI><A HREF=" & dQ & "#" & ConvertStringForHref("Tool Parameters") & dQ & ">Tool Parameters</A></LI>" & vbNewLine
    '// ConvertStringForHref("Tool Parameters")
    
        ' Special entry for "Alerts by Chronological Order"        
        sHrefName = ConvertStringForHref("Chronological Order")
        sTOCOutput = sTOCOutput & "<LI><A HREF=" & dQ & "#" & sHrefName & dQ & ">Chronological Order</A></LI>" & vbNewLine & _
        "<UL>" & vbNewLine
        sHrefName = ConvertStringForHref("Alerts by Chronological Order")
        sTOCOutput = sTOCOutput & "<LI><A HREF=" & dQ & "#" & sHrefName & dQ & ">Alerts by Chronological Order</A></LI>" & vbNewLine & _
        "</UL>" & vbNewLine
        
        Set oXMLCategories = oXML.SelectNodes("./CATEGORY")
        For Each oXMLCategory in oXMLCategories
            sHrefName = ConvertStringForHref(oXMLCategory.GetAttribute("NAME"))
            sTOCOutput = sTOCOutput & "<LI><A HREF=" & dQ & "#" & sHrefName & dQ & ">" & oXMLCategory.GetAttribute("NAME") & "</A></LI>" & vbNewLine
            Set oXMLAnalysi = oXMLCategory.SelectNodes("./ANALYSIS")
            sTOCOutput = sTOCOutput & "<UL>" & vbNewLine        
            For Each oXMLAnalysis in oXMLAnalysi
                sHrefName = ConvertStringForHref(oXMLAnalysis.GetAttribute("NAME"))
                Set oXMLAlerts = oXMLAnalysis.SelectNodes("./ALERT")
                iCount = 0
                bNoAlerts = True
                bOKAlertsExist = False                
                For Each oXMLAlert in oXMLAlerts
                    If oXMLAlert.GetAttribute("CONDITION") <> "OK" Then
                        iCount = iCount + 1
                        bNoAlerts = False
                    Else
                        bOKAlertsExist = True
                    End If                    
                Next
                If bOKAlertsExist = False AND bNoAlerts = True Then
                    sTOCOutput = sTOCOutput & "<LI><A HREF=" & dQ & "#" & sHrefName & dQ & ">" & oXMLAnalysis.GetAttribute("NAME") & " (Stats only)" & vbNewLine
                Else
                    sTOCOutput = sTOCOutput & "<LI><A HREF=" & dQ & "#" & sHrefName & dQ & ">" & oXMLAnalysis.GetAttribute("NAME") & " (Alerts: " & iCount & ")</A></LI>" & vbNewLine
                End If
            Next
            sTOCOutput = sTOCOutput & "</UL>" & vbNewLine
        Next
    sHrefName = ConvertStringForHref("Disclaimer")
    sTOCOutput = sTOCOutput & "<LI><A HREF=" & dQ & "#" & sHrefName & dQ & ">Disclaimer" & vbNewLine & _
    "</UL>" & vbNewLine & _
    "<BR>" & vbNewLine 
    
    '''''''''''''''''''''''''''''''''''''''''''''''''''''
    '// Tool parameters
    '''''''''''''''''''''''''''''''''''''''''''''''''''''
    
    sToolParameterOutput = "<TABLE BORDER=0 WIDTH=50%>" & vbNewLine & _
    "<TR><TD>" & vbNewLine & _
    "<H1><A NAME=" & dQ & "#" & ConvertStringForHref("Tool Parameters") & dQ & ">Tool Parameters:</A></H1>" & vbNewLine & _
    "<HR>" & vbNewLine & _
    "</TD></TR>" & vbNewLine & _
    "</TABLE>" & vbNewLine & _
    "<TABLE BORDER=0 CELLPADDING=5>" & vbNewLine & _
    "<TR><TH WIDTH=300 BGCOLOR=""#000000""><FONT COLOR=""#FFFFFF"">Name</FONT></TH><TH BGCOLOR=""#000000""><FONT COLOR=""#FFFFFF"">Value</FONT></TH><TR>" & vbNewLine
    sInterval = g_Interval
    SELECT CASE g_IntervalDescription
        CASE "Hour"
            sInterval = sInterval & " seconds (1 Hour)"
        CASE "Minute"
            sInterval = sInterval & " seconds (1 Minute)"
        CASE Else
            sInterval = Round(sInterval / 60)
            sInterval = sInterval & " seconds"
    END SELECT
    sAnalysisInterval = ProcessAnalysisIntervalIntoHTML    
    sToolParameterOutput = sToolParameterOutput & "" & _
    "<TR><TD WIDTH=300><B>Analysis of Log: </B></TD><TD>" & GetFileNameFromPath(g_OriginalPerfmonLogArg) & "</TD></TR>" & vbNewLine & _
    "<TR><TD WIDTH=300><B>Analysis Interval: </B></TD><TD>" & sAnalysisInterval & "</TD></TR>" & vbNewLine & _
    "<TR><TD WIDTH=300><B>Threshold File: </B></TD><TD>" & GetFileNameFromPath(g_XMLThresholdFile) & "</TD></TR>" & vbNewLine
        '// Enumerate the questions and answers
        Dim sKey
        For each sKey in g_dctQuestions.Keys
            sToolParameterOutput = sToolParameterOutput & "<TR><TD WIDTH=300><B>" & g_dctQuestions(sKey).Question & "</B></TD><TD>" & g_dctQuestions(sKey).Answer & "</TD></TR>" & vbNewLine
        Next
            '    sToolParameterOutput = sToolParameterOutput & "<TR><TD><B>Number of Processors:</B></TD><TD>" & g_dctQuestions("NumberOfProcessors").Answer & "</TD></TR>" & vbNewLine
            '    sToolParameterOutput = sToolParameterOutput & "<TR><TD><B>/3GB Switch:</B></TD><TD>" & g_dctQuestions("ThreeGBSwitch").Answer & "</TD></TR>" & vbNewLine
            '    sToolParameterOutput = sToolParameterOutput & "<TR><TD><B>Total Memory:</B></TD><TD>" & g_dctQuestions("TotalMemory").Answer & " GBs</TD></TR>" & vbNewLine
            '    sToolParameterOutput = sToolParameterOutput & "<TR><TD><B>64-bit:</B></TD><TD>" & g_dctQuestions("SixtyFourBit").Answer & "</TD></TR>" & vbNewLine
            '    'sToolParameterOutput = sToolParameterOutput & "<TR><TD><B>Operating System:</B></TD><TD>" & OperatingSystem & "</TD></TR>" & vbNewLine
    sToolParameterOutput = sToolParameterOutput & "</TABLE>" & vbNewLine & _
    "<A HREF=" & dQ & "#top" & dQ & ">Back to the top</A><BR>" & vbNewLine & _
    "<BR>" & vbNewLine
    
    '''''''''''''''''''''''''''''''''''''''''''''''''''''
    'Poplulate "Alerts by Chronological Order" category
    '''''''''''''''''''''''''''''''''''''''''''''''''''''
    sChronoOrderOutput = "" & _
    "<TABLE BORDER=0 WIDTH=50%>" & vbNewLine & _
    "<TR><TD>" & vbNewLine & _
    "<H1><A NAME=" & dQ & "#" & ConvertStringForHref("Chronological Order") & dQ & ">Chronological Order</A></H1>" & vbNewLine & _
    "<HR>" & vbNewLine & _
    "</TD></TR>" & vbNewLine & _
    "</TABLE>" & vbNewLine
        '''''''''''
        ' Name
        '''''''''''
        sChronoOrderOutput = sChronoOrderOutput & "<H2><A NAME=" & dQ & "#" & ConvertStringForHref("Alerts by Chronological Order") & dQ & ">Alerts by Chronological Order</A></H2>" & vbNewLine                
        
        '''''''''''
        ' Description
        '''''''''''
        sChronoOrderOutput = sChronoOrderOutput & "<BLOCKQUOTE><B>Description: </B> This section displays all of the alerts in chronological order.</BLOCKQUOTE><BR>" & vbNewLine
           
    ' Enumerate all of the Alerts in the XML and put them in chronological order.    
    
    sChronoOrderOutput = sChronoOrderOutput & "<CENTER>" & vbNewLine & _
    "<H3>Alerts</H3>" & _
    "<TABLE BORDER=0 WIDTH=60%><TR><TD>" & vbNewLine & _
    "An alert is generated if any of the thresholds were broken during one of the time intervals analyzed. The background of each of the values represents the highest priority threshold that the value broke. See the each of the counter's respective analysis section for more details about what the threshold means. A white background indicates that the value was not analyzed by any of the thresholds." & vbNewLine & _
    "</TD></TR></TABLE>" & vbNewLine
    
    '// Check to see if any alerts exist
    Set oXMLAlerts = oXML.SelectNodes("//ALERT")
    bNoAlerts = True
    For Each oXMLAlert in oXMLAlerts
        If oXMLAlert.GetAttribute("CONDITION") <> "OK" Then
            bNoAlerts = False
            Exit For
        End If                    
    Next
    'OutputToConsoleAndLog "DEBUG: bNoAlerts: " & bNoAlerts
    If bNoAlerts = False Then
        sChronoOrderOutput = sChronoOrderOutput & "<TABLE BORDER=1 CELLPADDING=5>" & vbNewLine & _
        "<TR><TH>Time</TH><TH></TH><TH></TH><TH></TH><TH></TH><TH></TH><TH></TH></TR>" & vbNewLine
        Set oXMLAlerts = oXML.SelectNodes("//ALERT")
        'OutputToConsoleAndLog "DEBUG: UBound(g_aTime): " & UBound(g_aTime)
        For a = 0 to UBound(g_aTime)
            sChronoOrderOutput = sChronoOrderOutput & "<TR><TH>" & g_aTime(a) & "</TH><TH>Condition</TH><TH>Counter</TH><TH>Min</TH><TH>Avg</TH><TH>Max</TH><TH>Hourly Trend</TH></TR>" & vbNewLine
            For Each oXMLAlert in oXMLAlerts
                tTime = oXMLAlert.GetAttribute("TIME")
                sHrefName = ConvertStringForHref(oXMLAlert.GetAttribute("ANALYSISNAME"))                
                If tTime <> "*" Then
                    tTime = CDate(tTime)
                End If
                If tTime = g_aTime(a) Then
                    sChronoOrderOutput = sChronoOrderOutput & "<TR><TD></TD><TD BGCOLOR=" & dQ & oXMLAlert.GetAttribute("CONDITIONCOLOR") & sDQ & ">" & "<A HREF=" & dQ & "#" & sHrefName & dQ & ">" & oXMLAlert.GetAttribute("CONDITIONNAME") & "</A></TD><TD>" & oXMLAlert.GetAttribute("COUNTER") & "</TD><TD BGCOLOR=" & dQ & oXMLAlert.GetAttribute("MINCOLOR") & sDQ & ">" & DigitGrouping(oXMLAlert.GetAttribute("MIN")) & "</TD><TD BGCOLOR=" & dQ & oXMLAlert.GetAttribute("AVGCOLOR") & sDQ & ">" & DigitGrouping(oXMLAlert.GetAttribute("AVG")) & "</TD><TD BGCOLOR=" & dQ & oXMLAlert.GetAttribute("MAXCOLOR") & sDQ & ">" & DigitGrouping(oXMLAlert.GetAttribute("MAX")) & "</TD><TD BGCOLOR=" & dQ & oXMLAlert.GetAttribute("TRENDCOLOR") & sDQ & ">" & DigitGrouping(oXMLAlert.GetAttribute("TREND")) & "</TD></TR>" & vbNewLine
                End If
            Next
        Next    
        sChronoOrderOutput = sChronoOrderOutput & "</TABLE>"
    Else
        sChronoOrderOutput = sChronoOrderOutput & "<TABLE BORDER=1 CELLPADDING=5>" & vbNewLine & _
        "<TR><TH>No Alerts Found</TH></TR>" & vbNewLine & _
        "</TABLE>"
    End If
    sChronoOrderOutput = sChronoOrderOutput & "</CENTER>" & vbNewLine & _
    "<A HREF=" & dQ & "#top" & dQ & ">Back to the top</A><BR>" & vbNewLine       
        
        Set oXMLCategories = oXML.SelectNodes("./CATEGORY")
        For Each oXMLCategory in oXMLCategories
            '''''''''''''
            ' Category 
            '''''''''''''            
            sAnalysisOutput = "<TABLE BORDER=0 WIDTH=50%>" & vbNewLine & _
            "<TR><TD>" & vbNewLine & _
            "<H1><A NAME=" & dQ & "#" & ConvertStringForHref(oXMLCategory.GetAttribute("NAME")) & dQ & ">" & oXMLCategory.GetAttribute("NAME") & "</A></H1>" & vbNewLine & _
            "<HR>" & vbNewLine & _
            "</TD></TR>" & vbNewLine & _
            "</TABLE>" & vbNewLine
            For Each oXMLAnalysis in oXMLCategory.ChildNodes
                '''''''''''
                ' Analysis Name
                '''''''''''
                sAnalysisOutput = sAnalysisOutput & "<H2><A NAME=" & dQ & "#" & ConvertStringForHref(oXMLAnalysis.GetAttribute("NAME")) & dQ & ">" & oXMLAnalysis.GetAttribute("NAME") & "</A></H2>" & vbNewLine                
                
                '''''''''''
                ' Analysis Description
                '''''''''''
                sAnalysisOutput = sAnalysisOutput & "<BLOCKQUOTE><B>Description: </B>" & oXMLAnalysis.GetAttribute("DESCRIPTION") & "</BLOCKQUOTE><BR>" & vbNewLine
                '''''''''''
                ' Charts
                '''''''''''
                Set oXMLCharts = oXMLAnalysis.selectNodes("./CHART")
                For Each oXMLChart in oXMLCharts
                    aImagePaths = Split(oXMLChart.GetAttribute("IMAGEFILEPATHS"),";")
                    For Each sImagePath in aImagePaths
                        sImagePath = MakeAbsolutePathToRelativePath(sImagePath)
                        sAnalysisOutput = sAnalysisOutput & "<CENTER><IMG SRC=" & dQ & sImagePath & dQ & " ALT=" & dQ & oXMLChart.GetAttribute("CHARTTITLE") & dQ & "></CENTER><BR>" & vbNewLine
                    Next                    
                Next
                sAnalysisOutput = sAnalysisOutput & "<A HREF=" & dQ & "#top" & dQ & ">Back to the top</A><BR>" & vbNewLine
                
                '''''''''''
                ' Analyzed Counter Stats
                '''''''''''
                sAnalysisOutput = sAnalysisOutput & "<CENTER>" & vbNewLine & _
                "<H3>Counter Instance Statistics</H3>" & vbNewLine & _
                "<TABLE BORDER=0 WIDTH=60%><TR><TD>" & vbNewLine & _
                "Overall statistics of each of the counter instances. Min is the minimum value recorded in the entire log, Avg is the average value of the entire log, Max is the maximum value recorded in the entire log, and Trend is the net, average, difference between data points of the entire log." & vbNewLine & _
                "</TD></TR></TABLE>" & vbNewLine & _
                "<TABLE BORDER=1 CELLPADDING=5>" & vbNewLine & _
                "<TR><TH>Name</TH><TH>Min</TH><TH>Avg</TH><TH>Max</TH><TH>Hourly Trend</TH><TH>Std Deviation</TH><TH>90th Percentile</TH><TH>80th Percentile</TH><TH>70th Percentile</TH></TR>" & vbNewLine
                Set oXMLStatistics = oXMLAnalysis.selectNodes("./STATISTIC")
                For Each oXMLStatistic in oXMLStatistics
                    sAnalysisOutput = sAnalysisOutput & "<TR><TD>" & oXMLStatistic.GetAttribute("NAME") & "</TD><TD>" & DigitGrouping(oXMLStatistic.GetAttribute("MIN")) & "</TD><TD>" & DigitGrouping(oXMLStatistic.GetAttribute("AVG")) & "</TD><TD>" & DigitGrouping(oXMLStatistic.GetAttribute("MAX")) & "</TD><TD>" & DigitGrouping(oXMLStatistic.GetAttribute("TREND")) & "</TD><TD>" & DigitGrouping(oXMLStatistic.GetAttribute("STANDARDDEVIATION")) & "</TD><TD>" & DigitGrouping(oXMLStatistic.GetAttribute("NINETYITHPERCENTILE")) & "</TD><TD>" & DigitGrouping(oXMLStatistic.GetAttribute("EIGHTYITHPERCENTILE")) & "</TD><TD>" & DigitGrouping(oXMLStatistic.GetAttribute("SEVENTYITHPERCENTILE")) & "</TD></TR>" & vbNewLine
                Next
                sAnalysisOutput = sAnalysisOutput & "</TABLE>" & vbNewLine & _
                "</CENTER>" & vbNewLine & _
                "<A HREF=" & dQ & "#top" & dQ & ">Back to the top</A><BR>" & vbNewLine
                '''''''''''
                ' Threshold Descriptions
                '''''''''''             
' Removed the threshold descriptions because they were getting confused with alerts.                  
'                sAnalysisOutput = sAnalysisOutput & "<CENTER>" & vbNewLine
'                sAnalysisOutput = sAnalysisOutput & "<H3>Threshold Descriptions</H3>"
'                sAnalysisOutput = sAnalysisOutput & "<TABLE BORDER=0 WIDTH=60%><TR><TD>" & vbNewLine
'                sAnalysisOutput = sAnalysisOutput & "This is a list of the thresholds that the counter values were analyzed against. The priority field indicates the order of precedence of the thresholds. Higher priority thresholds will override lower priority thresholds. <B>See the Alerts section to see if any of these thresholds were exceeded.</B>" & vbNewLine
'                sAnalysisOutput = sAnalysisOutput & "</TD></TR></TABLE>" & vbNewLine
'                sAnalysisOutput = sAnalysisOutput & "<TABLE BORDER=1 CELLPADDING=5>" & vbNewLine
'                sAnalysisOutput = sAnalysisOutput & "<TR><TH>Name</TH><TH>Condition</TH><TH>Description</TH><TH>Priority</TH></TR>" & vbNewLine
'                Set oXMLThresholds = oXMLAnalysis.selectNodes("./THRESHOLD")
'                For Each oXMLThreshold in oXMLThresholds
'                    sAnalysisOutput = sAnalysisOutput & "<TR><TD>" & oXMLThreshold.GetAttribute("NAME") & "</TD><TD BGCOLOR=" & dQ & oXMLThreshold.GetAttribute("COLOR") & dQ & ">" & oXMLThreshold.GetAttribute("CONDITION") & "</TD><TD>" & oXMLThreshold.GetAttribute("DESCRIPTION") & "</TD><TD>" & oXMLThreshold.GetAttribute("PRIORITY") & "</TD></TR>"    
'                Next
'                sAnalysisOutput = sAnalysisOutput & "</TABLE>"
'                sAnalysisOutput = sAnalysisOutput & "</CENTER>" & vbNewLine
'                sAnalysisOutput = sAnalysisOutput & "<BR>" & vbNewLine             
                
                '''''''''''
                ' Alerts
                '''''''''''
                Set oXMLAlerts = oXMLAnalysis.selectNodes("./ALERT")
                iAlertCount = 0
                For Each oXMLAlert in oXMLAlerts
                    iAlertCount = iAlertCount + 1
                Next
                If iAlertCount > 0 Then 
                    sAnalysisOutput = sAnalysisOutput & "<CENTER>" & vbNewLine & _
                    "<H3>Alerts</H3>" & _
                    "<TABLE BORDER=0 WIDTH=60%><TR><TD>" & vbNewLine  & _
                    "An alert is generated if any of the above thresholds were broken during one of the time intervals analyzed. An alert condition of OK means that the counter instance was analyzed, but did not break any thresholds. The background of each of the values represents the highest priority threshold that the value broke. See the 'Thresholds Analyzed' section as the color key to determine which threshold was broken. A white background indicates that the value was not analyzed by any of the thresholds." & vbNewLine & _
                    "</TD></TR></TABLE>" & vbNewLine & _
                    "<TABLE BORDER=1 CELLPADDING=5>" & vbNewLine & _
                    "<TR><TH>Time</TH><TH>Condition</TH><TH>Counter</TH><TH>Min</TH><TH>Avg</TH><TH>Max</TH><TH>Hourly Trend</TH></TR>" & vbNewLine
                    Set oXMLAlerts = oXMLAnalysis.selectNodes("./ALERT")
                    For Each oXMLAlert in oXMLAlerts
                        sAnalysisOutput = sAnalysisOutput & "<TR><TD>" & oXMLAlert.GetAttribute("TIME") & "</TD><TD BGCOLOR=" & dQ & oXMLAlert.GetAttribute("CONDITIONCOLOR") & sDQ & ">" & oXMLAlert.GetAttribute("CONDITIONNAME") & "</TD><TD>" & oXMLAlert.GetAttribute("COUNTER") & "</TD><TD BGCOLOR=" & dQ & oXMLAlert.GetAttribute("MINCOLOR") & sDQ & ">" & DigitGrouping(oXMLAlert.GetAttribute("MIN")) & "</TD><TD BGCOLOR=" & dQ & oXMLAlert.GetAttribute("AVGCOLOR") & sDQ & ">" & DigitGrouping(oXMLAlert.GetAttribute("AVG")) & "</TD><TD BGCOLOR=" & dQ & oXMLAlert.GetAttribute("MAXCOLOR") & sDQ & ">" & DigitGrouping(oXMLAlert.GetAttribute("MAX")) & "</TD><TD BGCOLOR=" & dQ & oXMLAlert.GetAttribute("TRENDCOLOR") & sDQ & ">" & DigitGrouping(oXMLAlert.GetAttribute("TREND")) & "</TD></TR>" & vbNewLine
                    Next                
                    sAnalysisOutput = sAnalysisOutput & "</TABLE>" & _
                    "</CENTER>" & vbNewLine & _
                    "<A HREF=" & dQ & "#top" & dQ & ">Back to the top</A><BR>" & vbNewLine
                End If
            Next
            sAllAnalysisOutput = sAllAnalysisOutput & sAnalysisOutput & "" & vbNewLine
        Next
    sFooterOutput = "<BR><BR>"
    sDisclaimer = "<A NAME=" & dQ & "#" & ConvertStringForHref("Disclaimer") & dQ & "><B>Disclaimer:</B></A> This report was generated using the Performance Analysis of Logs (PAL) tool. The information provided in this report is provided " & chr(34) & "as is" & chr(34) & " and is intended for information purposes only. The authors and contributors of this tool take no responsibility for damages or losses incurred by use of this tool."
    sFooterOutput = sFooterOutput& sDisclaimer & _
    "</BODY></HTML>"
    
    sOutput = sHeaderOutput & sTOCOutput & sToolParameterOutput & sChronoOrderOutput & sAllAnalysisOutput & sFooterOutput
    
    Set oFSO = CreateObject("Scripting.FileSystemObject")
    Set oFile = oFSO.CreateTextFile(sHTMLOutputPath, True)
    If Err.number <> 0 OR oFSO.FileExists(sHTMLOutputPath) = False Then
        OutputToConsoleAndLog "Unable to create report file " & chr(34) & sHTMLOutputPath & chr(34) & ". Due to error: " & Err.number & ", " & Err.Description
        WScript.Quit
    Else
        oFile.Write sOutput        
    End If
    oFile.Close
    
    Dim objShell, strCommand
    Set objShell = createobject("Wscript.shell")
    If Instr(1, sHTMLOutputPath, chr(34), 1) > 0 Then
        strCommand = sHTMLOutputPath
    Else
        strCommand = chr(34) & sHTMLOutputPath & chr(34)
    End If
    
    objShell.Run strCommand
    Set objShell = Nothing    
    
End Sub

Function MakeAbsolutePathToRelativePath(sFilePath)
    'C:\Dev\PAL\Testing\HealthCheck_IIS_000001_PERFMON_LOG_ANALYSIS_Date_2007-06-06_17-46-13PM\image.gif
    Dim aFilePath, sNewFilePath, iImage, iDir
    aFilePath = Split(sFilePath, "\")
    iImage = UBound(aFilePath)
    iDir = UBound(aFilePath) - 1
    MakeAbsolutePathToRelativePath = aFilePath(iDir) & "\" & aFilePath(iImage)    
End Function

Function ConvertCounterToFileName(sCounter)
    Dim sCounterObject, sCounterName
    ' \\IDCWEB1\Processor(_Total)\% Processor Time
    sCounterObject = GetCounterObject(sCounter)
    sCounterName = GetCounterName(sCounter)
    ConvertCounterToFileName = sCounterObject & "_" & sCounterName
    ConvertCounterToFileName = Replace(ConvertCounterToFileName, "/", "_")
    ConvertCounterToFileName = Replace(ConvertCounterToFileName, "%", "Percent")
    ConvertCounterToFileName = Replace(ConvertCounterToFileName, " ", "_")
    ConvertCounterToFileName = Replace(ConvertCounterToFileName, ".", "")
    ConvertCounterToFileName = Replace(ConvertCounterToFileName, ":", "_")
    ConvertCounterToFileName = Replace(ConvertCounterToFileName, ">", "_")
    ConvertCounterToFileName = Replace(ConvertCounterToFileName, "<", "_")
End Function

Function ConvertStringForHref(ByVal sValue)
    sValue = Replace(sValue, "/", "_")
    sValue = Replace(sValue, "%", "Percent")
    sValue = Replace(sValue, " ", "")
    sValue = Replace(sValue, ".", "")
    ConvertStringForHref = sValue
End Function

Function GetCountersNeededForAnalysis
    '// Written by Ricardo Torre (ricardot@microsoft.com)
    Dim b, m
    Dim oAnalysis, oCounter, oChart
    Dim sName
    
    Dim Hash, HashFinal
    Set Hash = CreateObject("Scripting.Dictionary")
    Set HashFinal = CreateObject("Scripting.Dictionary")

    For Each oAnalysis in g_aData
        If oAnalysis.AllCountersFound = True Then
            For Each oCounter in oAnalysis.Counters
                For m = 0 to UBound(oCounter.MatchedCounters)
                    If Not Hash.Exists(oCounter.MatchedCounters(m).FullPath) Then
                        Hash.Add oCounter.MatchedCounters(m).FullPath, oCounter.MatchedCounters(m).FullPath
                    End If
                Next
            Next
            If oAnalysis.Charts(0).ChartTitle <> "NO CHARTS" Then
                For Each oChart in oAnalysis.Charts
                    For m = 0 to UBound(oChart.MatchedCounters)
                        IF Not Hash.Exists(oChart.MatchedCounters(m).FullPath) Then
                            Hash.Add oChart.MatchedCounters(m).FullPath, oChart.MatchedCounters(m).FullPath
                        End If
                    Next
                Next
            End If
        End If
    Next
  
    OutputToConsoleAndLog "   Looking for duplicate counters in counter list..."

    For Each sName in Hash.Items
        Dim instanceName
        instanceName = GetCounterInstance(sName)
        If (instanceName = "*") OR (instanceName = "") Then
            HashFinal.Add sName, sName
        Else
            If Not Hash.Exists(Replace(sName, "(" & instanceName & ")\", "(*)\")) Then
                HashFinal.Add sName, sName
            End If
        End If
    Next

    If HashFinal.Count = 0 Then
        OutputToConsoleAndLog "[GetCountersNeededForAnalysis] No counters in Threshold XML file found in the perfmon log."
        WScript.Quit
    End If

    GetCountersNeededForAnalysis = HashFinal.Items
End Function


Sub GenerateChart(sPerfmonLog, oChart, aPerfmonLogCounterList)
    Dim aCounters(), aTempOutputFiles, aFilteredCounters, aReversed
    Dim iCounterIndex, i, bExclude, oExclude
    
    'aFilteredCounters = FilterForCounterInstances(aPerfmonLogCounterList,oChart.DataSource)
    aFilteredCounters = oChart.MatchedCounters
    ' Remove excluded counters
    iCounterIndex = 0
    For i = 0 to UBound(aFilteredCounters)
        bExclude = False
        For Each oExclude in oChart.Exclusions
            If LCase(GetCounterInstance(aFilteredCounters(i).FullPath)) = LCase(oExclude) Then
                bExclude = True
                Exit For
            End If    
        Next
        If bExclude = False Then
            ReDim Preserve aCounters(iCounterIndex)
            aCounters(iCounterIndex) = aFilteredCounters(i).FullPath
            iCounterIndex = iCounterIndex + 1           
        End If              
    Next
    If iCounterIndex = 0 Then
        '// Either no counters are present or all counter instances were excluded.
        Dim aEmptyArray(0)
        aEmptyArray(0) = ""
        oChart.ImageFilePaths = aEmptyArray
        Exit Sub
    End If
    aTempOutputFiles = GenerateChartUsingLogParser(sPerfmonLog, oChart, aCounters, 0)
    ReDim Preserve aChartOutputFiles(iChartCounter)
    aChartOutputFiles(iChartCounter) = aTempOutputFiles
    iChartCounter = iChartCounter + 1
    aReversed = ReverseArrayOrder(aChartOutputFiles)
    oChart.ImageFilePaths = aReversed
End Sub

Function GenerateChartUsingLogParser(sPerfmonLog, oChart, aCounters, iStartingIndex)
    Dim sImageFileName, sImageFileNameShort
    Dim a, b, f, i, sInstanceForChart, sCounters, aTempOutputFiles
    Dim oLogQuery, oChartFormat, sQuery, oCSVFormat, RetVal
    Dim sInstanceA, sInstanceB, bDupInstances, sOrderBy
    Dim sCounterObject, iLocColon, iLocDollarSign, iLenSQLInstanceName
    
    ' Check for same instance names
    bDupInstances = False
    For a = 0 to UBound(aCounters)
        sInstanceA = GetCounterInstance(aCounters(a))
        For b = 0 to UBound(aCounters)
            If a = b Then
                b = b + 1
                If b > UBound(aCounters) Then
                    Exit For
                End If
            End If
            sInstanceB = GetCounterInstance(aCounters(b))
            If LCase(sInstanceA) = LCase(sInstanceB) Then
                bDupInstances = True
                Exit For
            End If
        Next
        If bDupInstances = True Then
            Exit For
        End If
    Next
    
    For i = iStartingIndex to UBound(aCounters)
        sInstanceForChart = GetCounterInstance(aCounters(i))
        If sInstanceForChart = "" Then
            sInstanceForChart = "Value"
            '// Special case for SQL named instances
            sCounterObject = GetCounterObject(aCounters(i))
            If LCase(sCounterObject) <> LCase(GetCounterObject(oChart.DataSource)) AND Instr(1, sCounterObject, "MSSQL", 1) > 0 Then
                '\\VSTP24\MSSQL$TP24PRD:Memory Manager\Target Server Memory(KB)
                iLocColon = Instr(sCounterObject, ":")
                iLocDollarSign = Instr(sCounterObject, "$") + 1
                iLenSQLInstanceName = iLocColon - iLocDollarSign 
                sInstanceForChart = Mid(sCounterObject, iLocDollarSign, iLenSQLInstanceName)
            End If
            If Instr(1, sCounterObject, "SQLServer:", 1) > 0 Then
                sInstanceForChart = "Default Instance"
            End If
            '// Continue normal execution            
        End If        
        If bDupInstances = True Then
            sInstanceForChart = GetCounterComputer(aCounters(i)) & "\" & sInstanceForChart
        End If        
        If Instr(sInstanceForChart, " ") > 0 Then
            sInstanceForChart = "[" & sInstanceForChart & "]"
        End If
        sInstanceForChart = Replace(sInstanceForChart, "#", "_")
        sInstanceForChart = Replace(sInstanceForChart, ".", "_")
        sInstanceForChart = Replace(sInstanceForChart, ":", "")
        If i = iStartingIndex Then
            sCounters = "AVG(TO_REAL([" & aCounters(i) & "])) AS " & sInstanceForChart
        Else        
            sCounters = sCounters & ", AVG(TO_REAL([" & aCounters(i) & "])) AS " & sInstanceForChart
        End If
        If i > (iStartingIndex + 18) Then            
            aTempOutputFiles = GenerateChartUsingLogParser(sPerfmonLog, oChart, aCounters, iStartingIndex + 19)
            ReDim Preserve aChartOutputFiles(iChartCounter)
            aChartOutputFiles(iChartCounter) = aTempOutputFiles
            iChartCounter = iChartCounter + 1
            Exit For
        End If
    Next
        
    sImageFileName = oChart.DataSource
    'sImageFileName = ConvertTextIntoFileName(oChart.ChartTitle) & "_" & ConvertCounterToFileName(sImageFileName) & "_" & iChartCounter & ".gif"
    sImageFileName = ConvertTextIntoFileName(oChart.ChartTitle) & "_" & iChartCounter & ".gif"
    sImageFileNameShort = g_ReportResourceDirNoSpaces & "\" & sImageFileName

    CheckToSeeIfLogParserIsInstalled
    
    ON ERROR RESUME NEXT
    Set oLogQuery = CreateObject("MSUtil.LogQuery")    
    Set oCSVFormat = CreateObject("MSUtil.LogQuery.CSVInputFormat")    
    ON ERROR GOTO 0
    
    oCSVFormat.iTsFormat = "MM/dd/yyyy hh:mm:ss.lll"
    Set oChartFormat = CreateObject("MSUtil.LogQuery.ChartOutputFormat")
    oChartFormat.chartTitle = oChart.ChartTitle
    oChartFormat.categories = oChart.Categories
    oChartFormat.chartType = oChart.ChartType
    oChartFormat.groupSize = oChart.GroupSize
    oChartFormat.legend = oChart.Legend
    oChartFormat.maxCategoryLabels = oChart.MaxCategoryLabels
    oChartFormat.oTsFormat = oChart.OTSFormat
    sOrderBy = GetOrderBy(oChart)        
    sQuery = FixLogParserEscapeSequences("SELECT QUANTIZE([" & GetFirstColumnFromCSV(sPerfmonLog) & "]," & g_Interval & ") AS " & g_IntervalDescription & ", " & sCounters & " INTO " & sImageFileNameShort & " FROM " & sPerfmonLog & " GROUP BY " & g_IntervalDescription & " ORDER BY " & g_IntervalDescription & " " & sOrderBy)
    OutputToConsoleAndLog "[CHART]" & sQuery
    ON ERROR RESUME NEXT
    oLogQuery.ExecuteBatch sQuery, oCSVFormat, oChartFormat
    If Err.number <> 0 Then
        OutputToConsoleAndLog "===============================ERROR========================================"
        OutputToConsoleAndLog "[GenerateChart]"
        OutputToConsoleAndLog "An error occurred while creating a chart using LogParser."
        OutputToConsoleAndLog " ChartTitle: " & oChart.ChartTitle
        OutputToConsoleAndLog " Categories: " & oChart.Categories
        OutputToConsoleAndLog " ChartType: " & oChart.ChartType
        OutputToConsoleAndLog " GroupSize: " & oChart.GroupSize
        OutputToConsoleAndLog " Legend: " & oChart.Legend
        OutputToConsoleAndLog " MaxCategoryLables: " & oChart.MaxCategoryLabels
        OutputToConsoleAndLog " OTSFormat: " & oChart.OTSFormat
        OutputToConsoleAndLog " Query: "
        OutputToConsoleAndLog " " & sQuery
        OutputToConsoleAndLog " Error Number: " & Err.number
        OutputToConsoleAndLog " Error Description: " & Err.Description
        If Instr(1, Err.Description, "Syntax Error: unknown field", 1) > 0 Then
            OutputToConsoleAndLog " Possible Cause: This will occur on occassion on Windows XP computers. These errors should not occur on Windows Vista."
        End If
        OutputToConsoleAndLog "============================================================================"
        Err.Clear
    End If
    ON ERROR GOTO 0
    sImageFileName = g_ReportResourceDir & "\" & sImageFileName
    GenerateChartUsingLogParser = sImageFileName
End Function

Sub CheckToSeeIfLogParserIsInstalled
    Dim oTestLogQuery, oTestCSVFormat, oTestChartFormat
    Dim objShell, strCommand, sHTMLOutputPath

    ON ERROR RESUME NEXT
    Set oTestLogQuery = CreateObject("MSUtil.LogQuery")    
    Set oTestCSVFormat = CreateObject("MSUtil.LogQuery.CSVInputFormat")
    If Err.number <> 0 Then
        OutputToConsoleAndLog "===============================ERROR========================================"
        OutputToConsoleAndLog " Microsoft LogParser 2.2 is required. Please install and try again."
        OutputToConsoleAndLog " LogParser can be downloaded from:"
        sHTMLOutputPath = "http://www.microsoft.com/downloads/details.aspx?FamilyID=890cd06b-abf8-4c25-91b2-f8d975cf8c07&displaylang=en"
        OutputToConsoleAndLog " " & sHTMLOutputPath            
        OutputToConsoleAndLog "============================================================================"
        Set objShell = createobject("Wscript.shell")		
        strCommand = sHTMLOutputPath
        objShell.Run strCommand
        WScript.Quit
    End If
    ON ERROR GOTO 0
    
    ON ERROR RESUME NEXT
    Set oTestChartFormat = CreateObject("MSUtil.LogQuery.ChartOutputFormat")
    oTestChartFormat.chartTitle = "Test"    
    If Err.number <> 0 Then
        If Instr(1,Err.Description,"requires a licensed Microsoft Office Chart Web Component",1) > 0 Then
            OutputToConsoleAndLog "===============================ERROR========================================"
            OutputToConsoleAndLog " Microsoft Office 2003 Web Components is required."
            OutputToConsoleAndLog " Please install and try again."
            OutputToConsoleAndLog " Microsoft Office 2003 Web Components can be downloaded from:"
            sHTMLOutputPath = "http://www.microsoft.com/downloads/details.aspx?FamilyID=7287252c-402e-4f72-97a5-e0fd290d4b76&DisplayLang=en"
            OutputToConsoleAndLog " " & sHTMLOutputPath            
            OutputToConsoleAndLog "============================================================================"
            Set objShell = createobject("Wscript.shell")		
            strCommand = sHTMLOutputPath
            objShell.Run strCommand
            WScript.Quit
        Else
            OutputToConsoleAndLog "ERROR [CheckToSeeIfLogParserIsInstalled]: " & Err.number & ";" & Err.Description
            WScript.Quit
        End If
    End If
    ON ERROR GOTO 0
End Sub

Function ConvertTextIntoFileName(sText)
    Dim sNewText
    sNewText = sText
    sNewText = Replace(sNewText, "/", "_")
    sNewText = Replace(sNewText, "\", "")
    sNewText = Replace(sNewText, ":", "")
    sNewText = Replace(sNewText, "(", "")
    sNewText = Replace(sNewText, ")", "")
    sNewText = Replace(sNewText, "*", "")
    sNewText = Replace(sNewText, "%", "Percent")
    sNewText = Replace(sNewText, " ", "_")
    sNewText = Replace(sNewText, ".", "")
    sNewText = Replace(sNewText, "<", "")
    sNewText = Replace(sNewText, ">", "")
    ConvertTextIntoFileName = sNewText
End Function


'''''''''''''''''''''''''''
'
' DetectExeType
'
' This can detect the type of exe the
' script is running under and warns the
' user of the popups.
'
'''''''''''''''''''''''''''
Sub DetectExeType()
        Dim ScriptHost
        Dim ShellObject

        Dim CurrentPathExt
        Dim EnvObject

        Dim RegCScript
        Dim RegPopupType ' This is used to set the pop-up box flags.
                                                ' I couldn't find the pre-defined names
        RegPopupType = 32 + 4

        On Error Resume Next

        ScriptHost = WScript.FullName
        ScriptHost = Right(ScriptHost, Len(ScriptHost) - InStrRev(ScriptHost, "\"))

        If (UCase(ScriptHost) = "WSCRIPT.EXE") Then
                OutputToConsoleAndLog ("This script does not work with WScript.")

                ' Create a pop-up box and ask if they want to register cscript as the default host.
                Set ShellObject = WScript.CreateObject("WScript.Shell")
                ' -1 is the time to wait.  0 means wait forever.
                RegCScript = ShellObject.PopUp("Would you like to register CScript as your default host for VBscript?", 0, "Register CScript", RegPopupType)
                                                                                
                If (Err.Number <> 0) Then
                        ReportError ()
                        OutputToConsoleAndLog "To run this script using CScript, type: ""CScript.exe " & WScript.ScriptName & """"
                        WScript.Quit (GENERAL_FAILURE)
                        WScript.Quit (Err.Number)
                End If

                ' Check to see if the user pressed yes or no.  Yes is 6, no is 7
                If (RegCScript = 6) Then
                        ShellObject.RegWrite "HKEY_CLASSES_ROOT\VBSFile\Shell\Open\Command\", "%WINDIR%\System32\CScript.exe //nologo ""%1"" %*", "REG_EXPAND_SZ"
                        ShellObject.RegWrite "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\VBSFile\Shell\Open\Command\", "%WINDIR%\System32\CScript.exe //nologo ""%1"" %*", "REG_EXPAND_SZ"
                        ' Check if PathExt already existed
                        CurrentPathExt = ShellObject.RegRead("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\PATHEXT")
                        If Err.Number = &H80070002 Then
                                Err.Clear
                                Set EnvObject = ShellObject.Environment("PROCESS")
                                CurrentPathExt = EnvObject.Item("PATHEXT")
                        End If

                        ShellObject.RegWrite "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\PATHEXT", CurrentPathExt & ";.VBS", "REG_SZ"

                        If (Err.Number <> 0) Then
                                ReportError ()
                                OutputToConsoleAndLog "Error Trying to write the registry settings!"
                                WScript.Quit (Err.Number)
                        Else
                                OutputToConsoleAndLog "Successfully registered CScript"
                        End If
                Else
                        OutputToConsoleAndLog "To run this script type: ""CScript.Exe adsutil.vbs <cmd> <params>"""
                End If

                Dim ProcString
                Dim ArgIndex
                Dim ArgObj
                Dim Result

                ProcString = "Cscript //nologo " & WScript.ScriptFullName

                Set ArgObj = WScript.Arguments

                For ArgIndex = 0 To ArgCount - 1
                        ProcString = ProcString & " " & Args(ArgIndex)
                Next

                'Now, run the original executable under CScript.exe
                Result = ShellObject.Run(ProcString, 0, True)

                WScript.Quit (Result)
        End If

End Sub

Function DigitGrouping(ByVal iNum)
    Dim sLocalizedDecimal, sLocalizedThousandsSeparator
    Dim iLocDecimal, iDecimalCount
    If IsNumeric(iNum) = False OR IsNull(iNum) = True Then
        DigitGrouping = iNum
        Exit Function
    End If    
    sLocalizedDecimal = GetLocalizedDecimalSeparator()
    sLocalizedThousandsSeparator = GetLocalizedThousandsSeparator()
    'Get the location of the decimal
    iLocDecimal = InStr(1, iNum, sLocalizedDecimal)
    'initialize decimal count to default=0
    iDecimalCount = 0
    If iLocDecimal > 0 then 
        'get the number of decimal places
        iDecimalCount = Len(Right(iNum, Len(iNum) - iLocDecimal))
    end if    
    DigitGrouping = FormatNumber(iNum, iDecimalCount)    
End Function

Function GetLocalizedDecimalSeparator()    
    Dim sDecimal
    sDecimal = ""
    sDecimal = GetRegistryKeyValue("HKCU\Control Panel\International\sDecimal")
    If sDecimal = "" Then
        GetLocalizedDecimalSeparator = "."
    Else
        GetLocalizedDecimalSeparator = sDecimal
    End If    
End Function

Function GetLocalizedThousandsSeparator()
    Dim sThousandsSeparator
    sThousandsSeparator = ""
    sThousandsSeparator = GetRegistryKeyValue("HKCU\Control Panel\International\sThousand")
    If sThousandsSeparator = "" Then
        GetLocalizedThousandsSeparator = ","
    Else
        GetLocalizedThousandsSeparator = sThousandsSeparator
    End If
End Function

Function GetRegistryKeyValue(sRegPath)
    Dim objShell
    ON ERROR RESUME NEXT
    Set objShell = WScript.CreateObject("WScript.Shell")
    GetRegistryKeyValue = objShell.RegRead(sRegPath)
    ON ERROR GOTO 0
End Function

'Function DigitGrouping(ByVal iNum)
'    Dim iLocPeriod, sLeftOfPeriod, sRightOfPeriod
'    Dim a, i, sDigitsToProcess, aDigits(), bPositive
'    ' 1234567890.1234567890

'    ' Making sure the argument is numeric and not NULL
'    If IsNumeric(iNum) = False OR IsNull(iNum) = True Then
'        DigitGrouping = iNum
'        Exit Function
'    End If
'    
'    ' Check to see if it is over 1000 to see if we need to process it.
'    ' Check if it is scentific notation. If so, then don't process it.
'    If Abs(iNum) < 1000 OR Instr(1, iNum, ",") > 0 OR  iNum > 999999999999999 Then
'        DigitGrouping = iNum
'        Exit Function        
'    End If        
'        
'    ' Determining if the number is positive or negative.
'    If iNum > 0 Then
'        bPositive = True
'    Else
'        bPositive = False
'    End If
'        
'    iLocPeriod = Instr(1, iNum,".")
'    If iLocPeriod > 0 Then
'        sLeftOfPeriod = Mid(iNum, 1, iLocPeriod - 1)
'        sRightOfPeriod = Mid(iNum,iLocPeriod)
'    Else
'        sLeftOfPeriod = iNum
'        sRightOfPeriod = ""
'    End If
'    
'    If bPositive = False Then
'        'strip off negative sign
'        sLeftOfPeriod = Mid(sLeftOfPeriod, 2)
'    End If
'    
'    ' Break up the number into an array
'    a = 0
'    sDigitsToProcess = sLeftOfPeriod
'    For i = 3 to Len(sLeftOfPeriod) Step 3
'        ReDim Preserve aDigits(a)
'        aDigits(a) = Right(sDigitsToProcess,3)
'        a = a + 1
'        sDigitsToProcess = Mid(sDigitsToProcess, 1, Len(sDigitsToProcess) - 3)
'        
'        If Len(sDigitsToProcess) <> 0 AND Len(sDigitsToProcess) < 3 AND sDigitsToProcess <> "-" Then
'            ReDim Preserve aDigits(a)
'            aDigits(a) = sDigitsToProcess
'            a = a + 1            
'        End If      
'    Next
'    
'    ' Test to see if the array exists
'    ON ERROR RESUME NEXT
'    i = UBound(aDigits)
'    If Err.number <> 0 Then
'        OutputToConsoleAndLog "******************"
'        OutputToConsoleAndLog " An error occurred in [DigitGrouping()]"
'        OutputToConsoleAndLog " Error Number: " & err.number
'        OutputToConsoleAndLog " Error Description: " & err.Description
'        OutputToConsoleAndLog "  iNum: " & iNum
'        OutputToConsoleAndLog "******************"
'        DigitGrouping = iNum
'        Exit Function
'    End If
'    ON ERROR GOTO 0
'    
'    ' Add commas for each of the thousands group    
'    sLeftOfPeriod = ""
'    For i = UBound(aDigits) to 0 Step - 1
'        sLeftOfPeriod = sLeftOfPeriod & aDigits(i) & ","
'    Next

'    sLeftOfPeriod = Left(sLeftOfPeriod, Len(sLeftOfPeriod) - 1)

'    If bPositive = False Then
'        sLeftOfPeriod = "-" & sLeftOfPeriod
'    End If
'    DigitGrouping = sLeftOfPeriod & sRightOfPeriod
'    
'End Function

Function GenerateArrayOfTimeIntervals(sPerfmonLog, sDateTimeFieldName, iInterval)
    Dim oLogQuery, oCSVFormat,oRecordSet, oRecord
    Dim aTime(), sQuery, i
    Dim dQ
    
    CheckToSeeIfLogParserIsInstalled   
    
    Set oLogQuery = CreateObject("MSUtil.LogQuery")
    Set oCSVFormat = CreateObject("MSUtil.LogQuery.CSVInputFormat")
    oCSVFormat.iTsFormat = "MM/dd/yyyy hh:mm:ss.lll"
    
    dQ = chr(34)    
    sQuery = FixLogParserEscapeSequences("SELECT QUANTIZE([" & sDateTimeFieldName & "], " & iInterval & ") AS Interval FROM " & g_FilteredPerfmonLogFile & " GROUP BY Interval")
    OutputToConsoleAndLog sQuery
    ON ERROR RESUME NEXT
    Set oRecordSet = oLogQuery.Execute(sQuery, oCSVFormat)
    If Err.number <> 0 Then
        OutputToConsoleAndLog "[GenerateArrayOfTimeIntervals] ERROR Number: " & Err.number
        OutputToConsoleAndLog "[GenerateArrayOfTimeIntervals] ERROR Description: " & Err.Description
        PALErrHandler Err
        Err.Clear
        Exit Function
    End If
    ON ERROR GOTO 0
    i = 0
    Do Until oRecordSet.atEnd
        Set oRecord = oRecordSet.getRecord        
        'OutputToConsoleAndLog "[QueryCounterInstanceData] Raw Data: " & oRecord.GetValue("avg")
        ReDim Preserve aTime(i)
        aTime(i) = CDate(oRecord.GetValue("Interval"))
        i = i + 1        
        oRecordSet.MoveNext
    Loop
    GenerateArrayOfTimeIntervals = aTime
End Function

Function IsThereIllegalCounterInstanceAssignment(oAnalysis)
    Dim sInstance, sOtherInstance, oCounter, oOtherCounter
    Dim oInstance, oOtherInstance, bFound
    IsThereIllegalCounterInstanceAssignment = False
    For Each oCounter in oAnalysis.Counters
        sInstance = LCase(GetCounterInstance(oCounter.Name))
        For Each oOtherCounter in oAnalysis.Counters
            sOtherInstance = LCase(GetCounterInstance(oOtherCounter.Name))
            
            SELECT CASE sInstance
                CASE "*"
                    ' All *'s are okay
                    ' Added in v1.1.7
                    SELECT CASE sOtherInstance
                        CASE ""
                            ' Okay
                        CASE "*"
                            If oCounter.Name <> oOtherCounter.Name Then
                                For Each oInstance in oCounter.Instances
                                    For Each oOtherInstance in oOtherCounter.Instances
                                        If LCase(GetCounterInstance(oInstance.Name)) = LCase(GetCounterInstance(oOtherInstance.Name)) Then
                                            bFound = True
                                            Exit For
                                        End If
                                    Next
                                Next
                                If bFound = False Then
                                    IsThereIllegalCounterInstanceAssignment = True
                                    Exit Function
                                End If                                
                            End If                                                                
                    END SELECT
                CASE ""
                    SELECT CASE sOtherInstance
                        CASE ""
                            ' Okay
                        CASE "*"
                            ' // Changed in v1.1.7
                            ' removed Illegal instance assignment                            
                            ' removed IsThereIllegalCounterInstanceAssignment = True
                            ' removed Exit Function
                            ' Okay
                        CASE Else
                            'Okay                        
                    END SELECT
                CASE Else
                    SELECT CASE sOtherInstance
                        CASE ""
                            ' Okay
                        CASE "*"
                            ' Okay
                        CASE Else
                            'Okay                        
                    END SELECT                
            END SELECT            
        Next
    Next    
End Function

Function ProcessAnalysisIntervalIntoHTML
    Dim iInterval, sInterval
    
    iInterval = g_Interval
    
    If iInterval > 60 Then
        iInterval = Int(iInterval / 60)
        sInterval = iInterval & " minute(s)"
        If iInterval > 60 Then
            sInterval = Int(iInterval / 60)
            sInterval = iInterval & " hour(s)"    
        End If
    Else
        sInterval = iInterval & " second(s)"
    End If

    ProcessAnalysisIntervalIntoHTML = sInterval
End Function

Function AskAQuestion(oQuestion)
    Dim sAnswer, sArgNote, sQuestion
    sArgNote = "Named Argument: " & oQuestion.QuestionVarName
    sQuestion = sArgNote & chr(10) & chr(10) & oQuestion.Question
    SELECT CASE oQuestion.DataType
        CASE "string"            
            sAnswer = InputBox(sQuestion, "PAL.vbs", oQuestion.DefaultValue)
            If sAnswer = "" Then
                'Set oQuestion = AskAQuestion(oQuestion)
                OutputToConsoleAndLog "Ending execution. User initiated cancel."
                WScript.Quit
            Else
                oQuestion.Answer = sAnswer
            End If            
        CASE "boolean"
            If LCase(oQuestion.DefaultValue) = "true" Then
                sAnswer = MsgBox(sQuestion, vbYesNo + vbDefaultButton1, "PAL.vbs")
            Else
                sAnswer = MsgBox(sQuestion, vbYesNo + vbDefaultButton2, "PAL.vbs")
            End If            
            If sAnswer = vbYes Then
                oQuestion.Answer = True
            Else
                oQuestion.Answer = False
            End If
            If sAnswer = "" Then
                WScript.Quit
            End If
    END SELECT
    Set AskAQuestion = oQuestion
End Function

Function GetFileNameFromPath(sPath)
    Dim aPath
    aPath = Split(sPath, "\")
    GetFileNameFromPath = aPath(UBound(aPath))    
End Function

Function OpenFileForWriting(sPath)
    ' Returns oFile object ForWriting
    Dim oFile, oFSO
    Set oFSO = CreateObject("Scripting.FileSystemObject")
    Set oFile = oFSO.CreateTextFile(sPath, True)    
    Set OpenFileForWriting = oFile
End Function

Sub StartDebugLogFile()
    Set g_oFileDebugLog = OpenFileForWriting(g_sFileDebugLogPath)
End Sub

Sub EndDebugLogFile()
    g_oFileDebugLog.Close    
End Sub

Sub OutputToConsoleAndLog(sText)
    WScript.Echo sText
    g_oFileDebugLog.WriteLine "[" & Now() & "] " & sText
End Sub

Sub ExecuteThresholdCode(oAnalysis, sCode, sOriginalCode, dctVariables, oCounter, oThreshold, aSI)
    Dim bIsNullData
    IsMinThresholdBroken = False
    IsAvgThresholdBroken = False
    IsMaxThresholdBroken = False
    IsTrendThresholdBroken = False
    
    bIsNullData = False
    bIsNullData = CheckForNullDataDictionary(dctVariables)
    
    If bIsNullData = True Then
        ' Null data detected. Skipping threshold execution.
        'OutputToConsoleAndLog "Info: Some null data detected. Small amounts of null data is normal."
        Exit Sub
        g_iNullDataCount = g_iNullDataCount + 1
    End If
    ON ERROR RESUME NEXT
    Err.Clear
    '// Read the sCode text and execute as inline code.
'    OutputToConsoleAndLog "[ExecuteThresholdCode]"
'    OutputToConsoleAndLog " Execute Code: " & sCode
'    OutputToConsoleAndLog sCode
    Execute sCode
    If Err.number <> 0 Then
        OutputToConsoleAndLog "===============================ERROR========================================"
        OutputToConsoleAndLog "[ExecuteThresholdCode]"
        OutputToConsoleAndLog " An error occurred while evaluating threshold code"
        OutputToConsoleAndLog " Analysis: " & oAnalysis.Name
        OutputToConsoleAndLog " Counter: " & oCounter.Name
        OutputToConsoleAndLog " Threshold: " & oThreshold.Name
        OutputToConsoleAndLog " " & oCounter.MinVarName & ": " & dctVariables(oCounter.MinVarName)
        OutputToConsoleAndLog " " & oCounter.AvgVarName & ": " & dctVariables(oCounter.AvgVarName)
        OutputToConsoleAndLog " " & oCounter.MaxVarName & ": " & dctVariables(oCounter.MaxVarName)
        OutputToConsoleAndLog " " & oCounter.TrendVarname & ": " & dctVariables(oCounter.TrendVarname)
        For s = 0 to UBound(aSI,2)
            OutputToConsoleAndLog " " & oAnalysis.Counters(aSI(0,s)).MinVarName & ": " & dctVariables(oAnalysis.Counters(aSI(0,s)).MinVarName)
            OutputToConsoleAndLog " " & oAnalysis.Counters(aSI(0,s)).AvgVarName & ": " & dctVariables(oAnalysis.Counters(aSI(0,s)).AvgVarName)
            OutputToConsoleAndLog " " & oAnalysis.Counters(aSI(0,s)).MaxVarName & ": " & dctVariables(oAnalysis.Counters(aSI(0,s)).MaxVarName)
            OutputToConsoleAndLog " " & oAnalysis.Counters(aSI(0,s)).TrendVarName & ": " & dctVariables(oAnalysis.Counters(aSI(0,s)).TrendVarName)
        Next
        OutputToConsoleAndLog " Error Number: " & Err.number
        OutputToConsoleAndLog " Error Description: " & Err.Description
        OutputToConsoleAndLog " Original Code:"
        OutputToConsoleAndLog sOriginalCode
        OutputToConsoleAndLog "---------------------------"
        OutputToConsoleAndLog " Actual Code:"
        OutputToConsoleAndLog sCode        
        OutputToConsoleAndLog "============================================================================"
        'WScript.Quit
    End If
    Err.Clear
    ON ERROR GOTO 0
End Sub

Function GetOrderBy(oChart)
    '// Returns the ORDER BY string
    ON ERROR RESUME NEXT
    If UCase(oChart.OrderBy) = "DESC" Then
        GetOrderBy = "DESC"
    Else
        GetOrderBy = "ASC"
    End If
    If Err.number <> 0 Then
        '// Likely the oChart.OrderBy property doesn't exist, so default to ASC
        GetOrderBy = "ASC"
    End If
    Err.Clear
    ON ERROR GOTO 0
End Function

Sub AnalyzeTheInterval()
    AutoDetectTheBestAnalysisInterval
    GetTimeIntervals
End Sub

Function ReverseArrayOrder(aArray)
    '// Reverses the order of an array
    Dim aTemp(), x, y    
    y = UBound(aArray)
    ReDim aTemp(y)    
    For x = 0 to UBound(aArray)
        aTemp(x) = aArray(y)
        y = y - 1      
    Next
    ReverseArrayOrder = aTemp
End Function

Function CheckForNullDataDictionary(dctToAnalyze)
    Dim sKey
    '// Returns True if Null or unusable data is contained.    
    CheckForNullDataDictionary = False
    For Each sKey in dctToAnalyze.Keys
        If IsNull(dctToAnalyze(sKey)) = True Or dctToAnalyze(sKey) = "-" Then
            CheckForNullDataDictionary = True
            Exit Function
        Else
            If (sKey = "CounterPath") OR (sKey = "CounterComputer") OR (sKey = "CounterObject" )OR (sKey = "CounterName") OR (sKey = "CounterInstance") Then
                ' Do Nothing
            Else
                If IsNumeric(dctToAnalyze(sKey)) = False Then
                    CheckForNullDataDictionary = True
                    Exit Function
                Else
                    CheckForNullDataDictionary = False
                End If            
            End If
        End If
    Next    
End Function

Sub GetUserTempDirectory()
    Dim WshShell
    set WshShell = WScript.CreateObject("WScript.Shell")
    g_UserTempDirectory = WshShell.ExpandEnvironmentStrings("%TEMP%")
End Sub

Sub SetTempFilesToTempDirectoryPath()
    Dim sGUID, bRetVal, sUniqueTempDirectory
    sGUID = g_GUID
    sUniqueTempDirectory = g_UserTempDirectory & "\" & sGUID
    bRetVal = CreateDirectory(sUniqueTempDirectory, 10)
    If bRetVal = False Then
        OutputToConsoleAndLog "Unable to create temporary directory " & chr(34) & sUniqueTempDirectory & chr(34)
        WScript.Quit
    End If
    g_WorkingDirectory = sUniqueTempDirectory
    g_FilteredPerfmonLogCounterListFile = sUniqueTempDirectory & "\" & gc_FilteredPerfmonLogCounterListFile    
    g_FilteredPerfmonLogFile = sUniqueTempDirectory & "\" & gc_FilteredPerfmonLogFile
    g_MergedPerfmonLogFile = sUniqueTempDirectory & "\" & gc_MergedPerfmonLogFile
    g_OriginalRealCounterList = sUniqueTempDirectory & "\" & gc_OriginalRealCounterList
    g_sFileDebugLogPath = g_UserTempDirectory & "\" & sGUID & gc_sFileDebugLogPath
End Sub

Function CalculateStdDeviation(arr) ' As Double
    Dim bSampleStdDev, bIgnoreEmpty
    bSampleStdDev = False
    bIgnoreEmpty = True
    ' The standard deviation of an array of any type
    '
    ' if the second argument is True or omitted,
    ' it evaluates the standard deviation of a sample,
    ' if it is False it evaluates the standard deviation of a population
    '
    ' if the third argument is True or omitted, Empty values aren't accounted for

    Dim sum 'As Double
    Dim sumSquare 'As Double
    Dim value 'As Double
    Dim count 'As Long
    Dim index 'As Long
    Dim IgnoreEmpty, bAllNull

    If TestForInitializedArray(arr) = False Then
        CalculateStdDeviation = "-"
        Exit Function
    End If

    ' evaluate sum of values
    ' if arr isn't an array, the following statement raises an error
    bAllNull = True
    For index = LBound(arr) To UBound(arr)
        value = arr(index)
        ' skip over non-numeric values
        If IsNumeric(value) Then
            ' skip over empty values, if requested
            If Not (IgnoreEmpty And IsEmpty(value)) Then
                ' add to the running total
                count = count + 1
                sum = sum + value
                sumSquare = sumSquare + value * value
                bAllNull = False
            End If
         End If
    Next
    
    ' evaluate the result
    ' use (Count-1) if evaluating the standard deviation of a sample
    If bAllNull = True Then
        CalculateStdDeviation = "-"
    Else
        If sum > 0 Then
            If bSampleStdDev = True AND count > 1 Then
                CalculateStdDeviation = Sqr(Abs((sumSquare - (sum * sum / count)) / (count - 1)))
            Else
                CalculateStdDeviation = Sqr(Abs((sumSquare - (sum * sum / count)) / count))
            End If
        Else
            CalculateStdDeviation = 0 
        End If
    End If
End Function

Function CalculatePercentile(aNumbers, iPercentile) ' As Double
    Dim iAvg, i, aNonDeviatedNumbers(), iIndex, iDeviation, iCount, iLBound, iUBound
    Dim aSortedNumbers
    
    iAvg = CalculateAverage(aNumbers)
    If iAvg = "-" Then
        CalculatePercentile = "-"
        Exit Function
    End If
    iDeviation = iAvg * (iPercentile / 100)
    iCount = UBound(aNumbers) + 1
    iLBound = iCount - CInt((iPercentile / 100) * iCount)
    iUBound = CInt((iPercentile / 100) * iCount)    
    aSortedNumbers = ArraySort(aNumbers)    
    iIndex = 0
    If iUBound > UBound(aSortedNumbers) Then
        iUBound = UBound(aSortedNumbers)    
    End If    
    If iLBound = iUBound Then
        CalculatePercentile = aSortedNumbers(iLBound)
        Exit Function
    End If
    For i = iLBound to iUBound
        ReDim Preserve aNonDeviatedNumbers(iIndex)
        aNonDeviatedNumbers(iIndex) = aSortedNumbers(i)
        iIndex = iIndex + 1    
    Next    
    If iIndex > 0 Then
        CalculatePercentile = CalculateAverage(aNonDeviatedNumbers)
    Else
        CalculatePercentile = "-"
    End If
End Function

Function ArraySort(ByVal arr)
	dim front, back, loc, temp, arrsize

	arrsize = ubound(arr)
	for front = 0 to arrsize - 1
		loc = front
		for back = front to arrsize
			if isnumeric(arr(loc)) and isnumeric(arr(back)) then
				if cdbl(arr(loc)) > cdbl(arr(back)) then
					loc = back
				end if
			else
				if arr(loc) > arr(back) then
					loc = back
				end if
			end if
		next
		temp = arr(loc)
		arr(loc) = arr(front)
		arr(front) = temp
	next
	ArraySort = arr
End Function

Function GetValueFromXMLInputFile(sXMLInputFilePath, sArgName)
    Dim oXMLInputDoc, oXMLRoot, oNodeList, oNode, sNodeName

    '<PAL>
    '  <INPUT NAME="NumberOfProcessors" VALUE="4"/>
    '  <INPUT NAME="ThreeGBSwitch" VALUE="True"/>
    '  <INPUT NAME="THRESOLDFILE" VALUE="SystemOverview.xml"/>
    '  <INPUT NAME="LOG" VALUE="Test.blg"/>
    '</PAL>
    
    Set oXMLInputDoc = CreateObject("Msxml2.DOMDocument")
    oXMLInputDoc.async = False
    oXMLInputDoc.Load sXMLInputFilePath
    Set oXMLRoot = oXMLInputDoc.documentElement
    ON ERROR RESUME NEXT
	Set oNodeList = oXMLRoot.selectNodes("//INPUT")
	If Err.number <> 0 Then
	    Exit Function
	End If
	ON ERROR GOTO 0
	For Each oNode in oNodeList
	    If LCase(oNode.GetAttribute("NAME")) = LCase(sArgName) Then
	        GetValueFromXMLInputFile = oNode.GetAttribute("VALUE")
	        Exit Function
	    End If	    
	Next
End Function

Sub ProcessInputXML(sXMLInputFilePath)
    g_PerfmonLog = GetValueFromXMLInputFile(sXMLInputFilePath, "LOG")
    g_XMLThresholdFile = GetValueFromXMLInputFile(sXMLInputFilePath, "THRESHOLDFILE")    
    g_Interval = GetValueFromXMLInputFile(sXMLInputFilePath, "INTERVAL")
    g_IsOutputXML = GetValueFromXMLInputFile(sXMLInputFilePath, "ISOUTPUTXML")
    g_IsOutputHTML = GetValueFromXMLInputFile(sXMLInputFilePath, "ISOUTPUTHTML")
End Sub

Sub EndingOutput()
    OutputToConsoleAndLog "For more details, see the log file located at: " & chr(34) & g_sFileDebugLogPath & chr(34)
    OutputToConsoleAndLog ""
    OutputToConsoleAndLog "If the report does not automatically display, then look for it in one of your existing Internet Explorer instances or in the PAL Reports directory in your My Documents folder. Note: If you specified a different output directory, then Windows Vista will automatically deny access with no notification to the PAL tool. To get around this, run the PAL tool under elevated privileges."
    OutputToConsoleAndLog ""
End Sub

Function GetDirectoryShortName(sDir)
   Dim fso, d, s
   Set fso = CreateObject("Scripting.FileSystemObject")
   Set d = fso.GetFolder(sDir)
   GetDirectoryShortName = d.ShortPath
End Function

Function CompareCounterPathToExpression(ByVal sCounterPath, ByVal sPattern, ByVal sCounterPathPart, ByVal IsRegularExpression)
    Dim sCounterString, sCounterPattern
    CompareCounterPathToExpression = False
    Select Case sCounterPathPart
        Case "COUNTER_COMPUTER"
            sCounterString = GetCounterComputer(sCounterPath)
            sCounterPattern = GetCounterComputer(sPattern)
            If sCounterPattern = "*" OR sCounterString = "" OR LCase(sCounterString) = LCase(sCounterPattern) Then
                CompareCounterPathToExpression = True
                Exit Function
            End If            
        Case "COUNTER_OBJECT"
            sCounterString = GetCounterObject(sCounterPath)
            sCounterPattern = GetCounterObject(sPattern)
            If sCounterPattern = "*" OR LCase(sCounterString) = LCase(sCounterPattern) Then
                CompareCounterPathToExpression = True
                Exit Function
            End If            
        Case "COUNTER_NAME"            
            sCounterString = GetCounterName(sCounterPath)
            sCounterPattern = GetCounterName(sPattern)            
            If sCounterPattern = "*" OR LCase(sCounterString) = LCase(sCounterPattern) Then
                CompareCounterPathToExpression = True
                Exit Function
            End If            
        Case "COUNTER_INSTANCE"
            sCounterString = GetCounterInstance(sCounterPath)
            sCounterPattern = GetCounterInstance(sPattern)        
            If sCounterPattern = "*" OR sCounterString = "" OR LCase(sCounterString) = LCase(sCounterPattern) Then
                CompareCounterPathToExpression = True
                Exit Function
            End If            
    End Select
    If IsRegularExpression = True Then
        CompareCounterPathToExpression = RegExpCompare(sCounterString, sCounterPattern)
    End If
End Function

Function RegExpCompare(sString, sPattern)
    'g_iBeginFunctionTime = Timer()
    Dim regEx, Match, Matches   ' Create variable.
    Dim bFound
    Set regEx = New RegExp   ' Create a regular expression.
    regEx.Pattern = sPattern   ' Set pattern.
    regEx.IgnoreCase = True   ' Set case insensitivity.
    regEx.Global = False   ' Set global applicability.
    RegExpCompare = regEx.Test(sString)   ' Execute search.
'    Set Matches = regEx.Execute(sString)   ' Execute search.
'    bFound = False
'    For Each Match in Matches   ' Iterate Matches collection.
'        bFound = True
'    Next
'    If bFound = True Then
'        RegExpCompare = True
'    Else
'        RegExpCompare = False
'    End If
    'g_iEndFunctionTime = Timer()
    'CalculateDurationOfTimer "RegExpCompare", g_iBeginFunctionTime, g_iEndFunctionTime
End Function

Function ConvertStringToArray(sText)
    Dim aStringArray(), iLen, i 
    iLen = Len(sText)
    ReDim aStringArray(iLen-1)    
    For i = 0 to iLen-1
        aStringArray(i) = Mid(sText, i+1, 1)
    Next           
    ConvertStringToArray = aStringArray    
End Function

Function ConstructMatchedCounterObject(sFullCounterPath)
    Dim oMatchedCounter
    Set oMatchedCounter = New MatchedCounterObject
    oMatchedCounter.FullPath = sFullCounterPath
    oMatchedCounter.CounterServerName = GetCounterComputer(sFullCounterPath)
    oMatchedCounter.CounterObject = GetCounterObject(sFullCounterPath)
    oMatchedCounter.CounterName = GetCounterName(sFullCounterPath)
    oMatchedCounter.CounterInstance = GetCounterInstance(sFullCounterPath)    
    Set ConstructMatchedCounterObject = oMatchedCounter
End Function

Sub CalculateDurationOfTimer(sDescription, iBeginTime, iEndTime)
    WScript.Echo "[" & sDescription & "] Execution Time in ms: " & iEndTime - iBeginTime
End Sub

Sub ProcessStatistics()
    Dim oAnalysis, iNumOfAnalysesProcessed, iNumOfAnalysesInThresholdFile    
    iNumOfAnalysesProcessed = 0
    For Each oAnalysis in g_aData
        If oAnalysis.AllCountersFound = True Then
            iNumOfAnalysesProcessed = iNumOfAnalysesProcessed + 1
        End If
        iNumOfAnalysesInThresholdFile = iNumOfAnalysesInThresholdFile + 1
    Next   
'    iNumOfAnalysesInThresholdFile = 0
'    For Each oAnalysis in g_XMLRoot.SelectNodes("//ANALYSIS")
'        iNumOfAnalysesInThresholdFile = iNumOfAnalysesInThresholdFile + 1
'    Next
    WScript.Echo "Analyses in Threshold File Processed: " & iNumOfAnalysesProcessed & "/" & iNumOfAnalysesInThresholdFile
End Sub

Function ReverseAlertsArrayOrder(aAlerts)
    Dim NewAlertsArray()
    Dim i, iNew
    iNew = 0
    ON ERROR RESUME NEXT
    For i = UBound(aAlerts) to 0 Step -1
        ReDim Preserve NewAlertsArray(iNew)
        Set NewAlertsArray(iNew) = aAlerts(i)
        iNew = iNew + 1
    Next
    If Err.number <> 0 Then
        ReverseAlertsArrayOrder = NewAlertsArray
    Else
        ReverseAlertsArrayOrder = aAlerts
    End If
    ON ERROR GOTO 0        
End Function

Function GetCounterListFromBLG(sPerfmonLogFilePath, sOutputCounterListFilePath)
    Dim iNumOfCounters, sFilteredLogForCounterlistFilePath
    GetCounterListFromBLG = 0
    sFilteredLogForCounterlistFilePath = g_WorkingDirectory & "\" & "_FilteredLogForCounterlist.csv"
    
    If UseRelogToConvertBLGToCSV(sPerfmonLogFilePath, sFilteredLogForCounterlistFilePath, 30) = True Then
        iNumOfCounters = CreateCounterListFromPerfmonCSVFile(sFilteredLogForCounterlistFilePath, sOutputCounterListFilePath)
        If iNumOfCounters > 0 Then
            GetCounterListFromBLG = iNumOfCounters
        End If
    End If
End Function

Function CreateCounterListFromPerfmonCSVFile(sPerfmonLogFilePath, sOutputFilePath)
    Const ForReading = 1
    Const ForWriting = 2
    Const ForAppending = 8
    Dim aLines, l, oFSO, oReadFile, sLine, oWriteFile, iCounterNumber, i
    iCounterNumber = 0
    Set oFSO = CreateObject("Scripting.FileSystemObject")
    Set oReadFile = oFSO.OpenTextFile(sPerfmonLogFilePath, ForReading)
	sLine = oReadFile.ReadLine
    aLines = Split(sLine, ",")
    Set oWriteFile = oFSO.CreateTextFile(sOutputFilePath, True)
    For i = 1 to UBound(aLines)
        aLines(i) = Replace(aLines(i), chr(34), "") ' remove double quotes
        oWriteFile.WriteLine aLines(i)
        iCounterNumber = iCounterNumber + 1
    Next
    CreateCounterListFromPerfmonCSVFile = iCounterNumber
End Function

Function UseRelogToConvertBLGToCSV(sPerfmonLog,sNewCounterLog, iTimeoutInSeconds)
	Dim WshShell, oExec
	Dim dQ, i, sCMD, strText
	Dim oFSO, oFile
    Const ForReading = 1, ForWriting = 2, ForAppending = 8
    Dim sCountersToFilterFile, iTimeOutCount
    dQ = chr(34)
    
    ' Create a file to read into ReLog for filtering.
    sCountersToFilterFile = g_WorkingDirectory & "\" & "_CountersToFilter.txt"
    Set oFSO = CreateObject("Scripting.FileSystemObject")

    Dim sPerfmonLogForRelog
    sPerfmonLogForRelog = sPerfmonLog
    ' If there are spaces, then surround it in doublequotes.
    If InStr(1, sPerfmonLogForRelog, " ") > 0 Then        
        sPerfmonLogForRelog = chr(34) & sPerfmonLogForRelog & chr(34)
    End If    
    
    Set WshShell = CreateObject("WScript.Shell")
    If Instr(1, sPerfmonLogForRelog, chr(34), 1) > 0 Then
        sCMD = "ReLog.exe " & sPerfmonLogForRelog & " -f CSV -y -o " & sNewCounterLog
    Else
        sCMD = "ReLog.exe " & chr(34) & sPerfmonLogForRelog & chr(34) & " -f CSV -y -o " & sNewCounterLog
    End If
    
	OutputToConsoleAndLog "Executing: " & sCMD
	Set oExec = WshShell.Exec(sCMD)
	
    'Do Until oExec.StdOut.AtEndOfStream
        strText = oExec.StdOut.ReadAll()
    	OutputToConsoleAndLog strText
    'Loop
    
    If InStr(1, strText, "successful", 1) > 0 Then
	    iTimeOutCount = 0
        Do 
            If iTimeOutCount >= iTimeoutInSeconds Then
                UseRelogToFilterCounters = False
                Exit Do
            Else
                UseRelogToConvertBLGToCSV = True                
            End If
            OutputToConsoleAndLog "Waiting for " & sNewCounterLog & " to be created..."
            WScript.Sleep 1000
            iTimeOutCount = iTimeOutCount + 1
        Loop Until oFSO.FileExists(sNewCounterLog) = True
        If UseRelogToConvertBLGToCSV = True Then
            OutputToConsoleAndLog "Found " & sNewCounterLog
        End If
    Else
        UseRelogToConvertBLGToCSV = False     
    End If
    
    ' Check to see if nothing was produced.
    Set oFile = oFSO.GetFile(sNewCounterLog)
    If oFile.Size = 0 Then
        OutputToConsoleAndLog "===============================ERROR========================================"
        OutputToConsoleAndLog "[UseRelogToConvertBLGToCSV]"
        OutputToConsoleAndLog " No data in the perfmon log file after converting."       
        OutputToConsoleAndLog "============================================================================"
        WScript.Quit    
    End If    
End Function

Function CreateGUID()
    Dim objScriptTypeLib, strGUID
    Set objScriptTypeLib = CreateObject("Scriptlet.TypeLib")
    strGUID = Left(objScriptTypeLib.GUID, 38)
    Set objScriptTypeLib = Nothing
    CreateGUID = strGUID
End Function

Sub DeletePALLogFile()
    Dim WshShell, objFSO, objFolder, colFiles, objFile, sFile
    Set WshShell = WScript.CreateObject("WScript.Shell")
    Set objFSO = CreateObject("Scripting.FileSystemObject")
    Set objFile = objFSO.GetFile(g_sFileDebugLogPath)
    'WScript.Echo "Deleting log file " & chr(34) & objFile.Name & chr(34) & "..."
    objFile.Delete(True)
    If Err.number <> 0 Then
        WScript.Echo "ERROR: Unable to delete the log file " & chr(34) & objFile.Name & chr(34) & " due to " & err.number & ", " & err.Description
    Else
        'WScript.Echo "Successfully deleted log file"
    End If
'    Set objFolder = objFSO.GetFolder(g_UserTempDirectory)
'    Set colFiles = objFolder.Files
'    For Each objFile in colFiles
'        If LCase(Right(objFile.Name, 7)) = "pal.log" Then
'            sFile = objFile.Name
'            WScript.Echo "Deleting " & sFile & "..."
'            ON ERROR RESUME NEXT
'            objFile.Delete(True)
'            If Err.number <> 0 Then
'                WScript.Echo "Unable to delete file " & sFile
'                WScript.Echo "ERROR: " & err.number & ", " & err.Description
'                WScript.Quit
'            Else
'                WScript.Echo sFile & " deleted."
'            End If            
'        End If
'    Next    
End Sub

Sub GenerateUniqueGUID()
    g_GUID = CreateGUID()
End Sub

Function RemoveCurlyBrackets(ByVal sString)
    Dim sNewString
    sNewString = sString
    sNewString = Replace(sNewString, "{", "")
    sNewString = Replace(sNewString, "}", "")
    RemoveCurlyBrackets = sNewString
End Function

Function ResolvePALStringVariables(ByVal sString)
    Dim sNewString
    Const ALL_POSSIBLE_REPLACEMENTS = -1
    Const START_AT_THE_BEGINNING = 1
    sNewString = sString
    '// [My Documents]
    Dim oShell, sMyDocs
    Set oShell = CreateObject("WScript.Shell") 
    sMyDocs = oShell.SpecialFolders("MyDocuments")
    sNewString = Replace(sNewString, "[My Documents]", sMyDocs, START_AT_THE_BEGINNING, ALL_POSSIBLE_REPLACEMENTS, vbTextCompare)    
    '// [LogFileName]
    Dim aPath, sPerfmonLogName
    aPath = Split(g_PerfmonLog, "\")
    sPerfmonLogName = aPath(UBound(aPath))
    sPerfmonLogName = Mid(sPerfmonLogName, 1, Len(sPerfmonLogName) - 4)
    sPerfmonLogName = RemoveNonFileSystemFriendlyCharacters(sPerfmonLogName)
    sNewString = Replace(sNewString, "[LogFileName]", sPerfmonLogName, START_AT_THE_BEGINNING, ALL_POSSIBLE_REPLACEMENTS, vbTextCompare)
    '// [DateTimeStamp]
    sNewString = Replace(sNewString, "[DateTimeStamp]", g_DateTimeStamp, START_AT_THE_BEGINNING, ALL_POSSIBLE_REPLACEMENTS, vbTextCompare)   
    '// [GUID]
    Dim sGUID
    sGUID = RemoveCurlyBrackets(g_GUID)
    sNewString = Replace(sNewString, "[GUID]", RemoveNonFileSystemFriendlyCharacters(sGUID), START_AT_THE_BEGINNING, ALL_POSSIBLE_REPLACEMENTS, vbTextCompare)
    ResolvePALStringVariables = sNewString    
End Function

Function RemoveNonFileSystemFriendlyCharacters(ByVal sString)
    '// Removes any non-friendly characters for files names.
    Dim sNewString, aNonFriendlies, i
    Const ALL_POSSIBLE_REPLACEMENTS = -1
    Const START_AT_THE_BEGINNING = 1
    aNonFriendlies = array("\", "/", ":", "*", "?", chr(34), "'", "<", ">", "|")    
    sNewString = sString    
    For i = 0 to UBound(aNonFriendlies)
        sNewString = Replace(sNewString, aNonFriendlies(i), "", START_AT_THE_BEGINNING, ALL_POSSIBLE_REPLACEMENTS, vbTextCompare)
    Next    
    RemoveNonFileSystemFriendlyCharacters = sNewString
End Function

Function RemoveFileExtension(ByVal sFileNameOrPath)
    Dim iLen, sNewText
    sNewText = sFileNameOrPath
    iLen = Len(sFileNameOrPath) - 4
    sNewText = Mid(sNewText, 1, iLen)
    RemoveFileExtension = sNewText
End Function

Function ConvertToTwentyFourHourTime(dDate)
    'Converts a 12-hour datetime to 24-hour datetime.
    '8/27/2008 7:30:00 PM"
    Dim dNewDate, dNewTime, dNewDateTime   
    dNewTime = TimeValue(dDate)
    dNewDate = DateValue(dDate)
    dNewTime = FormatDateTime(dNewTime, 4)
    dNewDateTime = dNewDate & " " & dNewTime
    ConvertToTwentyFourHourTime = dNewDateTime
End Function