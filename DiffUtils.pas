unit DiffUtils;

interface

uses
  System.SysUtils,System.Generics.Defaults,System.Generics.Collections;

type
  TListHistoryItem<T>=record
    index,length:integer;
    Value:T;
    constructor Create(index,length:integer;Value:T);
  end;

  THistoriedStructure<T>=class abstract
    strict private
      type
        PStackItem=^TStackItem;
        TStackItem=record
          Next:PStackItem;
          Val:T;
        end;
      var
        FHistoryBack,FHistoryForward:PStackItem;
        FHistoryCountBack,FHistoryCountForward:Integer;
    strict protected
      function GetHistoryItem(index:integer):T;virtual;
      function GetHistoryCountBack:integer;virtual;
      function GetHistoryCountForward:integer;virtual;
      procedure AddToHistory(Item:T);virtual;
      procedure GoBackWork(var Change:T);virtual;abstract;
      procedure GoForwardWork(var Change:T);virtual;abstract;
    public
      constructor Create();
      procedure GoBack(count:integer=1);
      procedure GoForward(count:integer=1);
      procedure ClearHistory();virtual;
      property HistoryCountBack:integer read GetHistoryCountBack;
      property HistoryCountForward:integer read GetHistoryCountForward;
      property History[index:integer]:T read GetHistoryItem;
  end;

  TDiffList<T>=class(THistoriedStructure<TListHistoryItem<TArray<T>>>)
    strict protected
      arr:TList<T>;
      procedure HistoryWork(var Change:TListHistoryItem<TArray<T>>);inline;
      procedure GoBackWork(var Change:TListHistoryItem<TArray<T>>);override;
      procedure GoForwardWork(var Change:TListHistoryItem<TArray<T>>);override;
      function GetElem(index:integer):T;
      procedure SetElem(index:integer;data:T);
      function GetCount():Integer;
    public
      constructor Create();
      procedure Add(elem:T);
      procedure AddRange(elems:TArray<T>);
      procedure Insert(index:integer;elem:T);
      procedure InsertRange(index:integer;elems:TArray<T>);
      procedure Remove(index:integer);
      procedure RemoveRange(index:integer;length:integer);
      procedure SetRange(index:integer;elems:TArray<T>);
      procedure Clear();virtual;
      procedure ClearWithHistory();virtual;
      property Items[index:integer]:T read GetElem write SetElem;default;
      property Count:integer read GetCount;
  end;

  TSmartDiffList<T,TID>=class(TDiffList<T>)
    strict protected
      type
        THistoryPoint=record
          CountBack:integer;
          ID:TID;
        end;
      var
        HistoryPoints:TList<THistoryPoint>;
        Comp:IEqualityComparer<TID>;
      procedure AddToHistory(item:TListHistoryItem<TArray<T>>);override;
    public
      constructor Create();
      procedure SetPoint(id:TID;Back:integer);
      procedure SetPointHere(id:TID);
      procedure GoToPoint(id:TID);
      //function DeletePoint(id:TID);
      //function DeletePointHere();
      //function GoToBackPoint(count:integer=1);
      //function GoToForwardPoint(count:integer=1);
      //procedure Clear();override;
      //procedure ClearHistory();override;
  end;

implementation

{TListHistoryItem<T>}

constructor TListHistoryItem<T>.Create(index,length:integer;value:T);
begin
Self.index:=index;
Self.length:=length;
Self.Value:=Value;
end;

{THistoriedStructure<T>}

function THistoriedStructure<T>.GetHistoryItem(index:integer):T;
var
  tmp:PStackItem;
begin
  if index<0 then
  begin
    tmp:=FHistoryForward;
    index:=-1-index;
  end
  else
    tmp:=FHistoryBack;
  while index>0 do
  begin
    if tmp=nil then
      raise Exception.Create('Error: HistoryItem not found');
    tmp:=tmp.Next;
    dec(index);
  end;
  if tmp=nil then
    raise Exception.Create('Error: HistoryItem not found');
  Result:=tmp.Val;
end;

function THistoriedStructure<T>.GetHistoryCountBack:integer;
begin
  Result:=FHistoryCountBack;
end;

function THistoriedStructure<T>.GetHistoryCountForward:integer;
begin
  Result:=FHistoryCountForward;
end;

procedure THistoriedStructure<T>.AddToHistory(item:T);
var
  tmp:PStackItem;
begin
  while FHistoryForward<>nil do
  begin
    Finalize(FHistoryForward.Val);
    tmp:=FHistoryForward;
    FHistoryForward:=FHistoryForward.Next;
    FreeMem(tmp);
  end;
  FHistoryCountForward:=0;
  tmp:=GetMemory(SizeOf(TStackItem));
  Initialize(tmp.Val);
  tmp.Next:=FHistoryBack;
  FHistoryBack:=tmp;
  inc(FHistoryCountBack);
