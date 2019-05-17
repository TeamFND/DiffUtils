//****************************************************
//*Copyright (c) 2019 Artem Gavrilov.                *
//*Website: https://teamfnd.ru			                 *
//*License: MIT 				                             *
//*Donate: https://money.yandex.ru/to/410014959153552*
//****************************************************
unit DiffUtils;

interface

uses
  System.SysUtils,System.Rtti,System.Generics.Defaults,System.Generics.Collections;

type
  TListHistoryItem<T>=record
    index,len:integer;
    Value:T;
    constructor Create(index,len:integer;const Value:T);
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
      procedure AddToHistory(const Item:T);virtual;
      procedure GoBackWork(var Change:T);virtual;abstract;
      procedure GoForwardWork(var Change:T);virtual;abstract;
    public
      constructor Create();
      procedure GoBack(count:integer=1);virtual;
      procedure GoForward(count:integer=1);virtual;
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
      procedure Add(const elem:T);
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

  TSmarter<TID>=record
    type
      PHistoryPoint=^THistoryPoint;
      THistoryPoint=record
        Next:PHistoryPoint;
        CountBack:integer;
        ID:TID;
      end;
    var
      FHistoryPointsBack,FHistoryPointsForward:PHistoryPoint;
      Comp:IEqualityComparer<TID>;
    procedure Init();
    procedure OnAddToHistory();
    procedure OnGoBack(count:integer);
    procedure OnGoForward(count:integer);
    procedure SetPoint(id:TID;Back:integer);
    procedure SetPointHere(id:TID);
    function GoToPoint(id:TID):integer;
    //function DeletePoint(id:TID);
    //function DeletePointHere();
    //function GoToBackPoint(count:integer=1);
    //function GoToForwardPoint(count:integer=1);
    //procedure OnClear();
    //procedure OnClearHistory();
  end;

  TSmartDiffList<T,TID>=class(TDiffList<T>)
    strict protected
      Smarter:TSmarter<TID>;
      procedure AddToHistory(const item:TListHistoryItem<TArray<T>>);override;
    public
      constructor Create();
      procedure GoBack(count:integer=1);override;
      procedure GoForward(count:integer=1);override;
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

constructor TListHistoryItem<T>.Create(index,len:integer;const value:T);
begin
Self.index:=index;
Self.len:=len;
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
      raise EArgumentOutOfRangeException.Create('Error: HistoryItem not found');
    tmp:=tmp.Next;
    dec(index);
  end;
  if tmp=nil then
    raise EArgumentOutOfRangeException.Create('Error: HistoryItem not found');
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

procedure THistoriedStructure<T>.AddToHistory(const item:T);
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
    raise EArgumentOutOfRangeException.Create('Error: HistoryItem not found');
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
    raise EArgumentOutOfRangeException.Create('Error: HistoryItem not found');
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
    min:=len;
    if Vl<len then
    begin
      SetLength(Value,len);
      for i:=Vl to len-1 do
        Value[i]:=arr[index+i];
      arr.DeleteRange(index+Vl,len-Vl);
      min:=Vl;
    end
    else if Vl>len then
    begin
      arr.InsertRange(index+len,Copy(Value,len,Vl-len));
      SetLength(Value,len);
    end;
    for i:=0 to min-1 do
      arr[i+index]:=Value[i];
    len:=Vl;
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
  AddToHistory(TListHistoryItem<TArray<T>>.Create(index,1,[arr[index]]));
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

procedure TDiffList<T>.Add(const elem:T);
begin
  AddToHistory(TListHistoryItem<TArray<T>>.Create(arr.Count,1,[]));
  arr.Add(elem);
end;

procedure TDiffList<T>.AddRange(elems:TArray<T>);
begin
  AddToHistory(TListHistoryItem<TArray<T>>.Create(arr.Count,length(elems),[]));
  arr.InsertRange(arr.Count,elems);
end;

procedure TDiffList<T>.Insert(index:integer;elem:T);
begin
  AddToHistory(TListHistoryItem<TArray<T>>.Create(index,1,[]));
  arr.Insert(index,elem);
end;

procedure TDiffList<T>.InsertRange(index:integer;elems:TArray<T>);
begin
  AddToHistory(TListHistoryItem<TArray<T>>.Create(index,length(elems),[]));
  arr.InsertRange(index,elems);
end;

procedure TDiffList<T>.Remove(index:integer);
begin
  AddToHistory(TListHistoryItem<TArray<T>>.Create(index,0,[arr[index]]));
  arr.Delete(index);
end;

procedure TDiffList<T>.RemoveRange(index:integer;length:integer);
begin
  AddToHistory(TListHistoryItem<TArray<T>>.Create(index,0,Copy(arr.List,index,length)));
  arr.DeleteRange(index,length);
end;

procedure TDiffList<T>.SetRange(index:integer;elems:TArray<T>);
var
  i:integer;
begin
  AddToHistory(TListHistoryItem<TArray<T>>.Create(index,length(elems),Copy(arr.List,index,length(elems))));
  for i:=0 to length(elems)-1 do
    arr[i+index]:=elems[i];
end;

procedure TDiffList<T>.Clear();
begin
  AddToHistory(TListHistoryItem<TArray<T>>.Create(0,0,arr.ToArray));
  arr.Clear;
end;

procedure TDiffList<T>.ClearWithHistory();
begin
  Clear;
  ClearHistory;
