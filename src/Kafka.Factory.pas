unit Kafka.Factory;

interface

uses
  Kafka.Interfaces,
  Kafka.Types,
  Kafka.Classes,
  Kafka.Helper,
  Kafka.Lib;

type
  TKafkaFactory = class
  public
    class function NewProducer(const ConfigurationKeys, ConfigurationValues: TArray<String>): IKafkaProducer; overload;
    class function NewProducer(const Configuration: prd_kafka_conf_t): IKafkaProducer; overload;

    class function NewConsumer(const Configuration: prd_kafka_conf_t; const Brokers: String; const Topics: TArray<String>; const Partitions: TArray<Integer>; const Handler: TConsumerMessageHandlerProc): IKafkaConsumer; overload; static;
    class function NewConsumer(const ConfigKeys, ConfigValues, ConfigTopicKeys, ConfigTopicValues: TArray<String>; const Brokers: String; const Topics: TArray<String>; const Partitions: TArray<Integer>; const Handler: TConsumerMessageHandlerProc): IKafkaConsumer; overload; static;
  end;

implementation

{ TKafkaFactory }

class function TKafkaFactory.NewConsumer(const ConfigKeys, ConfigValues, ConfigTopicKeys, ConfigTopicValues: TArray<String>; const Brokers: String;
  const Topics: TArray<String>; const Partitions: TArray<Integer>; const Handler: TConsumerMessageHandlerProc): IKafkaConsumer;
var
  Configuration: prd_kafka_conf_t;
  TopicConfiguration: prd_kafka_topic_conf_t;
begin
  Configuration := TKafkaHelper.NewConfiguration(
    ConfigKeys,
    ConfigValues);

  TopicConfiguration := TKafkaHelper.NewTopicConfiguration(
    ConfigTopicKeys,
    ConfigTopicValues);

  rd_kafka_conf_set_default_topic_conf(
    Configuration,
    TopicConfiguration);

  Result := NewConsumer(
    Configuration,
    Brokers,
    Topics,
    Partitions,
    Handler
  );
end;

class function TKafkaFactory.NewProducer(const Configuration: prd_kafka_conf_t): IKafkaProducer;
begin
  Result := TKafkaProducer.Create(Configuration);
end;

class function TKafkaFactory.NewProducer(const ConfigurationKeys, ConfigurationValues: TArray<String>): IKafkaProducer;
var
  Configuration: prd_kafka_conf_t;
begin
  Configuration := TKafkaHelper.NewConfiguration(
    ConfigurationKeys,
    ConfigurationValues);

  Result := NewProducer(Configuration);
end;

class function TKafkaFactory.NewConsumer(const Configuration: prd_kafka_conf_t; const Brokers: String;
  const Topics: TArray<String>; const Partitions: TArray<Integer>; const Handler: TConsumerMessageHandlerProc): IKafkaConsumer;
begin
  Result := TKafkaConsumer.Create(
    Configuration,
    Handler,
    Brokers,
    Topics,
    Partitions
  );
end;

end.
