# NORCPU code

needle = literal Example + "\x00"

i, ch, t, ptr, crc16 = var 5

label :entry  
      MOVi 0xFFFF, crc16
      MOVi needle, ptr
label :crc_loop                  # crc_loop:
      PEEK ptr, ch               #   ch = *ptr
      IS_0 ch                    #   is ch == 0?
      JZi  :exit                 #   if yes, goto "exit"
      ANDi ch, 0xFF, ch          #   ch &= 0xFF
      XOR  crc16, ch, crc16      #   crc16 ^= ch
      MOVi 8, i
label :loop_i                    # crc_loop_i:
      ANDi crc16, 1, t           #   t = crc16 & 1
      SHR crc16, crc16           #   crc16 >>= 1
      IS_0 t                     #   is t == 0?
      JZi :skip_xor              #   if yes, goto "skip_xor"
      XORi crc16, 0x8401, crc16  #   crc16 ^= 0x8401
label :skip_xor                  # skip_xor:
      ADDi i, 0xFFFF, i          #   i -= 1
      IS_0 i                     #   is i == 0?
      JNZi :loop_i               #   if not, goto "loop_i"
      ADDi ptr, 0x0001, ptr      #   ptr += 1
      JMPi :crc_loop             #   goto crc_loop

label :exit
      EXITi()
