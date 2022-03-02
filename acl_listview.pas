unit ACL_ListView;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ComCtrls,
  WSComCtrls, LCLStrConsts, LCLIntf, LCLType, LMessages, WSLCLClasses, LCLProc;

type

  TACL_TreeNode=class;
  TACL_ListView=class;
  TACLCheckedNodeEvent = procedure(Sender:TObject;Item:TACL_TreeNode) of object;

  TACL_TreeNode=class
    FObject:TObject;
    FParent:TACL_TreeNode;
    FList:TList;
    FName:string;
    FChecked:boolean;
    FLevel:integer;
    FOwner:TACL_ListView;
  private
    property Items:TList read FList;
  public
    property Name:string read FName;
    property Checked:boolean read FChecked write FChecked;
    property Data:TObject read FObject write FObject;
    property Owner:TACL_ListView read FOwner;
  public
    constructor Create(AItem:string;AParent:TACL_TreeNode;AObject:TObject;AChecked:boolean);
    destructor Destroy;override;
  public
    procedure AddChild(AItem:string;AObject:TObject;AChecked:boolean);
    procedure DelChild(index:integer);
    procedure Clear;
    procedure CheckAll;
    procedure UnCheckAll;
  end;

  TACL_ListView = class(TListView)
  private
    FACL_TEST:string;
    FTreeRoot:TACL_TreeNode;
    FCurrentTreeNode:TACL_TreeNode;
    FOnNodeChecked:TACLCheckedNodeEvent;
  private
    procedure CurrentInit;
    function CurrentInto(AName:string):boolean;
    function CurrentOut:boolean;
  protected
    procedure NodeChecked(Sender:TObject;Item:TListItem);
  public
    constructor Create(AOwner: TComponent);override;
    destructor Destroy;override;
    procedure AddShellNodeItem(Item:string;AObject:TObject;AChecked:boolean);
    procedure CheckShellNodeItem(Item:string;checked:boolean);
    function  GetShellNodeItem(Item:string):TACL_TreeNode;
    procedure Clear;
    procedure RePaint;override;
    procedure GenerateItems(ANode:TACL_TreeNode);
  published
    property ACL_TEST:string read FACL_TEST write FACL_TEST;//这是一个完全没有用的属性
    property Checkboxes default true;
    property ViewStyle default vsReport;
    property OnNodeChecked:TACLCheckedNodeEvent read FOnNodeChecked write FOnNodeChecked;
  published
    //property OnItemChecked:Integer;

  end;

procedure Register;

implementation

procedure Register;
begin
  {$I acl_listview_icon.lrs}
  RegisterComponents('Apiglio Component',[TACL_ListView]);
end;

{ TACL_TreeNode }

constructor TACL_TreeNode.Create(AItem:string;AParent:TACL_TreeNode;AObject:TObject;AChecked:boolean);
begin
  inherited Create;
  FParent:=AParent;
  FName:=AItem;
  FObject:=AObject;
  FList:=TList.Create;
  FChecked:=AChecked;
  if AParent=nil then
    begin
      FLevel:=0;
      FOwner:=nil;//在ACL_ListView中创建后立刻赋值
    end
  else
    begin
      FLevel:=AParent.FLevel+1;
      FOwner:=AParent.Owner;
    end;
end;

destructor TACL_TreeNode.Destroy;
begin
  while FList.Count<>0 do DelChild(0);
  FList.Free;
  inherited Destroy;
end;

procedure TACL_TreeNode.AddChild(AItem:string;AObject:TObject;AChecked:boolean);
begin
  FList.Add(TACL_TreeNode.Create(Aitem,Self,AObject,AChecked));
end;

procedure TACL_TreeNode.DelChild(index:integer);
begin
  TACL_TreeNode(FList.Items[index]).Free;
  FList.Delete(index);
end;

procedure TACL_TreeNode.Clear;
var index:integer;
begin
  for index:=0 to FList.Count-1 do TACL_TreeNode(FList.Items[index]).Free;
  FList.Clear;
end;

procedure TACL_TreeNode.CheckAll;
var index:integer;
begin
  for index:=0 to FList.Count-1 do TACL_TreeNode(FList.Items[index]).CheckAll;
  FChecked:=true;
  if Assigned(Self.Owner.FOnNodeChecked) then Self.Owner.FOnNodeChecked(Self.Owner,Self);
end;

procedure TACL_TreeNode.UnCheckAll;
var index:integer;
begin
  for index:=0 to FList.Count-1 do TACL_TreeNode(FList.Items[index]).UnCheckAll;
  FChecked:=false;
  if Assigned(Self.Owner.FOnNodeChecked) then Self.Owner.FOnNodeChecked(Self.Owner,Self);
end;

{ TACL_ListView }

procedure TACL_ListView.CurrentInit;
begin
  FCurrentTreeNode:=FTreeRoot;
end;

function TACL_ListView.CurrentInto(AName:string):boolean;
var index:integer;
begin
  result:=false;
  index:=0;
  while index<FCurrentTreeNode.Items.Count do
    begin
      if TACL_TreeNode(FCurrentTreeNode.Items[index]).FName=AName then
        begin
          FCurrentTreeNode:=TACL_TreeNode(FCurrentTreeNode.Items[index]);
          result:=true;
          exit;
        end;
      inc(index);
    end;
