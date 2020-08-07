unit Kafka.FMX.Helper;

interface

uses
  System.Types,

  FMX.Grid;

type
  TFMXHelper = class
  public
    const MAX_LOG_LINES = 5000;
  public
    class procedure SetGridRowCount(const Grid: TGrid; const RowCount: Integer; const ScrollToBottom: Boolean = True); static;
  end;

implementation

class procedure TFMXHelper.SetGridRowCount(const Grid: TGrid; const RowCount: Integer; const ScrollToBottom: Boolean);
var
  ViewPort, CellRect: TRectF;
  SelectedRow, SelectedColumn: Integer;
begin
  if RowCount <> Grid.RowCount then
  begin
    Grid.BeginUpdate;
    try
      if Grid.Selected <> -1 then
      begin
        SelectedRow := Grid.Row;
        SelectedColumn := Grid.Col;

        if SelectedColumn = 1 then
        begin
          SelectedColumn := 0;
        end;
      end;

      Grid.Selected := -1;

      Grid.RowCount := RowCount;
    finally
     Grid.EndUpdate;
    end;

    if not Grid.IsFocused then
    begin
      Grid.ScrollBy(0, MaxInt);
      Grid.SelectRow(Grid.RowCount - 1);
      Grid.Repaint;
    end
    else
    begin
      // This is a tricky workaround for an awful FMX bug
      ViewPort := RectF(
        0,
        Grid.ViewportPosition.Y,
        MaxInt,
        Grid.ViewportPosition.Y + Grid.ViewportSize.Height);

      CellRect := Grid.CellRect(0, SelectedRow);

      if ViewPort.Contains(CellRect) then
      begin
        Grid.SelectCell(SelectedColumn, SelectedRow);
      end;
    end;
  end;
end;

end.
