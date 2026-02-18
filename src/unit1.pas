

// Icklenote - Gareth

// FileList.ItemIndex   is the selected item from 0 (-1 no item selected).

// BUG when saving file with a space in the filename ?

// To use DebugLn need to:
//"Project Options" > "Compiler options" > "Config and Target" > "Win32 gui application"


//------------------------------------------------------------------------------

unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Windows, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, ExtCtrls, Menus, ActnList, RichMemo, strutils, fileutil,
  IniFiles, Types, lclintf, MouseAndKeyInput, LCLType, LazLogger, clipbrd;

type

    SearchMatchEntry = record
        LineInSearchResults: Integer;
	DocumentFilename : string;
        LineInDocument : Integer;
        DocumentInFileList: Integer;
        SelStartPosInDoc: Integer;
    end;

  { TForm1 }

  TForm1 = class(TForm)
    ChangeFont1: TButton;
    FindButton:       TButton;
    HighlightText:    TMenuItem;
    MenuItem1:        TMenuItem;
    MenuItem2:        TMenuItem;
    GoogleSearch: TMenuItem;
    NewFile:          TButton;
    CopyText:         TMenuItem;
    MainMenu1:        TMainMenu;
    FileMenu:         TMenuItem;
    CutText:          TMenuItem;
    FileListTextFontLabel: TLabel;
    Rescan:           TButton;
    Save:             TMenuItem;
    EditCopy:         TMenuItem;
    EditMenu:         TMenuItem;
    EditPaste:        TMenuItem;
    EditOpenExternal: TMenuItem;
    OpenExternal:     TMenuItem;
    PasteText:        TMenuItem;
    SaveDialog1:      TSaveDialog;
    FindBox:          TLabeledEdit;
    SearchText:       TMenuItem;
    PopupMenu1:       TPopupMenu;
    Separator1: TMenuItem;
    StaticText1: TStaticText;
    WordWrapCheckBox: TCheckBox;
    WordWrapLabel:    TLabel;
    SearchFile:       TRichMemo;
    SearchButton:     TButton;
    ChangeFont:       TButton;
    AutoSaveCheckBox: TCheckBox;
    FontDialog1:      TFontDialog;
    PlainTextFontLabel1: TLabel;
    AutoSaveLabel:    TLabel;
    SearchBox:        TLabeledEdit;
    Search:           TRichMemo;
    Document:         TRichMemo;
    FileList:         TListBox;
    PageControl1:     TPageControl;
    DocumentTab:      TTabSheet;
    SearchTab:        TTabSheet;
    HelpTab:          TTabSheet;
    Splitter1:        TSplitter;

    procedure ChangeFont1Click(Sender: TObject);
    procedure ChangeFontClick(Sender: TObject);
    procedure CopyTextClick(Sender: TObject);
    procedure CutTextClick(Sender: TObject);
    procedure DocumentClick(Sender: TObject);
    procedure DocumentKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
      );
    procedure DocumentMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FileListClick(Sender: TObject);
    procedure FileListDrawItem(Control: TWinControl; Index: Integer; ARect: TRect; State: TOwnerDrawState);
    procedure FindButtonClick(Sender: TObject);
    procedure FormClose(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure HighlightTextClick(Sender: TObject);
    procedure GoogleSearchClick(Sender: TObject);
    procedure NewFileClick(Sender: TObject);
    procedure OpenExternalClick(Sender: TObject);
    procedure PasteTextClick(Sender: TObject);
    procedure LoadDoc(Index:Integer);
    procedure RescanClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure SaveDoc();
    procedure LoadIni();
    procedure SaveIni();
    procedure DoSearch();
    procedure DoFind();
    procedure SearchButtonClick(Sender: TObject);
    procedure SearchDblClick(Sender: TObject);
    procedure SearchMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure SearchTextClick(Sender: TObject);
    procedure StaticText1Click(Sender: TObject);
    procedure TRichMemoMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer);
    procedure WordWrapCheckBoxChange(Sender: TObject);
    procedure LoadFileList();

  private

  public

  end;


