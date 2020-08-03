unit Kafka.Classes;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Threading, System.SyncObjs,

  Kafka.Interfaces,
  Kafka.Types,
  Kafka.Lib;

type
  EKafkaError = class(Exception);

  TOnLog = procedure(const Values: TStrings) of object;

  TConsumerMessageHandlerProc = reference to procedure(const Msg: prd_kafka_message_t);

  TKafkaConnectionThreadBase = class(TThread)
  protected
    FKafkaHandle: prd_kafka_t;

    procedure DoSetup; virtual; abstract;
    procedure DoExecute; virtual; abstract;
    procedure DoCleanUp; virtual; abstract;

    procedure Execute; override;
  end;

  TKafkaConnectionThread = class(TKafkaConnectionThreadBase)
  protected
    FKafkaHandle: prd_kafka_t;
    FConfiguration: prd_kafka_conf_t;
    FHandler: TConsumerMessageHandlerProc;
    FTopics: TArray<String>;
    FPartitions: TArray<Integer>;
    FBrokers: String;
    FConsumedCount: Int64;

    procedure DoSetup; override;
    procedure DoExecute; override;
    procedure DoCleanUp; override;
  public
    constructor Create(const Configuration: prd_kafka_conf_t; const Handler: TConsumerMessageHandlerProc; const Brokers: String; const Topics: TArray<String>; const Partitions: TArray<Integer>);
  end;

  TKafkaConsumer = class
  private
    procedure OnThreadTerminate(Sender: TObject);
    function GetConsumedCount: Int64;
  protected
    FThread: TKafkaConnectionThread;
  public
    constructor Create(const Configuration: prd_kafka_conf_t; const Handler: TConsumerMessageHandlerProc; const Brokers: String; const Topics: TArray<String>; const Partitions: TArray<Integer>);
    destructor Destroy; override;

    property ConsumedCount: Int64 read GetConsumedCount;
  end;

  TKafkaProducer = class
  protected
    FKafkaHandle: prd_kafka_t;
    FConfiguration: prd_kafka_conf_t;
  public
    constructor Create(const ConfigurationKeys, ConfigurationValues: TArray<String>);
    destructor Destroy; override;

    function Produce(const Topic: String; const Payload: Pointer; const PayloadLength: NativeUInt; const Key: Pointer = nil; const KeyLen: NativeUInt = 0; const Partition: Int32 = RD_KAFKA_PARTITION_UA; const MsgFlags: Integer = RD_KAFKA_MSG_F_COPY; const MsgOpaque: Pointer = nil): Integer; overload;
    function Produce(const Topic: String; const Payload: String; const Key: Pointer = nil; const KeyLen: NativeUInt = 0; const Partition: Int32 = RD_KAFKA_PARTITION_UA; const MsgFlags: Integer = RD_KAFKA_MSG_F_COPY; const MsgOpaque: Pointer = nil): Integer; overload;
    function Produce(const Topic: String; const Payloads: TArray<Pointer>; const PayloadLengths: TArray<Integer>; const Key: Pointer = nil; const KeyLen: NativeUInt = 0; const Partition: Int32 = RD_KAFKA_PARTITION_UA; const MsgFlags: Integer = RD_KAFKA_MSG_F_COPY; const MsgOpaque: Pointer = nil): Integer; overload;
    function Produce(const Topic: String; const Payloads: TArray<String>; const Key: Pointer = nil; const KeyLen: NativeUInt = 0; const Partition: Int32 = RD_KAFKA_PARTITION_UA; const MsgFlags: Integer = RD_KAFKA_MSG_F_COPY; const MsgOpaque: Pointer = nil): Integer; overload;
  end;

  TKafka = class
  private
    class var FLogStrings: TStringList;
    class var FOnLog: TOnLog;
    class procedure CheckKeyValues(const Keys, Values: TArray<String>); static;
  protected
    class procedure DoLog(const Text: String; const LogType: TKafkaLogType);
  public
    class constructor Create;
    class destructor Destroy;

    class procedure Log(const Text: String; const LogType: TKafkaLogType);

    class function NewConfiguration(const DefaultCallBacks: Boolean = True): prd_kafka_conf_t; overload; static;
    class function NewConfiguration(const Keys, Values: TArray<String>; const DefaultCallBacks: Boolean = True): prd_kafka_conf_t; overload; static;
    class procedure SetConfigurationValue(var Configuration: prd_kafka_conf_t; const Key, Value: String); static;
    class procedure DestroyConfiguration(const Configuration: Prd_kafka_conf_t); static;

    class function NewTopicConfiguration: prd_kafka_topic_conf_t; overload; static;
    class function NewTopicConfiguration(const Keys, Values: TArray<String>): prd_kafka_topic_conf_t; overload; static;
    class procedure SetTopicConfigurationValue(var TopicConfiguration: prd_kafka_topic_conf_t; const Key, Value: String); static;
    class procedure DestroyTopicConfiguration(const TopicConfiguration: Prd_kafka_topic_conf_t); static;

    class function NewProducer(const Configuration: prd_kafka_conf_t): prd_kafka_t; static;
    class function NewConsumer(const Configuration: prd_kafka_conf_t): prd_kafka_t; overload; static;
    class function NewConsumer(const ConfigKeys, ConfigValues, ConfigTopicKeys, ConfigTopicValues: TArray<String>; const Brokers: String; const Topics: TArray<String>; const Partitions: TArray<Integer>; const Handler: TConsumerMessageHandlerProc): TKafkaConsumer; overload; static;
    class function NewConsumer(const Configuration: prd_kafka_conf_t; const Brokers: String; const Topics: TArray<String>; const Partitions: TArray<Integer>; const Handler: TConsumerMessageHandlerProc): TKafkaConsumer; overload; static;
    class procedure ConsumerClose(const KafkaHandle: prd_kafka_t); static;
    class procedure DestroyHandle(const KafkaHandle: prd_kafka_t); static;

    class function NewTopic(const KafkaHandle: prd_kafka_t; const TopicName: String; const TopicConfiguration: prd_kafka_topic_conf_t = nil): prd_kafka_topic_t;

    class function Produce(const Topic: prd_kafka_topic_t; const Partition: Int32; const MsgFlags: Integer; const Payload: Pointer; const PayloadLength: NativeUInt; const Key: Pointer; const KeyLen: NativeUInt; const MsgOpaque: Pointer = nil): Integer; overload;
    class function Produce(const Topic: prd_kafka_topic_t; const Partition: Int32; const MsgFlags: Integer; const Payload: String; const Key: Pointer; const KeyLen: NativeUInt; const MsgOpaque: Pointer = nil): Integer; overload;
    class function Produce(const Topic: prd_kafka_topic_t; const Partition: Int32; const MsgFlags: Integer; const Payloads: TArray<String>; const Key: Pointer; const KeyLen: NativeUInt; const MsgOpaque: Pointer = nil): Integer; overload;
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

