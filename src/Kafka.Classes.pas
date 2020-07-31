unit Kafka.Classes;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Threading,

  Kafka.Interfaces,
  Kafka.Types,
  Kafka.Lib;

type
  EKafkaError = class(Exception);

  TOnLog = procedure(const Values: TStrings) of object;

  TConsumerMessageHandlerProc = reference to procedure(const Msg: prd_kafka_message_t);

  TKafkaConnectionBase = class
  protected
    FKafkaHandle: prd_kafka_t;

    procedure DoSetup; virtual; abstract;
    procedure DoExecute; virtual; abstract;
    procedure DoCleanUp; virtual; abstract;
  end;

  TKafkaConsumer = class(TKafkaConnectionBase)
  private
    procedure OnThreadTerminate(Sender: TObject);
  protected
    FConfiguration: prd_kafka_conf_t;
    FHandler: TConsumerMessageHandlerProc;
    FThread: TThread;
    FBrokers: PAnsiChar;
    FTopics: TArray<PAnsiChar>;
    FPartitions: TArray<Integer>;

    procedure DoSetup; override;
    procedure DoExecute; override;
    procedure DoCleanUp; override;
  public
    constructor Create(const Configuration: prd_kafka_conf_t; const Handler: TConsumerMessageHandlerProc; const Brokers: PAnsiChar; const Topics: TArray<PAnsiChar>; const Partitions: TArray<Integer>);
    destructor Destroy; override;

    procedure Start;
    procedure Stop;
  end;

  TKafka = class
  private
    class var FLogStrings: TStringList;
    class var FOnLog: TOnLog;
    class procedure CheckKeyValues(const Keys, Values: TArray<PAnsiChar>); static;
  protected
    class procedure DoLog(const Text: String; const LogType: TKafkaLogType);
  public
    class constructor Create;
    class destructor Destroy;

    class procedure Log(const Text: String; const LogType: TKafkaLogType);

    class function NewConfiguration(const DefaultCallBacks: Boolean = True): prd_kafka_conf_t; overload; static;
    class function NewConfiguration(const Keys, Values: TArray<PAnsiChar>; const DefaultCallBacks: Boolean = True): prd_kafka_conf_t; overload; static;
    class procedure SetConfigurationValue(var Configuration: prd_kafka_conf_t; const Key, Value: PAnsiChar); static;

    class function NewTopicConfiguration: prd_kafka_topic_conf_t; overload; static;
    class function NewTopicConfiguration(const Keys, Values: TArray<PAnsiChar>): prd_kafka_topic_conf_t; overload; static;
    class procedure SetTopicConfigurationValue(var TopicConfiguration: prd_kafka_topic_conf_t; const Key, Value: PAnsiChar); static;

    class function NewProducer(const Configuration: prd_kafka_conf_t): prd_kafka_t; static;
    class function NewConsumer(const Configuration: prd_kafka_conf_t): prd_kafka_t; overload; static;
    class function NewConsumer(const Configuration: prd_kafka_conf_t; const Brokers: PAnsiChar; const Topics: TArray<PAnsiChar>; const Partitions: TArray<Integer>; const Handler: TConsumerMessageHandlerProc): TKafkaConsumer; overload; static;

    class function NewTopic(const KafkaHandle: prd_kafka_t; const TopicName: PAnsiChar; const TopicConfiguration: prd_kafka_topic_conf_t = nil): prd_kafka_topic_t;

    class function Produce(const Topic: prd_kafka_topic_t; const Partition: Int32; const MsgFlags: Integer; const Payload: Pointer; const PayloadLength: NativeUInt; const Key: Pointer; const KeyLen: NativeUInt; const MsgOpaque: Pointer = nil): Integer; overload;
    class function Produce(const Topic: prd_kafka_topic_t; const Partition: Int32; const MsgFlags: Integer; const Payload: AnsiString; const Key: Pointer; const KeyLen: NativeUInt; const MsgOpaque: Pointer = nil): Integer; overload;
    class function Produce(const Topic: prd_kafka_topic_t; const Partition: Int32; const MsgFlags: Integer; const Payloads: TArray<AnsiString>; const Key: Pointer; const KeyLen: NativeUInt; const MsgOpaque: Pointer = nil): Integer; overload;
    class function Produce(const Topic: prd_kafka_topic_t; const Partition: Int32; const MsgFlags: Integer; const Payloads: TArray<Pointer>; const PayloadLengths: TArray<Integer>; const Key: Pointer; const KeyLen: NativeUInt; const MsgOpaque: Pointer = nil): Integer; overload;

    class procedure FlushLogs;

    class property OnLog: TOnLog read FOnLog write FOnLog;
  end;

  TKafkaHelper = class
  public
    class function PointerToStr(const Value: Pointer; const Len: Integer): String; static;
    class function IsKafkaError(const Error: rd_kafka_resp_err_t): Boolean; static;
  end;