var
   Form1:            TForm1;
   LastFileName:     string;
   SearchMatch:      Array of Boolean;
   SearchRow:        integer;
   SearchMatchList:  Array of SearchMatchEntry;      //Records of search matches
   GlobalDocRow:     String;                         //String under pointer in document
   SearchMask:       String;                         //Used to populate filelist


const
     IniFileName = 'IckleNote.ini';


implementation

{$R *.lfm}
//In Code Typhon this is *.frm

{ TForm1 }

//------------------------------------------------------------------------------
procedure TForm1.FormCreate(Sender: TObject);

begin
     LoadIni();

     ChangeFont.Caption  := InttoStr(Document.font.Size) + 'pt  '+Document.font.Name;
     ChangeFont1.Caption := InttoStr(FileList.font.Size) + 'pt  '+FileList.font.Name;

     Form1.Caption      :=  'IckleNote [v0.693 / 2026-02-18 / Lazarus 4.2] Path: ' + Application.Location;

     LoadFileList();

     FileList.ItemIndex := 0;
     LoadDoc(0);

     ActiveControl := Searchbox;

     //Disable menu item "Edit/Paste" when searchbox active
     EditPaste.Enabled := false;

     //SearchFile.Width := Document.Width;

     GlobalDocRow := '';
     Document.ShowHint := False;
end;

//------------------------------------------------------------------------------
procedure TForm1.HighlightTextClick(Sender: TObject);
begin
     //If on Document tab
     Findbox.text := Document.SelText;

     // If empty string then don't bother
     If ( FindBox.Text <> '') then
        begin
             If PageControl1.TabIndex <> 0 then PageControl1.TabIndex := 0;
             DoFind();
        end;
end;

procedure TForm1.GoogleSearchClick(Sender: TObject);

var
     SearchStr: string;

begin
     Document.CopyToClipboard;

     //If on Search tab
     If (PageControl1.TabIndex = 1) then
        begin
             Search.CopyToClipboard;
        end;

    SearchStr := 'www.google.com/search?q=' + Clipboard.AsText;

    //Replace spaces with +
    SearchStr := stringreplace(SearchStr,' ','+',[rfReplaceAll]);
    //Replace " with %22
    SearchStr := stringreplace(SearchStr,'"','%22',[rfReplaceAll]);

    DebugLn(SearchStr);

    OpenURL(SearchStr);

end;

//------------------------------------------------------------------------------

procedure TForm1.LoadFileList();

begin
     // Populate List Box with all relevant file names
     //Filelist.Items := FindAllFiles('', '*.txt;*.rtf;*.asc;*.md;*.ini;*.pas', true);
     Filelist.Items := FindAllFiles('', SearchMask, true);

     if (FileList.items.Count = 0) then begin
        ShowMessage('No Files Found. Click Okay to Exit.');
        Application.terminate;
     end;

     //Initialise Array
     Setlength(SearchMatch,FileList.items.count);

     SetLength(SearchMatchList, 1);

     SearchRow := 0;
end;

//------------------------------------------------------------------------------

procedure TForm1.NewFileClick(Sender: TObject);

var
     F: Longint;
     FileIndex: integer;

begin
     SaveDialog1.InitialDir := Application.Location;
     if SaveDialog1.Execute then begin

        //Skip this if file exists
        If not FileExists(SaveDialog1.FileName) then begin
           F := FileCreate(SaveDialog1.FileName);
           FileClose(F);

           LoadFileList();
        end;

        //Switch to Doc tab
        PageControl1.TabIndex := 0;

        //Show new (or existing) file
        for FileIndex := 0 to FileList.Items.Count-1 do begin

            //DebugLn(SaveDialog1.Filename);
            //DebugLn(Filelist.Items[FileIndex]);

            if (SaveDialog1.Filename.Contains(Filelist.Items[FileIndex]))then begin

               FileList.ItemIndex := FileIndex;
               LoadDoc(FileIndex);
            end;
        end;
     end;

end;

//------------------------------------------------------------------------------

procedure TForm1.OpenExternalClick(Sender: TObject);
begin
     OpenDocument(Filelist.Items[FileList.ItemIndex]);

end;

//------------------------------------------------------------------------------

procedure TForm1.SaveIni();

Var
    IniFile : TMemIniFile;

