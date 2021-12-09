unit Kafka.Classes;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.SyncObjs,

  Kafka.Interfaces,
  Kafka.Types,
  Kafka.Helper,
  Kafka.Lib;

const
  ConsumerPollTimeout = 100;

type
  TConsumerMessageHandlerProc = reference to procedure(const Msg: prd_kafka_message_t);

  TKafkaConsumerThreadBase = class(TThread)
  protected
    FKafkaHandle: prd_kafka_t;
    FConfiguration: prd_kafka_conf_t;
    FHandler: TConsumerMessageHandlerProc;
    FTopics: TArray<String>;
    FPartitions: TArray<Integer>;
    FBrokers: String;
    FConsumedCount: Int64;

    procedure DoSetup; virtual; abstract;
    procedure DoExecute; virtual; abstract;
    procedure DoCleanUp; virtual; abstract;

    procedure Execute; override;
  public
    constructor Create(const Configuration: prd_kafka_conf_t; const Handler: TConsumerMessageHandlerProc; const Brokers: String; const Topics: TArray<String>; const Partitions: TArray<Integer>);
  end;
  TKafkaConsumerThreadClass = class of TKafkaConsumerThreadBase;

  TKafkaConsumerThread = class(TKafkaConsumerThreadBase)
  protected
    procedure DoSetup; override;
    procedure DoExecute; override;
    procedure DoCleanUp; override;
  public
    destructor Destroy; override;
  end;

  TKafkaConsumer = class(TInterfacedObject, IKafkaConsumer)
  private
    function GetConsumedCount: Int64;
  protected
    FThread: TKafkaConsumerThreadBase;

    procedure DoNeedConsumerThreadClass(out Value: TKafkaConsumerThreadClass); virtual;
  public
    constructor Create(const Configuration: prd_kafka_conf_t; const Handler: TConsumerMessageHandlerProc; const Brokers: String; const Topics: TArray<String>; const Partitions: TArray<Integer>);
    destructor Destroy; override;

    function GetConsumerThreadClass: TKafkaConsumerThreadClass;

    property ConsumedCount: Int64 read GetConsumedCount;
  end;

  TKafkaProducer = class(TInterfacedObject, IKafkaProducer)
  private
    FProducedCount: Int64;

    function GetKafkaHandle: prd_kafka_t;
    function GetProducedCount: Int64;
  protected
    FKafkaHandle: prd_kafka_t;
    FConfiguration: prd_kafka_conf_t;
  public
    constructor Create(const ConfigurationKeys, ConfigurationValues: TArray<String>); overload;
    constructor Create(const Configuration: prd_kafka_conf_t); overload;

    destructor Destroy; override;

    function Produce(const Topic: String; const Payload: Pointer; const PayloadLength: NativeUInt; const Key: Pointer = nil; const KeyLen: NativeUInt = 0; const Partition: Int32 = RD_KAFKA_PARTITION_UA; const MsgFlags: Integer = RD_KAFKA_MSG_F_COPY; const MsgOpaque: Pointer = nil): Integer; overload;
    function Produce(const Topic: String; const Payloads: TArray<Pointer>; const PayloadLengths: TArray<Integer>; const Key: Pointer = nil; const KeyLen: NativeUInt = 0; const Partition: Int32 = RD_KAFKA_PARTITION_UA; const MsgFlags: Integer = RD_KAFKA_MSG_F_COPY; const MsgOpaque: Pointer = nil): Integer; overload;
    function Produce(const Topic: String; const Payload: String; const Key: String; const Partition: Int32 = RD_KAFKA_PARTITION_UA; const MsgFlags: Integer = RD_KAFKA_MSG_F_COPY; const MsgOpaque: Pointer = nil): Integer; overload;
    function Produce(const Topic: String; const Payload: String; const Key: String; const Encoding: TEncoding; const Partition: Int32 = RD_KAFKA_PARTITION_UA; const MsgFlags: Integer = RD_KAFKA_MSG_F_COPY; const MsgOpaque: Pointer = nil): Integer; overload;
    function Produce(const Topic: String; const Payloads: TArray<String>; const Key: String; const Partition: Int32 = RD_KAFKA_PARTITION_UA; const MsgFlags: Integer = RD_KAFKA_MSG_F_COPY; const MsgOpaque: Pointer = nil): Integer; overload;
    function Produce(const Topic: String; const Payloads: TArray<String>; const Key: String; const Encoding: TEncoding; const Partition: Int32 = RD_KAFKA_PARTITION_UA; const MsgFlags: Integer = RD_KAFKA_MSG_F_COPY; const MsgOpaque: Pointer = nil): Integer; overload;

    property ProducedCount: Int64 read GetProducedCount;
    property KafkaHandle: prd_kafka_t read GetKafkaHandle;
  end;

