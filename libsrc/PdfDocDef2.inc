!* pdfMake doc definitions
!* v2, compatible with Easy Edge (Chromium)
!* mikeduglas@yandex.ru 2022

!- nodes:
!  'id', 'text', 'ul', 'ol', 'table', 'image', 'qr', 'canvas', 'columns',
!  'headlineLevel', 'style', 'pageBreak', 'pageOrientation',
!  'width', 'height' 

!- available style properties:
!  'font',
!  'fontSize',
!  'fontFeatures',
!  'bold',
!  'italics',
!  'alignment',
!  'color',
!  'columnGap',
!  'fillColor',
!  'decoration',
!  'decorationStyle',
!  'decorationColor',
!  'background',
!  'lineHeight',
!  'characterSpacing',
!  'noWrap',
!  'markerColor',
!  'leadingIndent' 

TDocDefinition                CLASS, TYPE, MODULE('PdfDocDef2.clw'), LINK('PdfDocDef2.clw')
contextStack                    &TContextStack PRIVATE

dsGlobals                       &DynStr, PROTECTED
dsDocInfo                       &DynStr, PROTECTED
dsStyles                        &DynStr, PROTECTED
dsImages                        &DynStr, PROTECTED
dsContent                       &DynStr, PROTECTED

bUseChromium                    BOOL, PROTECTED  !- set to true for PdfMake2

Construct                       PROCEDURE()
Destruct                        PROCEDURE(), VIRTUAL

!!!<summary>
!!!Where we are, inside paragraph, inside list, inside table, inside content?
!!!</summary>
GetContext                      PROCEDURE(), *DynStr, PRIVATE

EndObject                       PROCEDURE(LONG pObjectType, <STRING pStyle>), PRIVATE

!--  passed strings not CLIPped


!!!<summary>Sets page size and orientatin</summary>
!!!<param name="pSize">One of predefined page sizes like 'A4' (see PDF::PageSizes)</param>
!!!<param name="pOrientation">portrait or landscape</param>
PageSettings                    PROCEDURE(<STRING pSize>, <STRING pOrientation>)
!!!<summary>Defines static page header text</summary>
!!!<param name="pText">Header text</param>
!!!<param name="pStyle">Header style</param>
PageHeader                      PROCEDURE(STRING pText, <STRING pStyle>)
!!!<summary>Defines static page footer text</summary>
!!!<param name="pText">Footer text</param>
!!!<param name="pStyle">Footer style</param>
PageFooter                      PROCEDURE(STRING pText, <STRING pStyle>)
!!!<summary>Defines background-layer</summary>
!!!<param name="pObject">text, image, table, ...</param>
!!!<param name="pValue">text or image to be added on every page</param>
!!!<param name="pStyle">node style</param>
Background                      PROCEDURE(STRING pObject, STRING pValue, <STRING pStyle>)
!!!<summary>Adds document metadata</summary>
!!!<param name="pName">Property name (like title, author...)</param>
!!!<param name="pValue">Property value</param>
AddDocInfo                      PROCEDURE(STRING pName, STRING pValue)
!!!<summary>Adds style to style dictionary</summary>
!!!<param name="pName">Style property name (like color, fontSize...)</param>
!!!<param name="pValue">Style property value</param>
AddStyle                        PROCEDURE(STRING pName, STRING pValue)
!!!<summary>Defines default style to the document</summary>
!!!<param name="pValue">key-value pairs</param>
AddDefaultStyle                 PROCEDURE(STRING pValue)
!!!<summary>Adds an image file to images dictionary</summary>
!!!<param name="pImageName">Image name</param>
!!!<param name="pImageFile">Image file</param>
AddDctImage                     PROCEDURE(STRING pImageName, STRING pImageFile)
!!!<summary>Adds a BLOB to images dictionary</summary>
!!!<param name="pImageName">Image name</param>
!!!<param name="pImageBlob">Image BLOB</param>
AddDctImage                     PROCEDURE(STRING pImageName, *BLOB pImageBlob)
!!!<summary>Adds a data to images dictionary</summary>
!!!<param name="pImageName">Image name</param>
!!!<param name="base64ImageData">Image data (base64 encoded)</param>
!!!<param name="pFormat">Image pFormat: PNG or JPG</param>
AddDctImageBase64               PROCEDURE(STRING pImageName, STRING base64ImageData, STRING pFormat)
!!!<summary>Adds a property of a document</summary>
!!!<param name="pName">Property name (like watermark, pageSize...)</param>
!!!<param name="pValue">Property value</param>
AddGlobalProperty               PROCEDURE(STRING pName, STRING pValue)
!!!<summary>Adds a property of a document's content</summary>
!!!<param name="pName">Property name</param>
!!!<param name="pValue">Property value</param>
AddContentProperty              PROCEDURE(STRING pName, STRING pValue)

