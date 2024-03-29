unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, Math;

type
  TForm1 = class(TForm)
    Memo3: TMemo;
    Button4: TButton;
    ProgressBar1: TProgressBar;
    Label1: TLabel;
    Edit1: TEdit;
    Label2: TLabel;
    edtfPath: TEdit;
    Label5: TLabel;
    procedure Button4Click(Sender: TObject);
  private
    { Private declarations }

  public
    { Public declarations }
  end;



// Estrutura do FILE_SEGMENT_ELEMENT em C++
//typedef union _FILE_SEGMENT_ELEMENT {
//    PVOID64 Buffer;
//    ULONGLONG Alignment;
//}FILE_SEGMENT_ELEMENT, *PFILE_SEGMENT_ELEMENT;
type
  FILE_SEGMENT_ELEMENT = record
    Buffer: Pointer;
    Alignment: Cardinal;
  end;

pFILE_SEGMENT_ELEMENT = ^FILE_SEGMENT_ELEMENT;

type
  TArray_FileSegmentElement = record
    FileSegmentElement: array of FILE_SEGMENT_ELEMENT;
  end;
    
type
  FILE_INFO_BY_HANDLE_CLASS = (
    FileBasicInfo                   = 0,
    FileStandardInfo                = 1,
    FileNameInfo                    = 2,
    FileRenameInfo                  = 3,
    FileDispositionInfo             = 4,
    FileAllocationInfo              = 5,
    FileEndOfFileInfo               = 6,
    FileStreamInfo                  = 7,
    FileCompressionInfo             = 8,
    FileAttributeTagInfo            = 9,
    FileIdBothDirectoryInfo         = 10, // 0xA
    FileIdBothDirectoryRestartInfo  = 11, // 0xB
    FileIoPriorityHintInfo          = 12, // 0xC
    FileRemoteProtocolInfo          = 13, // 0xD
    FileFullDirectoryInfo           = 14, // 0xE
    FileFullDirectoryRestartInfo    = 15, // 0xF
    FileStorageInfo                 = 16, // 0x10
    FileAlignmentInfo               = 17, // 0x11
    FileIdInfo                      = 18, // 0x12
    FileIdExtdDirectoryInfo         = 19, // 0x13
    FileIdExtdDirectoryRestartInfo  = 20, // 0x14
    MaximumFileInfoByHandlesClass);

  FILE_END_OF_FILE_INFO = record
    EndOfFile: LARGE_INTEGER;
  end;

type
  NTSTATUS = ULONG;
  {$EXTERNALSYM NTSTATUS}
  PNTSTATUS = ^NTSTATUS;
  {$EXTERNALSYM PNTSTATUS}
  TNTStatus = NTSTATUS;

function ReadFileScatter(hFile: THandle; aSegmentArray: pFILE_SEGMENT_ELEMENT;
    nNumberOfBytesToRead: LongWord; lpReserved: PLongWord; lpOverlapped: POverlapped): LongBool;
    StdCall; External 'Kernel32.dll' Name 'ReadFileScatter';

function WriteFileGather(hFile: THandle; aSegmentArray: pFILE_SEGMENT_ELEMENT;
  nNumberOfBytesToWrite: LongWord; lpReserved: PLongWord; lpOverlapped: POVERLAPPED): LongBool;
  StdCall; External 'Kernel32.dll' Name 'WriteFileGather';

function SetFileInformationByHandle(
  hFile: THandle;
  FileInformationClass: FILE_INFO_BY_HANDLE_CLASS;
  lpFileInformation: Pointer;
  dwBufferSize: DWORD
  ): BOOL; stdcall; External 'Kernel32.dll' Name 'SetFileInformationByHandle';


type
  PCardinal = ^cardinal;
  TCompRoutineRequest = record
    DataFileBufferPointer: array of PChar;
    vOverlapped: OVERLAPPED;
    CompletionRoutine: Pointer;
    BUFPointer: Pointer;
  end;

  TArray_CompletionRoutineRequest = record
    CompletionRoutineRequest: array of TCompRoutineRequest;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button4Click(Sender: TObject);