implementation

resourcestring
  StrBrokersCouldNotBe = 'Brokers could not be added';

{ TKafkaConsumerThread }

destructor TKafkaConsumerThread.Destroy;
begin
  inherited;
end;

procedure TKafkaConsumerThread.DoCleanUp;
begin
  if FKafkaHandle <> nil then
  begin
    (*rd_kafka_commit(
      FKafkaHandle,
      Msg,
      1);*)

    TKafkaHelper.ConsumerClose(FKafkaHandle);
    TKafkaHelper.DestroyHandle(FKafkaHandle);
  end;
end;

procedure TKafkaConsumerThread.DoExecute;
var
  Msg: prd_kafka_message_t;
begin
  Msg := rd_kafka_consumer_poll(FKafkaHandle, ConsumerPollTimeout);

  if Msg <> nil then
  try
    if (Msg.err <> RD_KAFKA_RESP_ERR__PARTITION_EOF) and
       (Assigned(FHandler)) then
    begin
      TInterlocked.Increment(FConsumedCount);

      try
        FHandler(Msg);

        (*rd_kafka_commit_message(
          FKafkaHandle,
          Msg,
          0);*)
      except
        on e: Exception do
        begin
          TKafkaHelper.Log('Exception in message callback - ' + e.Message, TKafkaLogType.kltError);
        end;
      end;
    end;
  finally
    rd_kafka_message_destroy(Msg);
  end;
end;

procedure TKafkaConsumerThread.DoSetup;
var
  i: Integer;
  TopicList: prd_kafka_topic_partition_list_t;
begin
  FKafkaHandle := TKafkaHelper.NewConsumer(FConfiguration);

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

  // Using rd_kafka_subscribe instead of rd_kafka_assign allows for RegEx wildcards in topic names
  rd_kafka_subscribe(FKafkaHandle, TopicList);
end;

{ TKafkaConsumerThreadBase }

constructor TKafkaConsumerThreadBase.Create(const Configuration: prd_kafka_conf_t; const Handler: TConsumerMessageHandlerProc; const Brokers: String;
  const Topics: TArray<String>; const Partitions: TArray<Integer>);
begin
  inherited Create(True);

  FreeOnTerminate := True;

  FConfiguration := Configuration;
  FHandler := Handler;
  FBrokers := Brokers;
  FTopics := Topics;
  FPartitions := Partitions;
end;

procedure TKafkaConsumerThreadBase.Execute;
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
      TKafkaHelper.Log(format('Critical exception: %s', [e.Message]), TKafkaLogType.kltError);
    end;
  end;
end;

{ TKafkaProducer }

constructor TKafkaProducer.Create(const ConfigurationKeys, ConfigurationValues: TArray<String>);
var
  Configuration: prd_kafka_conf_t;
begin
  Configuration := TKafkaHelper.NewConfiguration(
    ConfigurationKeys,
    ConfigurationValues);

  Create(Configuration);
end;

constructor TKafkaProducer.Create(const Configuration: prd_kafka_conf_t);
begin
  FKafkaHandle := TKafkaHelper.NewProducer(Configuration);
end;

destructor TKafkaProducer.Destroy;
begin
  rd_kafka_destroy(FKafkaHandle);

  inherited;
end;

function TKafkaProducer.GetKafkaHandle: prd_kafka_t;
begin
  Result := FKafkaHandle;
end;

function TKafkaProducer.GetProducedCount: Int64;
begin
  TInterlocked.Exchange(Result, FProducedCount);
end;

function TKafkaProducer.Produce(const Topic: String; const Payload: String; const Key: String; const Partition: Int32; const MsgFlags: Integer;
  const MsgOpaque: Pointer): Integer;
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