begin

     // ScaledWidth   := Width  * 144 div Screen.PixelsPerInch;
     // ScaledHeight  := Height * 144 div Screen.PixelsPerInch;

     IniFile := nil;

     IniFile := TMemIniFile.Create(IniFileName);

     IniFile.WriteInteger('Placement','Top', Top);
     IniFile.WriteInteger('Placement','Left', Left);

     // Used to have to do this on earlier Lazarus.
     //IniFile.WriteInteger('Placement','Width', Width  * 144 div Screen.PixelsPerInch);
     //IniFile.WriteInteger('Placement','Height', Height * 144 div Screen.PixelsPerInch);
     //IniFile.WriteInteger('Placement','Split', FileList.Width * 144 div Screen.PixelsPerInch);

     // After moving to Laz 4.2 on Win 11 VM removed scaling.
     IniFile.WriteInteger('Placement','Width', Width);
     IniFile.WriteInteger('Placement','Height', Height);
     IniFile.WriteInteger('Placement','Split', FileList.Width);

     IniFile.WriteBool('Options','AutoSave',AutoSaveCheckBox.Checked);
     IniFile.WriteBool('Options','WordWrap',WordWrapCheckBox.Checked);

     IniFile.WriteString('PlainTextFont','Name', Document.Font.Name);
     IniFile.WriteInteger('PlainTextFont','CharSet', Document.Font.CharSet);
     IniFile.WriteInteger('PlainTextFont','Color', Document.Font.Color);
     IniFile.WriteInteger('PlainTextFont','Size', Document.Font.Size);
     IniFile.WriteInteger('PlainTextFont','Style', Integer(Document.Font.Style));

     IniFile.WriteString('FileListFont','Name', FileList.Font.Name);
     IniFile.WriteInteger('FileListFont','CharSet', FileList.Font.CharSet);
     IniFile.WriteInteger('FileListFont','Color', FileList.Font.Color);
     IniFile.WriteInteger('FileListFont','Size', FileList.Font.Size);
     IniFile.WriteInteger('FileListFont','Style', Integer(FileList.Font.Style));

     IniFile.WriteString('Search','SearchMask', '*.txt;*.rtf;*.asc;*.md;*.ini;*.pas' );
  Try
     IniFile.UpdateFile;
  finally
     IniFile.Free;
  end;
end;

//------------------------------------------------------------------------------

procedure TForm1.DoSearch();

var
     FS: TFileStream;
     FileName: string;
     SearchString: string;
     FileIndex: integer;
     SearchIndex: integer;
     LineStart: integer;
     InfoLen: integer;
     SearchLen: integer;
     InfoStr: String;
     SearchBoxText: String;
     TextParams: TFontParams;
     NumMatches: Integer;