implementation

resourcestring
  StrInvalidTopicConfig = 'Invalid topic configuration key';
  StrInvalidConfiguratio = 'Invalid configuration key';
  StrMessageNotQueued = 'Message not Queued';
  StrKeysAndValuesMust = 'Keys and Values must be the same length';
  StrUnableToCreateKaf = 'Unable to create Kafka Handle - %s';
  StrErrorCallBackReaso = 'Error_CallBack'#10'Reason =  %s';
  StrLogCallBackFac = 'Log_CallBack - fac = %s, buff = %s';
  StrMessageSendResult = 'Message send result = %d';
  StrBrokersCouldNotBe = 'Brokers could not be added';
  StrCriticalError = 'Critical Error: ';

class constructor TKafka.Create;
begin
  FLogStrings := TStringList.Create;
end;

class destructor TKafka.Destroy;
begin
  FreeAndNil(FLogStrings);
end;

procedure ProducerCallBackLogger(rk: prd_kafka_t; rkmessage: prd_kafka_message_t;
  opaque: Pointer); cdecl;
begin
  if rkmessage <> nil then
  begin
    TKafka.Log(format(StrMessageSendResult, [Integer(rkmessage.err)]), TKafkaLogType.kltProducer);
  end;
end;

procedure LogCallBackLogger(rk: prd_kafka_t; level: integer; fac: PAnsiChar;
  buf: PAnsiChar); cdecl;
begin
  TKafka.Log(format(StrLogCallBackFac, [String(fac), String(buf)]), TKafkaLogType.kltLog);
end;

procedure ErrorCallBackLogger(rk: prd_kafka_t; err: integer; reason: PAnsiChar;
  opaque: Pointer); cdecl;
begin
  TKafka.Log(format(StrErrorCallBackReaso, [String(reason)]), kltError);
end;

class procedure TKafka.DoLog(const Text: String; const LogType: TKafkaLogType);
begin
  TMonitor.Enter(TKafka.FLogStrings);
  try
    TKafka.FLogStrings.AddObject(Text, TObject(LogType));
  finally
    TMonitor.Exit(TKafka.FLogStrings);
  end;
end;

class procedure TKafka.FlushLogs;
begin
  TMonitor.Enter(TKafka.FLogStrings);
  try
    if Assigned(FOnLog) then
    begin
      FOnLog(TKafka.FLogStrings);
    end;

    TKafka.FLogStrings.Clear;
  finally
    TMonitor.Exit(TKafka.FLogStrings);
  end;
end;

class procedure TKafka.Log(const Text: String; const LogType: TKafkaLogType);
begin
  DoLog(Text, LogType);
end;

class function TKafka.NewConfiguration(const Keys: TArray<PAnsiChar>; const Values: TArray<PAnsiChar>; const DefaultCallBacks: Boolean): prd_kafka_conf_t;
var
  i: Integer;
