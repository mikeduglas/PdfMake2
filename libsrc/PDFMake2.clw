!* PDFMake2
!* Easy Edge (Chromium) v1.06 and higher required.
!* v1.01

  MEMBER

  INCLUDE('PDFMake2.inc'), ONCE
  INCLUDE('PdfDocDef2.inc'), ONCE
  INCLUDE('winapi.inc'), ONCE
  INCLUDE('b64.inc'), ONCE

  MAP
    MODULE('Win api')
      winapi::GetLastError(), LONG, PASCAL, NAME('GetLastError')
    END

    INCLUDE('printf.inc'), ONCE
  END


!-- list of temporary files
TTempFilesQ                   QUEUE, TYPE
filename                        STRING(256)
                              END

!!!region TPDFMake2
TPDFMake2.Construct      PROCEDURE()
  CODE
  SELF.tempFiles &= NEW TTempFilesQ
  SELF.sErrorPattern = '<<p style="color: red; font-size: 16px;">%s<</p>'
  
TPDFMake2.Destruct       PROCEDURE()
qIndex                          LONG, AUTO
  CODE
  !- remove temporary files
  LOOP qIndex = 1 TO RECORDS(SELF.tempFiles)
    GET(SELF.tempFiles, qIndex)
    REMOVE(SELF.tempFiles.filename)
  END
  IF EXISTS(SELF.sDdFile)
    REMOVE(SELF.sDdFile)
  END
  
TPDFMake2.WaitCompleted  PROCEDURE(LONG pTimeout=10)
w                               WINDOW
                                END
  CODE
  OPEN(w)
  w{PROP:Hide} = TRUE
  w{PROP:Timer} = pTimeout
  ACCEPT
    IF EVENT() = EVENT:Timer
      IF SELF.bIsAsyncCompleted
        BREAK
      END
    END
  END
  CLOSE(w)
  SELF.bIsAsyncCompleted = FALSE


TPDFMake2.Init           PROCEDURE(<STRING browserExecutableFolder>, | 
                          <STRING userDataFolder>, | 
                          <STRING language>, | 
                          <STRING additionalBrowserArguments>, |
                          BOOL allowSingleSignOnUsingOSPrimaryAccount=FALSE)
  CODE
  SELF.bIsAsyncCompleted = FALSE
  
  IF PARENT.Init(browserExecutableFolder, userDataFolder, language, additionalBrowserArguments, allowSingleSignOnUsingOSPrimaryAccount)
    SELF.WaitCompleted()
    RETURN TRUE
  ELSE
    CASE SELF.InitErrorReason()
    OF   RuntimeInitErrorReason:RuntimeMismatch
    OROF RuntimeInitErrorReason:RuntimeNotFound
      MESSAGE('WebView2 runtime not installed.', 'ClaEdge error', ICON:Exclamation)
    OF RuntimeInitErrorReason:LoaderNotFound
      MESSAGE('WebView2Loader.dll not found.', 'ClaEdge error', ICON:Exclamation)
    ELSE
      MESSAGE('Unknown error occured.', 'ClaEdge error', ICON:Exclamation)
    END
    RETURN FALSE
  END
  
TPDFMake2.Kill           PROCEDURE()
  CODE
  SELF.viewer &= NULL
  PARENT.Kill()
  
TPDFMake2.Load           PROCEDURE(STRING pHtmlFile)
  CODE
  SELF.bIsLoaded = FALSE
  SELF.bIsAsyncCompleted = FALSE
  
  SELF.NavigateToFile(pHtmlFile)
  SELF.WaitCompleted()

  IF SELF.bIsLoaded
    !- add 'bridge' host object
    SELF.AddDefaultHostObjectToScript('bridge')
  ELSE
    SELF.TakeError(printf('File %s not found.', pHtmlFile))
  END
  
  RETURN SELF.bIsLoaded
    
TPDFMake2.IsLoaded       PROCEDURE()
  CODE
  RETURN SELF.bIsLoaded

TPDFMake2.SetViewer      PROCEDURE(TClaEdgeBase pViewer)
  CODE
  SELF.viewer &= pViewer
  !- disable some features
  SELF.viewer.AreBrowserAcceleratorKeysEnabled(FALSE)
  SELF.viewer.AreDefaultContextMenusEnabled(FALSE)
  
TPDFMake2.WaitMessage    PROCEDURE(<STRING pHtmlMsg>)
  CODE
  IF pHtmlMsg
    SELF.sWaitMessage = CLIP(pHtmlMsg)
  END
  RETURN CLIP(SELF.sWaitMessage)

TPDFMake2.ErrorPattern   PROCEDURE(<STRING pErrorPattern>)
  CODE
  IF pErrorPattern
    SELF.sErrorPattern = CLIP(pErrorPattern)
  END
  RETURN CLIP(SELF.sErrorPattern)

TPDFMake2.DisplayPdf     PROCEDURE(STRING pPdfFile)
  CODE
  IF NOT SELF.viewer &= NULL AND SELF.viewer.IsInitialized()
    SELF.viewer.NavigateToFile(pPdfFile)
  END
  
