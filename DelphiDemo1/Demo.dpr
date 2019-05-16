program Demo;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  DiffUtils in '..\DiffUtils.pas';

var
  lst: TSmartDiffList<integer,string>;
  action, param1, param2: integer;
  pname:string;

procedure show(com: string);
var
  i: integer;
begin
  write(com, ': ');
  for i := 0 to lst.Count - 1 do
    write(lst[i], ' ');
  writeln;
end;

function ReadArr():TArray<integer>;
var
  i,l:integer;
begin
  write('Enter length: ');
  readln(l);
  SetLength(Result,l);
  write('Enter array: ');
  for i:=0 to l-1 do
     read(Result[i]);
end;

begin
  lst := TSmartDiffList<integer,string>.Create;
  lst.Add(90);
  lst.Add(80);
  lst.Add(70);
  lst.Add(60);
  lst.Add(50);
  show('set to');
  repeat
    writeln('1  - add     4 - change      7 - Clear list      10 - remove range ');
    writeln('2  - remove  5 - Go back     8 - Clear history   11 - set range    ');
    writeln('3  - insert  6 - Go forward  9 - insert range    0  - exit         ');
    writeln('-------------------------------------------------------------------');
    writeln('12 - Set History point                   13 - Delete history point ');
    writeln('14 - Go to history point                                           ');
    readln(action);
    case action of
      1:
        begin
          writeln('enter value');
          readln(param1);
          lst.Add(param1);
        end;
      2:
        begin
          writeln('enter index');
          readln(param1);
          lst.Remove(param1);
        end;
      3:
        begin
          writeln('enter index and value');
          readln(param1, param2);
          lst.Insert(param1, param2);
        end;
      4:
        begin
          writeln('enter index and value');
          readln(param1, param2);
          lst[param1] := param2;
        end;
      5:lst.GoBack;
      6:lst.GoForward;
      7:lst.Clear;
      8:lst.ClearHistory;
      9:
        begin
          write('Enter start index: ');
          readln(param1);
          lst.InsertRange(param1,ReadArr);
        end;//insert range;
      10:
        begin
          write('Enter start index: ');
          readln(param1);
          write('Enter length: ');
          readln(param2);
          lst.RemoveRange(param1,param2);
        end;//remove range;
      11:
        begin
          write('Enter start index: ');
          readln(param1);
          lst.SetRange(param1,ReadArr);
        end;//set range;
      12:
        begin
          write('Please enter point name: ');
          readln(pname);
          lst.SetPointHere(pname);
        end;//Set history point
      13:begin
          {write('Please enter point name: ');
          readln(pname);
          lst.SetPointHere(pname);}
        end;//Delete history point
      14:begin
          write('Please enter point name: ');
          readln(pname);
          lst.GoToPoint(pname);
        end;//Go to history point
    end;
    show('current state');
  until (action = 0);

  // writeln(lst[0]);

end.
