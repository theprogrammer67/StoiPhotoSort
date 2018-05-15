unit uMainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, uPhotoSort, Vcl.ComCtrls,
  Vcl.Menus, System.UITypes, Vcl.ToolWin, Vcl.ActnMan, Vcl.ActnCtrls,
  Vcl.ExtCtrls, Vcl.PlatformDefaultStyleActnCtrls, System.Actions, Vcl.ActnList,
  System.ImageList, Vcl.ImgList;

const
  INI_FILENAME = 'settings.ini';
  APPDATA_DIR = 'StoiPhotoSort';
  TAG_SETTINGS = 'settings';

type
  TfrmMainForm = class(TForm)
    lblPrefix: TLabel;
    actmgrActions: TActionManager;
    actAddDestination: TAction;
    actDeleteDestination: TAction;
    actClearDestination: TAction;
    actEditDestination: TAction;
    statStatus: TStatusBar;
    ilImages: TImageList;
    pnlBottom: TPanel;
    pnlDestionation: TPanel;
    acttbDestionation: TActionToolBar;
    lvDestinations: TListView;
    btnCopyFiles: TButton;
    edtPrefix: TEdit;
    pbCopyProgress: TProgressBar;
    btn1: TButton;
    btn2: TButton;
    pnlBody: TPanel;
    lvPhotos: TListView;
    pnlTop: TPanel;
    btnSelectSrcFolder: TButton;
    edtSrcPath: TEdit;
    imgSource: TImage;
    procedure btnSelectSrcFolderClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnCopyFilesClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure actAddDestinationExecute(Sender: TObject);
    procedure actClearDestinationExecute(Sender: TObject);
    procedure actDeleteDestinationExecute(Sender: TObject);
    procedure lvDestinationsClick(Sender: TObject);
    procedure lvDestinationsDblClick(Sender: TObject);
    procedure btn1Click(Sender: TObject);
    procedure btn2Click(Sender: TObject);
    procedure edtSrcPathChange(Sender: TObject);
  private
    FDefFolder: string;
    FPhotoSort: TPhotoSort;
    FDestination: string;
  private
    procedure SelectSrcFile(APhoto: TPhoto);
    procedure DoCopyFile(Sender: TObject);
    procedure LoadPhotos;
    // procedure DoAddFile(Sender: TObject);
    procedure CopyFiles(const ADestinfation: string);
    procedure UpdateData;
    procedure SaveSettings;
    procedure ReadSettings;
    function SelectFolder(const ACaption, ADefDestination: string): string;
  private
    procedure OnMsgAddFile(var Msg: TMessage); message WM_ADDFILE;
    procedure OnMsgClear(var Msg: TMessage); message WM_CLEAR;
    procedure OnMsgLoaded(var Msg: TMessage); message WM_LOADED;
  public
    { Public declarations }
  end;

var
  frmMainForm: TfrmMainForm;

implementation

uses Winapi.ShlObj, System.IniFiles;

function BrowseCallbackProc(HWND: HWND; uMsg: UINT; lParam: lParam;
  lpData: lParam): Integer; stdcall;
begin
  if (uMsg = BFFM_INITIALIZED) then
  begin
    if frmMainForm.FDefFolder = '' then
      SendMessage(HWND, BFFM_SETSELECTION, 1, lpData)
    else
      SendMessage(HWND, BFFM_SETSELECTION, Integer(True),
        Integer(PChar(frmMainForm.FDefFolder)));
  end;

  Result := 0;
end;

function GetFolderDialog(Handle: Integer; Caption: string;
  var strFolder: string): Boolean;
const
  BIF_STATUSTEXT = $0004;
  BIF_NEWDIALOGSTYLE = $0040;
  BIF_RETURNONLYFSDIRS = $0080;
  BIF_SHAREABLE = $0100;
  BIF_USENEWUI = BIF_EDITBOX or BIF_NEWDIALOGSTYLE;
var
  BrowseInfo: TBrowseInfo;
  ItemIDList: PItemIDList;
  JtemIDList: PItemIDList;
  Path: PChar;
