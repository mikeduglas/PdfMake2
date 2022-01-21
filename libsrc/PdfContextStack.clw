!* TDocDefinition helper
!* mikeduglas@yandex.ru 2018

  MEMBER

  INCLUDE('PdfContextStack.inc'), ONCE

  MAP
  END

TContextStack.Construct       PROCEDURE()
  CODE
  SELF.q &= NEW TContextQueue
  
TContextStack.Destruct        PROCEDURE()
  CODE
  SELF.Free()
  DISPOSE(SELF.q)
  
TContextStack.Push            PROCEDURE(LONG pType, STRING pStyle)
startBracket                    CSTRING(33)
endBracket                      CSTRING(33)
propName                        CSTRING(33)
  CODE
  CASE pType
  OF PDF::Content
    startBracket = ''; endBracket = ''; propName = ''
  OF PDF::TOC
    startBracket = '{{"toc": {{'; endBracket = '}}'; propName = '"title": '
  OF PDF::Paragraph
    startBracket = '{{'; endBracket = ']}'; propName = '"text": ['
  OF PDF::Stack
    startBracket = '{{'; endBracket = ']}'; propName = '"stack": ['
  OF PDF::OL
    startBracket = '{{'; endBracket = ']}'; propName = '"ol": ['
  OF PDF::UL
    startBracket = '{{'; endBracket = ']}'; propName = '"ul": ['
  OF PDF::Columns
    startBracket = '{{'; endBracket = ']}'; propName = '"columns": ['
  OF PDF::NestedColumns
    startBracket = '['; endBracket = ']]'; propName = '['
  OF PDF::Table
    startBracket = '{{"table": {{'; endBracket = ']}}'; propName = '"body": ['
  OF PDF::Row
    startBracket = '['; endBracket = ']'; propName = ''
  OF PDF::QR
    startBracket = '{{'; endBracket = '}'; propName = '"qr": '
  ELSE
    ASSERT(TRUE, 'Invalid PDF object type '& pType)
    RETURN NULL
  END
  
  SELF.q.type = pType
  SELF.q.ctx &= NEW DynStr
  IF startBracket
    SELF.q.ctx.Cat(startBracket)
    
    IF pStyle
      SELF.q.ctx.Cat(pStyle &',')
    END
    
    SELF.q.ctx.Cat(propName)

    SELF.q.initValueSize = SELF.q.ctx.StrLen()
  ELSE
    SELF.q.initValueSize = 0
  END
  SELF.q.endBracket = endBracket
  
  ADD(SELF.q)
  RETURN SELF.Q.ctx
  
TContextStack.Pop             PROCEDURE()
ret                             ANY
  CODE
  GET(SELF.q, RECORDS(SELF.q))
  IF NOT ERRORCODE()
    DELETE(SELF.q)
    IF SELF.q.endBracket
      SELF.q.ctx.Cat(SELF.q.endBracket)
    END
    
    ret = SELF.q.ctx.Str()
    DISPOSE(SELF.q.ctx)
    RETURN CLIP(ret)
  END

  RETURN ''

TContextStack.Context         PROCEDURE()
  CODE
  ASSERT(RECORDS(SELF.q), 'Empty Context stack: BeginContent() was not called.')
  GET(SELF.q, RECORDS(SELF.q))
  IF NOT ERRORCODE()
    RETURN SELF.q.ctx
  END

  RETURN NULL

TContextStack.Type            PROCEDURE()
  CODE
  GET(SELF.q, RECORDS(SELF.q))
  IF NOT ERRORCODE()
    RETURN SELF.q.type
  END

  RETURN PDF::Unknown

TContextStack.Free            PROCEDURE()
qIndex                          LONG, AUTO
  CODE
  LOOP qIndex = RECORDS(SELF.q) TO 1 BY -1
    GET(SELF.q, qIndex)
    IF NOT SELF.q.ctx &= NULL
      DISPOSE(SELF.q.ctx)
      SELF.q.ctx &= NULL
      PUT(SELF.q)
    END
  END
  
  FREE(SELF.q)

TContextStack.IsEmpty         PROCEDURE()
  CODE
  RETURN CHOOSE(RECORDS(SELF.q) = 0)
  
TContextStack.IsChanged       PROCEDURE()
  CODE
  GET(SELF.q, RECORDS(SELF.q))
  IF NOT ERRORCODE()
    RETURN CHOOSE(SELF.q.ctx.StrLen() > SELF.q.initValueSize)
  END

  RETURN FALSE
