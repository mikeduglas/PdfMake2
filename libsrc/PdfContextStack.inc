!* TDocDefinition helper
!* mikeduglas@yandex.ru 2018

  INCLUDE('dynstrclass.inc'),ONCE

PDF::ObjectEnum               ITEMIZE
PDF::Unknown                    EQUATE(0)
PDF::Content                    EQUATE
PDF::TOC                        EQUATE
PDF::Paragraph                  EQUATE
PDF::Stack                      EQUATE
PDF::OL                         EQUATE
PDF::UL                         EQUATE
PDF::Columns                    EQUATE
PDF::NestedColumns              EQUATE
PDF::Table                      EQUATE
PDF::Row                        EQUATE
PDF::QR                         EQUATE
                              END

TContextGroup                 GROUP, TYPE
type                            LONG        !- PDF::ObjectEnum
ctx                             &DynStr
endBracket                      STRING(10)
initValueSize                   LONG        !- size of initial value. if value.StrLen() > initValueSize that means some data was appended (see IsChanged).
                              END

TContextQueue                 QUEUE(TContextGroup), TYPE
                              END

TContextStack                 CLASS, TYPE, MODULE('PdfContextStack.clw'), LINK('PdfContextStack.clw')
q                               &TContextQueue, PRIVATE

Construct                       PROCEDURE()
Destruct                        PROCEDURE, VIRTUAL

!!!<summary>
!!!Creates DynStr instance and pushes to the stack
!!!</summary>
Push                            PROCEDURE(LONG pType, STRING pStyle), *DynStr, PROC
!!!<summary>
!!!Removes top instance from the stack and returns it's value
!!!</summary>
Pop                             PROCEDURE(), STRING
!!!<summary>
!!!Appends endBracket to value and returns top context
!!!</summary>
Context                         PROCEDURE(), *DynStr

!!!<summary>
!!!Returns top type to a caller
!!!</summary>
Type                            PROCEDURE(), LONG

Free                            PROCEDURE()
IsEmpty                         PROCEDURE(), BOOL
IsChanged                       PROCEDURE(), BOOL
                              END
