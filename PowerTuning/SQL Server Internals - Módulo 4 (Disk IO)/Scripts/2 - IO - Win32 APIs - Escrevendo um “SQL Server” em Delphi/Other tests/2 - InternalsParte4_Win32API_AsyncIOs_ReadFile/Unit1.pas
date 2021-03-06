unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls;

type
  TForm1 = class(TForm)
    Memo3: TMemo;
    Button4: TButton;
    procedure Button4Click(Sender: TObject);
  private
    { Private declarations }
    InitTimeStamp: TTimeStamp;
    procedure InitFileAndSections(InitialPos: Integer);
    procedure DoRead;
    procedure Cleanup;
  public
    { Public declarations }
  end;

const
  nNumberOfBytesToRead = 8192; // 8KB
  nThreads = 16;

type
  PCardinal = ^cardinal;
  TFileSection = record
    StartOfs: cardinal;
    DataFileBuffer: array [0..nNumberOfBytesToRead -1] of AnsiChar;
    Overlapped: OVERLAPPED;
  end;

  TFileBlock = record
    FileHandle: THandle;
    SectionData: array [0..Pred(nThreads)] of TFileSection;
  end;

var
  Form1: TForm1;
  FileBlock: TFileBlock;

implementation

{$R *.dfm}

procedure TForm1.InitFileAndSections (InitialPos: Integer);
var
  i: cardinal;
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

  //SetFilePointer(FileBlock.FileHandle, 9950, 0, FILE_BEGIN);

  for i := 0 to Pred(nThreads) do
  begin
    FileBlock.SectionData[i].StartOfs := (nNumberOfBytesToRead * i) + (InitialPos);
    FileBlock.SectionData[i].Overlapped.hEvent := CreateEvent(nil, true, false, nil);
    if FileBlock.SectionData[i].Overlapped.hEvent = 0 then
      raise Exception.Create('Couldn''t create event.');
  end;
end;

procedure TForm1.DoRead;
var
  i, j, waitresult: cardinal;
  WaitArray: array[0..Pred(nThreads)] of THandle;
  ReadWorked: boolean;
  BytesRead: cardinal;
  Data, Expected: cardinal;
  PC: PCardinal;
  bResult: LongBool;
  VarlpNumberOfBytesTransferred: DWORD;
  GetLastErrorResult: cardinal;
label
  GotoScanFile;

begin

j := 0;

GotoScanFile:
  for i := 0 to Pred(nThreads) do
  begin
    WaitArray[i] := FileBlock.SectionData[i].Overlapped.hEvent;
    FileBlock.SectionData[i].Overlapped.Offset := FileBlock.SectionData[i].StartOfs;

    ReadWorked := ReadFile(FileBlock.FileHandle,
                           FileBlock.SectionData[i].DataFileBuffer,
                           nNumberOfBytesToRead,
                           BytesRead,
                           @FileBlock.SectionData[i].Overlapped);

    if not ReadWorked then
      ReadWorked := GetLastError() = ERROR_IO_PENDING;
    if not ReadWorked then
      raise Exception.Create('Read call failed');
  end;
  //Memo3.Lines.Add('Reads Actioned');

  // Fingindo que estou fazendo algo e consumindo a CPU...
  Sleep(5000);

  WaitForMultipleObjects(nThreads, @WaitArray, true, INFINITE);

  for i := 0 to Pred(nThreads) do
  begin
    Memo3.Lines.Add('DataFileBuffer: ' + FileBlock.SectionData[i].DataFileBuffer);
  end;

  // Check the result of the asynchronous read
  // without waiting (forth parameter FALSE).
  // Checking latest thread read as they've all finished
  bResult := GetOverlappedResult(FileBlock.FileHandle,
                                 FileBlock.SectionData[nThreads-1].Overlapped,
                                 VarlpNumberOfBytesTransferred,
                                 False);

  GetLastErrorResult := GetLastError();

  {
  if GetLastErrorResult = ERROR_IO_PENDING then
    Memo3.Lines.Add('GetLastErrorResult = ERROR_IO_PENDING');
  if GetLastErrorResult = ERROR_IO_INCOMPLETE then
    Memo3.Lines.Add('Operation is still pending - GetLastErrorResult = ERROR_IO_INCOMPLETED');
  }
  
  if (GetLastErrorResult <> ERROR_HANDLE_EOF) or (VarlpNumberOfBytesTransferred > 0) then
  begin
    //Memo3.Lines.Add('Not on ERROR_HANDLE_EOF or VarlpNumberOfBytesTransferred > 0... Starting more threads');
    //Memo3.Lines.Add('VarlpNumberOfBytesTransferred = ' + IntToStr(VarlpNumberOfBytesTransferred));

    j:= j + (nThreads * nNumberOfBytesToRead);

    Cleanup();
    InitFileAndSections(j);
    Goto GotoScanFile;
  end;
  
end;

procedure TForm1.Cleanup;
var
  i: cardinal;
begin
  for i := 0 to Pred(nThreads) do
  begin
    CloseHandle(FileBlock.SectionData[i].Overlapped.hEvent);
    //FreeMem(FileBlock.SectionData[i].DataFileBuffer);
  end;
  CloseHandle(FileBlock.FileHandle);
  ZeroMemory(@FileBlock, sizeof(FileBlock));
end;

procedure TForm1.Button4Click(Sender: TObject);
Var
  Tempo : TDateTime;
begin
  Tempo := Now();
  Memo3.Clear;
  Memo3.Lines.Add('Started');
  InitFileAndSections(0);
  DoRead();
  Cleanup();
  Memo3.Lines.Add('Done');
  Memo3.Lines.Add(FormatDateTime('hh:mm:ss.zzz', Tempo - Now()))
end;

end.
