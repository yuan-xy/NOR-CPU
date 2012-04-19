#!/usr/bin/ruby

$embedded = true

load 'assembler.rb'  
Assembler.asm("crc16.asm","nor.bin")

load 'norcpu.rb'
cpu = NorCpu.new
cpu.load_run("nor.bin")

puts "NOR CPU CRC16: %04X" % cpu.reg(:reg0)
#puts cpu.mem

def calc_crc16(data)
  crc = 0xFFFF
  data.each_byte do |x|
    crc = crc ^ (x & 0xFF)
    8.times do
      shift = (crc & 1) != 0
      crc = crc >> 1 
      crc = crc ^ 0x8401 if shift 
    end
  end
  return crc
end

puts "Ruby CRC16: %04X" % calc_crc16("String for testing")