begin
     Search.Cursor := crHourGlass;

     //Switch to Search Tab
     PageControl1.TabIndex := 1;
     Search.SetFocus;

     Search.Clear;
     Search.Lines.Add(sLineBreak +'Searching...');
     //Application.ProcessMessages;

     //DebugLn('276: SEARCH START FOR TERM: '+SearchBox.Text+ '----------------------------------------------');

     //Trim leading & trailing spaces from SearchBox.Text
     //SearchBox.Text := AnsiLowerCase(trim(SearchBox.Text));
     SearchBoxText := AnsiLowerCase(trim(SearchBox.Text));

     // Get existing font params and change background
     TextParams := GetFontParams(Search.Font);
     TextParams.HasBkClr:= True;
     TextParams.BkColor := clYellow;

     SearchLen := Length(SearchBoxText);

     NumMatches := 0;

     SetLength(SearchMatchList, 1);

     for FileIndex := 0 to FileList.Items.Count-1 do

       begin
           FileName := Filelist.Items[FileIndex];

           //Clear search match array
           SearchMatch[FileIndex] := FALSE;

           //Load file into SearchFile
           SearchFile.Clear;
           if(AnsiContainsText(FileName,'.rtf')) then
           begin
              //Load RTF file
              FS := TFileStream.Create(FileName, fmOpenRead);
              SearchFile.LoadRichText(FS);
              FS.free;
           end
           //Anything other than RTF load as plain text.
           else SearchFile.Lines.LoadFromFile(FileName);

           //DebugLn('301: FILE LOADED: '+Filename);

           // SearchFile:TRichMemo - now contains the whole file that we want to search
           // Search:TRichMemo - is the document shown in the search tab

           SearchFile.SelStart := 0;

           for SearchIndex := 0 to SearchFile.Lines.Count do

           begin
                Search.Cursor := crHourGlass;
                //DbgOut('/'+inttostr(SearchIndex));
                //DebugLn('LINE: ' + inttostr(SearchIndex) + ' / FILE: ' + Filename);

                SearchString := AnsiLowerCase(SearchFile.Lines[SearchIndex]);

                //if (SearchString.Contains(SearchBox.Text))

                if (SearchString.Contains(SearchBoxText))
                then begin

                   //DebugLn('SEARCH TERM MATCH IN FILE: '+Filename);
                   //DebugLn('SelStart: ' + IntToStr(SearchFile.SelStart));

                   //Save in array
                   //Line number in search results - get that from Search.Lines.Count
                   //File index - get from FileIndex
                   //Line in file - get from SearchIndex

                   //Save in global array for reference later
                   //DebugLn('Filename: ' + FileName + ' LineInDocument: ' + inttostr(SearchIndex) + ' LineInSearchResults: ' + inttostr(Search.Lines.Count +1));

                   With SearchMatchList[NumMatches] do begin

                        DocumentFilename    := FileName;
                        LineInDocument      := SearchIndex;              //Probably not used now
                        LineInSearchResults := Search.Lines.Count +1;
                        DocumentInFileList  := FileIndex;
                        SelStartPosInDoc    := SearchFile.SelStart;
                   end;

                   //So we can highlight in FileList
                   SearchMatch[FileIndex] := TRUE;

                   //Prefix with filename and line numbers
                   InfoStr := (FileName+' ('+format('%.3d',[SearchIndex])+') ');

                   //Number of characters
                   LineStart := Search.GetTextLen;
                   InfoLen := Length(InfoStr);

                   //Add line to Search tab - included unprintable character
                   Search.Lines.Add(lineEnding + InfoStr + char(28) + lineEnding + AnsiToUTF8(SearchFile.Lines[SearchIndex]));

                   //Set colour for prefix
                   Search.SetRangeColor(LineStart,InfoLen,clBlue);

                   //Skip over prefix
                   LineStart := LineStart + InfoLen;

                   //Skip to search term
                   LineStart := Search.Search(SearchBoxText,LineStart,10000,[]);

                   //Set colour of search term
                   //Search.SetRangeColor(LineStart,SearchLen,clRed);

                   //Background yellow
                   Search.SetTextAttributes(LineStart,SearchLen,TextParams);

                   Application.ProcessMessages;

                   SetLength(SearchMatchList, Length(SearchMatchList)+1);

                   Inc(NumMatches);

                end;
                //Advance SelStart so we can save it in the array when we get a match
                SearchFile.SelStart := SearchFile.SelStart + Length(SearchString) +1;
           end;
       end;

       Search.Lines.Add(sLineBreak +'Search completed.');
       FileList.Repaint;
       Search.Cursor := crDefault;
end;

//------------------------------------------------------------------------------

procedure TForm1.SearchButtonClick(Sender: TObject);
begin
     // If empty string then don't bother
     If ( searchbox.Text <> '') then begin
          //PageControl1.TabIndex := 1;
          DebugLn('DoSearch called from SearchButtonClick');
          //To avoid double trigger
          If Search.Cursor <> crHourGlass then DoSearch();
     end;
end;

//------------------------------------------------------------------------------

//Actually single click calls this
//Iterate through the global array that links filename and line in search results and line in document
//SearchMatchEntry = record
//        LineInSearchResults: Integer;
//        DocumentFilename : string;
//        LineInDocument : Integer;
//        DocumentInFileList: Integer;
//        SelStartPosInDoc: Integer;
//If there is a match then open the doc and switch to the document tab then scroll down to the correct line

procedure TForm1.SearchDblClick(Sender: TObject);

var
       i:  Integer;
       //FileName: String;
       //Line, j:  Integer;
       //NewCaretPos: TPoint;

