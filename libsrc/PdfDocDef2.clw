!* pdfMake doc definitions
!* v2, compatible with Easy Edge (Chromium)
!* mikeduglas@yandex.ru 2022

  MEMBER

  INCLUDE('dynstrclass.inc'),ONCE
  INCLUDE('PdfContextStack.inc'),ONCE
  INCLUDE('PdfDocDef2.inc'), ONCE
  INCLUDE('winapi.inc'), ONCE
  INCLUDE('b64.inc'), ONCE

  MAP
    !- DynStr extensions
    AppendJSON(DynStr this, STRING pJSON), PRIVATE
    AppendObject(DynStr this, STRING pName, STRING pValue), PRIVATE
    AppendTextObject(DynStr this, STRING pName, STRING pValue), PRIVATE
    AppendComplexObject(DynStr this, STRING pName, STRING pValue), PRIVATE
    AppendArrayObject(DynStr this, STRING pName, STRING pValue), PRIVATE
    AppendStyledObject(DynStr this, STRING pName, STRING pSubname, STRING pValue, STRING pStyle), PRIVATE
    EscapeJSON(DynStr this, BOOL pUseChromium), PRIVATE

    GetImageFormat(*STRING pImageData), STRING, PRIVATE
  END


!!!<summary>
!!!Appends passed text
!!!</summary>
AppendJSON                    PROCEDURE(DynStr this, STRING pJSON)
  CODE
  IF pJSON
    IF this.StrLen()
      this.Cat(',')
    END
    this.Cat(pJSON)
  END
  
!!!<summary>
!!!Appends "name":value
!!!</summary>
AppendObject                  PROCEDURE(DynStr this, STRING pName, STRING pValue)
  CODE
  !-- don't append if name or value are blank
  IF pName OR pValue
    this.AppendJSON('"'& pName &'":'& pValue)
  END
  
!!!<summary>
!!!Appends "name":"value"
!!!</summary>
AppendTextObject              PROCEDURE(DynStr this, STRING pName, STRING pValue)
  CODE
  !-- don't append if name or value are blank
  IF pName OR pValue
!    this.AppendJSON('"'& pName &'":"'& pValue &'"')
    this.AppendObject(pName, '"'& pValue &'"')
  END
  
!!!<summary>
!!!Appends "name":{value}
!!!</summary>
AppendComplexObject           PROCEDURE(DynStr this, STRING pName, STRING pValue)
  CODE
  !-- don't append if name or value are blank
  IF pName OR pValue
    this.AppendJSON('"'& pName &'":{{'& pValue &'}')
  END
  
!!!<summary>
!!!Appends "name":[value]
!!!</summary>
AppendArrayObject             PROCEDURE(DynStr this, STRING pName, STRING pValue)
  CODE
  !-- don't append if name or value are blank
  IF pName OR pValue
    this.AppendJSON('"'& pName &'":['& pValue &']')
  END
  
!!!<example>
!!!"header": {"text":"Doc header", "style": "headerStyle"}
!!!</example>
!!!<summary>
!!!Appends "name":{"subname":"value", style} where style = "bold":true, fontSize:24
!!!</summary>
AppendStyledObject            PROCEDURE(DynStr this, STRING pName, STRING pSubname, STRING pValue, STRING pStyle)
  CODE
  IF NOT pStyle
    this.AppendTextObject(pName, pValue)
  ELSE
    this.AppendJSON('"'& pName &'":{{"'& pSubname &'":"'& pValue &'",'& pStyle &'}')
  END

EscapeJSON                    PROCEDURE(DynStr this, BOOL pUseChromium)
  CODE
