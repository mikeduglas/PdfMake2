!* Base64 encoding.
!* Mike Duglas 2021

TBase64                       CLASS, TYPE, MODULE('b64.clw'), LINK('b64.clw')
Encode                          PROCEDURE(STRING input_buf), STRING
Encode                          PROCEDURE(*BLOB input_buf), STRING
Decode                          PROCEDURE(STRING input_buf), STRING
                              END
