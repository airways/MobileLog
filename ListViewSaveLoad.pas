unit ListViewSaveLoad;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView,
  StrUtils;

procedure ListViewSaveToFile(ListView: TListView; const FileName: string);
         procedure ListViewLoadFromFile(ListView: TListView; const FileName: string);

implementation

uses
  Model, System.DateUtils;

procedure ListViewSaveToFile(ListView: TListView; const FileName: string);
  procedure AddValueToLine(var Line: string; const Text: string);
  begin
    Line := Line + Text.Replace(#3, '~e~')        // End of Text used to separate subvalues
                       .Replace(#9, '~t~')        // Tab used to separate values
                       .Replace(#10, '~n~')       // Newline used to separate records
                       .Replace(#13, '~r~')       // Carriage Return not used but encoded for safety
                       + #9;                      // Add separator for this level
  end;

  procedure AddSubValueToLine(var Line: string; const Text: string);
  begin
    Line := Line + Text.Replace(#3, '~e~')
                       .Replace(#9, '~t~')
                       .Replace(#10, '~n~')
                       .Replace(#13, '~r~')
                       + #3;                      // Add separator for this level
  end;

  procedure MoveCompletedLineToList(const Strings: TStringList; var Line: string);
  begin
    Strings.Add(System.Copy(Line, 1, Length(Line)-1));//remove trailing tab
    Line := '';
  end;

var
  Strings: TStringList;
  LatestLine: string;
  i, j: Integer;
  meta: TMetaFields;
begin
  LatestLine := '';

  Strings := TStringList.Create;
  try
    for i := 0 to ListView.Items.Count-1 do begin
      meta := TMetaFields(ListView.Items[i].TagObject);

      // Title and Tag
      AddValueToLine(LatestLine, ListView.Items[i].Text);
      AddValueToLine(LatestLine, ListView.Items[i].Tag.Tostring);

      // Meta Fields
      AddSubValueToLine(LatestLine, '1');     // Meta Fields Version
      AddSubValueToLine(LatestLine, DateToISO8601(meta.Created));
      AddSubValueToLine(LatestLine, DateToISO8601(meta.Updated));
      AddValueToLine(LatestLine, '');         // Terminate meta field subvalues

      // Body
      AddValueToLine(LatestLine, ListView.Items[i].TagString);
      LatestLine := LatestLine;
      MoveCompletedLineToList(Strings, LatestLine);
    end;
    Strings.SaveToFile(FileName, TEncoding.UTF8);
  finally
    Strings.Free;
  end;
end;

procedure ListViewLoadFromFile(ListView: TListView; const FileName: string);
var
  Strings: TStringList;
  i, j: Integer;
  Fields: TStringDynArray;
  SubFields: TStringDynArray;
  Item: TListViewItem;
  meta: TMetaFields;
begin
  Strings := TStringList.Create;
  try
    Strings.LoadFromFile(FileName);
    ListView.Items.Clear;
    for i := 0 to Strings.Count-1 do begin
      Fields := SplitString(Strings[i], #9);
      Item := ListView.Items.Add;
      meta := TMetaFields.Create;
      Item.TagObject := meta;

      // Title and tag
      Item.Text := Fields[0].Replace('~e~', #3)
                                 .Replace('~t~', #9)
                                 .Replace('~n~', #10)
                                 .Replace('~r~', #13);
      Item.Tag := Fields[1].ToInteger;

      // Meta Fields
      SubFields := SplitString(Fields[2], #3);
      case SubFields[0].ToInteger() of        // Meta Fields Version
        1: begin
          meta.Created := ISO8601ToDate(SubFields[1]);
          meta.Updated := ISO8601ToDate(SubFields[2]);
        end;
      end;

      // Body
      Item.TagString := Fields[3].Replace('~e~', #3)
                                 .Replace('~t~', #9)
                                 .Replace('~n~', #10)
                                 .Replace('~r~', #13);
    end;
  finally
    Strings.Free;
  end;
end;

end.

