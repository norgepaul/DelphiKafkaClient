unit Kafka.Helper;

interface

uses
  System.SysUtils, System.Classes,

  Kafka.Types,
  Kafka.Lib;

type
  EKafkaError = class(Exception);

  TOnLog = procedure(const Values: TStrings) of object;

  TKafkaHelper = class
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

    // Wrappers
    class function NewConfiguration(const DefaultCallBacks: Boolean = True): prd_kafka_conf_t; overload; static;
    class function NewConfiguration(const Keys, Values: TArray<String>; const DefaultCallBacks: Boolean = True): prd_kafka_conf_t; overload; static;
    class procedure SetConfigurationValue(var Configuration: prd_kafka_conf_t; const Key, Value: String); static;
    class procedure DestroyConfiguration(const Configuration: Prd_kafka_conf_t); static;

    class function NewTopicConfiguration: prd_kafka_topic_conf_t; overload; static;
    class function NewTopicConfiguration(const Keys, Values: TArray<String>): prd_kafka_topic_conf_t; overload; static;
    class procedure SetTopicConfigurationValue(var TopicConfiguration: prd_kafka_topic_conf_t; const Key, Value: String); static;
    class procedure DestroyTopicConfiguration(const TopicConfiguration: Prd_kafka_topic_conf_t); static;

    class function NewProducer(const Configuration: prd_kafka_conf_t): prd_kafka_t; overload; static;
    class function NewProducer(const ConfigKeys, ConfigValues: TArray<String>): prd_kafka_t; overload; static;

    class function NewConsumer(const Configuration: prd_kafka_conf_t): prd_kafka_t; overload; static;

    class procedure ConsumerClose(const KafkaHandle: prd_kafka_t); static;
    class procedure DestroyHandle(const KafkaHandle: prd_kafka_t); static;

    class function NewTopic(const KafkaHandle: prd_kafka_t; const TopicName: String; const TopicConfiguration: prd_kafka_topic_conf_t = nil): prd_kafka_topic_t;

    class function Produce(const Topic: prd_kafka_topic_t; const Payload: Pointer; const PayloadLength: NativeUInt; const Key: Pointer = nil; const KeyLen: NativeUInt = 0; const Partition: Int32 = RD_KAFKA_PARTITION_UA; const MsgFlags: Integer = RD_KAFKA_MSG_F_COPY; const MsgOpaque: Pointer = nil): Integer; overload;
    class function Produce(const Topic: prd_kafka_topic_t; const Payloads: TArray<Pointer>; const PayloadLengths: TArray<Integer>; const Key: Pointer = nil; const KeyLen: NativeUInt = 0; const Partition: Int32 = RD_KAFKA_PARTITION_UA; const MsgFlags: Integer = RD_KAFKA_MSG_F_COPY; const MsgOpaque: Pointer = nil): Integer; overload;
    class function Produce(const Topic: prd_kafka_topic_t; const Payload: String; const Key: String; const Partition: Int32 = RD_KAFKA_PARTITION_UA; const MsgFlags: Integer = RD_KAFKA_MSG_F_COPY; const MsgOpaque: Pointer = nil): Integer; overload;
    class function Produce(const Topic: prd_kafka_topic_t; const Payload: String; const Key: String; const Encoding: TEncoding; const Partition: Int32 = RD_KAFKA_PARTITION_UA; const MsgFlags: Integer = RD_KAFKA_MSG_F_COPY; const MsgOpaque: Pointer = nil): Integer; overload;
    class function Produce(const Topic: prd_kafka_topic_t; const Payloads: TArray<String>; const Key: String; const Partition: Int32 = RD_KAFKA_PARTITION_UA; const MsgFlags: Integer = RD_KAFKA_MSG_F_COPY; const MsgOpaque: Pointer = nil): Integer; overload;
    class function Produce(const Topic: prd_kafka_topic_t; const Payloads: TArray<String>; const Key: String; const Encoding: TEncoding; const Partition: Int32 = RD_KAFKA_PARTITION_UA; const MsgFlags: Integer = RD_KAFKA_MSG_F_COPY; const MsgOpaque: Pointer = nil): Integer; overload;

    class procedure Flush(const KafkaHandle: prd_kafka_t; const Timeout: Integer = 1000);

    // Helpers
    class function PointerToStr(const Value: Pointer; const Len: Integer; const Encoding: TEncoding): String; static;
    class function StrToBytes(const Value: String; const Encoding: TEncoding): TBytes; static;
    class function IsKafkaError(const Error: rd_kafka_resp_err_t): Boolean; static;

    // Internal
    class procedure FlushLogs;

    class property OnLog: TOnLog read FOnLog write FOnLog;
  end;

implementation

