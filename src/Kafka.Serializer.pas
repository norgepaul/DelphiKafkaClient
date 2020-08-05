unit Kafka.Serializer;

interface

uses
  System.SysUtils, System.RTTI, System.TypInfo, Generics.Collections;

type
  TKafkaSerializer = class
  public
    class function Serialize<T>(const Value: T): TValue;
    class function DeSerialize<T>(const Data: Pointer; const Len: Integer): TValue;
  end;

implementation

{ TKafkaSerializer }

class function TKafkaSerializer.DeSerialize<T>(const Data: Pointer; const Len: Integer): TValue;
begin
  TValue.Make(Data, TypeInfo(T), Result);
end;

class function TKafkaSerializer.Serialize<T>(const Value: T): TValue;
begin
  Result := TValue.From<T>(Value);
end;

end.