end;

{TSmarter<TID>}

procedure TSmarter<TID>.Init();
begin
  FHistoryPointsBack:=nil;
  FHistoryPointsForward:=nil;
  Comp:=TEqualityComparer<TID>.Default;
end;

procedure TSmarter<TID>.OnAddToHistory();
var
  tmp:PHistoryPoint;
  sum,i:integer;
begin
  while FHistoryPointsForward<>nil do
  begin
    tmp:=FHistoryPointsForward;
    FHistoryPointsForward:=FHistoryPointsForward.Next;
    Finalize(tmp.ID);
    FreeMem(tmp);
  end;
end;

procedure TSmarter<TID>.OnGoBack(count:integer);
var
  tmp:PHistoryPoint;
begin
  while(FHistoryPointsBack<>nil)and(count>0)do
    if FHistoryPointsBack.CountBack<count then
    begin
      tmp:=FHistoryPointsBack;
      FHistoryPointsBack:=tmp.Next;
      tmp.Next:=FHistoryPointsForward;
      FHistoryPointsForward:=tmp;
      dec(count,tmp.CountBack);
      tmp.CountBack:=count-1;
    end
    else
    begin
      dec(FHistoryPointsBack.CountBack,count);
      break;
    end;
end;

procedure TSmarter<TID>.OnGoForward(count:integer);
var
  tmp:PHistoryPoint;
begin
  while(FHistoryPointsForward<>nil)and(count>0)do
    if FHistoryPointsForward.CountBack<count then
    begin
      tmp:=FHistoryPointsForward;
      FHistoryPointsForward:=tmp.Next;
      tmp.Next:=FHistoryPointsBack;
      FHistoryPointsBack:=tmp;
      dec(count,tmp.CountBack);
      tmp.CountBack:=count-1;
    end
    else
    begin
      dec(FHistoryPointsForward.CountBack,count);
      break;
    end;
end;

procedure TSmarter<TID>.SetPoint(id:TID;Back:integer);
begin

end;

procedure TSmarter<TID>.SetPointHere(id:TID);
begin

end;

function TSmarter<TID>.GoToPoint(id:TID);
begin

end;

{TSmartDiffList<T,TID>}

procedure TSmartDiffList<T,TID>.AddToHistory(const item:TListHistoryItem<TArray<T>>);
begin
  Smarter.OnAddToHistory();
  inherited;
end;

constructor TSmartDiffList<T,TID>.Create();
begin
  inherited Create;
  Smarter.Init;
end;

procedure TSmartDiffList<T,TID>.GoBack(count:integer=1);
begin
  Smarter.OnGoBack(count);
  inherited;
end;

procedure TSmartDiffList<T,TID>.GoForward(count:integer=1);
begin
  Smarter.OnGoForward(count);
  inherited;
end;

procedure TSmartDiffList<T,TID>.SetPoint(id:TID;Back:integer);
var
  tmp:^PHistoryPoint;
  t:PHistoryPoint;
begin
  tmp:=@FHistoryPointsForward;
  while(tmp^<>nil)and not Comp.Equals(tmp^.ID,id)do
    tmp:=@tmp^.Next;
  if not((tmp<>nil)and(Comp.Equals(tmp^.ID,id)))then
  begin
    tmp:=@FHistoryPointsBack;
    while(tmp^<>nil)and not Comp.Equals(tmp^.ID,id)do
      tmp:=@tmp^.Next;
  end;
  if(tmp<>nil)and(Comp.Equals(tmp^.ID,id))then
  begin
    t:=tmp^;
    tmp^:=t.Next;
  end
  else
  begin
    GetMem(t,SizeOf(t));
    t.ID:=id;
  end;
  if Back>=0 then
  begin
    tmp:=@FHistoryPointsBack;
    while(Back>0)and(tmp^<>nil)do
    begin
      dec(Back,tmp^.CountBack);
      tmp:=@tmp^.Next;
    end;
    t.Next:=tmp^;
    tmp^:=t;
  end
  else
  begin
    tmp:=@FHistoryPointsForward;
    while(Back<-1)and(tmp^<>nil)do
    begin
      inc(Back,tmp^.CountBack);
      tmp:=@tmp^.Next;
    end;
    t.Next:=tmp^;
    tmp^:=t;
  end;
end;

procedure TSmartDiffList<T,TID>.SetPointHere(id:TID);
begin
  SetPoint(id,0);
end;

procedure TSmartDiffList<T,TID>.GoToPoint(id:TID);
var
  tmp:PHistoryPoint;
  sum:integer;
begin
  sum:=0;
  tmp:=FHistoryPointsForward;
  while(tmp<>nil)and not Comp.Equals(tmp.ID,id)do
    tmp:=tmp.Next;
  if(tmp<>nil)and(Comp.Equals(tmp.ID,id))then
  begin
    while(FHistoryPointsForward<>nil)and not Comp.Equals(FHistoryPointsForward.ID,id)do
    begin
      inc(sum,FHistoryPointsForward.CountBack);
      //
      FHistoryPointsForward:=FHistoryPointsForward.Next;
    end;
    GoForward(sum+FHistoryPointsForward.CountBack);
  end
  else
  begin
    tmp:=FHistoryPointsBack;
    while(tmp<>nil)and not Comp.Equals(tmp.ID,id)do
      tmp:=tmp.Next;
  end;
end;

end.
