{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit ACL_ListViewEx;

{$warn 5023 off : no warning about unused units}
interface

uses
  ACL_ListView, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('ACL_ListView', @ACL_ListView.Register);
end;

initialization
  RegisterPackage('ACL_ListViewEx', @Register);
end.
