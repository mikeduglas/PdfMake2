!* Base64 encoding.
!* Mike Duglas 2021

  MEMBER

  MAP
    Base64::EncodeBlock(STRING in, *STRING out, LONG len), PRIVATE
  END

  INCLUDE('b64.inc'), ONCE

!-- Base64 encoding
cb64                          STRING('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/')
DECODED_BUF_SIZE              EQUATE(54)    !54 characters per line
ENCODED_BUF_SIZE              EQUATE(72)    !54 * 4 / 3

!!!region Helper functions
Base64::EncodeBlock           PROCEDURE(STRING in, *STRING out, LONG len)
  CODE
!  {
!  out[0] = cb64[ in[0] >> 2 ];
!  out[1] = cb64[ ((in[0] & 0x03) << 4) | ((in[1] & 0xf0) >> 4) ];
!  out[2] = (unsigned char) (len > 1 ? cb64[ ((in[1] & 0x0f) << 2) | ((in[2] & 0xc0) >> 6) ] : '=');
!  out[3] = (unsigned char) (len > 2 ? cb64[ in[2] & 0x3f ] : '=');
!  }

  ASSERT(LEN(in) = 3 AND LEN(out) = 4)
  out[1] = cb64[BSHIFT(VAL(in[1]), -2) + 1]
  out[2] = cb64[BOR(BSHIFT(BAND(VAL(in[1]), 003h), 4), BSHIFT(BAND(VAL(in[2]), 0f0h), -4)) + 1]
  IF len > 1
    out[3] = cb64[BOR(BSHIFT(BAND(VAL(in[2]), 00fh), 2), BSHIFT(BAND(VAL(in[3]), 0c0h), -6)) + 1]
  ELSE
    out[3] = '='
  END
  IF len > 2
    out[4] = cb64[BAND(VAL(in[3]), 03fh) + 1]
  ELSE
    out[4] = '='
  END
!!!endregion

!!!region TBase64
TBase64.Encode                PROCEDURE(STRING input_buf)
input_size                      LONG, AUTO
output_buf                      STRING((LEN(input_buf)/DECODED_BUF_SIZE + 1) * ENCODED_BUF_SIZE)
in                              STRING(3), AUTO
out                             STRING(4), AUTO
iIndex                          LONG, AUTO
block_size                      LONG, AUTO    !block size
sIndex                          LONG, AUTO    !pos in input_buf
n_block                         LONG, AUTO    !block number
  CODE
  input_size = LEN(input_buf)
  n_block = 0
  
  LOOP sIndex = 1 TO input_size BY 3
    block_size = 0
    LOOP iIndex = 1 TO 3
      IF sIndex + (iIndex - 1) <= input_size
        in[iIndex] = input_buf[sIndex + (iIndex - 1)]
        block_size += 1
      ELSE
        in[iIndex] = 0
      END
    END
    
    IF block_size
      Base64::EncodeBlock(in, out, block_size)

      n_block += 1
      output_buf[(n_block - 1) * 4 + 1 : n_block * 4] = out
    END
  END
  
  RETURN CLIP(output_buf)

TBase64.Encode                PROCEDURE(*BLOB input_buf)
  CODE
  IF input_buf &= NULL OR input_buf{PROP:Size} = 0
    RETURN ''
  END
  
  RETURN SELF.Encode(input_buf[0 : input_buf{PROP:Size} - 1])

!https://stackoverflow.com/questions/342409/how-do-i-base64-encode-decode-in-c
TBase64.Decode                PROCEDURE(STRING input_buf)
B64index                        LONG, DIM(256), STATIC
in_len                          LONG, AUTO
out_buf                         STRING((LEN(input_buf) / 4) * 3 + 3)
L                               LONG, AUTO
out_len                         LONG, AUTO
pad                             LONG, AUTO
i                               LONG, AUTO
j                               LONG, AUTO
n                               LONG, AUTO
b1                              LONG, AUTO
b2                              LONG, AUTO
b3                              LONG, AUTO
b4                              LONG, AUTO
c1                              BYTE, AUTO
c2                              BYTE, AUTO
c3                              BYTE, AUTO
c4                              BYTE, AUTO

  CODE
  in_len = LEN(input_buf)
  IF in_len = 0
    RETURN ''
  END
  
  IF B64index[44] = 0
    DO Build_B64
  END
  
  IF (in_len % 4) OR (input_buf[in_len] = '=')
    pad = 1
  ELSE
    pad = 0
  END
  
  L = ((INT((in_len + 3) / 4) - pad) * 4)
  out_len = INT(L / 4) * 3 + pad
  
  j = 1
  LOOP i = 1 TO L BY 4
    c1 = VAL(input_buf[i+0])+1
    c2 = VAL(input_buf[i+1])+1
    c3 = VAL(input_buf[i+2])+1
    c4 = VAL(input_buf[i+3])+1
    b1 = BSHIFT(B64index[c1], 18)
    b2 = BSHIFT(B64index[c2], 12)
    b3 = BSHIFT(B64index[c3], 6)
    b4 = B64index[c4]
    n = BOR(b1, BOR(b2, BOR(b3, b4)))
    b1 = BSHIFT(n, -16)
    b2 = BAND(BSHIFT(n, -8), 0FFh)
    b3 = BAND(n, 0FFh)
    out_buf[j] = CHR(b1); j += 1
    out_buf[j] = CHR(b2); j += 1
    out_buf[j] = CHR(b3); j += 1
  END

  IF pad
    c1 = VAL(input_buf[L+1])+1
    c2 = VAL(input_buf[L+2])+1
    b1 = BSHIFT(B64index[c1], 18)
    b2 = BSHIFT(B64index[c2], 12)
    n = BOR(b1, b2)
    b1 = BSHIFT(n, -16)
    out_buf[out_len] = CHR(b1)

    IF (in_len > L + 2) AND (input_buf[L + 3] <> '=')
      c1 = VAL(input_buf[L + 3])+1
      b1 = BSHIFT(B64index[c1], 6)
      n = BOR(n, b1)
      b1 = BAND(BSHIFT(n, -8), 0FFh)
      out_buf[out_len] = CHR(b1)
    END
  END
  
  RETURN out_buf[1 : out_len]
  
Build_B64                     ROUTINE
  !-- build static table
  B64index[44] = 62;  B64index[45] = 63;  B64index[46] = 62;  B64index[47] = 62;  B64index[48] = 63
    
  LOOP i = 52 TO 61
    B64index[i - 3] = i
  END
    
  LOOP i = 1 TO 25
    B64index[i + 66] = i
  END
    
  B64index[96] = 63
    
  LOOP i = 26 TO 51
    B64index[i + 72] = i
  END
!!!endregion
