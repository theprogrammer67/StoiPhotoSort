program StoiPhotoSort;

uses
  Vcl.Forms,
  uMainForm in 'uMainForm.pas' {frmMainForm},
  uPhotoSort in 'uPhotoSort.pas',
  Vcl.Themes,
  Vcl.Styles,
  CCR.Exif.Consts in 'CCR.Exif-1.1.2\CCR.Exif.Consts.pas',
  CCR.Exif.IPTC in 'CCR.Exif-1.1.2\CCR.Exif.IPTC.pas',
  CCR.Exif.JpegUtils in 'CCR.Exif-1.1.2\CCR.Exif.JpegUtils.pas',
  CCR.Exif in 'CCR.Exif-1.1.2\CCR.Exif.pas',
  CCR.Exif.StreamHelper in 'CCR.Exif-1.1.2\CCR.Exif.StreamHelper.pas',
  CCR.Exif.TagIDs in 'CCR.Exif-1.1.2\CCR.Exif.TagIDs.pas',
  CCR.Exif.XMPUtils in 'CCR.Exif-1.1.2\CCR.Exif.XMPUtils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Smokey Quartz Kamri');
  Application.CreateForm(TfrmMainForm, frmMainForm);
  Application.Run;
end.