begin
  Result := False;
  Path := StrAlloc(MAX_PATH);
  SHGetSpecialFolderLocation(Handle, CSIDL_DRIVES, JtemIDList);
  with BrowseInfo do
  begin
    hwndOwner := GetActiveWindow;
    pidlRoot := JtemIDList;
    SHGetSpecialFolderLocation(hwndOwner, CSIDL_DRIVES, JtemIDList);
    ulFlags := BIF_RETURNONLYFSDIRS or BIF_NEWDIALOGSTYLE or
      BIF_NONEWFOLDERBUTTON;

    pszDisplayName := StrAlloc(MAX_PATH);
    { Возврат названия выбранного элемента }
    lpszTitle := PChar(Caption); { Установка названия диалога выбора папки }
    lpfn := @BrowseCallbackProc; { Флаги, контролирующие возврат }
    lParam := LongInt(PChar(strFolder));
    { Дополнительная информация, которая отдаётся обратно в обратный вызов (callback) }
  end;

  ItemIDList := SHBrowseForFolder(BrowseInfo);

  if (ItemIDList <> nil) then
    if SHGetPathFromIDList(ItemIDList, Path) then
    begin
      strFolder := Path;
      GlobalFreePtr(ItemIDList);
      Result := True;
    end;

  GlobalFreePtr(JtemIDList);
  StrDispose(Path);
  StrDispose(BrowseInfo.pszDisplayName);
end;

function GetSpecialPath(CSIDL: Word): string;
var
  S: string;
begin
  SetLength(S, MAX_PATH);
  if not SHGetSpecialFolderPath(0, PChar(S), CSIDL, True) then
    S := GetSpecialPath(CSIDL_APPDATA);
  Result := IncludeTrailingPathDelimiter(PChar(S));
end;

function GetIniFilePath: string;
begin
  Result := IncludeTrailingPathDelimiter(GetSpecialPath(CSIDL_COMMON_APPDATA) +
    APPDATA_DIR);
  ForceDirectories(Result);
  Result := Result + INI_FILENAME;
end;

{$R *.dfm}

procedure TfrmMainForm.actAddDestinationExecute(Sender: TObject);
var
  LItem: TListItem;
  LFolder: string;
begin
  LFolder := SelectFolder('Select destionation', '');
  if LFolder.IsEmpty then
    Exit;

  LItem := lvDestinations.Items.Add;
  LItem.Checked := True;
  LItem.Caption := LFolder;
  LItem.ImageIndex := 1;
end;

procedure TfrmMainForm.actClearDestinationExecute(Sender: TObject);
begin
  lvDestinations.Clear;
end;

procedure TfrmMainForm.actDeleteDestinationExecute(Sender: TObject);
var
  LItem: TListItem;
begin
  LItem := lvDestinations.Selected;
  if not Assigned(LItem) then
    Exit;

  lvDestinations.DeleteSelected;
end;

procedure TfrmMainForm.btn1Click(Sender: TObject);
begin
  LoadPhotos;
end;

procedure TfrmMainForm.btn2Click(Sender: TObject);
begin
  FPhotoSort.TerminateThreads;
end;

procedure TfrmMainForm.btnCopyFilesClick(Sender: TObject);
var
  I: Integer;
begin
  UpdateData;

  // FPhotoSort.LoadPhotos(edtSrcPath.Text);
  FPhotoSort.AddPrefix := Trim(edtPrefix.Text);

  for I := 0 to lvDestinations.Items.Count - 1 do
  begin
    lvDestinations.ItemIndex := I;
    if lvDestinations.Items[I].Checked then
      CopyFiles(lvDestinations.Items[I].Caption);
  end;
end;

procedure TfrmMainForm.btnSelectSrcFolderClick(Sender: TObject);
var
  LFolder: string;
begin
  LFolder := SelectFolder('Select source directory', edtSrcPath.Text);
  if LFolder.IsEmpty then
    Exit;

  edtSrcPath.Text := LFolder;
end;

procedure TfrmMainForm.CopyFiles(const ADestinfation: string);
begin
  FDestination := ADestinfation;
  // statStatus.Panels[0].Text := 'Copyng to: ' + ADestinfation;
  pbCopyProgress.Max := FPhotoSort.Count - 1;
  pbCopyProgress.Position := 0;

  if not FPhotoSort.SavePhotos(ADestinfation) then
    MessageDlg('Error copyng files to "' + ADestinfation + '"', mtError,
      [mbOK], 0);

  pbCopyProgress.Position := 0;
  statStatus.Panels[0].Text := '';
end;

procedure TfrmMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveSettings;
end;

procedure TfrmMainForm.FormCreate(Sender: TObject);
begin
  FPhotoSort := TPhotoSort.Create(Self.Handle);
  FPhotoSort.OnCopyFile := DoCopyFile;

  ReadSettings;
end;

procedure TfrmMainForm.FormDestroy(Sender: TObject);
begin
  FPhotoSort.Free;
end;

procedure TfrmMainForm.LoadPhotos;
begin
  // lvPhotos.Clear;
  FPhotoSort.ExecLoadPhotos(edtSrcPath.Text);
end;