begin
  CheckKeyValues(Keys, Values);

  Result := rd_kafka_conf_new();

  for i := Low(keys) to High(Keys) do
  begin
    SetConfigurationValue(
      Result,
      Keys[i],
      Values[i]);
  end;

  if DefaultCallBacks then
  begin
    rd_kafka_conf_set_dr_msg_cb(Result, @ProducerCallBackLogger);
    rd_kafka_conf_set_log_cb(Result, @LogCallBackLogger);
    rd_kafka_conf_set_error_cb(Result, @ErrorCallBackLogger);
  end;
end;

class function TKafka.NewConsumer(const Configuration: prd_kafka_conf_t; const Brokers: PAnsiChar;
  const Topics: TArray<PAnsiChar>; const Partitions: TArray<Integer>; const Handler: TConsumerMessageHandlerProc): TKafkaConsumer;
begin
  Result := TKafkaConsumer.Create(
    Configuration,
    Handler,
    Brokers,
    Topics,
    Partitions);
end;

class function TKafka.NewConsumer(const Configuration: prd_kafka_conf_t): prd_kafka_t;
var
  ErrorStr: TKafkaErrorArray;
begin
  Result := rd_kafka_new(
    RD_KAFKA_CONSUMER,
    Configuration,
    ErrorStr,
    Sizeof(ErrorStr));

  if Result = nil then
  begin
    raise EKafkaError.CreateFmt(StrUnableToCreateKaf, [String(ErrorStr)]);
  end;
end;

class function TKafka.NewProducer(const Configuration: prd_kafka_conf_t): prd_kafka_t;
var
  ErrorStr: TKafkaErrorArray;
begin
  Result := rd_kafka_new(
    RD_KAFKA_PRODUCER,
    Configuration,
    ErrorStr,
    Sizeof(ErrorStr));

  if Result = nil then
  begin
    raise EKafkaError.CreateFmt(StrUnableToCreateKaf, [String(ErrorStr)]);
  end;
end;

class function TKafka.NewTopic(const KafkaHandle: prd_kafka_t; const TopicName: PAnsiChar; const TopicConfiguration: prd_kafka_topic_conf_t): prd_kafka_topic_t;
begin
  Result := rd_kafka_topic_new(
    KafkaHandle,
    TopicName,
    TopicConfiguration);

  if Result = nil then
  begin
    raise EKafkaError.Create(String(rd_kafka_err2str(rd_kafka_last_error)));
  end;
end;

class function TKafka.NewTopicConfiguration: prd_kafka_topic_conf_t;
begin
  Result := NewTopicConfiguration([], []);
end;

class procedure TKafka.CheckKeyValues(const Keys, Values: TArray<PAnsiChar>);
begin
  if length(keys) <> length(values) then
  begin
    raise EKafkaError.Create(StrKeysAndValuesMust);
  end;
end;

class function TKafka.NewTopicConfiguration(const Keys, Values: TArray<PAnsiChar>): prd_kafka_topic_conf_t;
var
  i: Integer;
begin
  Result := rd_kafka_topic_conf_new;

  CheckKeyValues(Keys, Values);

  for i := Low(keys) to High(Keys) do
  begin
    SetTopicConfigurationValue(
      Result,
      Keys[i],
      Values[i]);
  end;
end;

class function TKafka.Produce(const Topic: prd_kafka_topic_t; const Partition: Int32; const MsgFlags: Integer; const Payloads: TArray<Pointer>;
  const PayloadLengths: TArray<Integer>; const Key: Pointer; const KeyLen: NativeUInt; const MsgOpaque: Pointer): Integer;
var
  i: Integer;
  Msgs: TArray<rd_kafka_message_t>;
  Msg: rd_kafka_message_t;
