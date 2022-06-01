unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, ThreadUtilities;

type
  TForm1 = class(TForm)
    Memo3: TMemo;
    Button4: TButton;
    Panel1: TPanel;
    Button1: TButton;
  private
    { Private declarations }
    procedure HandleLogRequest(Data: Pointer; AThread: TThread);
  public
    { Public declarations }
    constructor Create(const FileName: string);
    destructor Destroy; override;
    procedure Log(const LogText: string);
  end;

type
    PLogRequest = ^TLogRequest;
    TLogRequest = record
        LogText: String;
    end;

    TThreadFileLog = class(TObject);

Var
  FFileName: String;
  FThreadPool: TThreadPool;

implementation

{$R *.dfm}

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
        Writeln(F, DateTimeToStr(Now) + ': ' + LogString);
    finally
        CloseFile(F);
    end;
end;

constructor TForm1.Create(const FileName: string);
begin
    FFileName := FileName;
    //-- Pool of one thread to handle queue of logs
    FThreadPool := TThreadPool.Create(HandleLogRequest, 1);
end;

destructor TForm1.Destroy;
begin
    FThreadPool.Free;
    inherited;
end;

procedure TForm1.HandleLogRequest(Data: Pointer; AThread: TThread);
var
    Request: PLogRequest;
begin
    Request := Data;
    try
        LogToFile(FFileName, Request^.LogText);
    finally
        Dispose(Request);
    end;
end;

procedure TForm1.Log(const LogText: string);
var
    Request: PLogRequest;
begin
    New(Request);
    Request^.LogText := LogText;
    FThreadPool.Add(Request);
end;

end.
