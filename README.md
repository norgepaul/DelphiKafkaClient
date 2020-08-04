



# DelphiKafkaClient

DelphiKafkaClient is a cross platform Delphi client/wrapper for Apache [Kafka](https://github.com/edenhill/librdkafka). Windows (i386/x64) and Linux (x64) are supported. Tested on Delphi 10.4, but should work with all modern Delphi releases.

## Installation
You will need to install Apache Kafka - [https://kafka.apache.org/quickstart](https://kafka.apache.org/quickstart)

### Linux
Install the `librdkafka` libray.

    sudo apt install librdkafka-dev
    
Once unstalled, right click the **Linux platform** item under the KafkaDemo project and select **Edit SDK**. Click **Update Local File Cache** and wait for the operation to complete.

### Windows
Copy the **.dll** files from the `lib` folder into the application output directory.

##  Code
All Kafka functionality can be accessed via the header translations in `Kafka.Lib`. To make life easier, many of the common Kafka functions are wrapped in the `Kafka.Classes.TKafka` class.
In addition there are two additional interfaced classes dedicated to Producing and Consuming messages.
### IKafkaProducer

    uses
      Kafka.Lib, Kafka.Factory, Kafka.Interfaces, Kafka.Helper, Kafka.Types;
    ... 
      FKafkaProducer: IKafkaProducer;
    ... 
    procedure TKafkaDemo.SendTestMessages(const Count: Integer);
    var
      Msgs: TArray<String>;
      i: Integer;
    begin
      // Create a new producer if required 
      if FKafkaProducer = nil then
      begin
        FKafkaProducer := TKafkaFactory.NewProducer(
          ['bootstrap.servers'],
          ['127.0.0.1:9092']);
      end;
    
      SetLength(Msgs, Trunc(edtMessageCount.Value));
    
      for i := 0 to pred(Trunc(edtMessageCount.Value)) do
      begin
        Msgs[i] := 'This is a test message' + ' - ' + DateTimeToStr(now) + '.' + MilliSecondOf(now).ToString.PadLeft(3, '0');
      end;
    
      FKafkaProducer.Produce(
        'test',
        Msgs,
        nil,
        0,
        RD_KAFKA_PARTITION_UA,
        RD_KAFKA_MSG_F_COPY,
        nil);
    
      TKafkaHelper.Flush(FKafkaProducer.KafkaHandle);      
    end;

### IKafkaConsumer
    uses
      Kafka.Lib, Kafka.Factory, Kafka.Interfaces, Kafka.Helper, Kafka.Types;
    ...  
      FKafkaConsumer: IKafkaConsumer;
    ... 
    procedure TKafkaDemo.StartConsuming;
    begin
      if FKafkaConsumer = nil then
      begin
        FKafkaConsumer := TKafkaFactory.NewConsumer(
          ['group.id'],
          ['GroupID'],
          ['auto.offset.reset'],
          ['earliest'],
          '127.0.0.1:9092',
          ['test'],
          [0],
          procedure(const Msg: prd_kafka_message_t)
          begin
            // This is called from the consumer thread, but TKafka.Log is threadsafe
            TKafkaHelper.Log(format('Message received - %s', [TKafkaHelper.PointerToStr(Msg.payload, Msg.len)]), TKafkaLogType.kltConsumer);
          end);
      end;
    end;

# Thanks
Shouts go out to @Zhikter and @HeZiHang for some initial inspiration and code examples.