begin
   Document.Cursor := crHourGlass;
   Search.SetFocus;
   Application.ProcessMessages;

   For i := 0 to Length(SearchMatchList) do begin

       with SearchMatchList[i] do
         begin

            If SearchRow = LineInSearchResults then
            begin
                 //DebugLn(DocumentFilename + ' ' + inttostr(LineInDocument) + ' File Index: ' + inttostr(DocumentInFileList));

                 // Save file before loading new file
                 If AutoSaveCheckBox.Checked then SaveDoc();

                 FileList.ItemIndex := DocumentInFileList;
                 LoadDoc(FileList.ItemIndex);

                 //Switch to Doc Tab
                 PageControl1.TabIndex := 0;
                 Application.ProcessMessages;

                 //Scroll down to line

// -- Old method using LineInDocument ----- No good for Wordwrap

//                 NewCaretPos.X := 0;

//                 j := 0;
//                 Repeat
//                     NewCaretPos.Y := j;
//                     Document.CaretPos := NewCaretPos;
//                     inc(j, 20);
//                 until (j > LineInDocument);

                 //Exact location

//                 NewCaretPos.Y := LineInDocument;
//                 Document.CaretPos := NewCaretPos;
                 //Document.SetFocus;

// -- New method using SelStartPosInDoc -----

                 Document.SelStart := SelStartPosInDoc;
                 Document.Perform(EM_SCROLLCARET, 0, 0);
                 Document.SetFocus;
                 Application.ProcessMessages;

                 //Highlight search string

                 Findbox.Text := Searchbox.Text;
                 DoFind();

                 Document.Cursor := crDefault;
                 //Document.SetFocus;
                 exit();
            end;
         end;
       end;
   Application.ProcessMessages;
   //Document.SetFocus;
   Document.Cursor := crDefault;
end;

//------------------------------------------------------------------------------
// Indicate with the pointer the clickable links
//

procedure TForm1.SearchMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);

Var
   Pt: TPoint;
   CharPos: DWord;
   Row: Integer;
   //Col: Integer;
   SearchLinesRow: String;

Begin
   Pt.X    := X;
   Pt.Y    := Y;
   CharPos := SendMessage(Search.Handle, EM_CHARFROMPOS,  0, Integer(@PT));
   Row     := SendMessage(Search.Handle, EM_EXLINEFROMCHAR, 0, CharPos);
   //Col     := CharPos - SendMessage(Search.Handle, EM_LINEINDEX, Row, 0);

   //Copy to Global
   SearchRow := Row;
   SearchLinesRow := Search.Lines[Row];

   DebugLn(inttostr(Row));
   DebugLn(SearchLinesRow);

   //If non printable marker present then highlight on mouse over
   If SearchLinesRow.EndsWith(char(28))
      then Search.Cursor := crHandPoint
      else Search.Cursor := crDefault;

end;

//------------------------------------------------------------------------------

procedure TForm1.SearchTextClick(Sender: TObject);
begin
     //If on Document tab
     SearchBox.text := Document.SelText;

     //If on Search tab
     If (PageControl1.TabIndex = 1) then begin
        SearchBox.text := Search.SelText;
     end;

     DoSearch();
end;

procedure TForm1.StaticText1Click(Sender: TObject);
begin

end;

//------------------------------------------------------------------------------

procedure TForm1.LoadIni();

Var
//  IniFile : TIniFile;
//  Changed to TMemIniFile as exception when saving into Dropbox
    IniFile : TMemIniFile;