function TKafkaProducer.Produce(const Topic: String; const Payload: Pointer; const PayloadLength: NativeUInt; const Key: Pointer; const KeyLen: NativeUInt;
  const Partition: Int32; const MsgFlags: Integer; const MsgOpaque: Pointer): Integer;
var
  KTopic: prd_kafka_topic_t;
begin
  KTopic := TKafkaHelper.NewTopic(
    FKafkaHandle,
    Topic,
    nil);
  try
    Result := TKafkaHelper.Produce(
      KTopic,
      Payload,
      PayloadLength,
      Key,
      KeyLen,
      Partition,
      MsgFlags,
      MsgOpaque);

    TInterlocked.Increment(FProducedCount);
  finally
    rd_kafka_topic_destroy(KTopic);
  end;
end;

function TKafkaProducer.Produce(const Topic: String; const Payloads: TArray<Pointer>; const PayloadLengths: TArray<Integer>; const Key: Pointer; const KeyLen: NativeUInt;
  const Partition: Int32; const MsgFlags: Integer; const MsgOpaque: Pointer): Integer;
var
  KTopic: prd_kafka_topic_t;
begin
  KTopic := TKafkaHelper.NewTopic(
    FKafkaHandle,
    Topic,
    nil);
  try
    Result := TKafkaHelper.Produce(
      KTopic,
      Payloads,
      PayloadLengths,
      Key,
      KeyLen,
      Partition,
      MsgFlags,
      MsgOpaque);

    TInterlocked.Add(FProducedCount, Length(Payloads));
  finally
    rd_kafka_topic_destroy(KTopic);
  end;
end;

function TKafkaProducer.Produce(const Topic: String; const Payloads: TArray<String>; const Key: String; const Partition: Int32;
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

function TKafkaProducer.Produce(const Topic: String; const Payloads: TArray<String>; const Key: String; const Encoding: TEncoding; const Partition: Int32;
  const MsgFlags: Integer; const MsgOpaque: Pointer): Integer;
var
  KTopic: prd_kafka_topic_t;
begin
  KTopic := TKafkaHelper.NewTopic(
    FKafkaHandle,
    Topic,
    nil);
  try
    Result := TKafkaHelper.Produce(
      KTopic,
      Payloads,
      Key,
      Encoding,
      Partition,
      MsgFlags,
      MsgOpaque);

    TInterlocked.Add(FProducedCount, Length(Payloads));
  finally
    rd_kafka_topic_destroy(KTopic);
  end;
end;

function TKafkaProducer.Produce(const Topic, Payload, Key: String; const Encoding: TEncoding; const Partition: Int32; const MsgFlags: Integer;
  const MsgOpaque: Pointer): Integer;
var
  KTopic: prd_kafka_topic_t;
begin
  KTopic := TKafkaHelper.NewTopic(
    FKafkaHandle,
    Topic,
    nil);
  try
    Result := TKafkaHelper.Produce(
      KTopic,
      Payload,
      Key,
      Encoding,
      Partition,
      MsgFlags,
      MsgOpaque);

    TInterlocked.Increment(FProducedCount);
  finally
    rd_kafka_topic_destroy(KTopic);
  end;
end;

{ TKafkaConsumer }

constructor TKafkaConsumer.Create(const Configuration: prd_kafka_conf_t; const Handler: TConsumerMessageHandlerProc; const Brokers: String; const Topics: TArray<String>; const Partitions: TArray<Integer>);
begin
  FThread := GetConsumerThreadClass.Create(
    Configuration,
    Handler,
    Brokers,
    Topics,
    Partitions);

  FThread.FreeOnTerminate := True;
  FThread.Start;
end;

destructor TKafkaConsumer.Destroy;
begin
  FThread.Terminate;

  inherited;
end;

procedure TKafkaConsumer.DoNeedConsumerThreadClass(out Value: TKafkaConsumerThreadClass);
begin
  Value := TKafkaConsumerThread;
end;

function TKafkaConsumer.GetConsumedCount: Int64;
begin
  TInterlocked.Exchange(Result, FThread.FConsumedCount);
end;

function TKafkaConsumer.GetConsumerThreadClass: TKafkaConsumerThreadClass;
begin
  DoNeedConsumerThreadClass(Result);
end;

end.
