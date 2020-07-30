unit Kafka.Types;

interface

uses
  System.SysUtils;

type
  PNativeUInt = ^NativeUInt;
  mode_t = LongWord;

  TKafkaErrorArray= Array [0 .. 512] of AnsiChar;

implementation

end.
