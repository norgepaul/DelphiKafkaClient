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
  Kafka.Helper,
  Kafka.Types;

type
  EKafkaError = class(Exception);

  TfrmKafkaDemo = class(TForm)
    ActionList1: TActionList;
    actProduceMessage: TAction;
    actStartConsuming: TAction;
    tmrUpdate: TTimer;
    actStopConsuming: TAction;
    GridPanelLayout1: TGridPanelLayout;
    actFlush: TAction;
    GroupBox2: TGroupBox;
    layConsumeControl: TLayout;
    btnConsumingStart: TButton;
    Button3: TButton;
    memLogConsumer: TMemo;
    GroupBox1: TGroupBox;
    Layout3: TLayout;
    edtMessageCount: TSpinBox;
    Button1: TButton;
    Button4: TButton;
    chkFlushAfterProduce: TCheckBox;
    memLogProducer: TMemo;
    chkLogProduceCallbacks: TCheckBox;
    chkLogConsumeCallbacks: TCheckBox;
    Options: TGroupBox;
    memLogOther: TMemo;
    lblStatus: TLabel;
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
    procedure actProduceMessageExecute(Sender: TObject);
    procedure actStartConsumingExecute(Sender: TObject);
    procedure tmrUpdateTimer(Sender: TObject);
    procedure actStopConsumingExecute(Sender: TObject);
    procedure ActionList1Update(Action: TBasicAction; var Handled: Boolean);
    procedure actFlushExecute(Sender: TObject);
    procedure layConsumeControlResize(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure edtKafkaServerChange(Sender: TObject);
    procedure edtTopicChange(Sender: TObject);
  private
    FKafkaProducer: IKafkaProducer;
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
       ((chkLogProduceCallbacks.IsChecked) and (Memo = memLogProducer)) or
       ((chkLogConsumeCallbacks.IsChecked) and (Memo = memLogConsumer)) then
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
      edtKafkaServer.Text,
      [edtTopic.Text],
      [0],
      procedure(const Msg: prd_kafka_message_t)
      begin
        // This is called from the consumer thread, but TKafka.Log is threadsafe
        if TKafkaHelper.IsKafkaError(Msg.err) then
        begin
          TKafkaHelper.Log(format('Message error - %d', [Integer(Msg.err)]), TKafkaLogType.kltConsumer);
        end
        else
        begin
          TKafkaHelper.Log(format('[key=%s] - %s', [
            TKafkaHelper.PointerToStr(Msg.key, Msg.key_len),
            TKafkaHelper.PointerToStr(Msg.payload, Msg.len)]),
            TKafkaLogType.kltConsumer);
        end;
      end);
  end;
end;

procedure TfrmKafkaDemo.actStopConsumingExecute(Sender: TObject);
begin
  FKafkaConsumer := nil;
end;

procedure TfrmKafkaDemo.actFlushExecute(Sender: TObject);
begin
  TKafkaHelper.Flush(FKafkaProducer.KafkaHandle);
end;

procedure TfrmKafkaDemo.ActionList1Update(Action: TBasicAction; var Handled: Boolean);
begin
  actStartConsuming.Enabled := (FKafkaConsumer = nil) and (edtKafkaServer.Text <> '');
  actStopConsuming.Enabled := FKafkaConsumer <> nil;
  actFlush.Enabled := FKafkaProducer <> nil;

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
      [edtKafkaServer.Text]);
  end;

  SetLength(Msgs, Trunc(edtMessageCount.Value));

  for i := 0 to pred(Trunc(edtMessageCount.Value)) do
  begin
    Msgs[i] := edtMessage.Text + ' - ' + DateTimeToStr(now) + '.' + MilliSecondOf(now).ToString.PadLeft(3, '0');
  end;

  FKafkaProducer.Produce(
    edtTopic.Text,
    Msgs,
    edtKey.Text,
    RD_KAFKA_PARTITION_UA,
    RD_KAFKA_MSG_F_COPY,
    @self);

  if chkFlushAfterProduce.IsChecked then
  begin
    TKafkaHelper.Flush(FKafkaProducer.KafkaHandle);
  end;
end;

constructor TfrmKafkaDemo.Create(AOwner: TComponent);
begin
  inherited;

  TKafkaHelper.OnLog := OnLog;

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
  FKafkaProducer := nil;
  FKafkaConsumer := nil;
end;

procedure TfrmKafkaDemo.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  DestroyClasses;

  // Wait for all the threads to terminate
  sleep(1000);
end;

procedure TfrmKafkaDemo.layConsumeControlResize(Sender: TObject);
begin
  btnConsumingStart.Width := (layConsumeControl.Width - 20) / 2;
end;

procedure TfrmKafkaDemo.tmrUpdateTimer(Sender: TObject);
begin
  UpdateStatus;
end;

procedure TfrmKafkaDemo.UpdateStatus;
var
  ProducedStr, ConsumedStr: String;
begin
  TKafkaHelper.FlushLogs;

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
