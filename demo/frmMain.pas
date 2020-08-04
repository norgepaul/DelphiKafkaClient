unit frmMain;

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
  Kafka.Classes,
  Kafka.Types;

type
  EKafkaError = class(Exception);

  TfrmKafkaDemo = class(TForm)
    ActionList1: TActionList;
    actProduceMessage: TAction;
    actStartConsuming: TAction;
    Layout1: TLayout;
    tmrUpdate: TTimer;
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
    lblStatus: TLabel;
    chkLogCallbacks: TCheckBox;
    chkFlushAfterProduce: TCheckBox;
    procedure actProduceMessageExecute(Sender: TObject);
    procedure actStartConsumingExecute(Sender: TObject);
    procedure tmrUpdateTimer(Sender: TObject);
    procedure actStopConsumingExecute(Sender: TObject);
    procedure ActionList1Update(Action: TBasicAction; var Handled: Boolean);
  private
    FKafkaProducer: IKafkaProducer;
    FKafkaConsumer: IKafkaConsumer;

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

    if (Memo = memLogOther) or 
       (chkLogCallbacks.IsChecked) then
    begin    
      Memo.Lines.Add(Values[i]);
    end;
  end;
end;

procedure TfrmKafkaDemo.actStartConsumingExecute(Sender: TObject);
begin
  if FKafkaConsumer = nil then
  begin
    FKafkaConsumer := TKafkaFactory.NewConsumer(
      ['group.id'],
      ['GroupID'],
      ['auto.offset.reset'],
      ['earliest'],
      KafkaServers,
      [DefaultTopic],
      [0],
      procedure(const Msg: prd_kafka_message_t)
      begin
        TKafka.Log(format('Message received - %s', [TKafkaHelper.PointerToStr(Msg.payload, Msg.len)]), TKafkaLogType.kltConsumer);
      end);
  end;
end;

procedure TfrmKafkaDemo.actStopConsumingExecute(Sender: TObject);
begin
  FKafkaConsumer := nil;
end;

procedure TfrmKafkaDemo.ActionList1Update(Action: TBasicAction; var Handled: Boolean);
begin
  actStartConsuming.Enabled := FKafkaConsumer = nil;
  actStopConsuming.Enabled := FKafkaConsumer <> nil;

  Handled := True;
end;

procedure TfrmKafkaDemo.actProduceMessageExecute(Sender: TObject);
var
  Msgs: TArray<String>;
  i: Integer;
begin
  if FKafkaProducer = nil then
  begin
    FKafkaProducer := TKafkaFactory.NewProducer(
      ['bootstrap.servers'],
      [KafkaServers]);
  end;

  SetLength(Msgs, Trunc(edtMessageCount.Value));

  for i := 0 to pred(Trunc(edtMessageCount.Value)) do
  begin
    Msgs[i] := DefaultMessage + ' - ' + DateTimeToStr(now) + '.' + MilliSecondOf(now).ToString.PadLeft(3, '0');
  end;

  FKafkaProducer.Produce(
    DefaultTopic,
    Msgs,
    nil,
    0,
    RD_KAFKA_PARTITION_UA,
    RD_KAFKA_MSG_F_COPY,
    nil);

  if chkFlushAfterProduce.IsChecked then
  begin
    TKafka.Flush(FKafkaProducer.KafkaHandle, 1000);
  end;
end;

constructor TfrmKafkaDemo.Create(AOwner: TComponent);
begin
  inherited;

  TKafka.OnLog := OnLog;
end;

procedure TfrmKafkaDemo.tmrUpdateTimer(Sender: TObject);
var 
  ProducedStr, ConsumedStr: String;
begin
  TKafka.FlushLogs;

  if FKafkaProducer = nil then
  begin
    ProducedStr := 'Idle';
  end
  else
  begin
    ProducedStr := FKafkaProducer.ProducedCount.ToString;
  end;

  if FKafkaConsumer = nil then
  begin
    ConsumedStr := 'Idle';
  end
  else
  begin
    ConsumedStr := FKafkaConsumer.ConsumedCount.ToString;
  end;
  
  lblStatus.Text := format('Produced: %s | Consumed: %s', [ProducedStr, ConsumedStr]);
end;

end.
