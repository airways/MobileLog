unit ListViewUtils;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView,
  StrUtils,

  Model;

procedure ListViewSaveToFile(ListView: TListView; const FileName: string);
procedure ListViewLoadFromFile(ListView: TListView; const FileName: string);
procedure RenderListItem(var Item: TListViewItem; meta: TMetaFields;
                         tag: integer; memo: string);
procedure AddHeadingRowIfNeeded(ListView: TListView; meta: TMetaFields; addToTop: boolean);

implementation

uses
  Note, System.DateUtils;

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
      if meta = nil then continue;

      // Title and Tag
      AddValueToLine(LatestLine, meta.TagValue);
      AddValueToLine(LatestLine, ListView.Items[i].Tag.Tostring);

      // Meta Fields
      AddSubValueToLine(LatestLine, '2');     // Meta Fields Version
      AddSubValueToLine(LatestLine, DateToISO8601(meta.Created));
      AddSubValueToLine(LatestLine, DateToISO8601(meta.Updated));
      AddSubValueToLine(LatestLine, DateToISO8601(meta.EntryDateTime));
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

procedure RenderListItem(var Item: TListViewItem; meta: TMetaFields;
                         tag: integer; memo: string);
var
  LocalDateTime: TDateTime;
  time: string;
begin
  LocalDateTime := TTimeZone.Local.ToLocalTime(meta.Created);
  Item.Detail := '';

  // Title
//  Item.Text := frmNote.TagToWord(tag) + StrUtils.IfThen(tag > 0, StrUtils.IfThen(meta.TagValue <> '', ': ', '') + meta.TagValue, '');
  Item.Text := frmNote.TagToWord(tag);
  if (Item.Text <> '') and (meta.TagValue <> '') then
  begin
    Item.Text := Item.Text + ': ';
  end;
  Item.Text := Item.Text + meta.TagValue;
  
  // Tag (type) -- this is a string encoded as an integer, up to 12 characters
  Item.Tag := tag;

  // Body
  Item.TagString := memo.Replace('~e', #3)
                        .Replace('~t~', #9)
                        .Replace('~n~', #10)
                        .Replace('~r~', #13);

  // Item details
  DateTimeToString(time, 'hh:nn am/pm', TTimeZone.Local.ToLocalTime(meta.EntryDateTime));
  Item.Detail := time;
  if Item.TagString <> '' then
  begin
    Item.Detail := Item.Detail + ';';
    Item.Detail := Item.Detail + ' ' + Item.TagString.Substring(0, 100);
    Item.Detail := Item.Detail.Trim;
    Item.Detail := Item.Detail.Replace(#3, ' ')
                              .Replace(#9, ' ')
                              .Replace(#10, ' ')
                              .Replace(#13, ' ');;
  end;

end;

procedure AddHeadingRowIfNeeded(ListView: TListView; meta: TMetaFields; addToTop: boolean);
var
  currDate: string;
  lastDate: string;
  Item: TListViewItem;
begin
  DateTimeToString(currDate, 'yy-mm-dd dddd', TTimeZone.Local.ToLocalTime(meta.Created));

  if addToTop then
  begin
    if (ListView.Items.Count > 0) then
    begin
      if (TMetaFields(ListView.Items[0].TagObject) <> nil) then
      begin
        DateTimeToString(lastDate, 'yy-mm-dd dddd', TTimeZone.Local.ToLocalTime(TMetaFields(ListView.Items[0].TagObject).Created));
      end
      else if (ListView.Items.Count > 1) then
      begin
        DateTimeToString(lastDate, 'yy-mm-dd dddd', TTimeZone.Local.ToLocalTime(TMetaFields(ListView.Items[1].TagObject).Created));
      end;
    end;
  end else begin
    if (ListView.Items.Count > 0) and (TMetaFields(ListView.Items[ListView.Items.Count-1].TagObject) <> nil) then
    begin
      DateTimeToString(lastDate, 'yy-mm-dd dddd', TTimeZone.Local.ToLocalTime(TMetaFields(ListView.Items[ListView.Items.Count-1].TagObject).Created));
    end;
  end;
  
  // Add heading row if we are on a new date
  if currDate <> lastDate then
  begin
    if addToTop then
    begin
      Item := ListView.Items.Insert(0);
    end else begin
      Item := ListView.Items.Add;
    end;
    Item.Text := currDate;
    lastDate := currDate;
    Item.Purpose := TListItemPurpose.Header;
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
      meta := TMetaFields.Create;

      meta.TagValue := Fields[0];
      
      // Meta Fields
      SubFields := SplitString(Fields[2], #3);
      case SubFields[0].ToInteger() of        // Meta Fields Version
        1: begin
          meta.Created := ISO8601ToDate(SubFields[1]);
          meta.Updated := ISO8601ToDate(SubFields[2]);
          meta.EntryDateTime := meta.Created;
          if Length(SubFields) > 2 then
          begin
            meta.TagValue := meta.TagValue + SubFields[3];
          end;
        end;
        2: begin
          meta.Created := ISO8601ToDate(SubFields[1]);
          meta.Updated := ISO8601ToDate(SubFields[2]);
          meta.EntryDateTime := ISO8601ToDate(SubFields[3]);
        end;
      end;
      AddHeadingRowIfNeeded(ListView, meta, false);

      Item := ListView.Items.Add;
      Item.TagObject := meta;

      

      RenderListItem(Item, meta, Fields[1].ToInteger, fields[3]);
    end;
  finally
    Strings.Free;
  end;
end;

end.