begin
    IniFile := TMemIniFile.Create(IniFileName);

    Top :=             IniFile.ReadInteger('Placement','Top', 100) ;
    Left :=            IniFile.ReadInteger('Placement','Left', 100) ;
    Width :=           IniFile.ReadInteger('Placement','Width', 1000) ;
    Height :=          IniFile.ReadInteger('Placement','Height', 600) ;
    FileList.Width :=  IniFile.ReadInteger('Placement','Split', 368) ;

    AutoSaveCheckBox.Checked := IniFile.ReadBool('Options','AutoSave',False);
    WordWrapCheckBox.Checked := IniFile.ReadBool('Options','WordWrap',True);


    Document.Font.Name :=    IniFile.ReadString('PlainTextFont','Name','Courier New');
    Document.Font.CharSet := IniFile.ReadInteger('PlainTextFont','CharSet',0);
    Document.Font.Color :=   IniFile.ReadInteger('PlainTextFont','Color',0);
    Document.Font.Size :=    IniFile.ReadInteger('PlainTextFont','Size',12);
    Document.Font.Style :=   TFontStyles(IniFile.ReadInteger('PlainTextFont','Style',0));

    FileList.Font.Name :=    IniFile.ReadString('FileListFont','Name','Courier New');
    FileList.Font.CharSet := IniFile.ReadInteger('FileListFont','CharSet',0);
    FileList.Font.Color :=   IniFile.ReadInteger('FileListFont','Color',0);
    FileList.Font.Size :=    IniFile.ReadInteger('FileListFont','Size',12);
    FileList.Font.Style :=   TFontStyles(IniFile.ReadInteger('FileListFont','Style',0));


    SearchMask :=            IniFile.ReadString('Search','SearchMask','*.txt;*.rtf;*.asc;*.md;*.ini;*.pas');

    IniFile.Free;
end;

//------------------------------------------------------------------------------
procedure TForm1.FileListClick(Sender: TObject);

begin
     // Save file before loading new file
     If AutoSaveCheckBox.Checked then SaveDoc();

     LoadDoc(FileList.ItemIndex);

     //Switch to Doc Tab
     PageControl1.TabIndex := 0;
end;

//------------------------------------------------------------------------------

//Custom text and backgrounds for file list

procedure TForm1.FileListDrawItem(Control: TWinControl; Index: Integer; ARect: TRect; State: TOwnerDrawState);

begin
    //Default
    FileList.Canvas.Brush.Color := clWhite;
    FileList.Canvas.Font.Color  := clBlack;
    FileList.Canvas.FillRect(Arect);
    FileList.Canvas.TextRect(ARect, 2, ARect.Top+2, FileList.Items[Index]);

    //Selected item
    if odSelected in State then begin
       FileList.Canvas.Brush.Color := clBlue;
       FileList.Canvas.Font.Color  := clWhite;
       FileList.Canvas.FillRect(Arect.Left,Arect.Top,Arect.right-20,Arect.bottom);
       FileList.Canvas.TextRect(ARect, 2, ARect.Top+2, FileList.Items[Index]);
    end;

    //Item with search match
    if SearchMatch[Index] then begin
        FileList.Canvas.Brush.Color := clYellow;

        //Draw Background
        FileList.Canvas.FillRect(Arect.Right-20,Arect.Top,Arect.right,Arect.bottom);

        //Draw Item text
        FileList.Canvas.TextRect(ARect, 2, ARect.Top+2, FileList.Items[Index]);
    end;
end;

//------------------------------------------------------------------------------

procedure TForm1.FindButtonClick(Sender: TObject);
begin
     // If empty string then don't bother
     If ( FindBox.Text <> '') then
        begin
             If PageControl1.TabIndex <> 0 then PageControl1.TabIndex := 0;
             DoFind();
        end;
end;

//------------------------------------------------------------------------------

procedure TForm1.DoFind();
          //Find matches in currently selected document
var
   MatchStrPos: Integer;
   MatchStrLen: Integer;
   TextParams:  TFontParams;
   FindBoxText: String;
   DocumentTextLen: Integer;

begin
   Document.Cursor := crHourGlass;
   FindBoxText := AnsiLowerCase(trim(FindBox.Text));

   MatchStrLen := Length(FindBoxText);
   DocumentTextLen := Document.GetTextLen;

   // Get existing font params and change background
   TextParams := GetFontParams(Document.Font);
   TextParams.HasBkClr:= True;
   TextParams.BkColor := clYellow;

   //Start from beginning
   MatchStrPos := 0;

   While (MatchStrPos <> -1) do Begin
         //DebugLn('MatchStrPos: ' + IntToStr(MatchStrPos));
         MatchStrPos := Document.Search(FindBoxText,MatchStrPos,DocumentTextLen,[]);

         If (MatchStrPos <> -1) then
            Begin
                 // Highlight match
                 Document.SetTextAttributes(MatchStrPos,MatchStrLen,TextParams);
                 // Move position past match
                 Inc(MatchStrPos, MatchStrLen);
            end;
   end;
   Document.Cursor := crDefault;
   Document.SetFocus;
   Application.ProcessMessages;
