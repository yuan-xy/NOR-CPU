#!/usr/bin/ruby

class NorCpu
  
  @mem = []

  def self.nor(a, b)
    ~(a | b) & 0xFFFF
  end
  
  def load(obj_file)
    File.open(obj_file) do |f|
      @mem = f.read.unpack("S*")
    end
  end
  
  def run
    ip = 0
    shift_reg = 1
    reg0 = 2
    @mem[ip] = 3

    puts "program @mem size: %d" % @mem.size
    while true do
      i = @mem[ip]
      a = @mem[i + 0]
      b = @mem[i + 1]
      r = @mem[i + 2]
      @mem[ip] = i + 3
      f = NorCpu.nor(@mem[a], @mem[b])
      @mem[r] = f
      @mem[shift_reg] = ((f >> 15) & 1) | ((f & 0x7FFF) << 1)
      break if @mem[ip] == 0xFFFF
    end

    puts "NOR CPU CRC16: %04X" % @mem[reg0]
  end
  
  def load_run(obj_file="a.out")
    load(obj_file)
    run
  end

end


unless $embedded
  if ARGV.size==0
    NorCpu.new.load_run
  else
    NorCpu.new.load_run(ARGV[0])
  end
end






