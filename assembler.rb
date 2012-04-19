#!/usr/bin/ruby

Text = []
Labels = []
Statics = {}
Consts = {}
Vars = {}
Regs = {}
Literals = {}

def make_label(name = "")
  name = name.to_s
  name = "label_%d" % Labels.size if name.empty?
  Labels.push name
  return name
end


def label(name) Text.push "#" + name.to_s end

def code(value) Text.push "  %s" % value end

def literal(value)
  name = "str_%d" % Literals.size
  Literals[name] = value
  return name
end

def static(*names)
  names.each { |name| Statics[name] = 0 }; names
end

def var(count = 1)
  names = []
  count.times { Vars[(names.push "var_%d" % Vars.size).last] = 0 }
  return names
end

def init_register(name,value)
  Regs[name] = value
  return name
end

def const(value)
  return Consts[value] if Consts.has_key? value
  Consts[value] = "const_%d" % Consts.size
end

IP = init_register("ip",0)
SHIFT_REG = init_register("shift_reg",1)
SP =  init_register("sp",2)
REG0 =  init_register("reg0",3)

CARRY_REG, ZERO_REG = var 2


def NOR(a, b, r)
  code a
  code b 
  code r 
end

def NOT(a, r)
  NOR a, a, r
end

def OR(a, b, r)
  t = static :OR_t
  NOR a, b, t
  NOT t, r 
end

def AND(a, b, r)
  t1, t2 = static :AND_t1, :AND_t2
  NOT a, t1 
  NOT b, t2 
  OR t1, t2, t1
  NOT t1, r
end

def ANDi(a, imm, r)
  t = static :ANDi_t
  MOVi imm, t
  AND a, t, r
end

def XOR(a, b, r)
  t1, t2 = static :XOR_t1, :XOR_t2
  NOT a, t1
  NOT b, t2
  AND a, t2, t2
  AND b, t1, t1
  OR t1, t2, r
end

def XORi(a, imm, r)
  t = static :XORi_t
  MOVi imm, t
  XOR a, t, r
end

def MOV(a, b)
  OR a, a, b
end

def JMP(a)
  MOV a, IP
end

def JMPi(a)
  JMP const(a)
end

def MOVi(imm, a)
  MOV const(imm), a         
end

# [a] -> b
def PEEK(a, b)
  l1 = make_label
  l2 = make_label
  MOV a, l1
  MOV a, l2
  t = static :PEEK_t
  # BEGIN: NOR 0, 0, t
label l1   
  code const(0)   # <- a [initially '0']
label l2
  code const(0)   # <- a [initialli '0']
  code t
  # END: NOT 0, 0, t 
  NOT t, b
end

# a -> [b]
def POKE(a, b)
  l = make_label
  MOV b, l
  t = static :POKE_t
  NOT a, t
  # BEGIN: NOR t, t, 0
  code t
  code t
label l
  code const(0)   # <- b [initially '0']
  # END: NOR t, t, 0
end

def PUSH(a)
  POKE a,SP
  ADDi SP, 1, SP
end

def POP(a)
  ADDi SP, -1, SP
  PEEK SP, a
end

def CALL(prog)
  label_call = make_label
  call_t = static :CALL_t
  MOV SP, call_t
  PUSH const(label_call)
  PUSH call_t
  JMPi prog
label label_call  
end

def RET
  ret_t1,ret_t2  = static :RET_t1, :RET_t2
  POP ret_t1
  POP ret_t2
  MOV ret_t1, SP
  MOV ret_t2, IP
end

def EXITi
  MOVi 0xFFFF, IP
end

def FADD(mask, carry, a, b, r)
  tmp_a, tmp_b, bit_r = static :FADD_a, :FADD_b, :FADD_bit_r
  t1, t2 = static :FADD_t1, :FADD_t2

  AND a, mask, tmp_a      # zeroing bits in 'a' except mask'ed
  AND b, mask, tmp_b      # zeroing bits in 'b' except mask'ed
  AND carry, mask, carry  # zeroing bits in 'carry' except mask'ed

  # SUM = (a ^ b) ^ carry
  XOR a, b, t1
  XOR t1, carry, bit_r

  # Leave only 'mask'ed bit in bit_r.
  AND bit_r, mask, bit_r

  # Add current added bit to the result.
  OR bit_r, r, r

  # CARRY = (a & b) | (carry & (a ^ b))
  AND a, b, t2
  AND carry, t1, t1

  # CARRY is calculated, and 'shift_reg' contains the same value
  # but shifted to the left by 1 bit.
  OR t2, t1, carry

  # CARRY is shifted to the left by 1 bit for the next round.
  MOV SHIFT_REG, carry

  # shift_reg = mask << 1
  MOV mask, mask 
  # mask = shift (in fact, "mask = mask << 1")
  MOV SHIFT_REG, mask 

  AND carry, mask, carry