TPDFMake2.DisplayMessage PROCEDURE(STRING pMsg, <STRING pParam1>, <STRING pParam2>)
  CODE
  IF pMsg AND NOT SELF.viewer &= NULL AND SELF.viewer.IsInitialized()
    SELF.viewer.NavigateToString(printf(pMsg, pParam1, pParam2))
  END

TPDFMake2.PdfFile        PROCEDURE(<STRING pPdfFile>)
  CODE
  IF NOT OMITTED(pPdfFile)
    SELF.sPdfFile = pPdfFile
  END
  RETURN CLIP(SELF.sPdfFile)

TPDFMake2.MakePdf        PROCEDURE(*TDocDefinition2 dd)
  CODE
  SELF.MakePDF(dd.ToJSON())

TPDFMake2.MakePdf        PROCEDURE(STRING dd)
  CODE
  IF SELF.IsLoaded()
    !- display "Wait a minute...' message
    SELF.DisplayMessage(SELF.sWaitMessage)
    !- execute fnGetPDF script
!    SELF.ExecuteScriptAsync(printf('fnGetPDF(%S)', dd))
    SELF.ExecuteScriptAsync(printf('fnGetPDF(`%s`)', dd))
  ELSE
    SELF.TakeError('Call Load() first.')
  END

TPDFMake2.TakeResult     PROCEDURE(STRING pPdfContents)
sPdfFile                        STRING(256), AUTO
tf                              TTempFile
b64                             TBase64
  CODE
  !- decode and save pdf contents in a file
  IF SELF.sPdfFile
    sPdfFile = LONGPATH(SELF.sPdfFile)
  ELSE
    sPdfFile = tf.GetTempFileName('pdf')
  END
    
  IF NOT tf.SaveFile(sPdfFile, b64.Decode(pPdfContents))
    printd('TPDFMake2.TakeResult: SaveFile(%s) error', sPdfFile)
    RETURN SELF.TakeError(printf('File "%s" not saved, Windows error code %i', sPdfFile, winapi::GetLastError()))
  END

  !- save file in temp queue
  IF NOT SELF.sPdfFile
    SELF.tempFiles.filename = sPdfFile
    ADD(SELF.tempFiles)
    SELF.sPdfFile = sPdfFile
  END
  
  !- display it
  SELF.DisplayPdf(sPdfFile)
  RETURN ''
  
TPDFMake2.TakeError      PROCEDURE(STRING pErrMsg)
  CODE
  printd('TPDFMake2.TakeError(%s)', pErrMsg)
  SELF.DisplayMessage(SELF.sErrorPattern, pErrMsg)
  RETURN ''
  
TPDFMake2.PageHeader     PROCEDURE(LONG pCurrentPage, LONG pPageCount, LONG pPageWidth, LONG pPageHeight)
  CODE
  RETURN ''

TPDFMake2.PageFooter     PROCEDURE(LONG pCurrentPage, LONG pPageCount)
  CODE
  RETURN ''
  
TPDFMake2.OnInitializationCompleted  PROCEDURE()
  CODE
  SELF.IsScriptEnabled(TRUE)
  SELF.IsWebMessageEnabled(TRUE)

  SELF.bIsAsyncCompleted = TRUE

TPDFMake2.OnNavigationCompleted  PROCEDURE(STRING pNavigationId, BOOL pIsSuccess, CoreWebView2WebErrorStatus pWebErrorStatus)
  CODE
  SELF.bIsLoaded = pIsSuccess  
  SELF.bIsAsyncCompleted = TRUE

TPDFMake2.OnHostObjectEvent  PROCEDURE(STRING pObjectName, STRING pEventName, | 
                                    STRING pParam1, STRING pParam2, STRING pParam3, STRING pParam4, STRING pParam5, |
                                    STRING pParam6, STRING pParam7, STRING pParam8, STRING pParam9, STRING pParam10)
  CODE
  CASE pObjectName
  OF 'bridge'
    CASE pEventName
    OF 'error'
      RETURN SELF.TakeError(pParam1)
    OF 'makepdf'
      RETURN SELF.TakeResult(pParam1)
    OF 'header'
      RETURN SELF.PageHeader(pParam1, pParam2, pParam3, pParam4)
    OF 'footer'
      RETURN SELF.PageFooter(pParam1, pParam2)
    ELSE
      printd('OnHostObjectEvent(%S, %S): unknown event.', pObjectName, pEventName)
    END
  ELSE
    printd('OnHostObjectEvent(%S, %S): unknown object.', pObjectName, pEventName)
  END
  
  RETURN ''
  
TPDFMake2.OnScriptException  PROCEDURE(STRING pUri, STRING pErrName, STRING pErrMsg)
  CODE
  PARENT.OnScriptException(pUri, pErrMsg, pErrMsg)
  SELF.TakeError(printf('URI "%s" thrown the exception %s: %s', pUri, pErrName, pErrMsg))
!!!endregion