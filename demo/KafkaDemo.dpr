program KafkaDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  frmMain in 'frmMain.pas' {frmKafkaDemo},
  Kafka.Types in '..\src\Kafka.Types.pas',
  Kafka.Lib in '..\src\Kafka.Lib.pas',
  Kafka.Classes in '..\src\Kafka.Classes.pas',
  Kafka.Interfaces in '..\src\Kafka.Interfaces.pas',
  Kafka.Factory in '..\src\Kafka.Factory.pas',
  Kafka.Helper in '..\src\Kafka.Helper.pas',
  Kafka.Serializer in '..\src\Kafka.Serializer.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;

  Application.Initialize;
  Application.CreateForm(TfrmKafkaDemo, frmKafkaDemo);
  Application.Run;
end.