!!!<summary>Begins document's content</summary>
BeginContent                    PROCEDURE()
!!!<summary>Ends document's content</summary>
EndContent                      PROCEDURE()
!!!<summary>Begins Table of contents</summary>
BeginTOC                        PROCEDURE(<STRING pStyle>)
!!!<summary>Ends Table of contents</summary>
EndTOC                          PROCEDURE(<STRING pStyle>)
!!!<summary>Begins a paragraph</summary>
BeginParagraph                  PROCEDURE(<STRING pStyle>)
!!!<summary>Ends a paragraph</summary>
EndParagraph                    PROCEDURE(<STRING pStyle>)
!!!<summary>Begins a stack of objects</summary>
BeginStack                      PROCEDURE(<STRING pStyle>)
!!!<summary>Ends a stack of objects</summary>
EndStack                        PROCEDURE(<STRING pStyle>)
!!!<summary>Begins an ordered list</summary>
BeginOrderedList                PROCEDURE(<STRING pStyle>)
!!!<summary>Ends an ordered list</summary>
EndOrderedList                  PROCEDURE(<STRING pStyle>)
!!!<summary>Begins an unordered list</summary>
BeginUnorderedList              PROCEDURE(<STRING pStyle>)
!!!<summary>Ends an unordered list</summary>
EndUnorderedList                PROCEDURE(<STRING pStyle>)
!!!<summary>Begins columns</summary>
BeginColumns                    PROCEDURE(<STRING pStyle>)
!!!<summary>Ends columns</summary>
EndColumns                      PROCEDURE(<STRING pStyle>)
!!!<summary>Begins nested columns</summary>
BeginNestedColumns              PROCEDURE(<STRING pStyle>)
!!!<summary>Ends nested columns</summary>
EndNestedColumns                PROCEDURE(<STRING pStyle>)
!!!<summary>Begins a table</summary>
BeginTable                      PROCEDURE(<STRING pStyle>)
!!!<summary>Ends a table</summary>
EndTable                        PROCEDURE(<STRING pStyle>)  !- pass here table layout: '"layout": "noBorders"'
!!!<summary>Begins a table's row</summary>
BeginRow                        PROCEDURE()
!!!<summary>Ends a table's row</summary>
EndRow                          PROCEDURE()

!!!<summary>Adds a text to document contents</summary>
!!!<param name="pText">Text</param>
!!!<param name="pStyle">Style</param>
AddText                         PROCEDURE(STRING pText, <STRING pStyle>)

!!!<summary>Adds an image to document contents</summary>
!!!<param name="pImageName">Image name from images dictionary, or image file name</param>
!!!<param name="pStyle">Style</param>
AddImage                        PROCEDURE(STRING pImageName, <STRING pStyle>)
!!!<summary>Adds an image to document contents</summary>
!!!<param name="pImageBlob">Image BLOB</param>
!!!<param name="pStyle">Style</param>
AddImage                        PROCEDURE(*BLOB pImageBlob, STRING pStyle) !- JPEG and PNG formats are supported.
!!!<summary>Adds an image to document contents</summary>
!!!<param name="base64ImageData">Image data</param>
!!!<param name="pFormat">Image pFormat: PNG or JPG</param>
!!!<param name="pStyle">Style</param>
AddImageBase64                  PROCEDURE(STRING base64ImageData, STRING pFormat, STRING pStyle) !- JPEG and PNG formats are supported.

!!!<summary>Adds QR code to document contents</summary>
!!!<param name="pText">Text to encode</param>
!!!<param name="pStyle">Style</param>
AddQR                           PROCEDURE(STRING pText, <STRING pStyle>)

!!!<summary>Returns JSON representation of this document definition object</summary>
ToJSON                          PROCEDURE(), STRING
                              END

TDocDefinition2               CLASS(TDocDefinition), TYPE, MODULE('PdfDocDef2.clw'), LINK('PdfDocDef2.clw')
Construct                       PROCEDURE()
                              END
