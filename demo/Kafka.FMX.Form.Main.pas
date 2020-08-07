unit Kafka.FMX.Form.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, System.Actions, System.DateUtils, System.SyncObjs,
  System.Generics.Collections, System.Rtti,

  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.ActnList, FMX.Memo.Types, FMX.ScrollBox,
  FMX.Edit, FMX.EditBox, FMX.SpinBox, FMX.Memo, FMX.Layouts,
  FMX.Grid.Style, FMX.Grid,

  Kafka.Lib,
  Kafka.Factory,
  Kafka.Interfaces,
  Kafka.Helper,
  Kafka.Types,

  Kafka.FMX.Helper;

type
  TLogEntryRec = record
    Sender: String;
    Value: String;
    Timestamp: TDateTime;
  end;

  TfrmKafkaDemo = class(TForm)
    ActionList1: TActionList;
    tmrUpdate: TTimer;
    GridPanelLayout1: TGridPanelLayout;
    GroupBox3: TGroupBox;
    Layout1: TLayout;
    Label1: TLabel;
    edtKafkaServer: TEdit;
    actNewProducer: TAction;
    actNewConsumer: TAction;
    Button2: TButton;
    Button1: TButton;
    Options: TGroupBox;
    GroupBox1: TGroupBox;
    grdCallbacks: TGrid;
    colType: TStringColumn;
    colValue: TStringColumn;
    grdDebugLog: TGrid;
    colTimestamp: TStringColumn;
    colLogText: TStringColumn;
    colCallbackTimestamp: TStringColumn;
    colDebugType: TStringColumn;
    procedure tmrUpdateTimer(Sender: TObject);
    procedure ActionList1Update(Action: TBasicAction; var Handled: Boolean);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure edtKafkaServerChange(Sender: TObject);
    procedure edtTopicChange(Sender: TObject);
    procedure actNewProducerExecute(Sender: TObject);
    procedure actNewConsumerExecute(Sender: TObject);
    procedure grdCallbackLogGetValue(Sender: TObject; const ACol, ARow: Integer; var Value: TValue);
    procedure grdDebugLogGetValue(Sender: TObject; const ACol, ARow: Integer; var Value: TValue);
  private
    FStringEncoding: TEncoding;
    FKafkaConsumer: IKafkaConsumer;
    FCallbackLog: TList<TLogEntryRec>;
    FDebugLog: TList<TLogEntryRec>;

    procedure OnLog(const Values: TStrings);
    procedure UpdateStatus;
    procedure DestroyClasses;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  frmKafkaDemo: TfrmKafkaDemo;

implementation

{$R *.fmx}

uses
  Kafka.FMX.Form.Producer,
  Kafka.FMX.Form.Consumer;

{ TfrmKafkaDemo }

procedure TfrmKafkaDemo.OnLog(const Values: TStrings);
var
  i: Integer;
  LogEntryRec: TLogEntryRec;
  List: TList<TLogEntryRec>;
begin
  for i := 0 to pred(Values.Count) do
  begin
    LogEntryRec.Timestamp := now;
    LogEntryRec.Value := Values[i];
    LogEntryRec.Sender := KafkaLogTypeDescriptions[TKafkaLogType(Values.Objects[i])];

    if TKafkaLogType(Values.Objects[i]) in [kltProducer, kltConsumer] then
    begin
      List := FCallbackLog;
    end
    else
    begin
      List := FDebugLog;
    end;

    List.Add(LogEntryRec);
  end;

  while FCallbackLog.Count > TFMXHelper.MAX_LOG_LINES do
  begin
    FCallbackLog.Delete(0);
  end;

  while FDebugLog.Count > TFMXHelper.MAX_LOG_LINES do
  begin
    FDebugLog.Delete(0);
  end;

  TFMXHelper.SetGridRowCount(grdCallbacks, FCallbackLog.Count);
  TFMXHelper.SetGridRowCount(grdDebugLog, FDebugLog.Count);
end;

procedure TfrmKafkaDemo.actNewConsumerExecute(Sender: TObject);
begin
  with TfrmConsume.Create(Self) do
  begin
    Execute(edtKafkaServer.Text);
  end;
end;

procedure TfrmKafkaDemo.actNewProducerExecute(Sender: TObject);
begin
  with TfrmProduce.Create(Self) do
  begin
    Execute(edtKafkaServer.Text);
  end;
end;

procedure TfrmKafkaDemo.ActionList1Update(Action: TBasicAction; var Handled: Boolean);
begin
  Handled := True;
end;

constructor TfrmKafkaDemo.Create(AOwner: TComponent);
begin
  inherited;

  TKafkaHelper.OnLog := OnLog;
  FStringEncoding := TEncoding.UTF8;

  FCallbackLog := TList<TLogEntryRec>.Create;
  FDebugLog := TList<TLogEntryRec>.Create;

  UpdateStatus;
end;

procedure TfrmKafkaDemo.edtKafkaServerChange(Sender: TObject);
begin
  DestroyClasses;
end;

procedure TfrmKafkaDemo.edtTopicChange(Sender: TObject);
begin
  FKafkaConsumer := nil;
end;

destructor TfrmKafkaDemo.Destroy;
begin
  FreeAndNil(FCallbackLog);
  FreeAndNil(FDebugLog);

  inherited;
end;

procedure TfrmKafkaDemo.DestroyClasses;
begin
  FKafkaConsumer := nil;
end;

procedure TfrmKafkaDemo.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  DestroyClasses;

  // Wait for all the threads to terminate
  sleep(1000);
end;

procedure TfrmKafkaDemo.grdCallbackLogGetValue(Sender: TObject; const ACol, ARow: Integer; var Value: TValue);
begin
  case ACol of
    0: Value := TKafkaUtils.DateTimeToStrMS(FCallbackLog[ARow].Timestamp);
    1: Value := FCallbackLog[ARow].Sender;
    2: Value := FCallbackLog[ARow].Value;
  end;
end;

procedure TfrmKafkaDemo.grdDebugLogGetValue(Sender: TObject; const ACol, ARow: Integer; var Value: TValue);
begin
  case ACol of
    0: Value := TKafkaUtils.DateTimeToStrMS(FDebugLog[ARow].Timestamp);
    1: Value := FDebugLog[ARow].Sender;
    2: Value := FDebugLog[ARow].Value;
  end;
end;

procedure TfrmKafkaDemo.tmrUpdateTimer(Sender: TObject);
begin
  UpdateStatus;
end;

procedure TfrmKafkaDemo.UpdateStatus;
begin
  TKafkaHelper.FlushLogs;
end;

end.
