unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;



type
  TMeuProcessoParalelo = class(TThread)
  private
    FAux: String;
    FMemo: TMemo;
  public
    constructor Create(AMemo: TMemo); reintroduce;
    procedure Execute; override;
    procedure Sincronizar;
  end;

 
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
        procedure Add(const Data: Pointer; Overlappeds: POverlapped);
    end;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Memo3: TMemo;
    Button2: TButton;
    Memo1: TMemo;
    Button3: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);

  private
    { Private declarations }
    FMeuProcessoParalelo: TMeuProcessoParalelo;
    procedure DoHandleThreadExecute(Thread: TThread);
    procedure HandleReadRequest2(Data: Pointer; AThread: TThread);

  public
    { Public declarations }
  end;

type
  PCardinal = ^cardinal;

  TThreadReadFile = class(TObject)
  private
      FThreadPool: TThreadPool;

  public
      constructor Create();
      destructor Destroy; override;
      procedure pReadFile(fHandle: Cardinal; Overlapped: POverlapped);
  end;

  TThreadFileLog = class(TObject)
  private
      FThreadPool: TThreadPool;
      procedure HandleLogRequest(Data: Pointer; AThread: TThread);
      procedure HandleReadRequest(Data: Pointer; AThread: TThread);
  public
      constructor Create();
      destructor Destroy; override;
      procedure Log(fHandle: Cardinal; Overlapped: POverlapped);
      procedure Log2(const FileName, LogText: string);
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
  nThreads = 4;

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
  CompletionRoutineTotalBytesTransfered: DWORD;

implementation

{$R *.dfm}

constructor TMeuProcessoParalelo.Create;
begin
  inherited Create(True);
  Self.FreeOnTerminate := True;

  FAux := '';
  FMemo := AMemo;
end;
 
procedure TMeuProcessoParalelo.Execute;
var
  I: Integer;
begin
  inherited;

  I := 0;
  while I < 1000 do
  begin
    I := I + 1;
    Self.FAux := 'Valor de I: ' + IntToStr(I);
    Self.Synchronize(Self.Sincronizar);
    Sleep(1);
  end;
end;
 
procedure TMeuProcessoParalelo.Sincronizar;
begin
  FMemo.Lines.Add(Self.FAux);
end;


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
                                 ExecuteEvent: TThreadExecuteEvent;
                                 AFreeOnTerminate: Boolean);
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

procedure TThreadPool.Add(Const Data: Pointer; Overlappeds: POverlapped);
begin
    if FFinalized then
        Raise EThreadStackFinalized.Create('Stack is finalized');
    //-- Add/Push a pointer on to the end of the queue
    PostQueuedCompletionStatus(FIOQueue, 0, Cardinal(Data), Overlappeds);
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
    FThreadPool := TThreadPool.Create(HandleReadRequest, nThreads);
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

end;

destructor TThreadReadFile.Destroy;
begin
    FThreadPool.Free;
    inherited;
end;

procedure TForm1.HandleReadRequest2(Data: Pointer; AThread: TThread);
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

    {
      ReadWorked := ReadFile(Request^.fHandle,
                             DataFileBuffer,
                             nNumberOfBytesToRead,
                             BytesRead,
                             Request^.Overlapped);

      if not ReadWorked then
        ReadWorked := GetLastError() = ERROR_IO_PENDING;
      if not ReadWorked then
        raise Exception.Create('Read call failed');

    Str := DataFileBuffer;
    }

    Str := IntToStr(Request^.Overlapped.Offset);

    AssignFile(F, 'C:\temp\IOCP.txt');

    if not FileExists('C:\temp\IOCP.txt') then
        Rewrite(F)
    else
        Append(F);

    try
        Writeln(F, 'DataFileBuffer: ' + Str);
    finally
        CloseFile(F);
    end;

    finally
        Dispose(Request);
    end;
end;

procedure TThreadFileLog.HandleReadRequest(Data: Pointer; AThread: TThread);
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

    {
      ReadWorked := ReadFile(Request^.fHandle,
                             DataFileBuffer,
                             nNumberOfBytesToRead,
                             BytesRead,
                             Request^.Overlapped);

      if not ReadWorked then
        ReadWorked := GetLastError() = ERROR_IO_PENDING;
      if not ReadWorked then
        raise Exception.Create('Read call failed');

    Str := DataFileBuffer;
    }

    Str := IntToStr(Request^.Overlapped.Offset);

    AssignFile(F, 'C:\temp\IOCP.txt');

    if not FileExists('C:\temp\IOCP.txt') then
        Rewrite(F)
    else
        Append(F);

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
    FThreadPool.Add(Request, Overlapped);

    //if FFinalized then
    //    Raise EThreadStackFinalized.Create('Stack is finalized');


    //FThreadPool.Add(Request);

    // Add/Push a pointer on to the end of the queue
    //PostQueuedCompletionStatus(FIOQueue, 0, Cardinal(Request), Overlapped);


end;

procedure TThreadFileLog.Log2(const FileName, LogText: string);
var
  Request: PLogRequest;
begin
  New(Request);
  Request^.LogText  := LogText;
  Request^.FileName := FileName;
  FThreadPool.Add(Request, nil);
end;

procedure TThreadFileLog.Log(fHandle: Cardinal; Overlapped: POverlapped);
var
    Request: PFileSection;
begin
    New(Request);
    Request^.Overlapped := Overlapped;
    Request^.fHandle := fHandle;
    dataHandle := Request;
    FThreadPool.Add(Request, Overlapped);
end;

