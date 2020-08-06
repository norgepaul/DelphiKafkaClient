program KafkaDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  Kafka.FMX.Form.Main in 'Kafka.FMX.Form.Main.pas' {frmKafkaDemo},
  Kafka.Types in '..\src\Kafka.Types.pas',
  Kafka.Lib in '..\src\Kafka.Lib.pas',
  Kafka.Classes in '..\src\Kafka.Classes.pas',
  Kafka.Interfaces in '..\src\Kafka.Interfaces.pas',
  Kafka.Factory in '..\src\Kafka.Factory.pas',
  Kafka.Helper in '..\src\Kafka.Helper.pas',
  Kafka.FMX.Form.Producer in 'Kafka.FMX.Form.Producer.pas' {frmProducer},
  Kafka.FMX.Form.Consumer in 'Kafka.FMX.Form.Consumer.pas' {frmConsumer};

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;

  Application.Initialize;
  Application.CreateForm(TfrmKafkaDemo, frmKafkaDemo);
  Application.Run;
end.
