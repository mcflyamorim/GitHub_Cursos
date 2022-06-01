unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;


type
    EThreadStackFinalized = class(Exception);

    // Thread Safe Pointer Queue
    TThreadQueue = class
    public
        constructor Create(fHandle: THandle);
        destructor Destroy; override;
        procedure Finalize;
        function Pop(var Data: Pointer): Boolean;
    end;

    TThreadExecuteEvent = procedure (Thread: TThread) of object;

    TSimpleThread = class(TThread)
    private
        FExecuteEvent: TThreadExecuteEvent;
    protected
        procedure Execute(); override;
    public
        constructor Create(CreateSuspended: Boolean; ExecuteEvent: TThreadExecuteEvent; AFreeOnTerminate: Boolean);
    end;

    TThreadPoolEvent = procedure (Data: Pointer; AThread: TThread) of Object;

    TThreadPool = class(TObject)
    public
        constructor Create( HandlePoolEvent: TThreadPoolEvent; MaxThreads: Integer = 1); virtual;
        destructor Destroy; override;
        procedure Add(const Data: Pointer);
    end;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Memo3: TMemo;
    Button4: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);

  private
    { Private declarations }
    procedure DoHandleThreadExecute(Thread: TThread);

  public
    { Public declarations }
  end;

type
  PCardinal = ^cardinal;

  TThreadReadFile = class(TObject)
  private
      FThreadPool: TThreadPool;
      procedure HandleReadRequest(Data: Pointer; AThread: TThread);
  public
      constructor Create();
      destructor Destroy; override;
      procedure pReadFile(fHandle: Cardinal; Overlapped: POverlapped);
  end;

  TThreadFileLog = class(TObject)
  private
      FThreadPool: TThreadPool;
      procedure HandleLogRequest(Data: Pointer; AThread: TThread);
  public
      constructor Create();
      destructor Destroy; override;
      procedure Log(const FileName, LogText: string);
  end;

  PFileSection = ^TFileSection;
    TFileSection = record
      fHandle: Cardinal;
      Overlapped: POverlapped;
  end;

    TFileBlock = record
      FileHandle: THandle;
      SectionData: TFileSection;
  end;

  PLogRequest = ^TLogRequest;
    TLogRequest = record
        LogText  : String;
        FileName : String;
  end;

type
//
// NTSTATUS
//

  NTSTATUS = ULONG;
  {$EXTERNALSYM NTSTATUS}
  PNTSTATUS = ^NTSTATUS;
  {$EXTERNALSYM PNTSTATUS}
  TNTStatus = NTSTATUS;

//
//  Status values are 32 bit values layed out as follows:
//
//   3 3 2 2 2 2 2 2 2 2 2 2 1 1 1 1 1 1 1 1 1 1
//   1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0
//  +---+-+-------------------------+-------------------------------+
//  |Sev|C|       Facility          |               Code            |
//  +---+-+-------------------------+-------------------------------+
//
//  where
//
//      Sev - is the severity code
//
//          00 - Success
//          01 - Informational
//          10 - Warning
//          11 - Error
//
//      C - is the Customer code flag
//
//      Facility - is the facility code
//
//      Code - is the facility's status code
//

//
// Generic test for success on any status value (non-negative numbers
// indicate success).
//

function GetOverlappedResult(hFile: THandle; const lpOverlapped: POverlapped;
  var lpNumberOfBytesTransferred: DWORD; bWait: BOOL): BOOL; stdcall;
{$EXTERNALSYM GetOverlappedResult}

function HasOverlappedIoCompleted(const lpOverlapped: POverlapped): BOOL;
{$EXTERNALSYM HasOverlappedIoCompleted}

function PostQueuedCompletionStatus(CompletionPort: THandle;
  dwNumberOfBytesTransferred: DWORD; dwCompletionKey: DWORD;
  lpOverlapped: POverlapped): BOOL; stdcall;
{$EXTERNALSYM PostQueuedCompletionStatus}

{GetProcedureAddress loads a function using a module name and an function name.
WARNING: Do not load a function defined by its index like PAnsiChar(123) in ProcName.
 Instead simply use the number and thus the other GetProcedureAddress.
}
procedure GetProcedureAddress(var P: Pointer; const ModuleName, ProcName: AnsiString); overload;

{GetProcedureAddress loads a function using a module name and an function index.}
procedure GetProcedureAddress(var P: Pointer; const ModuleName : AnsiString; ProcNumber : Cardinal); overload;