begin
  if length(Payloads) = 0 then
  begin
    Result := 0;
  end
  else
  begin
    SetLength(Msgs, length(Payloads));

    for i := Low(Payloads) to High(Payloads) do
    begin
      Msg.partition := Partition;
      Msg.rkt := Topic;
      Msg.payload := Payloads[i];
      Msg.len := PayloadLengths[i];
      Msg.key := Key;
      Msg.key_len := KeyLen;

      Msgs[i] := Msg;
    end;

    Result := rd_kafka_produce_batch(
      Topic,
      Partition,
      MsgFlags,
      @Msgs[0],
      length(Payloads));

    if Result <> length(Payloads) then
    begin
      raise EKafkaError.Create(StrMessageNotQueued);
    end;
  end;
end;

class function TKafka.Produce(const Topic: prd_kafka_topic_t; const Partition: Int32; const MsgFlags: Integer; const Payload: AnsiString;
  const Key: Pointer; const KeyLen: NativeUInt; const MsgOpaque: Pointer): Integer;
begin
  Result := Produce(
    Topic,
    Partition,
    MsgFlags,
    @Payload[1],
    Length(Payload),
    Key,
    KeyLen,
    MsgOpaque)
end;

class function TKafka.Produce(const Topic: prd_kafka_topic_t; const Partition: Int32; const MsgFlags: Integer; const Payload: Pointer;
  const PayloadLength: NativeUInt; const Key: Pointer; const KeyLen: NativeUInt; const MsgOpaque: Pointer): Integer;
begin
  Result := rd_kafka_produce(
    Topic,
    Partition,
    MsgFlags,
    Payload,
    PayloadLength,
    Key,
    KeyLen,
    MsgOpaque);

  if Result = -1 then
  begin
    raise EKafkaError.Create(StrMessageNotQueued);
  end;
end;

class function TKafka.NewConfiguration(const DefaultCallBacks: Boolean): prd_kafka_conf_t;
begin
  Result := NewConfiguration([], [], DefaultCallBacks);
end;

class procedure TKafka.SetConfigurationValue(var Configuration: prd_kafka_conf_t; const Key, Value: PAnsiChar);
var
  ErrorStr: TKafkaErrorArray;
begin
  if Value = '' then
  begin
    raise EKafkaError.Create(StrInvalidConfiguratio);
  end;

  if rd_kafka_conf_set(
    Configuration,
    Key,
    Value,
    ErrorStr,
    Sizeof(ErrorStr)) <> RD_KAFKA_CONF_OK then
  begin
    raise EKafkaError.Create(String(ErrorStr));
  end;
end;

class procedure TKafka.SetTopicConfigurationValue(var TopicConfiguration: prd_kafka_topic_conf_t; const Key, Value: PAnsiChar);
var
  ErrorStr: TKafkaErrorArray;
begin
  if Value = '' then
  begin
    raise EKafkaError.Create(StrInvalidTopicConfig);
  end;

  if rd_kafka_topic_conf_set(
    TopicConfiguration,
    Key,
    Value,
    ErrorStr,
    Sizeof(ErrorStr)) <> RD_KAFKA_CONF_OK then
  begin
    raise EKafkaError.Create(String(ErrorStr));
  end;
end;

{ TKafkaHelper }

class function TKafkaHelper.IsKafkaError(const Error: rd_kafka_resp_err_t): Boolean;
begin
  Result :=
    (Error <> RD_KAFKA_RESP_ERR_NO_ERROR) and
    (Error <> RD_KAFKA_RESP_ERR__PARTITION_EOF);
end;

class function TKafkaHelper.PointerToStr(const Value: Pointer; const Len: Integer): String;
begin
  Result := copy(String(PAnsiChar(Value)), 1, len);
end;

{ TKafkaConsumer }

constructor TKafkaConsumer.Create(const Configuration: prd_kafka_conf_t; const Handler: TConsumerMessageHandlerProc; const Brokers: PAnsiChar; const Topics: TArray<PAnsiChar>; const Partitions: TArray<Integer>);
begin
  FConfiguration := Configuration;
  FHandler := Handler;
  FBrokers := Brokers;
  FTopics := Topics;
  FPartitions := Partitions;