class procedure TKafka.ConsumerClose(const KafkaHandle: prd_kafka_t);
begin
  rd_kafka_consumer_close(KafkaHandle);
end;

class procedure TKafka.DestroyHandle(const KafkaHandle: prd_kafka_t);
begin
  rd_kafka_destroy(KafkaHandle);
end;

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

class procedure TKafka.DestroyConfiguration(const Configuration: Prd_kafka_conf_t);
begin
  rd_kafka_conf_destroy(Configuration);
end;

class procedure TKafka.DestroyTopicConfiguration(const TopicConfiguration: Prd_kafka_topic_conf_t);
begin
  rd_kafka_topic_conf_destroy(TopicConfiguration);
end;

class function TKafka.NewConfiguration(const Keys: TArray<String>; const Values: TArray<String>; const DefaultCallBacks: Boolean): prd_kafka_conf_t;
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

class function TKafka.NewConsumer(const ConfigKeys, ConfigValues, ConfigTopicKeys, ConfigTopicValues: TArray<String>; const Brokers: String;
  const Topics: TArray<String>; const Partitions: TArray<Integer>; const Handler: TConsumerMessageHandlerProc): TKafkaConsumer;
var
  Configuration: prd_kafka_conf_t;
  TopicConfiguration: prd_kafka_topic_conf_t;
begin
  Configuration := TKafka.NewConfiguration(
    ConfigKeys,
    ConfigValues);

  TopicConfiguration := TKafka.NewTopicConfiguration(
    ConfigTopicKeys,
    ConfigTopicValues);

  rd_kafka_conf_set_default_topic_conf(
    Configuration,
    TopicConfiguration);

  Result := TKafka.NewConsumer(
    Configuration,
    Brokers,
    Topics,
    Partitions,
    Handler
  );