end

def ZERO(a)
  XOR a, a, a
end

def ADC(a, b, r)
  mask, t = static :ADC_mask, :ADC_t
  ZERO t
  MOVi 0x0001, mask
  16.times { FADD mask, CARRY_REG, a, b, t }
  MOV t, r

  ZERO t
  16.times do
    OR t, CARRY_REG, t
    MOV CARRY_REG, CARRY_REG
    MOV SHIFT_REG, CARRY_REG
  end
  MOV t, CARRY_REG
end

def ADD(a, b, r)
  ZERO CARRY_REG
  ADC a, b, r
end

def ADDi(a, imm, r)
  t = static :ADDi_t
  MOVi imm, t
  ADD a, t, r
end

# Jump 'a', if cond = FFFF, and 'b' if cond = 0000
def BRANCH(a, b, cond)
  t1, t2 = static :BRANCH_t1, :BRANCH_t2
  AND a, cond, t1     # t1 = a & cond
  NOT cond, t2        # t2 = !cond
  AND b, t2, t2       # t2 = b & t2 = b & !cond
  OR t1, t2, IP       # ip = (a & cond) | (b & !cond)
end

# Jump 'a', if cond = FFFF, and 'b' if conf = 0000
def BRANCHi(a, b, cond)
  BRANCH const(a), const(b), cond
end

# if a != 0 -> zero = FFFF else zero = 0000
def IS_0(a)
  t = static :IS_0_t
  ZERO CARRY_REG
  ADC a, const(0xFFFF), t
  NOT CARRY_REG, ZERO_REG
end

# ip = (zero_reg == FFFF ? a : ip)
def JZi(a)
  bypass = make_label
  BRANCHi a, bypass, ZERO_REG
label bypass
end

# ip = (zero_reg == FFFF ? a : ip)
def JNZi(a)
  bypass = make_label
  BRANCHi bypass, a, ZERO_REG
label bypass
end

def ROL(a, b)
  MOV a, a             # shift_reg = a << 1
  MOV SHIFT_REG, b
end

def ROR(a, b)
  t = static :ROR_t
  MOV a, t
  15.times { ROL t, t }
  MOV t, b
end

def SHL(a, b)
  ROL a, b 
  ANDi b, 0xFFFE, b
end

def SHR(a, b)
  ROR a, b 
  ANDi b, 0x7FFF, b
end

class Assembler
  
  def self.parse(asm_file)
    load asm_file
  end
  
  def self.dump(obj_file)
    
    assembly = []
    Regs.each {|k,v| assembly.push 0 }
    Text.each { |x| assembly.push x }
    Vars.each { |k, v| assembly.push "#%s" % k, v }
    Statics.each { |k, v| assembly.push "#%s" % k, v }
    Consts.each { |k, v| assembly.push "#%s" % v, k }
    Literals.each do |k, v|
      assembly.push "#%s" % k
      v.each_byte { |x| assembly.push x }
    end

    offset = 0
    labels = {}
    assembly.each do |x|
      x = x.to_s
      if x.start_with? '#' then
        labels[x[1..-1]] = offset
      else 
        offset = offset + 1
      end
    end
    
    #debugger
    
    # Remove all list having labels.
    assembly.delete_if { |x| x.to_s.start_with? "#" }

    Regs.each { |k, v| labels[k]=v }
    assembly[Regs[SP]] = assembly.size
    
    # Substitute labels by values.
    assembly.collect! do |x| 
      if x.class==String ||  x.class==Symbol
        labels[x.to_s.strip]
      else
        x
      end
    end
    
    #debugger
    #assembly[labels[SP]] = assembly.size
    
    #puts assembly

    File.open(obj_file,"wb") do |f|
      f << assembly.pack("S*")
    end
  end
  
  def self.asm(asm_file, obj_file="a.out")
    Assembler.parse(asm_file)
    Assembler.dump(obj_file)
  end
end


unless $embedded
  if ARGV.size==0
    puts "usage: ruby #{__FILE__} asm_file [obj_file]"
    exit
  elsif ARGV.size==1
    Assembler.asm(ARGV[0])
  else
    Assembler.asm(ARGV[0],ARGV[1])
  end
end

