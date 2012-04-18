
mem = []

File.open("a.out") do |f|
  mem = f.read.unpack("S*")
end

puts mem

def nor(a, b)
  ~(a | b) & 0xFFFF
end

#ip = labels[IP]
#shift_reg = labels[SHIFT_REG]

ip = 1
shift_reg = 2

puts "program mem size: %d" % mem.size
while true do
  i = mem[ip]
  a = mem[i + 0]
  b = mem[i + 1]
  r = mem[i + 2]
  mem[ip] = i + 3
  f = nor(mem[a], mem[b])
  mem[r] = f
  mem[shift_reg] = ((f >> 15) & 1) | ((f & 0x7FFF) << 1)
  break if mem[ip] == 0xFFFF
end

# puts "NOR CPU CRC16: %04X" % mem[labels[crc16]]
puts "NOR CPU CRC16: %04X" % mem[0]