end;

constructor THistoriedStructure<T>.Create();
begin
  FHistoryCountBack:=0;
  FHistoryCountForward:=0;
  FHistoryBack:=nil;
  FHistoryForward:=nil;
end;

procedure THistoriedStructure<T>.GoBack(count:integer=1);
var
  tmp:PStackItem;
begin
  if FHistoryCountBack<count then
    raise Exception.Create('Error: HistoryItem not found');
  dec(FHistoryCountBack,count);
  inc(FHistoryCountForward,count);
  for count:=count downto 1 do
  begin
    GoBackWork(FHistoryBack.Val);
    tmp:=FHistoryBack.Next;
    FHistoryBack.Next:=FHistoryForward;
    FHistoryForward:=FHistoryBack;
    FHistoryBack:=tmp;
  end;
end;

procedure THistoriedStructure<T>.GoForward(count:integer=1);
var
  tmp:PStackItem;
begin
  if FHistoryCountForward<count then
    raise Exception.Create('Error: HistoryItem not found');
  dec(FHistoryCountForward,count);
  inc(FHistoryCountBack,count);
  for count:=count downto 1 do
  begin
    GoForwardWork(FHistoryForward.Val);
    tmp:=FHistoryForward.Next;
    FHistoryForward.Next:=FHistoryBack;
    FHistoryBack:=FHistoryForward;
    FHistoryForward:=tmp;
  end;
end;

procedure THistoriedStructure<T>.ClearHistory();
var
  tmp:PStackItem;
begin
  while FHistoryForward<>nil do
  begin
    Finalize(FHistoryForward.Val);
    tmp:=FHistoryForward;
    FHistoryForward:=FHistoryForward.Next;
    FreeMem(tmp);
  end;
  FHistoryCountForward:=0;
  while FHistoryBack<>nil do
  begin
    Finalize(FHistoryBack.Val);
    tmp:=FHistoryBack;
    FHistoryBack:=FHistoryBack.Next;
    FreeMem(tmp);
  end;
  FHistoryCountBack:=0;
end;

{TDiffList<T>}

procedure TDiffList<T>.HistoryWork(var Change:TListHistoryItem<TArray<T>>);
var
  i,Vl,min:integer;
  tmp:T;
begin
  with Change do
  begin
    Vl:=length(Value);
    min:=length;
    if Vl<length then
    begin
      SetLength(Value,length);
      for i:=Vl to length-1 do
        Value[i]:=arr[index+i];
      arr.DeleteRange(index+Vl,length-Vl);
      min:=Vl;
    end
    else if Vl>length then
    begin
      arr.InsertRange(index+length,Copy(Value,length,Vl-length));
      SetLength(Value,length);
    end;
    for i:=0 to min-1 do
      arr[i+index]:=Value[i];
    length:=Vl;
  end;
end;

procedure TDiffList<T>.GoBackWork(var Change:TListHistoryItem<TArray<T>>);
begin
  HistoryWork(Change);
end;

procedure TDiffList<T>.GoForwardWork(var Change:TListHistoryItem<TArray<T>>);
begin
  HistoryWork(Change);
end;

function TDiffList<T>.GetElem(index:integer):T;
begin
  Result:=arr[index];
end;

procedure TDiffList<T>.SetElem(index:integer;data:T);
begin
  AddToHistory(TListHistoryItem<TArray<T>>.Create(index,Change,[data],[arr[index]]));
  arr[index]:=data;
end;

function TDiffList<T>.GetCount():integer;
begin
  Result:=arr.Count;
end;

constructor TDiffList<T>.Create();
begin
  inherited;
  arr:=Tlist<T>.Create();
end;

procedure TDiffList<T>.Add(elem:T);
begin
  AddToHistory(TListHistoryItem<TArray<T>>.Create(arr.Count,TAction.Insert,[elem],[]));
  arr.Add(elem);
end;

procedure TDiffList<T>.AddRange(elems:TArray<T>);
begin
  AddToHistory(TListHistoryItem<TArray<T>>.Create(arr.Count,TAction.Insert,elems,[]));
  arr.InsertRange(arr.Count,elems);
end;

procedure TDiffList<T>.Insert(index:integer;elem:T);
begin
  AddToHistory(TListHistoryItem<TArray<T>>.Create(index,TAction.Insert,[elem],[]));
  arr.Insert(index,elem);
end;

procedure TDiffList<T>.InsertRange(index:integer;elems:TArray<T>);
begin
  AddToHistory(TListHistoryItem<TArray<T>>.Create(index,TAction.Insert,elems,[]));
  arr.InsertRange(index,elems);