resourcestring
  StrLogCallBackFac = 'Log_CallBack - fac = %s, buff = %s';
  StrMessageSendResult = 'Message send result = %d';
  StrErrorCallBackReaso = 'Error =  %s';
  StrUnableToCreateKaf = 'Unable to create Kafka Handle - %s';
  StrKeysAndValuesMust = 'Keys and Values must be the same length';
  StrMessageNotQueued = 'Message not Queued';
  StrInvalidConfiguratio = 'Invalid configuration key';
  StrInvalidTopicConfig = 'Invalid topic configuration key';
  StrCriticalError = 'Critical Error: ';

// Global callbacks

procedure ProducerCallBackLogger(rk: prd_kafka_t; rkmessage: prd_kafka_message_t;
  opaque: Pointer); cdecl;
begin
  if rkmessage <> nil then
  begin
    TKafkaHelper.Log(format(StrMessageSendResult, [Integer(rkmessage.err)]), TKafkaLogType.kltProducer);
  end;
end;

procedure LogCallBackLogger(rk: prd_kafka_t; level: integer; fac: PAnsiChar;
  buf: PAnsiChar); cdecl;
begin
  TKafkaHelper.Log(format(StrLogCallBackFac, [String(fac), String(buf)]), TKafkaLogType.kltLog);
end;

procedure ErrorCallBackLogger(rk: prd_kafka_t; err: integer; reason: PAnsiChar;
  opaque: Pointer); cdecl;
begin
  TKafkaHelper.Log(format(StrErrorCallBackReaso, [String(reason)]), kltError);
end;

{ TKafkaHelper }

class procedure TKafkaHelper.ConsumerClose(const KafkaHandle: prd_kafka_t);
begin
  rd_kafka_consumer_close(KafkaHandle);
end;

class procedure TKafkaHelper.DestroyHandle(const KafkaHandle: prd_kafka_t);
begin
  rd_kafka_destroy(KafkaHandle);
end;

class constructor TKafkaHelper.Create;
begin
  FLogStrings := TStringList.Create;
end;

class destructor TKafkaHelper.Destroy;
begin
  FreeAndNil(FLogStrings);
end;

class procedure TKafkaHelper.DoLog(const Text: String; const LogType: TKafkaLogType);
begin
  TMonitor.Enter(TKafkaHelper.FLogStrings);
  try
    TKafkaHelper.FLogStrings.AddObject(Text, TObject(LogType));
  finally
    TMonitor.Exit(TKafkaHelper.FLogStrings);
  end;
end;

class procedure TKafkaHelper.Flush(const KafkaHandle: prd_kafka_t; const Timeout: Integer);
begin
  rd_kafka_flush(KafkaHandle, Timeout);
end;

class procedure TKafkaHelper.FlushLogs;
begin
  TMonitor.Enter(TKafkaHelper.FLogStrings);
  try
    if Assigned(FOnLog) then
    begin
      FOnLog(TKafkaHelper.FLogStrings);
    end;

    TKafkaHelper.FLogStrings.Clear;
  finally
    TMonitor.Exit(TKafkaHelper.FLogStrings);
  end;
end;

class procedure TKafkaHelper.Log(const Text: String; const LogType: TKafkaLogType);
begin
  DoLog(Text, LogType);
end;

class procedure TKafkaHelper.DestroyConfiguration(const Configuration: Prd_kafka_conf_t);
begin
  rd_kafka_conf_destroy(Configuration);
end;

class procedure TKafkaHelper.DestroyTopicConfiguration(const TopicConfiguration: Prd_kafka_topic_conf_t);
begin
  rd_kafka_topic_conf_destroy(TopicConfiguration);
end;

class function TKafkaHelper.NewConfiguration(const Keys: TArray<String>; const Values: TArray<String>; const DefaultCallBacks: Boolean): prd_kafka_conf_t;
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

class function TKafkaHelper.NewProducer(const ConfigKeys, ConfigValues: TArray<String>): prd_kafka_t;
var
  Configuration: prd_kafka_conf_t;
begin
  Configuration := TKafkaHelper.NewConfiguration(
    ConfigKeys,
    ConfigValues);

  Result := NewProducer(Configuration);
end;

class function TKafkaHelper.NewConsumer(const Configuration: prd_kafka_conf_t): prd_kafka_t;
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

class function TKafkaHelper.NewProducer(const Configuration: prd_kafka_conf_t): prd_kafka_t;
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

class function TKafkaHelper.NewTopic(const KafkaHandle: prd_kafka_t; const TopicName: String; const TopicConfiguration: prd_kafka_topic_conf_t): prd_kafka_topic_t;
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

class function TKafkaHelper.NewTopicConfiguration: prd_kafka_topic_conf_t;
begin
  Result := NewTopicConfiguration([], []);
end;

class procedure TKafkaHelper.CheckKeyValues(const Keys, Values: TArray<String>);
begin
  if length(keys) <> length(values) then
  begin
    raise EKafkaError.Create(StrKeysAndValuesMust);
  end;
end;