const
  nNumberOfBytesToRead = 10;
  SECTION_COUNT = 16;

const
  RsELibraryNotFound = 'Library not found: %0:s';
  RsEFunctionNotFound = 'Function not found: %0:s.%1:s';
  RsEFunctionNotFound2 = 'Function not found: %0:s.%1:d';

var
  Form1: TForm1;
  FileBlock: TFileBlock;
  FThreadFileLog: TThreadFileLog;
  FThreadReadFile: TThreadReadFile;
  FThreadPool1 : TThreadPool;
  FThreads: TList;
  FThreadQueue: TThreadQueue;
  FHandlePoolEvent: TThreadPoolEvent;
  FIOQueue: THandle;
  fHandle: THandle = INVALID_HANDLE_VALUE;
  dataHandle: Pointer;
  FFinalized: Boolean;

implementation

{$R *.dfm}

function GetOverlappedResult; external kernel32 name 'GetOverlappedResult';


procedure GetProcedureAddress(var P: Pointer; const ModuleName, ProcName: AnsiString);
var
  ModuleHandle: HMODULE;
begin
  if not Assigned(P) then
  begin
    ModuleHandle := {$IFDEF JWA_INCLUDEMODE}jwaWinType_GetModuleHandle
                    {$ELSE}GetModuleHandle
                    {$ENDIF JWA_INCLUDEMODE}
                    (PAnsiChar(AnsiString(ModuleName)));
    if ModuleHandle = 0 then
    begin
      ModuleHandle := {$IFDEF JWA_INCLUDEMODE}jwaWinType_LoadLibrary
                    {$ELSE}LoadLibrary
                    {$ENDIF JWA_INCLUDEMODE}(PAnsiChar(ModuleName));
      if ModuleHandle = 0 then

    end;
    P := Pointer({$IFDEF JWA_INCLUDEMODE}jwaWinType_GetProcAddress
                    {$ELSE}GetProcAddress
                    {$ENDIF JWA_INCLUDEMODE}(ModuleHandle, PAnsiChar(ProcName)));
    if not Assigned(P) then

  end;
end;

procedure GetProcedureAddress(var P: Pointer; const ModuleName : AnsiString; ProcNumber : Cardinal);
var
  ModuleHandle: HMODULE;
begin
  if not Assigned(P) then
  begin
    ModuleHandle := {$IFDEF JWA_INCLUDEMODE}jwaWinType_GetModuleHandle
                    {$ELSE}GetModuleHandle
                    {$ENDIF JWA_INCLUDEMODE}
                    (PAnsiChar(AnsiString(ModuleName)));
    if ModuleHandle = 0 then
    begin
      ModuleHandle := {$IFDEF JWA_INCLUDEMODE}jwaWinType_LoadLibrary
                    {$ELSE}LoadLibrary
                    {$ENDIF JWA_INCLUDEMODE}(PAnsiChar(ModuleName));
      if ModuleHandle = 0 then

    end;
    P := Pointer({$IFDEF JWA_INCLUDEMODE}jwaWinType_GetProcAddress
                    {$ELSE}GetProcAddress
                    {$ENDIF JWA_INCLUDEMODE}(ModuleHandle, PAnsiChar(ProcNumber)));
    if not Assigned(P) then

  end;
end;
var
  _PostQueuedCompletionStatus: Pointer;
  
function PostQueuedCompletionStatus;
begin
  GetProcedureAddress(_PostQueuedCompletionStatus, kernel32, 'PostQueuedCompletionStatus');
  asm
        MOV     ESP, EBP
        POP     EBP
        JMP     [_PostQueuedCompletionStatus]
  end;
end;


function HasOverlappedIoCompleted(const lpOverlapped: POverlapped): BOOL;
begin
  Result := NTSTATUS(lpOverlapped.Internal) <> STATUS_PENDING;
end;

{ TThreadQueue }

constructor TThreadQueue.Create(fHandle: THandle);
begin
    //-- Create IO Completion Queue
    FIOQueue := CreateIOCompletionPort(fHandle, 0, 0, 0);
    FFinalized := False;
end;

destructor TThreadQueue.Destroy;
begin
    //-- Destroy Completion Queue
    if (FIOQueue <> 0) then
        CloseHandle(FIOQueue);
    inherited;
end;

procedure TThreadQueue.Finalize;
begin
    //-- Post a finialize pointer on to the queue
    PostQueuedCompletionStatus(FIOQueue, 0, 0, Pointer($FFFFFFFF));
    FFinalized := True;
