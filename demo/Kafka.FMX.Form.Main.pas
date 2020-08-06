unit Kafka.FMX.Form.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, System.Actions, System.DateUtils, System.SyncObjs,

  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.ActnList, FMX.Memo.Types, FMX.ScrollBox,
  FMX.Edit, FMX.EditBox, FMX.SpinBox, FMX.Memo, FMX.Layouts,

  Kafka.Lib,
  Kafka.Factory,
  Kafka.Interfaces,
  Kafka.Helper,
  Kafka.Types;

type
  TfrmKafkaDemo = class(TForm)
    ActionList1: TActionList;
    tmrUpdate: TTimer;
    GridPanelLayout1: TGridPanelLayout;
    GroupBox2: TGroupBox;
    memLogConsumer: TMemo;
    Options: TGroupBox;
    memLogOther: TMemo;
    GroupBox3: TGroupBox;
    Layout1: TLayout;
    Label1: TLabel;
    edtKafkaServer: TEdit;
    Layout2: TLayout;
    Label2: TLabel;
    edtTopic: TEdit;
    Layout4: TLayout;
    Label3: TLabel;
    edtMessage: TEdit;
    Layout5: TLayout;
    Label4: TLabel;
    edtKey: TEdit;
    actNewProducer: TAction;
    Layout3: TLayout;
    Button1: TButton;
    chkLog: TCheckBox;
    Button2: TButton;
    actNewConsumer: TAction;
    GroupBox1: TGroupBox;
    memLogProducer: TMemo;
    procedure tmrUpdateTimer(Sender: TObject);
    procedure ActionList1Update(Action: TBasicAction; var Handled: Boolean);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure edtKafkaServerChange(Sender: TObject);
    procedure edtTopicChange(Sender: TObject);
    procedure actNewProducerExecute(Sender: TObject);
    procedure actNewConsumerExecute(Sender: TObject);
  private
    FStringEncoding: TEncoding;
    FKafkaConsumer: IKafkaConsumer;

    procedure OnLog(const Values: TStrings);
    procedure UpdateStatus;
    procedure DestroyClasses;
  public
    constructor Create(AOwner: TComponent); override;
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
  Memo: TMemo;
begin
  for i := 0 to pred(Values.Count) do
  begin
    case TKafkaLogType(Values.Objects[i]) of
      kltProducer: Memo := memLogProducer;
      kltConsumer: Memo := memLogConsumer;
    else
      Memo := memLogOther;
    end;

    if (Memo = memLogOther) or
       (chkLog.IsChecked) then
    begin
      Memo.Lines.Add(Values[i]);
    end;
  end;
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

procedure TfrmKafkaDemo.tmrUpdateTimer(Sender: TObject);
begin
  UpdateStatus;
end;

procedure TfrmKafkaDemo.UpdateStatus;
begin
  TKafkaHelper.FlushLogs;
end;

end.