end;
//------------------------------------------------------------------------------

procedure TForm1.FormClose(Sender: TObject);
begin

     If AutoSaveCheckBox.Checked then SaveDoc();
     SaveIni();
end;
//------------------------------------------------------------------------------
procedure TForm1.LoadDoc(Index:Integer);

var
   FS: TFileStream;
   FileName: string;

begin
     FileName:= Filelist.Items[Index];

     Document.Clear;
     Document.ZoomFactor := 1;

     if(AnsiContainsText(FileName,'.rtf')) then
     begin
        //Load RTF file
        FS := TFileStream.Create(FileName, fmOpenRead);
        Document.LoadRichText(FS);
        FS.free;
     end
     //Anything other than RTF load as plain text.
     else Begin
         Try Document.Lines.LoadFromFile(FileName);
         Except
                //If the file has been deleted since the directory was read
                Begin
                     LoadFileList();
                     FileList.ItemIndex := 0;
                     LoadDoc(0);
                end;
         //finally;
         end;
     end;

     LastFileName := FileName;
end;
//------------------------------------------------------------------------------

procedure TForm1.RescanClick(Sender: TObject);

var
     Item: Integer;

begin
     //Save index
     Item := FileList.ItemIndex;

     //Reload
     LoadFileList();
     FileList.ItemIndex := Item;
     LoadDoc(Item);
end;

//------------------------------------------------------------------------------

procedure TForm1.SaveClick(Sender: TObject);

Begin
          SaveDoc();
end;

//------------------------------------------------------------------------------
procedure TForm1.SaveDoc();

var
   FS: TFileStream;
   FileName: string;
   caretpos: tpoint;
   scrollpos: integer;

begin
     //Save caret position
     caretpos := Document.CaretPos;
     scrollpos := Document.VertScrollBar.Position;

     Document.Wordwrap := False;

     FileName:= LastFileName;

     if(AnsiContainsText(FileName,'.rtf')) then begin
        //Save RTF file
        FS := TFileStream.Create(FileName, fmOpenWrite or fmShareDenyNone);
        Document.SaveRichText(FS);
        FS.free;
     end
     //Anything other than RTF save as plain text.
     else Document.Lines.SaveToFile(FileName);

     Document.Wordwrap := WordWrapCheckBox.Checked;

     //Move caret back to original location
     Document.CaretPos := caretpos;

     //Scroll window down to original position
     Document.VertScrollBar.Position := scrollpos;
end;

//------------------------------------------------------------------------------
procedure TForm1.ChangeFontClick(Sender: TObject);

begin
     fontdialog1.Font := Document.Font;
     if fontdialog1.Execute then
        begin
             Document.Font:=fontdialog1.Font;
             ChangeFont.Caption := InttoStr(Document.font.Size) + 'pt  ' + Document.font.Name;
        end;
end;
//------------------------------------------------------------------------------
procedure TForm1.ChangeFont1Click(Sender: TObject);
begin
     fontdialog1.Font := FileList.Font;
     if fontdialog1.Execute then
        begin
             FileList.Font:=fontdialog1.Font;
             FileList.ItemHeight := (FileList.Font.Size + 2) * 2 ;
             ChangeFont1.Caption := InttoStr(FileList.font.Size) + 'pt  ' + FileList.font.Name;
        end;
end;

//------------------------------------------------------------------------------

procedure TForm1.CopyTextClick(Sender: TObject);
begin
     Document.CopyToClipboard;

     //If on Search tab
     If (PageControl1.TabIndex = 1) then
        begin
             Search.CopyToClipboard;
        end;
end;

//------------------------------------------------------------------------------

procedure TForm1.CutTextClick(Sender: TObject);
begin
     //Only if on Document tab
     If (PageControl1.TabIndex = 0) then begin
        Document.CutToClipboard;
     end;
end;

//------------------------------------------------------------------------------