end;

(* Pop will return false if the queue is completed *)
function TThreadQueue.Pop(var Data: Pointer): Boolean;
var
    A: Cardinal;
    OL: POverLapped;
begin
    Result := True;

    if (not FFinalized) then
    //-- Remove/Pop the first pointer from the queue or wait
        GetQueuedCompletionStatus(FIOQueue, A, Cardinal(Data), OL, INFINITE);

    //-- Check if we have finalized the queue for completion
    if FFinalized or (OL = Pointer($FFFFFFFF)) then begin
        Data := nil;
        Result := False;
        Finalize;
    end;
end;

{ TSimpleThread }

constructor TSimpleThread.Create(CreateSuspended: Boolean;
  ExecuteEvent: TThreadExecuteEvent; AFreeOnTerminate: Boolean);
begin
    FreeOnTerminate := AFreeOnTerminate;
    FExecuteEvent := ExecuteEvent;
    inherited Create(CreateSuspended);
end;

procedure TSimpleThread.Execute;
begin
    if Assigned(FExecuteEvent) then
        FExecuteEvent(Self);
end;

{ TThreadPool }

procedure TThreadPool.Add(Const Data: Pointer);
begin
    if FFinalized then
        Raise EThreadStackFinalized.Create('Stack is finalized');
    //-- Add/Push a pointer on to the end of the queue
    PostQueuedCompletionStatus(FIOQueue, 0, Cardinal(Data), nil);
end;

constructor TThreadPool.Create(HandlePoolEvent: TThreadPoolEvent; MaxThreads: Integer);
begin
    FHandlePoolEvent := HandlePoolEvent;
    FThreadQueue := TThreadQueue.Create(fHandle);
    FThreads := TList.Create;
    while FThreads.Count < MaxThreads do
        FThreads.Add(TSimpleThread.Create(False, Form1.DoHandleThreadExecute, False));
end;

destructor TThreadPool.Destroy;
var
    t: Integer;
begin
    FThreadQueue.Finalize;
    for t := 0 to FThreads.Count-1 do
        TThread(FThreads[t]).Terminate;
    while (FThreads.Count > 0) do begin
        TThread(FThreads[0]).WaitFor;
        TThread(FThreads[0]).Free;
        FThreads.Delete(0);
    end;
    FThreadQueue.Free;
    FThreads.Free;
    inherited;
end;

procedure TForm1.DoHandleThreadExecute(Thread: TThread);
var
    Data: Pointer;
begin
    while FThreadQueue.Pop(Data) and (not TSimpleThread(Thread).Terminated) do begin
        try
            FHandlePoolEvent(Data, Thread);
        except
        end;
    end;
end;


constructor TThreadFileLog.Create();
begin
    FThreadPool := TThreadPool.Create(HandleLogRequest, 1);
end;

destructor TThreadFileLog.Destroy;
begin
    FThreadPool.Free;
    inherited;
end;

(* Simple reuse of a logtofile function for example *)
procedure LogToFile(const FileName, LogString: String);
var
    F: TextFile;
begin
    AssignFile(F, FileName);

    if not FileExists(FileName) then
        Rewrite(F)
    else
        Append(F);

    try
        Writeln(F, LogString);
    finally
        CloseFile(F);
    end;
end;

procedure TThreadFileLog.HandleLogRequest(Data: Pointer; AThread: TThread);
var
    Request: PLogRequest;
begin
    Request := Data;
    try
        LogToFile(Request^.FileName, Request^.LogText);
    finally
        Dispose(Request);
    end;
end;

constructor TThreadReadFile.Create();
begin
    FThreadPool := TThreadPool.Create(HandleReadRequest, 1);
end;

destructor TThreadReadFile.Destroy;
begin
    FThreadPool.Free;
    inherited;
end;

procedure TThreadReadFile.HandleReadRequest(Data: Pointer; AThread: TThread);
var
  Request: PFileSection;
  ReadWorked: boolean;
  BytesRead: cardinal;
  bResult: LongBool;
  VarlpNumberOfBytesTransferred: DWORD;
  GetLastErrorResult: cardinal;
  DataFileBuffer: array [0..nNumberOfBytesToRead -1] of AnsiChar;
  Str: String;
  F: TextFile;