class function TKafkaHelper.NewTopicConfiguration(const Keys, Values: TArray<String>): prd_kafka_topic_conf_t;
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

class function TKafkaHelper.Produce(const Topic: prd_kafka_topic_t; const Payloads: TArray<Pointer>; const PayloadLengths: TArray<Integer>; const Key: Pointer;
  const KeyLen: NativeUInt; const Partition: Int32; const MsgFlags: Integer; const MsgOpaque: Pointer): Integer;
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

class function TKafkaHelper.Produce(const Topic: prd_kafka_topic_t; const Payloads: TArray<String>; const Key: String; const Encoding: TEncoding;
  const Partition: Int32; const MsgFlags: Integer; const MsgOpaque: Pointer): Integer;
var
  PayloadPointers: TArray<Pointer>;
  PayloadLengths: TArray<Integer>;
  KeyBytes, PayloadBytes: TBytes;
  i: Integer;
  KeyData: TBytes;
begin
  SetLength(PayloadPointers, length(Payloads));
  SetLength(PayloadLengths, length(Payloads));

  KeyData := TEncoding.UTF8.GetBytes(Key);

  KeyBytes := StrToBytes(Key, Encoding);

  for i := Low(Payloads) to High(Payloads) do
  begin
    PayloadBytes := StrToBytes(Payloads[i], Encoding);

    PayloadPointers[i] := @PayloadBytes[0];
    PayloadLengths[i] := Length(PayloadBytes);
  end;

  Result := Produce(
    Topic,
    PayloadPointers,
    PayloadLengths,
    @KeyBytes[0],
    Length(KeyBytes),
    Partition,
    MsgFlags,
    MsgOpaque);
end;

class function TKafkaHelper.Produce(const Topic: prd_kafka_topic_t; const Payload: String; const Key: String; const Encoding: TEncoding;
  const Partition: Int32; const MsgFlags: Integer; const MsgOpaque: Pointer): Integer;
var
  KeyBytes, PayloadBytes: TBytes;
begin
  KeyBytes := StrToBytes(Key, TEncoding.UTF8);
  PayloadBytes := StrToBytes(Payload, TEncoding.UTF8);

  Result := Produce(
    Topic,
    @PayloadBytes[0],
    length(PayloadBytes),
    @KeyBytes[0],
    length(KeyBytes),
    Partition,
    MsgFlags,
    MsgOpaque)
end;

class function TKafkaHelper.Produce(const Topic: prd_kafka_topic_t; const Payload: String; const Key: String; const Partition: Int32;
  const MsgFlags: Integer; const MsgOpaque: Pointer): Integer;
begin
  Result := Produce(
    Topic,
    Payload,
    Key,
    TEncoding.UTF8,
    Partition,
    MsgFlags,
    MsgOpaque);
end;

class function TKafkaHelper.Produce(const Topic: prd_kafka_topic_t; const Payload: Pointer; const PayloadLength: NativeUInt;
  const Key: Pointer; const KeyLen: NativeUInt; const Partition: Int32; const MsgFlags: Integer; const MsgOpaque: Pointer): Integer;
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

class function TKafkaHelper.NewConfiguration(const DefaultCallBacks: Boolean): prd_kafka_conf_t;
begin
  Result := NewConfiguration([], [], DefaultCallBacks);
end;

class procedure TKafkaHelper.SetConfigurationValue(var Configuration: prd_kafka_conf_t; const Key, Value: String);
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

class procedure TKafkaHelper.SetTopicConfigurationValue(var TopicConfiguration: prd_kafka_topic_conf_t; const Key, Value: String);
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

class function TKafkaHelper.StrToBytes(const Value: String; const Encoding: TEncoding): TBytes;
begin
  if Value = '' then
  begin
    Result := [];
  end
  else
  begin
    Result := Encoding.GetBytes(Value);
  end;
end;

{ TKafkaHelper }

class function TKafkaHelper.IsKafkaError(const Error: rd_kafka_resp_err_t): Boolean;
begin
  Result :=
    (Error <> RD_KAFKA_RESP_ERR_NO_ERROR) and
    (Error <> RD_KAFKA_RESP_ERR__PARTITION_EOF);
end;

class function TKafkaHelper.PointerToStr(const Value: Pointer; const Len: Integer; const Encoding: TEncoding): String;
var
  Data: TBytes;
begin
  SetLength(Data, Len);
  Move(Value^, Pointer(Data)^, Len);

  Result := Encoding.GetString(Data);
end;

class function TKafkaHelper.Produce(const Topic: prd_kafka_topic_t; const Payloads: TArray<String>; const Key: String; const Partition: Int32;
   const MsgFlags: Integer; const MsgOpaque: Pointer): Integer;
begin
  Result := Produce(
    Topic,
    Payloads,
    Key,
    TEncoding.UTF8,
    Partition,
    MsgFlags,
    MsgOpaque);
end;


end.
