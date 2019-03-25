unit DiffUtils;

interface

uses
  Generics.Collections;

type
  TDiffList<T>=class
    private
      type
        TAction=(Remove,Change,Insert);
        THistoryItem=record
          index:integer;
          action:TAction;
          value,OldValue:T;
        end;
      var
        arr:TList<T>;
        FHistory:TList<THistoryItem>;
        HistoryPos:integer;
      function GetElem(index:integer):T;
      procedure SetElem(index:integer;data:T);
      function GetCount():Integer;
      procedure AddToHistory(Pindex:integer;Paction:TAction;Pvalue:T;POldValue:T);
      function GetHistoryItem(index:integer):THistoryItem;
      function GetHistoryCountBack:integer;
      function GetHistoryCountForward:integer;
    public
      procedure AddElem(elem:T);overload;
      procedure Insert(i:integer;elem:T);overload;
      procedure GoBack();
      property Count:integer read GetCount;
      procedure GoForward();
      constructor Create();
      procedure Remove(index:integer);
      procedure Clear();
      procedure ClearHistory();
      property HistoryCountBack:integer read GetHistoryCountBack;
      property HistoryCountForward:integer read GetHistoryCountForward;
      property History[index:integer]:THistoryItem read GetHistoryItem;
      property Items[index:integer]:T read GetElem write SetElem;default;
  end;

implementation

function TDiffList<T>.GetElem(index:integer):T;
begin
  Result:=arr[index];
end;

procedure TDiffList<T>.SetElem(index:integer;data:T);
begin
  AddToHistory(index,Change,data,arr[index]);
  arr[index]:=data;
end;

procedure TDiffList<T>.AddElem(elem:T);
begin
  AddToHistory(arr.Count,TAction.Insert,elem,elem);
  arr.Add(elem);
end;

procedure TDiffList<T>.Insert(i:integer;elem:T);
begin
  AddToHistory(i,TAction.Insert,elem,elem);
  arr.Insert(i,elem);
end;

procedure TDiffList<T>.AddToHistory(Pindex:integer;Paction:TAction;Pvalue,POldValue:T);
var
  item:THistoryItem;
begin
  with item do
  begin
    index:=Pindex;
    action:=Paction;
    value:=Pvalue;
    OldValue:=POldValue;
  end;
  FHistory.Insert(0,item);
end;

procedure TDiffList<T>.GoBack();
begin
  if HistoryPos<FHistory.Count then
  begin
    with FHistory[HistoryPos] do
    begin
      case action of
        TAction.Insert:arr.Delete(index);
        TAction.Remove:arr.Insert(index,Oldvalue);
        TAction.Change:arr[index]:=OldValue;
      end;
    end;
    inc(HistoryPos);
  end;
end;

procedure TDiffList<T>.GoForward();
begin
  if HistoryPos>0 then
  begin
    dec(HistoryPos);
    with FHistory[HistoryPos] do
    begin
      case action of
       TAction.Insert:arr.Insert(index,value);
       TAction.Remove:arr.Delete(index);
       TAction.Change:arr[index]:=value;
      end;
    end;
  end;
end;

constructor TDiffList<T>.Create();
begin
  arr:=Tlist<T>.Create();
  FHistory:=TList<THistoryItem>.Create();
  HistoryPos:=0;
end;

function TDiffList<T>.GetCount():integer;
begin
  Result:=arr.Count;
end;

procedure TDiffList<T>.Remove(index:integer);
begin
  AddToHistory(arr.Count,TAction.Remove,arr[index],arr[index]);
  arr.Delete(index);
end;

procedure TDiffList<T>.Clear();
begin
  FHistory.Clear;
  arr.Clear;
end;

procedure TDiffList<T>.ClearHistory();
begin
  FHistory.Clear;
end;

function TDiffList<T>.GetHistoryItem(index:integer):THistoryItem;
begin
   Result:=FHistory[index+HistoryPos];
end;

function TDiffList<T>.GetHistoryCountBack:integer;
begin
  Result:=FHistory.Count-HistoryPos;
end;

function TDiffList<T>.GetHistoryCountForward:integer;
begin
  Result:=HistoryPos;
end;

end.
