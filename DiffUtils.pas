unit DiffUtils;

interface

uses
  System.SysUtils,System.Generics.Defaults,System.Generics.Collections;

type
  TDiffList<T>=class
    private
      type
        TArr=array of T;
        TAction=(Remove,Change,Insert);
        THistoryItem=record
          index:integer;
          action:TAction;
          value,OldValue:TArr;
        end;
      var
        arr:TList<T>;
        FHistory:TList<THistoryItem>;
        HistoryPos:integer;
      procedure AddToHistory(Pindex:integer;Paction:TAction;Pvalue,POldValue:Tarr);virtual;
      function GetHistoryItem(index:integer):THistoryItem;
      function GetHistoryCountBack:integer;
      function GetHistoryCountForward:integer;
      function GetElem(index:integer):T;
      procedure SetElem(index:integer;data:T);
      function GetCount():Integer;
    public
      constructor Create();
      procedure Add(elem:T);
      procedure AddRange(elems:TArr);
      procedure Insert(index:integer;elem:T);
      procedure InsertRange(index:integer;elems:TArr);
      procedure Remove(index:integer);
      procedure RemoveRange(index:integer;length:integer);
      procedure SetRange(index:integer;elems:TArr);
      procedure GoBack();//count:integer=1
      procedure GoForward();//count:integer=1
      procedure Clear();virtual;
      procedure ClearHistory();virtual;
      property HistoryCountBack:integer read GetHistoryCountBack;
      property HistoryCountForward:integer read GetHistoryCountForward;
      property History[index:integer]:THistoryItem read GetHistoryItem;
      property Items[index:integer]:T read GetElem write SetElem;default;
      property Count:integer read GetCount;
  end;

  TSmartDiffList<T,TID>=class(TDiffList<T>)
    private
      type
        THistoryPoint=record   // только контрольные точки а не изменения массива
          CountBack:integer; //from the next one
          ID:TID;
        end;
      var
        HistoryPoints:TList<THistoryPoint>;
        Comp:IComparer<TID>;
      procedure AddToHistory(Pindex:integer;Paction:TAction;Pvalue,POldValue:Tarr);override;
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

{TSmartDiffList<T,TID>}

procedure TSmartDiffList<T,TID>.AddToHistory(Pindex:integer;Paction:TAction;Pvalue,POldValue:Tarr);
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
        inherited AddToHistory;
        exit;
      end;
    HistoryPoints.Clear;
  end;
  inherited AddToHistory;
end;

constructor TSmartDiffList<T,TID>.Create();
begin
  inherited Create;
  HistoryPoints:=TList<THistoryPoint>.Create;
  Comp:=TComparer<TID>.Default;
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
    if Comp.Compare(HistPoint.ID,id)=0 then
    begin
      // юзаем GoBack и GoForward
      while sum<HistoryPos do
        GoForward;
      while sum>HistoryPos do
        GoBack;
    end
    else
      inc(sum,HistPoint.CountBack);
end;

{TDiffList<T>}

function TDiffList<T>.GetElem(index:integer):T;
begin
  Result:=arr[index];
end;

procedure TDiffList<T>.SetElem(index:integer;data:T);
begin
  AddToHistory(index,Change,[data],[arr[index]]);
  arr[index]:=data;
end;

function TDiffList<T>.GetCount():integer;
begin
  Result:=arr.Count;
end;

procedure TDiffList<T>.AddToHistory(Pindex:integer;Paction:TAction;Pvalue,POldValue:Tarr);
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
  if HistoryPos=0 then
    FHistory.Insert(0,item)
  else
  begin
    if HistoryPos<>1 then
      FHistory.DeleteRange(0,HistoryPos-1);
    FHistory[0]:=item;
    HistoryPos:=0;
  end;
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

constructor TDiffList<T>.Create();
begin
  arr:=Tlist<T>.Create();
  FHistory:=TList<THistoryItem>.Create();
  HistoryPos:=0;
end;

procedure TDiffList<T>.Add(elem:T);
begin
  AddToHistory(arr.Count,TAction.Insert,[elem],[]);
  arr.Add(elem);
end;

procedure TDiffList<T>.AddRange(elems:TArr);
begin
  AddToHistory(arr.Count,TAction.Insert,elems,[]);
  arr.InsertRange(arr.Count,elems);
end;

procedure TDiffList<T>.Insert(index:integer;elem:T);
begin
  AddToHistory(index,TAction.Insert,[elem],[]);
  arr.Insert(index,elem);
end;

procedure TDiffList<T>.InsertRange(index:integer;elems:TArr);
begin
  AddToHistory(index,TAction.Insert,elems,[]);
  arr.InsertRange(index,elems);
end;

procedure TDiffList<T>.SetRange(index:integer;elems:TArr);
var
  i:integer;
begin
  AddToHistory(index,TAction.Change,elems,Copy(arr.List,index,length(elems)));
  for i:=0 to length(elems)-1 do
    arr[i+index]:=elems[i];
end;

procedure TDiffList<T>.Remove(index:integer);
begin
  AddToHistory(index,TAction.Remove,[],[arr[index]]);
  arr.Delete(index);
end;

procedure TDiffList<T>.RemoveRange(index:integer;length:integer);
begin
  AddToHistory(index,TAction.Remove,[],Copy(arr.List,index,length));
  arr.DeleteRange(index,length);
end;

procedure TDiffList<T>.GoBack();
var
  i:integer;
begin
  if HistoryPos<FHistory.Count then
  begin
    with FHistory[HistoryPos] do
      case action of
        TAction.Insert:arr.DeleteRange(index,length(Value));
        TAction.Remove:arr.InsertRange(index,Oldvalue);
        TAction.Change:
        for i:=0 to length(Value)-1 do
          arr[i+index]:=OldValue[i];
      end;
    inc(HistoryPos);
  end;
end;

procedure TDiffList<T>.GoForward();
var
  i:integer;
begin
  if HistoryPos>0 then
  begin
    dec(HistoryPos);
    with FHistory[HistoryPos] do
      case action of
      TAction.Insert:arr.InsertRange(index,value);
      TAction.Remove:arr.DeleteRange(index,length(OldValue));
      TAction.Change:
        for i:=0 to length(Value)-1 do
          arr[i+index]:=Value[i];
      end;
  end;
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

end.