end;

procedure TDiffList<T>.Remove(index:integer);
begin
  AddToHistory(TListHistoryItem<TArray<T>>.Create(index,TAction.Remove,[],[arr[index]]));
  arr.Delete(index);
end;

procedure TDiffList<T>.RemoveRange(index:integer;length:integer);
begin
  AddToHistory(TListHistoryItem<TArray<T>>.Create(index,TAction.Remove,[],Copy(arr.List,index,length)));
  arr.DeleteRange(index,length);
end;

procedure TDiffList<T>.SetRange(index:integer;elems:TArray<T>);
var
  i:integer;
begin
  AddToHistory(TListHistoryItem<TArray<T>>.Create(index,TAction.Change,elems,Copy(arr.List,index,length(elems))));
  for i:=0 to length(elems)-1 do
    arr[i+index]:=elems[i];
end;

procedure TDiffList<T>.Clear();
begin
  AddToHistory(TListHistoryItem<TArray<T>>.Create(0,arr.Count,[],arr.ToArray));
  arr.Clear;
end;

procedure TDiffList<T>.ClearWithHistory();
begin
  Clear;
  ClearHistory;
end;

{TSmartDiffList<T,TID>}

procedure TSmartDiffList<T,TID>.AddToHistory(item:TListHistoryItem<TArray<T>>);
var
  tmp:THistoryPoint;
  sum,i:integer;
begin
  if HistoryPos=0 then
  begin
    if HistoryPoints.Count>0 then
    begin
      tmp:=HistoryPoints[0];
      inc(tmp.CountBack);
      HistoryPoints[0]:=tmp;
    end
  end
  else
  begin
    sum:=-(HistoryPos-1);
    for i:=0 to HistoryPoints.Count-1 do
      if HistoryPoints[i].CountBack+sum<0 then
        inc(sum,HistoryPoints[i].CountBack)
      else
      begin
        HistoryPoints.DeleteRange(0,i);
        tmp.ID:=HistoryPoints[0].ID;
        tmp.CountBack:=sum;
        HistoryPoints[0]:=tmp;
        inherited;
        exit;
      end;
    HistoryPoints.Clear;
  end;
  inherited;
end;

constructor TSmartDiffList<T,TID>.Create();
begin
  inherited Create;
  HistoryPoints:=TList<THistoryPoint>.Create;
  Comp:=TEqualityComparer<TID>.Default;
end;

procedure TSmartDiffList<T,TID>.SetPoint(id:TID;Back:integer);
var
  HistPoint:THistoryPoint;
  i,sum:integer;
begin
  HistPoint.ID:=id;
  sum:=0;
  for i:=0 to HistoryPoints.Count-1 do
  begin
    inc(sum,HistoryPoints[i].CountBack);
    HistoryPos:=HistoryPos+Back;
    if sum>HistoryPos then
    begin
      HistPoint.CountBack:=HistoryPos-sum+HistoryPoints[i].CountBack;
      HistoryPoints.Insert(i,HistPoint);
      HistPoint:=HistoryPoints[i+1];
      HistPoint.CountBack:=sum-HistoryPos;
      HistoryPoints[i+1]:=HistPoint;
      exit();
    end;
  end;
  HistPoint.CountBack:=HistoryPos-sum;
  HistoryPoints.Add(HistPoint);
end;

procedure TSmartDiffList<T,TID>.SetPointHere(id:TID);
var
  HistPoint:THistoryPoint;
  i,sum:integer;
begin
  HistPoint.ID:=id;
  sum:=0;
  for i:=0 to HistoryPoints.Count-1 do
  begin
    inc(sum,HistoryPoints[i].CountBack);
    if sum>HistoryPos then
    begin
      HistPoint.CountBack:=HistoryPos-sum+HistoryPoints[i].CountBack;
      HistoryPoints.Insert(i,HistPoint);
      HistPoint:=HistoryPoints[i+1];
      HistPoint.CountBack:=sum-HistoryPos;
      HistoryPoints[i+1]:=HistPoint;
      exit();
    end;
  end;
  HistPoint.CountBack:=HistoryPos-sum;
  HistoryPoints.Add(HistPoint);
end;

procedure TSmartDiffList<T,TID>.GoToPoint(id:TID);
var
  HistPoint:THistoryPoint;
  sum:integer;
begin
  sum:=0;
  for HistPoint in HistoryPoints do
    if Comp.Equals(HistPoint.ID,id) then
    begin
      // ‏חאול GoBack ט GoForward
      while sum<HistoryPos do
        GoForward;
      while sum>HistoryPos do
        GoBack;
    end
    else
      inc(sum,HistPoint.CountBack);
end;

end.
