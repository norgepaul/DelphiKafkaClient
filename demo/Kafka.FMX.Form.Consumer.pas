unit Kafka.FMX.Form.Consumer;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Generics.Collections,

  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.Edit, FMX.StdCtrls, FMX.ScrollBox, FMX.Memo, FMX.Controls.Presentation, FMX.Layouts,

  Kafka.Lib,
  Kafka.Factory,
  Kafka.Interfaces,
  Kafka.Helper,
  Kafka.Types, System.Rtti, FMX.Grid.Style, FMX.Grid;

type
  TKafkaMsg = record
    Key: TBytes;
    Data: TBytes;
    Partition: Integer;
  end;

  TfrmConsume = class(TForm)
    layConsumeControl: TLayout;
    btnStart: TButton;
    btnStop: TButton;
    Layout1: TLayout;
    Layout2: TLayout;
    Label2: TLabel;
    edtTopic: TEdit;
    tmrUpdate: TTimer;
    lblStatus: TLabel;
    Layout3: TLayout;
    layKafkaConfiguration: TLayout;
    Label1: TLabel;
    memKafkaConfig: TMemo;
    Layout5: TLayout;
    Label3: TLabel;
    memTopicConfig: TMemo;
    grdMessages: TGrid;
    colPartition: TStringColumn;
    colKey: TStringColumn;
    colPayload: TStringColumn;
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure layConsumeControlResize(Sender: TObject);
    procedure tmrUpdateTimer(Sender: TObject);
    procedure grdMessagesGetValue(Sender: TObject; const ACol, ARow: Integer; var Value: TValue);
    procedure grdMessagesResize(Sender: TObject);
  private
    FKafkaConsumer: IKafkaConsumer;
    FKafkaServers: String;
    FStringEncoding: TEncoding;
    FMsgs: TList<TKafkaMsg>;

    procedure UpdateStatus;
    procedure Start;
    procedure Stop;
    procedure Log(const Text: String);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Execute(const KafkaServers: String);
  end;

var
  frmConsume: TfrmConsume;

implementation

{$R *.fmx}

procedure TfrmConsume.btnStartClick(Sender: TObject);
begin
  Start;
end;

procedure TfrmConsume.btnStopClick(Sender: TObject);
begin
  Stop;
end;

constructor TfrmConsume.Create(AOwner: TComponent);
begin
  inherited;

  FStringEncoding := TEncoding.UTF8;

  FMsgs := TList<TKafkaMsg>.Create;

  UpdateStatus;
end;

destructor TfrmConsume.Destroy;
begin
  FreeAndNil(FMsgs);

  inherited;
end;

procedure TfrmConsume.Execute(const KafkaServers: String);
begin
  FKafkaServers := KafkaServers;

  memKafkaConfig.Lines.Add('bootstrap.servers=' + KafkaServers);

  Show;
end;

procedure TfrmConsume.grdMessagesGetValue(Sender: TObject; const ACol, ARow: Integer; var Value: TValue);
begin
  case ACol of
    0: Value := FMsgs[ARow].Partition.ToString;
    1: Value := FStringEncoding.GetString(FMsgs[ARow].Key);
    2: Value := FStringEncoding.GetString(FMsgs[ARow].Data);
  end;
end;

procedure TfrmConsume.grdMessagesResize(Sender: TObject);
begin
//  StringColumn1.Width := grdMessages.Width - 22;
end;

procedure TfrmConsume.layConsumeControlResize(Sender: TObject);
begin
  btnStart.Width := (layConsumeControl.Width - 20) / 2;
  layKafkaConfiguration.Width := btnStart.Width;
end;

procedure TfrmConsume.Log(const Text: String);
begin
end;

procedure TfrmConsume.Start;
var
  KafkaNames, KafkaValues, TopicNames, TopicValues: TArray<String>;
begin
  if FKafkaConsumer = nil then
  begin
    TKafkaHelper.StringsToConfigArrays(memKafkaConfig.Lines, KafkaNames, KafkaValues);
    TKafkaHelper.StringsToConfigArrays(memTopicConfig.Lines, TopicNames, TopicValues);

    FKafkaConsumer := TKafkaFactory.NewConsumer(
      KafkaNames,
      KafkaValues,
      TopicNames,
      TopicValues,
      FKafkaServers,
      [edtTopic.Text],
      [0],
      procedure(const Msg: prd_kafka_message_t)
      begin
        TThread.Synchronize(
          TThread.Current,
          procedure
          var
            MsgRec: TKafkaMsg;
          begin
            if TKafkaHelper.IsKafkaError(Msg.err) then
            begin
              Log(format('Message error - %d', [Integer(Msg.err)]));
            end
            else
            begin
              MsgRec.Key := TKafkaHelper.PointerToBytes(Msg.key, Msg.key_len);
              MsgRec.Data := TKafkaHelper.PointerToBytes(Msg.payload, Msg.len);
              MsgRec.Partition := Msg.partition;

              FMsgs.Add(MsgRec);
            end;
          end);
      end);
  end;
end;

procedure TfrmConsume.Stop;
begin
  FKafkaConsumer := nil;
end;

procedure TfrmConsume.tmrUpdateTimer(Sender: TObject);
begin
  UpdateStatus;
end;

procedure TfrmConsume.UpdateStatus;
var
  ConsumedStr: String;
begin
  if FKafkaConsumer = nil then
  begin
    ConsumedStr := 'Idle';
  end
  else
  begin
    ConsumedStr := FKafkaConsumer.ConsumedCount.ToString;
  end;

  lblStatus.Text := format('Consumed: %s', [ConsumedStr]);

  btnStart.Enabled := FKafkaConsumer = nil;
  btnStop.Enabled := FKafkaConsumer <> nil;

  memKafkaConfig.Enabled := FKafkaConsumer = nil;
  memTopicConfig.Enabled := FKafkaConsumer = nil;
  edtTopic.Enabled := FKafkaConsumer = nil;

  if grdMessages.RowCount <> FMsgs.Count then
  begin
    grdMessages.BeginUpdate;
    try
      grdMessages.RowCount := FMsgs.Count;
    finally
      grdMessages.EndUpdate;
    end;
  end;
end;

end.
