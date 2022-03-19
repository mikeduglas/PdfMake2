!* PDFMake2
!* Easy Edge (Chromium) v1.06 and higher required.
!* v01.01

  INCLUDE('claedge.inc'), ONCE

!- available page sizes; use it as page size selector: ?droplist{prop:from} = PDF::PageSizes
PDF::PageSizes                STRING('4A0|2A0|A0|A1|A2|A3|A4|A5|A6|A7|A8|A9|A10|B0|B1|B2|B3|B4|B5|B6|B7|B8|B9|B10|C0|C1|C2|C3|C4|C5|C6|C7|C8|C9|C10|RA0|RA1|RA2|RA3|RA4|SRA0|SRA1|SRA2|SRA3|SRA4|EXECUTIVE|FOLIO|LEGAL|LETTER|TABLOID')

TPDFMake2                CLASS(TClaEdgeFileViewer), TYPE, MODULE('PDFMake2.clw'), LINK('PDFMake2.clw')
bIsLoaded                       BOOL, PROTECTED
bIsAsyncCompleted               BOOL, PROTECTED
sPdfFile                        STRING(256), PROTECTED      !-- output file
sDdFile                          STRING(256), PROTECTED      !-- dd file
tempFiles                       &TTempFilesQ, PRIVATE       !-- list of temp files; they will be purged in descructor

viewer                          &TClaEdgeBase, PROTECTED    !-- pdf viewer
sWaitMessage                    ANY, PROTECTED              !- wait message to display in the viewer
sErrorPattern                   ANY, PROTECTED

Construct                       PROCEDURE()
Destruct                        PROCEDURE(), DERIVED

!!!<summary>Waits for async operation completion</summary>
!!!<param name="pTimeout">Timeout walue in hudredths of a second.</param>
WaitCompleted                   PROCEDURE(LONG pTimeout=10), PROTECTED

Init                            PROCEDURE(<STRING browserExecutableFolder>, | 
                                  <STRING userDataFolder>, | 
                                  <STRING language>, | 
                                  <STRING additionalBrowserArguments>, |
                                  BOOL allowSingleSignOnUsingOSPrimaryAccount=FALSE), BOOL, PROC, DERIVED

Kill                            PROCEDURE(), DERIVED

!!!<summary>Loads pdfMake scripts.</summary>
!!!<param name="pHtmlFile">HTML file with the scripts.</param>
!!!<returns>false on error.</returns>
Load                            PROCEDURE(STRING pHtmlFile), BOOL PROC, VIRTUAL
!!!<summary>Returns loaded state.</summary>
IsLoaded                        PROCEDURE(), BOOL
!!!<summary>Sets PDF viewer.</summary>
!!!<param name="pViewer">TClaEdgeBase instance.</param>
SetViewer                       PROCEDURE(TClaEdgeBase pViewer)
!!!<summary>Gets or sets wait message.</summary>
!!!<param name="pHtmlMsg">HTML message.</param>
WaitMessage                     PROCEDURE(<STRING pHtmlMsg>), STRING, PROC
!!!<summary>Gets or sets error message pattern.</summary>
!!!<param name="pErrorPattern">HTML pattern.</param>
ErrorPattern                    PROCEDURE(<STRING pErrorPattern>), STRING, PROC

DisplayPdf                      PROCEDURE(STRING pPdfFile)
DisplayMessage                  PROCEDURE(STRING pMsg, <STRING pParam1>, <STRING pParam2>)

!!!<summary>Gets or sets PDF file.</summary>
PdfFile                         PROCEDURE(<STRING pPdfFile>), STRING, PROC

MakePdf                         PROCEDURE(*TDocDefinition2 dd), VIRTUAL
MakePdf                         PROCEDURE(STRING dd), VIRTUAL

!!!<summary>Takes base64 encoded PDF contents and displays it in the viewer.</summary>
!!!<param name="pPdfContents">PDF contents.</param>
TakeResult                      PROCEDURE(STRING pPdfContents), STRING, PROC, VIRTUAL, PROTECTED
!!!<summary>Takes an error and displays it if PDF viewer is enabled.</summary>
!!!<param name="pErrMsg">Error message.</param>
TakeError                       PROCEDURE(STRING pErrMsg), STRING, PROC, VIRTUAL, PROTECTED
!!!<summary>Returns page header.</summary>
!!!<param name="pCurrentPage">Current page number.</param>
!!!<param name="pPageCount">Total pages.</param>
!!!<param name="pPageWidth">Page width.</param>
!!!<param name="pPageHeight">Page height.</param>
PageHeader                      PROCEDURE(LONG pCurrentPage, LONG pPageCount, LONG pPageWidth, LONG pPageHeight), STRING, VIRTUAL, PROTECTED
!!!<summary>Returns page footer.</summary>
!!!<param name="pCurrentPage">Current page number.</param>
!!!<param name="pPageCount">Total pages.</param>
PageFooter                      PROCEDURE(LONG pCurrentPage, LONG pPageCount), STRING, VIRTUAL, PROTECTED

OnInitializationCompleted       PROCEDURE(), DERIVED, PROTECTED
OnNavigationCompleted           PROCEDURE(STRING pNavigationId, BOOL pIsSuccess, CoreWebView2WebErrorStatus pWebErrorStatus), DERIVED, PROTECTED
OnHostObjectEvent               PROCEDURE(STRING pObjectName, STRING pEventName, | 
                                  STRING pParam1, STRING pParam2, STRING pParam3, STRING pParam4, STRING pParam5, |
                                  STRING pParam6, STRING pParam7, STRING pParam8, STRING pParam9, STRING pParam10), STRING, DERIVED, PROTECTED
OnScriptException               PROCEDURE(STRING pUri, STRING pErrName, STRING pErrMsg), DERIVED, PROTECTED
                              END