var
      BytesReturnedFromWriteFileGatherResult, BytesReturnedFromReadFileScatter, T: Cardinal;
      i, ii, x: Integer;
      vSYSTEM_INFO: TSystemInfo;
      fHandleInput, fHandleOutput: THandle;
      vOverlappedRead: Array of TOverlapped;
      vOverlappedWrite: Array of TOverlapped;
      vFileSegmentElement: Array of TArray_FileSegmentElement;
      vGetOverlappedResult, bFinishedIO, ReadFileScatterResult, WriteFileGatherResult: Boolean;
      FileSize: Integer;
      fPath: String;
      FileSegmentSize, A1Lenght: Integer;
      eof: FILE_END_OF_FILE_INFO;
      nNumberOfBytesToRead: Integer;
      SectorSize, BytesPerSector, dummy: Cardinal;
      nOutstandingIOs, FinalSize: Int64;
      ASystemInfo: TSystemInfo;
begin
  Memo3.Clear;
  
  // Windows utiliza blocos de 4KB de mem�ria...
  // Chamando a GetSystemInfo s� pra confirmar os 4096 bytes de "Memory Page Size"
  // Esse valor � importante porque pra usar a ReadFileScatter ou WriteFileGather
  // A mem�ria informada precisa estar alinhada com o Windows, ou seja,
  // N�o posso passar um array de mem�ria de 3KB ou 9KB pq vai dar erro...
  // A mem precisa ser um multiplo do dwPageSize
  GetSystemInfo(ASystemInfo);
  Memo3.Lines.Add('Memory Page Size = ' + IntToStr(ASystemInfo.dwPageSize));
  Memo3.Lines.Add('Come�ando o ReadFileScatter');
  Application.ProcessMessages;

  T := GetTickCount;

  // Quantidade m�ximo de I/Os que vou gerar antes de esperar o
  // I/O terminar... a ideia � deixar alguns I/Os na fila
  // pra usar o m�ximo que o disco consegue me oferecer
  nOutstandingIOs := 16;

  // Especificando a quantidade de Overlapped que vou precisar no Array
  SetLength(vOverlappedRead, nOutstandingIOs);
  SetLength(vOverlappedWrite, nOutstandingIOs);
  SetLength(vFileSegmentElement, nOutstandingIOs + 1);

  fPath := edtfPath.Text;
  fHandleInput := CreateFile(PChar(fPath), GENERIC_READ, FILE_SHARE_READ, nil,
    OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN or FILE_FLAG_NO_BUFFERING or FILE_FLAG_OVERLAPPED, 0);
        
  // Se o handle for inv�lido, disparar uma exce��o
  if fHandleInput = INVALID_HANDLE_VALUE then
    raise Exception.Create('Deu ruim na hora de rodar o CreateFile... GetLastError() = ' + IntToStr(GetLastError()));
      
      
  FileSize := GetFileSize(fHandleInput, @dummy);
  ProgressBar1.Max := FileSize;
      
  // Pra simplificar vou utilizar o "Bytes Per Sector" fixo de 512...
  // O ideal seria chamar a GetFileInformationByHandleEx pra pegar o PhysicalBytesPerSectorForAtomicity
  SectorSize := 512;

  // ReadFileScatter requer que o a quantidade de bytes lidos
  // seja um m�ltiplo do SectorSize do disco (normalmente entre 512-4096 bytes)...
  // Se eu tentar usar um valor que n�o � m�ltiplo do SectorSize do disco,
  // vou tomar um erro ERROR_INVALID_PARAMETER
  nNumberOfBytesToRead := StrToInt(Edit1.Text);

  // Identificando o �memory page size� do Windows
  // GetSystemInfo, vai preencher o dwPageSize na estrutura SYSTEM_INFO
  GetSystemInfo(vSYSTEM_INFO);

  // Com base no tamanho do "memory page size", especifico a quantidade
  // de FileSegmentElement que vou precissar no Array
  // + 1 no final, � pq o Array sempre precisa ter um elemento sobrando
  // pro "terminating NULL"
  // Ex, se quero ler 65536 bytes (64KB), preciso de (65536 / 4096) = 16 elementos + 1 pro NULL

  for i := 0 to High(vFileSegmentElement) - 1 do
  begin
    SetLength(vFileSegmentElement[i].FileSegmentElement, (nNumberOfBytesToRead div vSYSTEM_INFO.dwPageSize) + 1);

    // FillMemory aloca mem�ria com um valor
    FillMemory(@vFileSegmentElement[i].FileSegmentElement[0], Length(vFileSegmentElement[i].FileSegmentElement) * SizeOf(FILE_SEGMENT_ELEMENT), 0);

    // Alocando a mem�ria que ser� utilizada pra ler os dados do arquivo...
    // Lembrando, a mem�ria utilizada precisa estar alinhada com o �memory page size� do Windows.
    // Windows l� e escreve na mem�ria em blocos de 4KB.
    // VirtualAlloc j� faz a aloca��o utilizando o �memory page size�
    vFileSegmentElement[i].FileSegmentElement[0].Buffer := VirtualAlloc(nil, nNumberOfBytesToRead, MEM_COMMIT, PAGE_READWRITE);

    // Especificando a posi��o do ponteiro de mem�ria pra cada FileSegmentElement
    ii := 1;
    for ii := 1 to High(vFileSegmentElement[i].FileSegmentElement) - 1 do
    begin
      vFileSegmentElement[i].FileSegmentElement[ii].Buffer := Pointer(Cardinal(vFileSegmentElement[i].FileSegmentElement[ii - 1].Buffer) + vSYSTEM_INFO.dwPageSize);
    end;

    // �ltimo elemento � pro "Terminating NULL"
     vFileSegmentElement[i].FileSegmentElement[High(vFileSegmentElement[i].FileSegmentElement)].Buffer := nil;
  end;
      
  // Inicializando as estruturas Overlapped usando o "byte value" = "0"
  for i := 0 to (nOutstandingIOs -1) do
  begin
    FillMemory(@vOverlappedRead[i], SizeOf(vOverlappedRead[i]), 0);
    FillMemory(@vOverlappedWrite[i], SizeOf(vOverlappedWrite[i]), 0);
  end;


  // Arquivo que vou escrever os dados lidos...
  fPath := 'E:\Test3_Output.txt';
  DeleteFile(fPath);
  fHandleOutput := CreateFile(PChar(fPath), GENERIC_WRITE, FILE_SHARE_READ, nil,
    CREATE_ALWAYS, FILE_FLAG_SEQUENTIAL_SCAN or FILE_FLAG_NO_BUFFERING or FILE_FLAG_WRITE_THROUGH or FILE_FLAG_OVERLAPPED, 0);

  // Se o handle for inv�lido, disparar uma exce��o
  if fHandleOutput = INVALID_HANDLE_VALUE then
    raise Exception.Create('Deu ruim na hora de rodar o CreateFile... GetLastError() = ' + IntToStr(GetLastError()));

      
  i := 0;
  ii := 0;
  x := 0;
  BytesReturnedFromReadFileScatter := 0;
  FinalSize := 0;
  bFinishedIO := False;
      
  repeat
    // Especificando o Offset na estrutura Overlapped
    vOverlappedRead[i].OffsetHigh := 0;
    vOverlappedRead[i].Offset := Int64(nNumberOfBytesToRead) * x;
    vOverlappedWrite[i].OffsetHigh := 0;
    vOverlappedWrite[i].Offset := Int64(nNumberOfBytesToRead) * x;

    // Chamando a ReadFileScatter... Os dados lidos ser�o armazenados no array de FileSegmentElement
    ReadFileScatterResult := ReadFileScatter(fHandleInput, @vFileSegmentElement[i].FileSegmentElement[0], nNumberOfBytesToRead, nil, @vOverlappedRead[i]);

    // Se ReadFileScatter for false, deu algum erro no ReadFileScatter...
    if ReadFileScatterResult = False then
      ReadFileScatterResult := GetLastError() = ERROR_IO_PENDING;
    if ReadFileScatterResult = False then
      raise Exception.Create('Deu ruim na chamada da ReadFileScatter... GetLastError() = ' + IntToStr(GetLastError()));

    // Se o n�mero de I/Os gerados (chamadas a ReadFileScatter) for multiplo de nOutstandingIOs
    // ent�o para de gerar I/Os e chama a GetOverlappedResult pra esperar pelos I/Os terminarem...
    if (((i+1) mod nOutstandingIOs) = 0) and (i > 0) then
    begin
      for ii := 0 to nOutstandingIOs - 1 do
      begin
          
        vGetOverlappedResult := GetOverlappedResult(fHandleInput, vOverlappedRead[ii], BytesReturnedFromReadFileScatter, True);
        if (vGetOverlappedResult = false) then
        begin
          if GetLastError() = ERROR_HANDLE_EOF then
          begin
            bFinishedIO := True;
            Break;
          end
          else
            raise Exception.Create('Deu ruim na chamada da GetOverlappedResult... GetLastError() = ' + IntToStr(GetLastError()));;
        end;


        // Valida se chegou no final do arquivo
        if BytesReturnedFromReadFileScatter = 0 then
        begin
          bFinishedIO := True;
          Break;
        end;

        // Incrementa o total de bytes lidos pra eu ajustar o tamanho final do
        // arquivo utilizado no WriteFileGather
        Inc(FinalSize, BytesReturnedFromReadFileScatter);
        ProgressBar1.Position := FinalSize;
        Application.ProcessMessages;


        // Arredonda o n�mero de bytes lidos pra alinhar com o SectorSize pra evitar erro na escrita
        BytesReturnedFromReadFileScatter := (BytesReturnedFromReadFileScatter + (SectorSize-1)) and (not (SectorSize-1));

        WriteFileGatherResult := WriteFileGather(fHandleOutput, @vFileSegmentElement[ii].FileSegmentElement[0], BytesReturnedFromReadFileScatter, nil, @vOverlappedWrite[ii]);

        // Se WriteFileGatherResult for false, deu algum erro no ReadFileScatter...
        if WriteFileGatherResult = False then
          WriteFileGatherResult := GetLastError() = ERROR_IO_PENDING;
        if WriteFileGatherResult = False then
          raise Exception.Create('Deu ruim na chamada da WriteFileGather... GetLastError() = ' + IntToStr(GetLastError()));

        vGetOverlappedResult := GetOverlappedResult(fHandleOutput, vOverlappedWrite[ii], BytesReturnedFromWriteFileGatherResult, True);
        if (vGetOverlappedResult = false) then
        begin
          if GetLastError() = ERROR_HANDLE_EOF then
          begin
            bFinishedIO := True;
            Break;
          end
          else
            raise Exception.Create('Deu ruim na chamada da GetOverlappedResult... GetLastError() = ' + IntToStr(GetLastError()));;
        end;
          CloseHandle(fHandleOutput);
  CloseHandle(fHandleInput);

      end;
      i := -1;
    end;

    {
    // Arredonda o n�mero de bytes lidos pra alinhar com o SectorSize pra evitar erro na escrita
    BytesReturnedFromReadFileScatter := (BytesReturnedFromReadFileScatter + (SectorSize-1)) and (not (SectorSize-1));
        
    WriteFileGatherResult := WriteFileGather(fHandleOutput, @vFileSegmentElement[0], BytesReturnedFromReadFileScatter, nil, @O[2]);

    // Se WriteFileGatherResult for false, deu algum erro no ReadFileScatter...
    if WriteFileGatherResult = False then
      WriteFileGatherResult := GetLastError() = ERROR_IO_PENDING;
    if WriteFileGatherResult = False then
      raise Exception.Create('Deu ruim na chamada da WriteFileGather... GetLastError() = ' + IntToStr(GetLastError()));

    GetOverlappedResult(fHandleOutput, O[2], BytesReturnedFromWriteFileGatherResult, True);
    }
    Inc(i);
    Inc(x);
  Until (bFinishedIO = True);

  //eof.EndOfFile.QuadPart := FinalSize;
  //if not SetFileInformationByHandle(fHandleOutput, FileEndOfFileInfo, @eof, SizeOf(eof)) then RaiseLastOSError;

  CloseHandle(fHandleOutput);
  CloseHandle(fHandleInput);
  for i := 0 to High(vFileSegmentElement) - 1 do
    VirtualFree(vFileSegmentElement[i].FileSegmentElement, 0, MEM_RELEASE);

  T := Max(GetTickCount - T, 1);
  Memo3.Lines.Add('Termino do ReadFileScatter');
  Memo3.Lines.Add(Format('%d - %d - %.1n', [i, T, (i / T) * 2000]));
end;

end.
