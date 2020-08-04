unit Kafka.Classes;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Threading, System.SyncObjs,

  Kafka.Interfaces,
  Kafka.Types,
  Kafka.Helper,
  Kafka.Lib;

const
  ConsumerPollTimeout = 100;

type
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
    destructor Destroy; override;
  end;

  TKafkaConsumer = class(TInterfacedObject, IKafkaConsumer)
  private
    function GetConsumedCount: Int64;
  protected
    FThread: TKafkaConnectionThread;
  public
    constructor Create(const Configuration: prd_kafka_conf_t; const Handler: TConsumerMessageHandlerProc; const Brokers: String; const Topics: TArray<String>; const Partitions: TArray<Integer>);
    destructor Destroy; override;

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
    function Produce(const Topic: String; const Payload: String; const Key: Pointer = nil; const KeyLen: NativeUInt = 0; const Partition: Int32 = RD_KAFKA_PARTITION_UA; const MsgFlags: Integer = RD_KAFKA_MSG_F_COPY; const MsgOpaque: Pointer = nil): Integer; overload;
    function Produce(const Topic: String; const Payloads: TArray<Pointer>; const PayloadLengths: TArray<Integer>; const Key: Pointer = nil; const KeyLen: NativeUInt = 0; const Partition: Int32 = RD_KAFKA_PARTITION_UA; const MsgFlags: Integer = RD_KAFKA_MSG_F_COPY; const MsgOpaque: Pointer = nil): Integer; overload;
    function Produce(const Topic: String; const Payloads: TArray<String>; const Key: Pointer = nil; const KeyLen: NativeUInt = 0; const Partition: Int32 = RD_KAFKA_PARTITION_UA; const MsgFlags: Integer = RD_KAFKA_MSG_F_COPY; const MsgOpaque: Pointer = nil): Integer; overload;

    property ProducedCount: Int64 read GetProducedCount;
    property KafkaHandle: prd_kafka_t read GetKafkaHandle;
  end;

implementation

resourcestring
  StrBrokersCouldNotBe = 'Brokers could not be added';

{ TKafkaConnectionThread }

constructor TKafkaConnectionThread.Create(const Configuration: prd_kafka_conf_t; const Handler: TConsumerMessageHandlerProc; const Brokers: String;
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

destructor TKafkaConnectionThread.Destroy;
begin
  inherited;
end;

procedure TKafkaConnectionThread.DoCleanUp;
begin
  if FKafkaHandle <> nil then
  begin
    TKafkaHelper.ConsumerClose(FKafkaHandle);
    TKafkaHelper.DestroyHandle(FKafkaHandle);
  end;
end;

procedure TKafkaConnectionThread.DoExecute;
var
  Msg: prd_kafka_message_t;
begin
  Msg := rd_kafka_consumer_poll(FKafkaHandle, ConsumerPollTimeout);

  if Msg <> nil then
  try
    if TKafkaHelper.IsKafkaError(Msg.err) then
    begin
      TKafkaHelper.Log(format('Message error - %d', [Integer(Msg.err)]), TKafkaLogType.kltConsumer);
    end else
    begin
      if Msg.key_len <> 0 then
      begin
        TKafkaHelper.Log(format('Key received - %s', [TKafkaHelper.PointerToStr(Msg.key, Msg.key_len)]), TKafkaLogType.kltConsumer);
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
  KTopic := TKafkaHelper.NewTopic(
    FKafkaHandle,
    Topic,
    nil);
  try
    Result := TKafkaHelper.Produce(
      KTopic,
      Partition,
      MsgFlags,
      Payload,
      PayloadLength,
      Key,
      KeyLen,
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
      Partition,
      MsgFlags,
      Payloads,
      PayloadLengths,
      Key,
      KeyLen,
      MsgOpaque);

    TInterlocked.Add(FProducedCount, Length(Payloads));
  finally
    rd_kafka_topic_destroy(KTopic);
  end;
end;

function TKafkaProducer.Produce(const Topic: String; const Payloads: TArray<String>; const Key: Pointer; const KeyLen: NativeUInt; const Partition: Int32;
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
      Partition,
      MsgFlags,
      Payloads,
      Key,
      KeyLen,
      MsgOpaque);

    TInterlocked.Add(FProducedCount, Length(Payloads));
  finally
    rd_kafka_topic_destroy(KTopic);
  end;
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

end.
