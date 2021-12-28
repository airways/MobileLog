unit Model;

interface

type TLogItem = class
public
  Created: TDateTime;
  Updated: TDateTime;
  EntryDateTime: TDateTime;
  TagName: string;
  TagValue: string;
  Memo: string;
end;

implementation

end.
