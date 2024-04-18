unit Form.Helper;

interface

uses
  Vcl.Forms,
  System.SysUtils,
  System.Classes,
  Vcl.Controls,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  System.JSON,
  IniFiles;

type
  TFileType = (ftText, ftINI, ftJSON, ftYML);

  TFormHelper = class helper for TForm
  private
    procedure SaveToTextFile(const FileName: string);
    procedure SaveToJSONFile(const FileName: string);
    procedure SaveToINIFile(const FileName: string);
    procedure SaveComponentToJSON(AControl: TWinControl; JSONObj: TJSONObject);
    function GetJSONArraySelectedItems(AListBox: TListBox): TJSONArray;
    function GetSelectedItems(AListBox: TListBox): TStrings;
    function GetJSONString(AText: string): string;
  public
    procedure SaveToFile(FileName: string; FileType: TFileType = ftJSON);
  end;

implementation

{ TFormHelper }

procedure TFormHelper.SaveToFile(FileName: string; FileType: TFileType = ftJSON);
begin
  FileName := ExpandFileName(FileName);

  case FileType of
    ftJSON: SaveToJSONFile(FileName);
    ftINI: SaveToINIFile(FileName);
    ftText: SaveToTextFile(FileName);
  else
    raise Exception.Create('Tipo de arquivo não suportado');
  end;
end;

procedure TFormHelper.SaveToTextFile(const FileName: string);
var
  i: Integer;
  Field: TComponent;
  FileStream: TFileStream;
  Writer: TStreamWriter;
begin
  FileStream := TFileStream.Create(FileName, fmCreate);
  try
    Writer := TStreamWriter.Create(FileStream);
    try
      for i := 0 to ComponentCount - 1 do
      begin
        Field := Components[i];

        if Field is TEdit then
          Writer.WriteLine(Field.Name + ' = ' + TEdit(Field).Text)
        else if Field is TMemo then
          Writer.WriteLine(Field.Name + ' = ' + TMemo(Field).Lines.Text)
        else if Field is TCheckBox then
          Writer.WriteLine(Field.Name + ' = ' + BoolToStr(TCheckBox(Field).Checked, True))
        else if Field is TRadioButton then
          Writer.WriteLine(Field.Name + ' = ' + BoolToStr(TRadioButton(Field).Checked, True))
        else if Field is TComboBox then
          Writer.WriteLine(Field.Name + ' = ' + TComboBox(Field).Text)
        else if Field is TRadioGroup and (TRadioGroup(Field).ItemIndex > -1) then
          Writer.WriteLine(Field.Name + ' = ' + TRadioGroup(Field).Items[TRadioGroup(Field).ItemIndex])
        else if Field is TListBox then
          Writer.WriteLine(Field.Name + ' = ' + GetSelectedItems(TListBox(Field)).CommaText);
      end;
    finally
      Writer.Free;
    end;
  finally
    FileStream.Free;
  end;
end;

function TFormHelper.GetSelectedItems(AListBox: TListBox): TStrings;
var
  J: Integer;
begin
  Result := TStringList.Create;
  for j := 0 to AListBox.Items.Count - 1 do
    if AListBox.Selected[j] then
      Result.Add(AListBox.Items[j]);
end;

procedure TFormHelper.SaveToJSONFile(const FileName: string);
var
  JSONValue: TJSONObject;
  JSONString: TStringList;
begin
  JSONValue := TJSONObject.Create;
  try
    SaveComponentToJSON(Self, JSONValue);

    JSONString := TStringList.Create;
    try
      JSONString.Text := JSONValue.ToString;
      JSONString.SaveToFile(FileName);
    finally
      JSONString.Free;
    end;
  finally
    JSONValue.Free;
  end;
end;

procedure TFormHelper.SaveComponentToJSON(AControl: TWinControl; JSONObj: TJSONObject);
var
  i: Integer;
  ChildJSONObj: TJSONObject;
  ChildControl: TControl;
begin
  for i := 0 to AControl.ControlCount - 1 do
  begin
    ChildControl := AControl.Controls[i];

    if ChildControl is TEdit then
      JSONObj.AddPair(ChildControl.Name, TEdit(ChildControl).Text)
    else if ChildControl is TMemo then
      JSONObj.AddPair(ChildControl.Name, GetJSONString(TMemo(ChildControl).Text))
    else if ChildControl is TCheckBox then
      JSONObj.AddPair(ChildControl.Name, BoolToStr(TCheckBox(ChildControl).Checked, True))
    else if ChildControl is TRadioButton then
      JSONObj.AddPair(ChildControl.Name, BoolToStr(TRadioButton(ChildControl).Checked, True))
    else if ChildControl is TComboBox then
      JSONObj.AddPair(ChildControl.Name, TComboBox(ChildControl).Text)
    else if ChildControl is TRadioGroup and (TRadioGroup(ChildControl).ItemIndex > -1) then
      JSONObj.AddPair(ChildControl.Name, TRadioGroup(ChildControl).Items[TRadioGroup(ChildControl).ItemIndex])
    else if ChildControl is TListBox then
      JSONObj.AddPair(ChildControl.Name, GetJSONArraySelectedItems(TListBox(ChildControl)));

    if (ChildControl is TWinControl) and (TWinControl(ChildControl).ControlCount > 0) then
    begin
      ChildJSONObj := TJSONObject.Create;
      SaveComponentToJSON(TWinControl(ChildControl), ChildJSONObj);
      if ChildJSONObj.Count > 0 then
        JSONObj.AddPair(ChildControl.Name, ChildJSONObj)
      else
        ChildJSONObj.Free;
    end;
  end;
end;

function TFormHelper.GetJSONString(AText: string): string;
begin
  Result := StringReplace(AText, sLineBreak, '\n', [rfReplaceAll]);
end;

function TFormHelper.GetJSONArraySelectedItems(AListBox: TListBox): TJSONArray;
var
  J: Integer;
begin
  Result := TJSONArray.Create;
  for j := 0 to AListBox.Items.Count - 1 do
    if AListBox.Selected[j] then
      Result.Add(AListBox.Items[j]);
end;

procedure TFormHelper.SaveToINIFile(const FileName: string);
var
  IniFile: TIniFile;
  i: Integer;
  Control: TControl;
begin
  IniFile := TIniFile.Create(FileName);
  try
    for i := 0 to Self.ComponentCount - 1 do
    begin
      Control := TWinControl(Self.Components[i]);

      if Control is TEdit then
        IniFile.WriteString(Control.Parent.Name, Control.Name, TEdit(Control).Text)
      else if Control is TMemo then
        IniFile.WriteString(Control.Parent.Name, Control.Name, TMemo(Control).Lines.Text)
      else if Control is TCheckBox then
        IniFile.WriteBool(Control.Parent.Name, Control.Name, TCheckBox(Control).Checked)
      else if Control is TListBox then
        IniFile.WriteString(Control.Parent.Name, Control.Name, TListBox(Control).Items.CommaText)
      else if Control is TComboBox then
        IniFile.WriteString(Control.Parent.Name, Control.Name, TComboBox(Control).Text)
      else if Control is TRadioButton then
        IniFile.WriteBool(Control.Parent.Name, Control.Name, TRadioButton(Control).Checked)
      else if Control is TRadioGroup then
        IniFile.WriteString(Control.Parent.Name, Control.Name, TRadioGroup(Control).Items[TRadioGroup(Control).ItemIndex]);
    end;
  finally
    IniFile.Free;
  end;
end;

end.