begin
    Request := Data;
    try
      ReadWorked := ReadFile(Request^.fHandle,
                             DataFileBuffer,
                             nNumberOfBytesToRead,
                             BytesRead,
                             @Request^.Overlapped);

      if not ReadWorked then
        ReadWorked := GetLastError() = ERROR_IO_PENDING;
      if not ReadWorked then
        raise Exception.Create('Read call failed');

    bResult := GetOverlappedResult(Request^.fHandle,
                                   Request^.Overlapped,
                                   VarlpNumberOfBytesTransferred,
                                   False);

    GetLastErrorResult := GetLastError();

    Str := DataFileBuffer;


    AssignFile(F, 'C:\temp\IOCP.txt');
    Rewrite(F);

    try
        Writeln(F, 'DataFileBuffer: ' + Str);
    finally
        CloseFile(F);
    end;

    finally
        Dispose(Request);
    end;
end;

procedure TThreadReadFile.pReadFile(fHandle: Cardinal; Overlapped: POverlapped);
var
    Request: PFileSection;
begin
    New(Request);
    Request^.Overlapped := Overlapped;
    Request^.fHandle := fHandle;
    dataHandle := Request;
    FThreadPool.Add(Request);

    //if FFinalized then
    //    Raise EThreadStackFinalized.Create('Stack is finalized');


    //FThreadPool.Add(Request);

    // Add/Push a pointer on to the end of the queue
    //PostQueuedCompletionStatus(FIOQueue, 0, Cardinal(Request), Overlapped);


end;

procedure TForm1.Button2Click(Sender: TObject);
Var
  vDataFileBuffer: array [0..nNumberOfBytesToRead -1] of AnsiChar;
  IOCP_Handle : THandle;
  A: Cardinal;
  HasOverlappedIoCompletedResult, GetQueuedCompletionStatusResult: LongBool;
begin
  FileBlock.FileHandle := CreateFile('C:\temp\Test3.txt',
                                     GENERIC_READ or GENERIC_WRITE,
                                     0,
                                     nil,
                                     OPEN_EXISTING,
                                     FILE_FLAG_OVERLAPPED,
                                     0);

  if FileBlock.FileHandle = INVALID_HANDLE_VALUE then
    raise Exception.Create('Couldn''t create file.');

  FileBlock.SectionData.Overlapped := New(POverLapped);

  FileBlock.SectionData.Overlapped.Internal := 0;
  FileBlock.SectionData.Overlapped.InternalHigh := 0;
  FileBlock.SectionData.Overlapped.hEvent := 0;
  FileBlock.SectionData.Overlapped.Offset := 0;
  FileBlock.SectionData.Overlapped.OffsetHigh := 0;

  fHandle := FileBlock.FileHandle;

  FThreadReadFile := TThreadReadFile.Create();

  FThreadReadFile.pReadFile(FileBlock.FileHandle, FileBlock.SectionData.Overlapped);

  GetQueuedCompletionStatusResult := GetQueuedCompletionStatus(FIOQueue, A, Cardinal(dataHandle), FileBlock.SectionData.Overlapped, INFINITE);

  HasOverlappedIoCompletedResult := HasOverlappedIoCompleted(FileBlock.SectionData.Overlapped);
  if HasOverlappedIoCompletedResult = false then
    raise Exception.Create('Deu ruim na chamada da HasOverlappedIoCompleted... GetLastError() = ' + IntToStr(GetLastError()));

  if GetQueuedCompletionStatusResult = False then
      raise Exception.Create('Deu ruim na chamada da GetQueuedCompletionStatus... GetLastError() = ' + IntToStr(GetLastError()));

  FThreadReadFile.Free;
  CloseHandle(FileBlock.FileHandle);
end;

procedure TThreadFileLog.Log(const FileName, LogText: string);
var
  Request: PLogRequest;
begin
  New(Request);
  Request^.LogText  := LogText;
  Request^.FileName := FileName;
  FThreadPool.Add(Request);
end;

procedure TForm1.Button1Click(Sender: TObject);
var
I : integer;
aNow : TDateTime;
begin
    FThreadFileLog := TThreadFileLog.Create();

    aNow := Now;

    for I := 0 to 500 do
       FThreadFileLog.Log(
        FormatDateTime('ddmmyyyyhhnn', aNow) + '.txt',
        FormatDateTime('dd-mm-yyyy hh:nn:ss.zzz', aNow) + ': I: ' + IntToStr(I)
      );

    ShowMessage('logs are performed!');

    FThreadFileLog.Free;
end;

end.
