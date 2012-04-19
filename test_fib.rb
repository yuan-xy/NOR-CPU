#!/usr/bin/ruby

$embedded = true

load 'assembler.rb'  
Assembler.asm("fib.asm")

load 'norcpu.rb'
cpu = NorCpu.new
cpu.load_run()

puts "return: %04X" % cpu.reg(:reg0)
#puts cpu.mem