!  list of special character used in JSON:
!  \b  Backspace (ascii code 08)
!  \f  Form feed (ascii code 0C)
!  \n  New line
!  \r  Carriage return
!  \t  Tab
!  \"  Double quote
!  \\  Backslash character
  
  this.Replace('\', '\\')
  IF NOT pUseChromium
    !- IE
    this.Replace('\', '\\')
    this.Replace('"', '\"')
    this.Replace('<08h>', '\b')
    this.Replace('<0Ch>', '\f')
    this.Replace('<09h>', '\t')
    this.Replace('<0Dh,0Ah>', '\n')
    this.Replace('<0Ah>', '\n')
    this.Replace('<0Dh>', '\r')
  ELSE
    !- Chromium
    this.Replace('\', '\\')
    this.Replace('"', '\\"')
    this.Replace('<08h>', '\\b')
    this.Replace('<0Ch>', '\\f')
    this.Replace('<09h>', '\\t')
    this.Replace('<0Dh,0Ah>', '\\n')
    this.Replace('<0Ah>', '\\n')
    this.Replace('<0Dh>', '\\r')
  END
  
GetImageFormat                PROCEDURE(*STRING pImageData)
  CODE
  IF SUB(pImageData, 1, 8) = '<137,80,78,71,13,10,26,10>'
    !- PNG Specification
    !- https://www.w3.org/TR/PNG-Structure.html
    RETURN 'PNG'
  ELSIF SUB(pImageData, 1, 2) = '<0FFh,0D8h>' AND SUB(pImageData, LEN(pImageData) - 1, 2) = '<0FFh,0D9h>'
    !- JPEG Specification
    RETURN 'JPG'
  END
  
  RETURN 'PNG'

!!!region TDocDefinition
TDocDefinition.Construct      PROCEDURE()
  CODE
  SELF.contextStack &= NEW TContextStack
  
  SELF.dsGlobals &= NEW DynStr
  SELF.dsDocInfo &= NEW DynStr
  SELF.dsStyles &= NEW DynStr
  SELF.dsImages &= NEW DynStr
  SELF.dsContent &= NEW DynStr
  
TDocDefinition.Destruct       PROCEDURE()
  CODE
  DISPOSE(SELF.dsContent)
  DISPOSE(SELF.dsImages)
  DISPOSE(SELF.dsStyles)
  DISPOSE(SELF.dsDocInfo)
  DISPOSE(SELF.dsGlobals)
  
  DISPOSE(SELF.contextStack)

TDocDefinition.AddDocInfo     PROCEDURE(STRING pName, STRING pValue)
  CODE
  SELF.dsDocInfo.AppendTextObject(pName, CLIP(pValue))
  
TDocDefinition.PageSettings   PROCEDURE(<STRING pSize>, <STRING pOrientation>)
  CODE
  SELF.dsGlobals.AppendTextObject('pageSize', CLIP(pSize))
  SELF.dsGlobals.AppendTextObject('pageOrientation', CLIP(pOrientation))

TDocDefinition.PageHeader     PROCEDURE(STRING pText, <STRING pStyle>)
  CODE
  SELF.dsGlobals.AppendStyledObject('header', 'text', pText, pStyle)

TDocDefinition.PageFooter     PROCEDURE(STRING pText, <STRING pStyle>)
  CODE
  SELF.dsGlobals.AppendStyledObject('footer', 'text', pText, pStyle)

TDocDefinition.Background     PROCEDURE(STRING pObject, STRING pValue, <STRING pStyle>)
  CODE
  SELF.dsGlobals.AppendStyledObject('background', CLIP(pObject), pValue, pStyle)

TDocDefinition.AddStyle       PROCEDURE(STRING pName, STRING pValue)
  CODE
  SELF.dsStyles.AppendComplexObject(pName, pValue)

TDocDefinition.AddDefaultStyle    PROCEDURE(STRING pValue)
  CODE
  SELF.dsGlobals.AppendComplexObject('defaultStyle', pValue)

  
TDocDefinition.AddDctImage    PROCEDURE(STRING pImageName, STRING pImageFile)
df                              TDiskFile
fileContent                     &STRING
b64                             TBase64
  CODE
  fileContent &= df.LoadFile(LONGPATH(pImageFile))
  SELF.AddDctImageBase64(pImageName, b64.Encode(fileContent), GetImageFormat(fileContent))
  DISPOSE(fileContent)

TDocDefinition.AddDctImage    PROCEDURE(STRING pImageName, *BLOB pImageBlob)
blobVal                         &STRING, AUTO
b64                             TBase64
  CODE
  IF NOT pImageBlob &= NULL AND pImageBlob{PROP:Size} > 0
    blobVal &= CLIP(pImageBlob[0 : pImageBlob{PROP:Size} - 1])
    SELF.AddDctImageBase64(pImageName, b64.Encode(blobVal), GetImageFormat(blobVal))
  END
  
TDocDefinition.AddDctImageBase64  PROCEDURE(STRING pImageName, STRING base64ImageData, STRING pFormat)
fmt                                 STRING(32), AUTO
  CODE
  CASE LOWER(pFormat)
  OF 'png'
    fmt = 'data:image/png;base64,'
  ELSE    !default format; OF 'jpeg' OROF 'jpg'
    fmt = 'data:image/jpeg;base64,'
  END
  SELF.dsImages.AppendTextObject(pImageName, CLIP(fmt) & CLIP(base64ImageData))

  
TDocDefinition.AddGlobalProperty  PROCEDURE(STRING pName, STRING pValue)
  CODE
  SELF.dsGlobals.AppendObject(pName, pValue)

TDocDefinition.AddContentProperty PROCEDURE(STRING pName, STRING pValue)
  CODE
  SELF.dsStyles.AppendObject(pName, pValue)

TDocDefinition.EndObject      PROCEDURE(LONG pObjectType, <STRING pStyle>)
val                             ANY
ctx                             &DynStr
  CODE
  ASSERT(SELF.contextStack.Type() = pObjectType, 'EndObject('& pObjectType &') mismatch')
  IF SELF.contextStack.Type() = pObjectType
    val = SELF.contextStack.Pop()
    IF CLIP(val) AND pStyle
      !- insert style before trailing bracket
      val = SUB(CLIP(val), 1, LEN(CLIP(val)) - 1) &','& pStyle & SUB(CLIP(val), LEN(CLIP(val)), 1)
    END
    
    ctx &= SELF.contextStack.Context()
    IF NOT ctx &= NULL
      IF SELF.contextStack.IsChanged()
        ctx.Cat(',')
      END
      ctx.Cat(val)
    END
  END
  

TDocDefinition.BeginContent   PROCEDURE()
  CODE
  SELF.dsContent.Trunc(0)
  SELF.contextStack.Push(PDF::Content, '')
  
TDocDefinition.EndContent     PROCEDURE()
  CODE
  ! don't call SELF.EndObject(PDF::Content)
  ASSERT(SELF.contextStack.Type() = PDF::Content, 'EndContent mismatch')
  IF SELF.contextStack.Type() = PDF::Content
    SELF.dsContent.Cat(SELF.contextStack.Pop())
  END

TDocDefinition.BeginTOC       PROCEDURE(<STRING pStyle>)
  CODE
  SELF.contextStack.Push(PDF::TOC, pStyle)
  
TDocDefinition.EndTOC         PROCEDURE(<STRING pStyle>)
  CODE
  SELF.EndObject(PDF::TOC, pStyle)

TDocDefinition.BeginParagraph PROCEDURE(<STRING pStyle>)
  CODE
  SELF.contextStack.Push(PDF::Paragraph, pStyle)
  
TDocDefinition.EndParagraph   PROCEDURE(<STRING pStyle>)
  CODE
  SELF.EndObject(PDF::Paragraph, pStyle)

TDocDefinition.BeginStack     PROCEDURE(<STRING pStyle>)
  CODE
  SELF.contextStack.Push(PDF::Stack, pStyle)
  
TDocDefinition.EndStack       PROCEDURE(<STRING pStyle>)
  CODE
  SELF.EndObject(PDF::Stack, pStyle)

TDocDefinition.BeginOrderedList   PROCEDURE(<STRING pStyle>)
  CODE
  SELF.contextStack.Push(PDF::OL, pStyle)

TDocDefinition.EndOrderedList PROCEDURE(<STRING pStyle>)
  CODE
  SELF.EndObject(PDF::OL, pStyle)

TDocDefinition.BeginUnorderedList PROCEDURE(<STRING pStyle>)
  CODE
  SELF.contextStack.Push(PDF::UL, pStyle)

TDocDefinition.EndUnorderedList   PROCEDURE(<STRING pStyle>)
  CODE
  SELF.EndObject(PDF::UL, pStyle)

TDocDefinition.BeginColumns   PROCEDURE(<STRING pStyle>)
  CODE
  SELF.contextStack.Push(PDF::Columns, pStyle)

TDocDefinition.EndColumns     PROCEDURE(<STRING pStyle>)
  CODE
  SELF.EndObject(PDF::Columns, pStyle)

TDocDefinition.BeginNestedColumns PROCEDURE(<STRING pStyle>)
  CODE
  SELF.contextStack.Push(PDF::NestedColumns, pStyle)

TDocDefinition.EndNestedColumns   PROCEDURE(<STRING pStyle>)
  CODE
  SELF.EndObject(PDF::NestedColumns, pStyle)

TDocDefinition.BeginTable     PROCEDURE(<STRING pStyle>)
  CODE
  SELF.contextStack.Push(PDF::Table, pStyle)

TDocDefinition.EndTable       PROCEDURE(<STRING pStyle>)
  CODE
  SELF.EndObject(PDF::Table, pStyle)

TDocDefinition.BeginRow       PROCEDURE()
  CODE
  SELF.contextStack.Push(PDF::Row, '')
  
TDocDefinition.EndRow         PROCEDURE()
  CODE
  SELF.EndObject(PDF::Row)

TDocDefinition.GetContext     PROCEDURE()
ds                              &DynStr
  CODE
  ds &= SELF.contextStack.Context()

  IF SELF.contextStack.IsChanged()
    ds.Cat(',')
  END

  RETURN ds

TDocDefinition.AddText        PROCEDURE(STRING pText, <STRING pStyle>)
ds                              &DynStr
tmp                             DynStr
  CODE
  ds &= SELF.GetContext()
  IF NOT ds &= NULL
    tmp.Cat(pText)
    tmp.EscapeJSON(SELF.bUseChromium)
  
    IF NOT pStyle
      ds.Cat('"'& tmp.Str() &'"')
    ELSE
      ds.Cat('{{"text":"'& tmp.Str() &'",'& CLIP(pStyle) &'}')
    END
  END
  
TDocDefinition.AddImage       PROCEDURE(STRING pImageName, <STRING pStyle>)
df                              TDiskFile
ds                              &DynStr, AUTO
fileContent                     &STRING, AUTO
b64                             TBase64
  CODE
  IF EXISTS(pImageName)
    !- filename
    fileContent &= df.LoadFile(LONGPATH(pImageName))
    SELF.AddImageBase64(b64.Encode(fileContent), GetImageFormat(fileContent), pStyle)
    DISPOSE(fileContent)
  ELSE
    !- image name from the dictionary
    ds &= SELF.GetContext()
    IF NOT ds &= NULL
      ds.Cat('{{"image":"'& CLIP(pImageName) &'"')
      IF pStyle
        ds.Cat(','& pStyle)
      END
      ds.Cat('}')
    END
  END

TDocDefinition.AddImage       PROCEDURE(*BLOB pImageBlob, STRING pStyle)
blobVal                         &STRING, AUTO
b64                             TBase64
  CODE
  IF NOT pImageBlob &= NULL AND pImageBlob{PROP:Size} > 0
    blobVal &= CLIP(pImageBlob[0 : pImageBlob{PROP:Size} - 1])
    SELF.AddImageBase64(b64.Encode(blobVal), GetImageFormat(blobVal), pStyle)
  END
  
TDocDefinition.AddImageBase64 PROCEDURE(STRING base64ImageData, STRING pFormat, STRING pStyle)
ds                              &DynStr
fmt                             STRING(32), AUTO
  CODE
  ds &= SELF.GetContext()
  IF NOT ds &= NULL
    CASE LOWER(pFormat)
    OF 'png'
      fmt = 'data:image/png;base64,'
    OF 'jpg'
      fmt = 'data:image/jpeg;base64,'
    ELSE
      fmt = ''
    END
  
    IF fmt
      ds.Cat('{{"image":"'& CLIP(fmt) & CLIP(base64ImageData) &'"')
      IF pStyle
        ds.Cat(','& pStyle)
      END
      ds.Cat('}')
    END
  END
  
TDocDefinition.AddQR          PROCEDURE(STRING pText, <STRING pStyle>)
ds                              &DynStr
tmp                             DynStr
  CODE
  ds &= SELF.GetContext()
  IF NOT ds &= NULL
    tmp.Cat(pText)
    tmp.EscapeJSON(SELF.bUseChromium)
  
    ds.Cat('{{"qr":"'& tmp.Str() &'"')
    IF pStyle
      ds.Cat(','& CLIP(pStyle))
    END
    ds.Cat('}')
  END
  
TDocDefinition.ToJSON         PROCEDURE()
ds                              DynStr
  CODE
  ds.AppendComplexObject('info', SELF.dsDocInfo.Str())
  ds.AppendArrayObject('content', SELF.dsContent.Str())
  ds.AppendComplexObject('styles', SELF.dsStyles.Str())
  ds.AppendComplexObject('images', SELF.dsImages.Str())
  ds.AppendJSON(SELF.dsGlobals.Str())
  
  RETURN '{{'& ds.Str() &'}'
!!!endregion

!!!region TDocDefinition2
TDocDefinition2.Construct     PROCEDURE()
  CODE
  SELF.bUseChromium = TRUE
!!!endregion