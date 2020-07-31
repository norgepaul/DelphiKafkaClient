unit frmMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, System.Actions, System.DateUtils, System.SyncObjs,

  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.ActnList, FMX.Memo.Types, FMX.ScrollBox,
  FMX.Edit, FMX.EditBox, FMX.SpinBox, FMX.Memo, FMX.Layouts,

  Kafka.Lib,
  Kafka.Classes,
  Kafka.Types;

type
  EKafkaError = class(Exception);

  TfrmKafkaDemo = class(TForm)
    ActionList1: TActionList;
    actProduceMessage: TAction;
    actStartConsuming: TAction;
    Layout1: TLayout;
    tmrLog: TTimer;
    Layout2: TLayout;
    Button2: TButton;
    actStopConsuming: TAction;
    Button3: TButton;
    Layout3: TLayout;
    edtMessageCount: TSpinBox;
    Button1: TButton;
    GridPanelLayout1: TGridPanelLayout;
    memLogProducer: TMemo;
    memLogConsumer: TMemo;
    memLogOther: TMemo;
    procedure actProduceMessageExecute(Sender: TObject);
    procedure actStartConsumingExecute(Sender: TObject);
    procedure tmrLogTimer(Sender: TObject);
    procedure actStopConsumingExecute(Sender: TObject);
    procedure ActionList1Update(Action: TBasicAction; var Handled: Boolean);
  private
    FKafkaConsumer: TKafkaConsumer;

    procedure OnLog(const Values: TStrings);
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  frmKafkaDemo: TfrmKafkaDemo;

implementation

{$R *.fmx}

{ TfrmKafkaDemo }

const
  KafkaServers = '127.0.0.1:9092';
  DefaultTopic = 'test';
  DefaultMessage = 'This is a test message';

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

    Memo.Lines.Add(Values[i]);
  end;
end;

procedure TfrmKafkaDemo.actStartConsumingExecute(Sender: TObject);
var
  Configuration: prd_kafka_conf_t;
  TopicConfiguration: prd_kafka_topic_conf_t;
  TopicName: PAnsiChar;
  Brokers: PAnsiChar;
begin
  if FKafkaConsumer = nil then
  begin
    Brokers := KafkaServers;
    TopicName := DefaultTopic;

    Configuration := TKafka.NewConfiguration(
      ['group.id'],
      ['GroupID']);

    TopicConfiguration := TKafka.NewTopicConfiguration(
      ['auto.offset.reset'],
      ['earliest']);

    rd_kafka_conf_set_default_topic_conf(
      Configuration,
      TopicConfiguration);

    FKafkaConsumer := TKafka.NewConsumer(
      Configuration,
      Brokers,
      [TopicName],
      [0],
      procedure(const Msg: prd_kafka_message_t)
      begin
        TKafka.Log(format('Message received - %s', [TKafkaHelper.PointerToStr(Msg.payload, Msg.len)]), TKafkaLogType.kltConsumer);
      end);

    FKafkaConsumer.Start;
  end;
end;

procedure TfrmKafkaDemo.actStopConsumingExecute(Sender: TObject);
begin
  if FKafkaConsumer <> nil then
  begin
    FKafkaConsumer.Free;

    FKafkaConsumer := nil;
  end;
end;

procedure TfrmKafkaDemo.ActionList1Update(Action: TBasicAction; var Handled: Boolean);
begin
  actStartConsuming.Enabled := FKafkaConsumer = nil;
  actStopConsuming.Enabled := FKafkaConsumer <> nil;

  Handled := True;
end;

procedure TfrmKafkaDemo.actProduceMessageExecute(Sender: TObject);
var
  Configuration: prd_kafka_conf_t;
  KafkaHandle: prd_kafka_t;
  Topic: prd_kafka_topic_t;
  Msgs: TArray<AnsiString>;
  i: Integer;
begin
  Configuration := TKafka.NewConfiguration(
    ['bootstrap.servers'],
    [KafkaServers]);

  KafkaHandle := TKafka.NewProducer(Configuration);
  try
    Topic := TKafka.NewTopic(
      KafkaHandle,
      DefaultTopic,
      nil);

    try
      SetLength(Msgs, Trunc(edtMessageCount.Value));

      for i := 0 to pred(Trunc(edtMessageCount.Value)) do
      begin
        Msgs[i] := AnsiString(DefaultMessage + ' - ' + DateTimeToStr(now) + '.' + MilliSecondOf(now).ToString.PadLeft(3, '0'));
      end;

      TKafka.Produce(
        Topic,
        RD_KAFKA_PARTITION_UA,
        RD_KAFKA_MSG_F_COPY,
        Msgs,
        nil,
        0,
        nil);

      rd_kafka_flush(KafkaHandle, 1000);
    finally
      rd_kafka_topic_destroy(Topic);
    end;
  finally
    rd_kafka_destroy(KafkaHandle);
  end;
end;

constructor TfrmKafkaDemo.Create(AOwner: TComponent);
begin
  inherited;

  TKafka.OnLog := OnLog;
end;

procedure TfrmKafkaDemo.tmrLogTimer(Sender: TObject);
begin
  TKafka.FlushLogs;
end;

end.