procedure TfrmMainForm.lvDestinationsClick(Sender: TObject);
var
  LItem: TListItem;
begin
  LItem := lvDestinations.Selected;
  if not Assigned(LItem) then
    Exit;
end;

procedure TfrmMainForm.lvDestinationsDblClick(Sender: TObject);
var
  LItem: TListItem;
  LFolder: string;
begin
  LItem := lvDestinations.Selected;
  if not Assigned(LItem) then
    Exit;

  LFolder := SelectFolder('Select destination', LItem.Caption);
  if not LFolder.IsEmpty then
    LItem.Caption := LFolder;
end;

procedure TfrmMainForm.OnMsgAddFile(var Msg: TMessage);
var
  LPhoto: TPhoto;
  LItem: TListItem;
begin
  LPhoto := TPhoto(Msg.WParam);
  LItem := lvPhotos.Items.Add;
  LItem.Caption := LPhoto.FName;
  LItem.Data := LPhoto;
  LItem.ImageIndex := 0;
  LItem.Checked := True;
end;

procedure TfrmMainForm.OnMsgClear(var Msg: TMessage);
begin
  lvPhotos.Clear;
  btnCopyFiles.Enabled := False;
end;

procedure TfrmMainForm.OnMsgLoaded(var Msg: TMessage);
begin
  btnCopyFiles.Enabled := Boolean(Msg.WParam);
end;

procedure TfrmMainForm.DoCopyFile(Sender: TObject);
begin
  pbCopyProgress.Position := pbCopyProgress.Position + 1;
  statStatus.Panels[0].Text := 'Copyng to "' + FDestination + '": ' +
    IntToStr(pbCopyProgress.Position) + ' - ' + TPhoto(Sender).FName;
  SelectSrcFile(TPhoto(Sender));

  pbCopyProgress.Invalidate;
  Application.ProcessMessages;
end;

procedure TfrmMainForm.edtSrcPathChange(Sender: TObject);
begin
  LoadPhotos;
end;

procedure TfrmMainForm.SaveSettings;
var
  Ini: TIniFile;
  I: Integer;
begin
  Ini := TIniFile.Create(GetIniFilePath);
  try
    Ini.WriteString(TAG_SETTINGS, 'source', edtSrcPath.Text);
    Ini.WriteString(TAG_SETTINGS, 'prefix', edtPrefix.Text);
    Ini.EraseSection('destinations');
    for I := 0 to lvDestinations.Items.Count - 1 do
    begin
      Ini.WriteString('destinations', lvDestinations.Items[I].Caption,
        BoolToStr(lvDestinations.Items[I].Checked, True));
    end;
  finally
    FreeAndNil(Ini);
  end;
end;

function TfrmMainForm.SelectFolder(const ACaption, ADefDestination
  : string): string;
var
  LFolder: string;
begin
  FDefFolder := ADefDestination;
  if not GetFolderDialog(Handle, ACaption, LFolder) then
    Exit('');

  Result := LFolder;
end;

procedure TfrmMainForm.SelectSrcFile(APhoto: TPhoto);
var
  I: Integer;
begin
  for I := 0 to lvPhotos.Items.Count - 1 do
  begin
    if APhoto = TPhoto(lvPhotos.Items[I].Data) then
    begin
      lvPhotos.ItemIndex := I;
      Exit;
    end;
  end;
end;

procedure TfrmMainForm.UpdateData;
var
  I: Integer;
begin
  for I := 0 to lvPhotos.Items.Count - 1 do
    TPhoto(lvPhotos.Items[I].Data).FChecked := lvPhotos.Items[I].Checked;
end;

procedure TfrmMainForm.ReadSettings;
var
  Ini: TIniFile;
  LFolders: TStrings;
  I: Integer;
  LItem: TListItem;
begin
  Ini := TIniFile.Create(GetIniFilePath);
  try
    edtSrcPath.Text := Ini.ReadString(TAG_SETTINGS, 'source', '');
    edtPrefix.Text := Ini.ReadString(TAG_SETTINGS, 'prefix', '');

    lvDestinations.Clear;
    LFolders := TStringList.Create;
    try
      Ini.ReadSectionValues('destinations', LFolders);
      for I := 0 to LFolders.Count - 1 do
      begin
        LItem := lvDestinations.Items.Add;
        LItem.Caption := LFolders.KeyNames[I];
        LItem.Checked := StrToBoolDef(LFolders.ValueFromIndex[I], False);
        LItem.ImageIndex := 1;
      end;
    finally
      FreeAndNil(LFolders);
    end;
  finally
    FreeAndNil(Ini);
  end;
end;

end.
