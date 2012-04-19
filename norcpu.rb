#!/usr/bin/ruby

class NorCpu
  @@REGS = [:ip, :shift_reg, :reg0]
  @mem = []
  
  attr_reader :mem

  def self.nor(a, b)
    ~(a | b) & 0xFFFF
  end

  def self.reg_index(name)
    @@REGS.index(name)
  end
    
  def reg(name)
    @mem[NorCpu.reg_index(name)]
  end

  def reg_set(name,value)
    @mem[NorCpu.reg_index(name)] = value
  end
    
  def load(obj_file)
    File.open(obj_file) do |f|
      @mem = f.read.unpack("S*")
    end
  end
  
  def run
    ip = NorCpu.reg_index(:ip)
    shift_reg = NorCpu.reg_index(:shift_reg)
    reg0 = NorCpu.reg_index(:reg0)
    @mem[ip] = @@REGS.size

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