end;

class function TKafka.NewConsumer(const Configuration: prd_kafka_conf_t; const Brokers: String;
  const Topics: TArray<String>; const Partitions: TArray<Integer>; const Handler: TConsumerMessageHandlerProc): TKafkaConsumer;
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

class function TKafka.NewTopic(const KafkaHandle: prd_kafka_t; const TopicName: String; const TopicConfiguration: prd_kafka_topic_conf_t): prd_kafka_topic_t;
begin
  Result := rd_kafka_topic_new(
    KafkaHandle,
    PAnsiChar(AnsiString(TopicName)),
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

class procedure TKafka.CheckKeyValues(const Keys, Values: TArray<String>);
begin
  if length(keys) <> length(values) then
  begin
    raise EKafkaError.Create(StrKeysAndValuesMust);
  end;
end;

class function TKafka.NewTopicConfiguration(const Keys, Values: TArray<String>): prd_kafka_topic_conf_t;
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

class function TKafka.Produce(const Topic: prd_kafka_topic_t; const Partition: Int32; const MsgFlags: Integer; const Payload: String;
  const Key: Pointer; const KeyLen: NativeUInt; const MsgOpaque: Pointer): Integer;
begin
  Result := Produce(
    Topic,
    Partition,
    MsgFlags,
    @PAnsiChar(AnsiString(Payload))[1],
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

class procedure TKafka.SetConfigurationValue(var Configuration: prd_kafka_conf_t; const Key, Value: String);
var
  ErrorStr: TKafkaErrorArray;
begin
  if Value = '' then
  begin
    raise EKafkaError.Create(StrInvalidConfiguratio);
  end;

  if rd_kafka_conf_set(
    Configuration,
    PAnsiChar(AnsiString(Key)),
    PAnsiChar(AnsiString(Value)),
    ErrorStr,
    Sizeof(ErrorStr)) <> RD_KAFKA_CONF_OK then
  begin
    raise EKafkaError.Create(String(ErrorStr));
  end;
end;

class procedure TKafka.SetTopicConfigurationValue(var TopicConfiguration: prd_kafka_topic_conf_t; const Key, Value: String);
var
  ErrorStr: TKafkaErrorArray;
begin
  if Value = '' then
  begin
    raise EKafkaError.Create(StrInvalidTopicConfig);
  end;

  if rd_kafka_topic_conf_set(
    TopicConfiguration,
    PAnsiChar(AnsiString(Key)),
    PAnsiChar(AnsiString(Value)),
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

constructor TKafkaConsumer.Create(const Configuration: prd_kafka_conf_t; const Handler: TConsumerMessageHandlerProc; const Brokers: String; const Topics: TArray<String>; const Partitions: TArray<Integer>);
begin
  FThread := TKafkaConnectionThread.Create(
    Configuration,
    Handler,
    Brokers,
    Topics,
    Partitions);

  FThread.OnTerminate := OnThreadTerminate;
  FThread.FreeOnTerminate := True;
  FThread.Start;
end;

destructor TKafkaConsumer.Destroy;
begin
  FThread.Terminate;

  inherited;
end;

function TKafkaConsumer.GetConsumedCount: Int64;
begin
  TInterlocked.Exchange(Result, FThread.FConsumedCount);
end;

procedure TKafkaConsumer.OnThreadTerminate(Sender: TObject);
begin
  FThread := nil;
end;

class function TKafka.Produce(const Topic: prd_kafka_topic_t; const Partition: Int32; const MsgFlags: Integer; const Payloads: TArray<String>;
  const Key: Pointer; const KeyLen: NativeUInt; const MsgOpaque: Pointer): Integer;
var
  PayloadPointers: TArray<Pointer>;
  PayloadLengths: TArray<Integer>;
  i: Integer;
  TempStr: AnsiString;
begin
  SetLength(PayloadPointers, length(Payloads));
  SetLength(PayloadLengths, length(Payloads));

  for i := Low(Payloads) to High(Payloads) do
  begin
    TempStr := AnsiString(Payloads[i]);

    PayloadPointers[i] := @TempStr[1];
    PayloadLengths[i] := length(TempStr);
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

{ TKafkaConnectionThread }

constructor TKafkaConnectionThread.Create(const Configuration: prd_kafka_conf_t; const Handler: TConsumerMessageHandlerProc; const Brokers: String;
  const Topics: TArray<String>; const Partitions: TArray<Integer>);
begin
  inherited Create(True);

  FConfiguration := Configuration;
  FHandler := Handler;
  FBrokers := Brokers;
  FTopics := Topics;
  FPartitions := Partitions;
end;

procedure TKafkaConnectionThread.DoCleanUp;
begin
  if FKafkaHandle <> nil then
  begin
    TKafka.ConsumerClose(FKafkaHandle);
    TKafka.DestroyHandle(FKafkaHandle);
  end;
end;

procedure TKafkaConnectionThread.DoExecute;
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
          TInterlocked.Increment(FConsumedCount);

          FHandler(Msg);
        end;
      end;
    end;
  finally
    rd_kafka_message_destroy(Msg);
  end;
end;

procedure TKafkaConnectionThread.DoSetup;
var
  i: Integer;
  TopicList: prd_kafka_topic_partition_list_t;
begin
  FKafkaHandle := TKafka.NewConsumer(FConfiguration);

  if rd_kafka_brokers_add(FKafkaHandle, PAnsiChar(AnsiString(FBrokers))) = 0 then
  begin
    raise EKafkaError.Create(StrBrokersCouldNotBe);
  end;

  rd_kafka_poll_set_consumer(FKafkaHandle);

  TopicList := rd_kafka_topic_partition_list_new(0);

  for i := Low(FTopics) to High(FTopics) do
  begin
    rd_kafka_topic_partition_list_add(
      TopicList,
      PAnsiChar(AnsiString(FTopics[i])),
      FPartitions[i]);
  end;

  rd_kafka_assign(
    FKafkaHandle,
    TopicList);
end;

{ TKafkaConnectionThreadBase }

procedure TKafkaConnectionThreadBase.Execute;
begin
  try
    DoSetup;
    try
      while not Terminated do
      begin
        DoExecute;
      end;
    finally
      DoCleanUp;
    end;
  except
    on e: Exception do
    begin
      TKafka.Log(format('Critical exception: %s', [e.Message]), TKafkaLogType.kltError);
    end;
  end;
end;

{ TKafkaProducer }

constructor TKafkaProducer.Create(const ConfigurationKeys, ConfigurationValues: TArray<String>);
var
  Configuration: prd_kafka_conf_t;
begin
  Configuration := TKafka.NewConfiguration(
    ConfigurationKeys,
    ConfigurationValues);

  FKafkaHandle := TKafka.NewProducer(Configuration);
end;

function TKafkaProducer.Produce(const Topic: String; const Payload: String; const Key: Pointer; const KeyLen: NativeUInt; const Partition: Int32; const MsgFlags: Integer;
  const MsgOpaque: Pointer): Integer;
begin
  Result := Produce(
    Topic,
    @Payload[1],
    length(Payload),
    Key,
    KeyLen,
    Partition,
    MsgFlags,
    MsgOpaque
  );
end;

function TKafkaProducer.Produce(const Topic: String; const Payload: Pointer; const PayloadLength: NativeUInt; const Key: Pointer; const KeyLen: NativeUInt;
  const Partition: Int32; const MsgFlags: Integer; const MsgOpaque: Pointer): Integer;
var
  KTopic: prd_kafka_topic_t;
begin
  KTopic := TKafka.NewTopic(
    FKafkaHandle,
    Topic,
    nil);

  try
    Result := TKafka.Produce(
      KTopic,
      Partition,
      MsgFlags,
      Payload,
      PayloadLength,
      Key,
      KeyLen,
      MsgOpaque);

    rd_kafka_flush(FKafkaHandle, 1000);
  finally
    rd_kafka_topic_destroy(KTopic);
  end;
end;

function TKafkaProducer.Produce(const Topic: String; const Payloads: TArray<Pointer>; const PayloadLengths: TArray<Integer>; const Key: Pointer; const KeyLen: NativeUInt;
  const Partition: Int32; const MsgFlags: Integer; const MsgOpaque: Pointer): Integer;
begin

end;

destructor TKafkaProducer.Destroy;
begin
  rd_kafka_destroy(FKafkaHandle);

  inherited;
end;

function TKafkaProducer.Produce(const Topic: String; const Payloads: TArray<String>; const Key: Pointer; const KeyLen: NativeUInt; const Partition: Int32;
  const MsgFlags: Integer; const MsgOpaque: Pointer): Integer;
begin

end;

end.
