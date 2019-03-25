program Project3;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  DiffUtils in 'DiffUtils.pas';

var
  lst: TDiffList<integer>;
  action, param1, param2: integer;

procedure show(com: string);
var
  i: integer;
begin
  write(com, ': ');
  for i := 0 to lst.Count - 1 do
    write(lst[i], ' ');
  writeln;
end;

begin
  lst := TDiffList<integer>.Create;
  lst.AddElem(90);
  lst.AddElem(80);
  lst.AddElem(70);
  lst.AddElem(60);
  lst.AddElem(50);
  show('set to');
  repeat
    writeln('1 - add     4 - change      7 - Clear list');
    writeln('2 - remove  5 - Go back     8 - Clear history');
    writeln('3 - insert  6 - Go forward  0 - exit');
    readln(action);
    case action of
      1:
        begin
          writeln('enter value');
          readln(param1);
          lst.AddElem(param1);
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
    end;
    show('current state');
  until (action = 0);

  // writeln(lst[0]);

end.