end;

function TACL_ListView.CurrentOut:boolean;
begin
  result:=false;
  if FCurrentTreeNode=FTreeRoot then exit;
  FCurrentTreeNode:=FCurrentTreeNode.FParent;
  result:=true;
end;

procedure TACL_ListView.NodeChecked(Sender:TObject;Item:TListItem);
begin
  {
  if Item.Checked then
    TACL_TreeNode(Item.Data).Checked:=true
  else
    TACL_TreeNode(Item.Data).UnCheckAll;
  }
  TACL_TreeNode(Item.Data).Checked:=Item.Checked;

  if Assigned(FOnNodeChecked) then FOnNodeChecked(Self,TACL_TreeNode(Item.Data));
  RePaint;
end;

constructor TACL_ListView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Checkboxes:=true;
  ViewStyle:=vsReport;
  FTreeRoot:=TACL_TreeNode.Create('',nil,nil,false);
  FTreeRoot.FOwner:=Self;
  FCurrentTreeNode:=FTreeRoot;
  AutoSort:=false;
  OnItemChecked:=@Self.NodeChecked;
end;

destructor TACL_ListView.Destroy;
begin
  FTreeRoot.Clear;
  FTreeRoot.Free;
  inherited Destroy;
end;

function SlashOverKiller(str:string):string;
var index:integer;
    last,curr:char;
begin
  result:='';
  last:=#0;
  for index:=1 to length(str) do
    begin
      curr:=str[index];
      if (last='\') and (curr='\') then else result:=result+curr;
      last:=curr;
    end;
end;

procedure TACL_ListView.AddShellNodeItem(Item:string;AObject:TObject;AChecked:boolean);
var stmp:string;
    poss:integer;
begin
  CurrentInit;
  Item:=SlashOverKiller(Item);
  poss:=pos('\',Item);
  while poss>0 do
    begin
      stmp:=Item;
      System.delete(stmp,poss,999);
      System.delete(Item,1,poss);
      if not CurrentInto(stmp) then begin
        FCurrentTreeNode.AddChild(stmp,nil,false);
        CurrentInto(stmp);
      end;
      poss:=pos('\',Item);
    end;
  if CurrentInto(Item) then CurrentOut
  else FCurrentTreeNode.AddChild(Item,AObject,AChecked);
end;
procedure TACL_ListView.CheckShellNodeItem(Item:string;checked:boolean);
var stmp:string;
    poss:integer;
begin
  CurrentInit;
  Item:=SlashOverKiller(Item);
  poss:=pos('\',Item);
  while poss>0 do
    begin
      stmp:=Item;
      System.delete(stmp,poss,999);
      System.delete(Item,1,poss);
      if not CurrentInto(stmp) then exit;
      poss:=pos('\',Item);
    end;
  if CurrentInto(Item) then FCurrentTreeNode.Checked:=checked;
end;
function TACL_ListView.GetShellNodeItem(Item:string):TACL_TreeNode;
var stmp:string;
    poss:integer;
begin
  result:=nil;
  CurrentInit;
  Item:=SlashOverKiller(Item);
  poss:=pos('\',Item);
  while poss>0 do
    begin
      stmp:=Item;
      System.delete(stmp,poss,999);
      System.delete(Item,1,poss);
      if not CurrentInto(stmp) then exit;
      poss:=pos('\',Item);
    end;
  if CurrentInto(Item) then result:=FCurrentTreeNode;
end;
procedure TACL_ListView.Clear;
begin
  FTreeRoot.Clear;
  inherited Clear;
end;

procedure TACL_ListView.RePaint;
begin
  BeginUpdate;
  inherited Clear;
  GenerateItems(FTreeRoot);
  EndUpdate;
  inherited RePaint;
end;

procedure TACL_ListView.GenerateItems(ANode:TACL_TreeNode);
var index:integer;
    tmpNode:TACL_TreeNode;
    nodeMode:byte;
    function LevelSpace(level:integer;kind:byte):string;
    var pi:integer;
    begin
      result:='';
      for pi:=2 to level-1 do result:=result+'　';
      if level>1 then begin
        case kind of
          0:result:=result+'- ';
          1:result:=result+'+ ';
          else result:=result+'> ';
        end;
      end;
    end;

begin
  if ANode.FList.Count=0 then exit;
  for index:=0 to ANode.FList.Count-1 do
    begin
      tmpNode:=TACL_TreeNode(ANode.FList[index]);

      if tmpNode.FList.Count=0 then nodeMode:=2
      else begin
        if tmpNode.FChecked then nodeMode:=0
        else nodeMode:=1;
      end;

      Self.AddItem(LevelSpace(tmpNode.FLevel,nodeMode)+tmpNode.FName,tmpNode);
      Self.Items[Self.Items.Count-1].Checked:=tmpNode.FChecked;
      if tmpNode.FChecked then begin
        //Application.ProcessMessages;
        GenerateItems(TACL_TreeNode(ANode.FList[index]));
      end;
    end;

end;

end.