procedure TForm1.Button1Click(Sender: TObject);
Var
  i, x, InitialPos : integer;
  vDataFileBuffer: array [0..nNumberOfBytesToRead -1] of AnsiChar;
  IOCP_Handle : THandle;
  OverlappedIOs : array [0..nThreads] of POverlapped;
  VarlpNumberOfBytesTransferred: Cardinal;
  vGetOverlappedResult, HasOverlappedIoCompletedResult, GetQueuedCompletionStatusResult: LongBool;
  p: Pointer;
  aNow : TDateTime;
label
  GotoScanFile;

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

  fHandle := FileBlock.FileHandle;


  FThreadFileLog := TThreadFileLog.Create();
  InitialPos := 0;
  CompletionRoutineTotalBytesTransfered := 0;

 // OverlappedIOs[i] := AllocMem(nThreads + 1);


  GotoScanFile:

  i:= 0;
  for i := 0 to nThreads do
  begin
    OverlappedIOs[i] := New(POverLapped);

    OverlappedIOs[i].Internal := 0;
    OverlappedIOs[i].InternalHigh := 0;
    OverlappedIOs[i].hEvent := 0;
    OverlappedIOs[i].Offset := (nNumberOfBytesToRead * i) + (InitialPos);;
    OverlappedIOs[i].OffsetHigh := 0;
    aNow := Now;
    FThreadFileLog.Log(fHandle, OverlappedIOs[i]);

    //for x := 0 to 100 do
    //   FThreadFileLog.Log2('C:\temp\tes999.txt',
    //    FormatDateTime('dd-mm-yyyy hh:nn:ss.zzz', aNow) + ': I: ' + IntToStr(I)  + ' - Offset = ' + IntToStr(OverlappedIOs[i].Offset)
    //);

    //OverlappedIOs[i] := FileBlock.SectionData.Overlapped;


  end;

  p := nil;






  // Inicia verificações para obter retorno do I/O...
  for i := 0 to nThreads do
  begin
    p := nil;
    //HasOverlappedIoCompletedResult := HasOverlappedIoCompleted(OverlappedIOs[i]);
    //if HasOverlappedIoCompletedResult = False then
    //  ShowMessage('Deu alguma zica na chamada da HasOverlappedIoCompleted, GetLastError() = ' + IntToStr(GetLastError()));

    vGetOverlappedResult := GetOverlappedResult(fHandle, OverlappedIOs[i], VarlpNumberOfBytesTransferred, True);
    Sleep(1000); // Give it some time to finish...

    GetQueuedCompletionStatusResult := GetQueuedCompletionStatus(FIOQueue, VarlpNumberOfBytesTransferred, Cardinal(p), OverlappedIOs[i], 30000);
    if (GetQueuedCompletionStatusResult = False) and (GetLastError() <> WAIT_TIMEOUT) then
    begin
      //ERROR_HANDLE_EOF = 38
      // Verifica se o erro é ERROR_HANDLE_EOF, se sim, significa que chegamos
      // no final o arquivo...
      if GetLastError() = ERROR_HANDLE_EOF then
        // Adiciona o no Memo pra eu saber que chegou no final do arquivo...
        ShowMessage('ERROR_HANDLE_EOF')
      else
        // Se for algum outro erro adiciona no Memo pra eu saber
        ShowMessage('Algum outro erro no resultado da GetQueuedCompletionStatusResult, GetLastError() = ' + IntToStr(GetLastError()));

      // Set CompletionRoutineTotalBytesTransfered para zero pra eu saber que não
      // preciso continuar a leitura...
      CompletionRoutineTotalBytesTransfered := 0;
      Break;
    end
    else
      CompletionRoutineTotalBytesTransfered := CompletionRoutineTotalBytesTransfered + VarlpNumberOfBytesTransferred;
  end;


  // Enquanto CompletionRoutineTotalBytesTransfered não for indicar
  // que nenhum byte foi lido continua gerando threads pra continuar leitura
  while (CompletionRoutineTotalBytesTransfered > 0) do
  begin
    InitialPos := CompletionRoutineTotalBytesTransfered;
    GOTO GotoScanFile;
  end;
  
  
  ShowMessage('Done');

  FThreadFileLog.Free;
  CloseHandle(fHandle);
  ZeroMemory(@OverlappedIOs, sizeof(OverlappedIOs));
end;

procedure TForm1.Button2Click(Sender: TObject);
Var
  Thread1: TThread;
begin
  fHandle := CreateFile('C:\temp\Test3.txt',
                                     GENERIC_READ or GENERIC_WRITE,
                                     0,
                                     nil,
                                     OPEN_EXISTING,
                                     FILE_FLAG_OVERLAPPED,
                                     0);

  if fHandle = INVALID_HANDLE_VALUE then
    raise Exception.Create('Couldn''t create file.');


  FIOQueue := CreateIOCompletionPort(fHandle, 0, 0, 0);

  //TThreadPool.Create(HandleReadRequest2, nThreads);

  //FHandlePoolEvent := Form1.DoHandleThreadExecute;

  //FThreadQueue := TThreadQueue.Create(fHandle);



  FThreads := TList.Create;
  Thread1 := TSimpleThread.Create(True, Form1.DoHandleThreadExecute, False);

  FThreads.Add(Thread1);
  Thread1.Resume;


  TThread(FThreads[0]).WaitFor;
  TThread(FThreads[0]).Free;
  FThreads.Delete(0);

  FThreadQueue.Free;
  FThreads.Free;

  CloseHandle(fHandle);
  CloseHandle(FIOQueue);

end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  Self.FMeuProcessoParalelo := TMeuProcessoParalelo.Create(Memo1);
  Self.FMeuProcessoParalelo.Resume;
end;

end.