procedure TForm1.DocumentClick(Sender: TObject);
var
     Key: TShiftState;
begin
     // ActiveControl := Document;
     // Need to enable menu item Paste / Ctrl-V when Doc tab is active
     EditPaste.Enabled := true;
     //DebugLn('Doc SelStart: ' + IntToStr(Document.SelStart));

     If (GlobalDocRow <> '') then
        begin
           //Ctrl down?
           Key := GetKeyShiftState;
           if(ssCtrl in Key) then OpenURL(GlobalDocRow);
        end;
end;

procedure TForm1.DocumentKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

begin
     if Key = VK_F5 then
     begin
          Clipboard.AsText := FormatDateTime('yyyy-mm-dd ', now);
          Document.PasteFromClipboard;
     end;

     if Key = VK_F6 then
     begin
          Clipboard.AsText := FormatDateTime('hh:nn:ss ', now);
          Document.PasteFromClipboard;
     end;


end;

//------------------------------------------------------------------------------

procedure TForm1.DocumentMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);

Var
   Pt: TPoint;
   CharPos: DWord;
   Row: Integer;
   //Col: Integer;
   DocLinesRow: String;
   Index: Integer;

Begin
   Pt.X    := X;
   Pt.Y    := Y;
   CharPos := SendMessage(Document.Handle, EM_CHARFROMPOS,  0, Integer(@PT));
   Row     := SendMessage(Document.Handle, EM_EXLINEFROMCHAR, 0, CharPos);
   //Col     := CharPos - SendMessage(Search.Handle, EM_LINEINDEX, Row, 0);

   DocLinesRow := Document.Lines[Row];

   //Clear Global
   GlobalDocRow := '';
   Document.ShowHint := False;

   //Find where the URL starts (if any)
   Index := pos('http',DocLinesRow);
   If (Index <> 0) then
      begin
           Document.ShowHint := True;
           Document.Cursor := crHandPoint;

           //Calc number of chars to keep and cut off everything before 'http'
           Index := DocLinesRow.Length - Index + 1;
           DocLinesRow := RightStr(DocLinesRow,Index);

           //Strip everything at the end of URL if there is anything after
           Index := pos(' ',DocLinesRow);
           If (Index <> 0) then
              begin
                   //Index := DocLinesRow.Length - Index + 1;
                   DocLinesRow := LeftStr(DocLinesRow,Index);
              end;
           //Save it for later if we get the mouse click
           GlobalDocRow := DocLinesRow;
      end
   else Document.Cursor := crDefault;

   DebugLn(GlobalDocRow);
end;

//------------------------------------------------------------------------------

procedure TForm1.PasteTextClick(Sender: TObject);
begin
     Document.PasteFromClipboard;
end;

//------------------------------------------------------------------------------
//Otherwise the TRichMemo only scrolls by a pixel instead of a line

procedure TForm1.TRichMemoMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer);

begin
     //check control key down for zoom, otherwise scroll

     If ((ssCtrl in Shift) and (Pagecontrol1.TabIndex = 0)) then
        begin
             DebugLn(IntToStr(Pagecontrol1.TabIndex));
             case WheelDelta of
                  // 120: Document.Font.Size := Document.Font.Size + 1;
                  //-120: Document.Font.Size := Document.Font.Size - 1;
                  120: Document.ZoomFactor := Document.ZoomFactor + 0.1;
                  -120: Document.ZoomFactor := Document.ZoomFactor - 0.1;
             end;

             //If (Document.Font.Size < 1) then Document.Font.Size := 1;
             If (Document.Zoomfactor < 0.2) then Document.Zoomfactor := 0.2;
             exit;
        end;

     case WheelDelta of
          120: SendMessage(TRichMemo(Sender).Handle, EM_LINESCROLL,0,-1);
         -120: SendMessage(TRichMemo(Sender).Handle, EM_LINESCROLL,0,1);
     end;
end;

//------------------------------------------------------------------------------

procedure TForm1.WordWrapCheckBoxChange(Sender: TObject);
begin
     Document.Wordwrap := WordWrapCheckBox.Checked;
     //SearchFile.Wordwrap := WordWrapCheckBox.Checked;
end;

//------------------------------------------------------------------------------
end.

