unit Kafka.FMX.Form.Producer;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.DateUtils,

  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, System.Actions, FMX.ActnList,
  FMX.Memo.Types, FMX.Edit, FMX.StdCtrls, FMX.ScrollBox, FMX.Memo,
  FMX.EditBox, FMX.SpinBox, FMX.Layouts, FMX.Controls.Presentation,

  Kafka.Lib,
  Kafka.Factory,
  Kafka.Interfaces,
  Kafka.Helper,
  Kafka.Types;

type
  TfrmProduce = class(TForm)
    tmrUpdate: TTimer;
    lblStatus: TLabel;
    Layout1: TLayout;
    Layout2: TLayout;
    Label2: TLabel;
    edtTopic: TEdit;
    Layout4: TLayout;
    Label3: TLabel;
    edtMessage: TEdit;
    Layout5: TLayout;
    Label4: TLabel;
    edtKey: TEdit;
    Layout3: TLayout;
    edtMessageCount: TSpinBox;
    Button1: TButton;
    Button4: TButton;
    chkFlushAfterProduce: TCheckBox;
    memConfig: TMemo;
    ActionList1: TActionList;
    Layout6: TLayout;
    Label1: TLabel;
    edtPartition: TSpinBox;
    procedure ActionList1Execute(Action: TBasicAction; var Handled: Boolean);
    procedure tmrUpdateTimer(Sender: TObject);
    procedure memConfigChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Action1Execute(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
  private
    FKafkaProducer: IKafkaProducer;
    FKafkaCluster: String;
    FStringEncoding: TEncoding;

    procedure UpdateStatus;
    procedure Start;
  public
    constructor Create(AOwner: TComponent); override;

    procedure Execute(const KafkaServers: String);
  end;

var
  frmProduce: TfrmProduce;

implementation

{$R *.fmx}

procedure TfrmProduce.Action1Execute(Sender: TObject);
var
  Msgs: TArray<String>;
  i: Integer;
begin
  Start;

  SetLength(Msgs, Trunc(edtMessageCount.Value));

  for i := 0 to pred(Trunc(edtMessageCount.Value)) do
  begin
    Msgs[i] := edtMessage.Text + ' - ' + DateTimeToStr(now) + '.' + MilliSecondOf(now).ToString.PadLeft(3, '0');
  end;

  FKafkaProducer.Produce(
    edtTopic.Text,
    Msgs,
    edtKey.Text,
    FStringEncoding,
    RD_KAFKA_PARTITION_UA,
    RD_KAFKA_MSG_F_COPY,
    @self);

  if chkFlushAfterProduce.IsChecked then
  begin
    TKafkaHelper.Flush(FKafkaProducer.KafkaHandle);
  end;
end;

procedure TfrmProduce.ActionList1Execute(Action: TBasicAction; var Handled: Boolean);
begin
  //actFlush.Enabled := FKafkaProducer <> nil;

  Handled := True;
end;

procedure TfrmProduce.Button1Click(Sender: TObject);
var
  Msgs: TArray<String>;
  i: Integer;
begin
  Start;

  SetLength(Msgs, Trunc(edtMessageCount.Value));

  for i := 0 to pred(Trunc(edtMessageCount.Value)) do
  begin
    Msgs[i] := edtMessage.Text + ' - ' + DateTimeToStr(now) + '.' + MilliSecondOf(now).ToString.PadLeft(3, '0');
  end;

  FKafkaProducer.Produce(
    edtTopic.Text,
    Msgs,
    edtKey.Text,
    FStringEncoding,
    Trunc(edtPartition.Value),
    RD_KAFKA_MSG_F_COPY);

  if chkFlushAfterProduce.IsChecked then
  begin
    TKafkaHelper.Flush(FKafkaProducer.KafkaHandle);
  end;
end;

procedure TfrmProduce.Button4Click(Sender: TObject);
begin
  Start;

  TKafkaHelper.Flush(FKafkaProducer.KafkaHandle);
end;

constructor TfrmProduce.Create(AOwner: TComponent);
begin
  inherited;

  FStringEncoding := TEncoding.UTF8;

  UpdateStatus;
end;

procedure TfrmProduce.Execute(const KafkaServers: String);
begin
  FKafkaCluster := KafkaServers;

  memConfig.Text := 'bootstrap.servers=' + KafkaServers;

  Show;

  Start;
end;

procedure TfrmProduce.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

procedure TfrmProduce.memConfigChange(Sender: TObject);
begin
  FKafkaProducer := nil;
end;

procedure TfrmProduce.Start;
var
  Names, Values: TArray<String>;
begin
  if FKafkaProducer = nil then
  begin
    TKafkaUtils.StringsToConfigArrays(memConfig.Lines, Names, Values);

    FKafkaProducer := TKafkaFactory.NewProducer(
      Names,
      Values);
  end;
end;

procedure TfrmProduce.tmrUpdateTimer(Sender: TObject);
begin
  UpdateStatus;
end;

procedure TfrmProduce.UpdateStatus;
var
  ProducedStr: String;
begin
  if FKafkaProducer = nil then
  begin
    ProducedStr := 'Idle';
  end
  else
  begin
    ProducedStr := FKafkaProducer.ProducedCount.ToString;
  end;

  lblStatus.Text := 'Produced: ' + ProducedStr;
end;

end.