end;

destructor TKafkaConsumer.Destroy;
begin
  Stop;

  inherited;
end;

procedure TKafkaConsumer.DoSetup;
var
  i: Integer;
  TopicList: prd_kafka_topic_partition_list_t;
begin
  FKafkaHandle := TKafka.NewConsumer(FConfiguration);

  if rd_kafka_brokers_add(FKafkaHandle, FBrokers) = 0 then
  begin
    raise EKafkaError.Create(StrBrokersCouldNotBe);
  end;

  rd_kafka_poll_set_consumer(FKafkaHandle);

  TopicList := rd_kafka_topic_partition_list_new(0);

  for i := Low(FTopics) to High(FTopics) do
  begin
    rd_kafka_topic_partition_list_add(
      TopicList,
      FTopics[i],
      FPartitions[i]);
  end;

  rd_kafka_assign(
    FKafkaHandle,
    TopicList);
end;

procedure TKafkaConsumer.DoExecute;
var
  Msg: prd_kafka_message_t;
begin
  Msg := rd_kafka_consumer_poll(FKafkaHandle, 1000);

  if Msg <> nil then
  try
    if TKafkaHelper.IsKafkaError(Msg.err) then
    begin
      TKafka.Log(format('Message error - %d', [Integer(Msg.err)]), TKafkaLogType.kltConsumer);
    end else
    begin
      if Msg.key_len <> 0 then
      begin
        TKafka.Log(format('Key received - %s', [TKafkaHelper.PointerToStr(Msg.key, Msg.key_len)]), TKafkaLogType.kltConsumer);
      end;

      if Msg.len <> 0 then
      begin
        if Assigned(FHandler) then
        begin
          FHandler(Msg);
        end;
      end;
    end;
  finally
    rd_kafka_message_destroy(Msg);
  end;
end;

procedure TKafkaConsumer.DoCleanUp;
begin
  if FKafkaHandle <> nil then
  begin
    rd_kafka_consumer_close(FKafkaHandle);
    rd_kafka_destroy(FKafkaHandle);
  end;
end;

procedure TKafkaConsumer.Start;
begin
  if FThread = nil then
  begin
    FThread := TThread.CreateAnonymousThread(
      procedure
      begin
        try
          DoSetup;
          try
            while not TThread.CurrentThread.CheckTerminated do
            begin
              DoExecute;
            end;
          finally
            { TODO : Why do we get an AV here? }
            DoCleanUp;
          end;
        except
          on e: Exception do
          begin
            TKafka.Log(StrCriticalError + e.Message, TKafkaLogType.kltConsumer);
          end;
        end;
      end);

    FThread.OnTerminate := OnThreadTerminate;
    FThread.FreeOnTerminate := True;
    FThread.Start;
  end;
end;

procedure TKafkaConsumer.OnThreadTerminate(Sender: TObject);
begin
  FThread := nil;
end;

procedure TKafkaConsumer.Stop;
begin
  if FThread <> nil then
  begin
    FThread.Terminate;
  end;
end;

class function TKafka.Produce(const Topic: prd_kafka_topic_t; const Partition: Int32; const MsgFlags: Integer; const Payloads: TArray<AnsiString>;
  const Key: Pointer; const KeyLen: NativeUInt; const MsgOpaque: Pointer): Integer;
var
  PayloadPointers: TArray<Pointer>;
  PayloadLengths: TArray<Integer>;
  i: Integer;
begin
  SetLength(PayloadPointers, length(Payloads));
  SetLength(PayloadLengths, length(Payloads));

  for i := Low(Payloads) to High(Payloads) do
  begin
    PayloadPointers[i] := @PayLoads[i][1];
    PayloadLengths[i] := length(PayLoads[i]);
  end;

  Result := Produce(
    Topic,
    Partition,
    MsgFlags,
    PayloadPointers,
    PayloadLengths,
    Key,
    KeyLen,
    MsgOpaque);
end;

end.
