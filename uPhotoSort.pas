unit uPhotoSort;

interface

uses Classes, Winapi.Messages, System.SysUtils;

const
  WM_ADDFILE = WM_USER + 0;
  WM_CLEAR = WM_USER + 1;
  WM_SAVEFILE = WM_USER + 2;
  WM_LOADED = WM_USER + 3;

type
  TPhoto = class
    FName: string;
    FDate: TDateTime;
    FChecked: Boolean;
    constructor Create(const FileName: string; FileDate: TDateTime);
  end;

  TPhotoSort = class(TList)
  private
    FFmtStngs: TFormatSettings;
    FAddPrefix: string;
    FSrcFolder: string;
    FCurrItem: TPhoto;
    FOnCopyFile: TNotifyEvent;
    FOnAddFile: TNotifyEvent;
    FOwnerHwnd: THandle;
    FLoadPhotosThread: TThread;
    FThreadTerminated: Boolean;
    FLoaded: Boolean;
    function Get(Index: Integer): TPhoto;
    procedure Put(Index: Integer; const Value: TPhoto);
    // procedure DoAddFile;
  protected
    procedure Notify(Ptr: Pointer; Action: TListNotification); override;
  public
    constructor Create(AOwnerHwnd: THandle);
    destructor Destroy; override;
    function Add(const FileName: string; FileDate: TDate): Integer; overload;
  public
    procedure LoadPhotos(const SrcFolder: string); overload;
    procedure LoadPhotos; overload;
    procedure ExecLoadPhotos(const ASrcFolder: string);
    function SavePhotos(const ADstFolder: string): Boolean;
    procedure TerminateThreads;
  public
    property Items[Index: Integer]: TPhoto read Get write Put; default;
    property OnCopyFile: TNotifyEvent read FOnCopyFile write FOnCopyFile;
    property AddPrefix: string read FAddPrefix write FAddPrefix;
    property OnAddFile: TNotifyEvent read FOnAddFile write FOnAddFile;
    property Loaded: Boolean read FLoaded;
  end;

implementation

uses Winapi.Windows, CCR.Exif, uMainForm;

{ TPhotoSort }

function TPhotoSort.Add(const FileName: string; FileDate: TDate): Integer;
begin
  Result := inherited Add(TPhoto.Create(FileName, FileDate));
  FCurrItem := Self[Result];
  PostMessage(FOwnerHwnd, WM_ADDFILE, Integer(Self[Result]), 0);
end;

constructor TPhotoSort.Create(AOwnerHwnd: THandle);
begin
  inherited Create;
  FOwnerHwnd := AOwnerHwnd;
  FFmtStngs.DateSeparator := '_';
  FLoaded := False;
end;

destructor TPhotoSort.Destroy;
begin
  FThreadTerminated := True;
  // TerminateThreads;
  inherited;
end;

procedure TPhotoSort.ExecLoadPhotos(const ASrcFolder: string);
begin
  FSrcFolder := IncludeTrailingPathDelimiter(ASrcFolder);

  FLoadPhotosThread := TThread.CreateAnonymousThread(
    procedure()
    begin
      try
        LoadPhotos;
      except
      end;
    end);
  FLoadPhotosThread.Start;
  // Sleep(50);
  // FThreadTerminated := True;
  // FLoadPhotosThread.Terminate;
end;

function TPhotoSort.Get(Index: Integer): TPhoto;
begin
  Result := TPhoto(inherited Get(Index));
end;

procedure TPhotoSort.LoadPhotos;
var
  SearchRec: TSearchRec; // поисковая переменная
  FindRes: Integer;
  FileDate: TDateTime;
  ExifData: TExifData;
begin
  Clear;
  FThreadTerminated := False;
  FLoaded := False;
  PostMessage(FOwnerHwnd, WM_CLEAR, 0, 0);

  try
    ExifData := TExifData.Create;
    try
      FindRes := System.SysUtils.FindFirst(FSrcFolder + '*.jpg', faAnyFile,
        SearchRec);

      while FindRes = 0 do
      begin
        ExifData.LoadFromJPEG(FSrcFolder + SearchRec.Name);
        if ExifData.Empty then
          FileDate := SearchRec.TimeStamp
        else
          FileDate := ExifData.DateTime;

        Add(SearchRec.Name, FileDate);
        if FThreadTerminated then
          Exit
        else
          FindRes := FindNext(SearchRec);
      end;

      FLoaded := Count > 0;
      PostMessage(FOwnerHwnd, WM_LOADED, Integer(FLoaded), 0);
    finally
      System.SysUtils.FindClose(SearchRec);
      ExifData.Free;
    end;
  except
  end;
end;

procedure TPhotoSort.LoadPhotos(const SrcFolder: string);
begin
  FSrcFolder := IncludeTrailingPathDelimiter(SrcFolder);
  LoadPhotos;
end;

procedure TPhotoSort.Notify(Ptr: Pointer; Action: TListNotification);
begin
  if Action = lnDeleted then
    TPhoto(Ptr).Free;
end;

procedure TPhotoSort.Put(Index: Integer; const Value: TPhoto);
begin
  inherited Put(Index, Pointer(Value));
end;

function TPhotoSort.SavePhotos(const ADstFolder: string): Boolean;
var
  I: Integer;
  FileFolder: string;
begin
  // FormatSettings.DateSeparator := '_';
  Result := False;

  for I := 0 to Count - 1 do
  begin
    if not Items[I].FChecked then
      Continue;

    FileFolder := IncludeTrailingPathDelimiter(ADstFolder) +
      FormatDateTime('yyyy', Items[I].FDate, FFmtStngs) + '\' +
      FormatDateTime('mm', Items[I].FDate, FFmtStngs) + '\' +
      FormatDateTime('yyyy_mm_dd', Items[I].FDate, FFmtStngs);

    Result := ForceDirectories(FileFolder);
    if not Result then
      Exit;

    Result := CopyFile(PWideChar(FSrcFolder + Items[I].FName),
      PWideChar(FileFolder + '\' + Trim(FAddPrefix) + Items[I].FName), False);

    if not Result then
      Exit;

    if Assigned(FOnCopyFile) then
      FOnCopyFile(Items[I]);
  end;
end;

procedure TPhotoSort.TerminateThreads;
begin
  FThreadTerminated := True;
  try
    if Assigned(FLoadPhotosThread) and FLoadPhotosThread.Started and
      (not FLoadPhotosThread.Finished) then
    begin
      FLoadPhotosThread.Terminate;
      FLoadPhotosThread.WaitFor;
    end;
  except
  end;
end;

{ TPhoto }

constructor TPhoto.Create(const FileName: string; FileDate: TDateTime);
begin
  FName := FileName;
  FDate := FileDate;
end;

end.
