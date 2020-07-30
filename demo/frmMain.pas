unit frmMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, System.Actions,

  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.ActnList, FMX.Memo.Types, FMX.ScrollBox,
  FMX.Memo, FMX.Layouts,

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
    Button1: TButton;
    memLog: TMemo;
    tmrLog: TTimer;
    Layout2: TLayout;
    Button2: TButton;
    actStopConsuming: TAction;
    Button3: TButton;
    procedure actProduceMessageExecute(Sender: TObject);
    procedure actStartConsumingExecute(Sender: TObject);
    procedure tmrLogTimer(Sender: TObject);
    procedure actStopConsumingExecute(Sender: TObject);
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
begin
  memLog.BeginUpdate;
  try
    for i := 0 to pred(Values.Count) do
    begin
      memLog.Lines.Add(Values[i]);
    end;

    if not memLog.IsFocused then
    begin
      memLog.ScrollBy(0, MaxInt, False);
    end;
  finally
    memLog.EndUpdate;
  end;
end;

procedure TfrmKafkaDemo.actStartConsumingExecute(Sender: TObject);
var
  Configuration: prd_kafka_conf_t;
  TopicConfiguration: prd_kafka_topic_conf_t;
  TopicName: PAnsiChar;
  Subscribing: Boolean;
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
        TKafka.Log(format('Message received - %s', [TKafkaHelper.PointerToStr(Msg.payload, Msg.len)]));
      end);

    FKafkaConsumer.Start;
  end;
end;

procedure TfrmKafkaDemo.actStopConsumingExecute(Sender: TObject);
begin
  if FKafkaConsumer <> nil then
  begin
    FKafkaConsumer.Free;
  end;
end;

procedure TfrmKafkaDemo.actProduceMessageExecute(Sender: TObject);
var
  Configuration: prd_kafka_conf_t;
  KafkaHandle: prd_kafka_t;
  Topic: prd_kafka_topic_t;
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
      TKafka.Produce(
        Topic,
        RD_KAFKA_PARTITION_UA,
        RD_KAFKA_MSG_F_COPY,
        DefaultMessage,
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
