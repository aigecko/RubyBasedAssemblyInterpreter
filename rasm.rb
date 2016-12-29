#coding: utf-8
class Rasm
  @@VERSION="1.0.319"
  @@op=nil
  class Var
    attr_reader :name
    def initialize(name)
      @name=name
    end
    def ==(o)
      o.class==self.class && o.name==name
    end
    def to_var(hash)
      hash[@name]
    end
  end
  def initialize
    @variables=Hash.new
    @instructions=[]
    @jmp_table=Hash.new
    @line=0
    @@op or init_instruct
  end
  def init_instruct
    @@op=Hash.new
    @@op[:movc]=->(var,klass){
      @variables[var]=Kernel.const_get(klass)
    }
    @@op[:movr]=->(dst,src){
      @variables[dst]=@variables[src]
    }
    @@op[:movi]=->(var,value){
      @variables[var]=value
    }
    
    @@op[:save]=->(var,key,src){
      @variables[var][key]=@variables[src]
    }
    @@op[:call]=->(var,to,fun,*arg){
      @variables[to]=@variables[var].send(fun,*arg)
    }
    
    @@op[:puts]=->(var){
      puts @variables[var]
    }
    @@op[:p]=->(var){
      p @variables[var]
    }
    @@op[:print]=->(var){
      print @variables[var]
    }
    
    @@op[:je]=->(a,b,dst){
      if @variables[a]==@variables[b]
        @line=@jmp_table[dst]
      end
    }
    @@op[:jne]=->(a,b,dst){
      if @variables[a]!=@variables[b]
        @line=@jmp_table[dst]
      end
    }
    @@op[:jmp]=->(dst){
      @line=@jmp_table[dst]
    }    
  end
  def run
    begin
      while @line<@instructions.size
        op,*arg=@instructions[@line]
        @@op[op].call(*arg)
        @line+=1
      end
    rescue =>e
      p e
      print "error inst: "
      p @instructions[@line]
      return
    end
  end
  def load(string)
    string.each_line{|line|
      line.chomp!
      line.strip!
      line.empty? and next

      data=line.match(/(?<label>(#[A-Za-z]\w*))?(?<cmd>.*)?/)
      label=data[:label] and @jmp_table[label]=@instructions.size-1
      data=data[:cmd].match(/(?<opcode>\S+)?\s*(?<oprands>.*)?/)
      data[:opcode] or next
      
      inst=[data[:opcode].to_sym]
      oprands=data[:oprands]
      while oprands=oprands&.match(/\
((?<var>(\$[A-Za-z]\w*))|\
(?<int>([-+]?0|([1-9]\d*)))|\
(?<float>([-+]?0|([1-9]\d*)\.\d*))|\
(?<sym>(\:[^,]+))|\
(?<label>(\#[A-Za-z]\w+))|\
(?<string>(".*")))\
\s*(,\s*(?<others>.*))?/)
        case
        when v=oprands[:var]
          inst<<v[1..-1].to_sym
        when n=oprands[:int]
          inst<<n.to_i
        when f=oprands[:float]
          inst<<f.to_f
        when sym=oprands[:sym]
          inst<<sym[1..-1].to_sym
        when l=oprands[:label]
          inst<<l
        when str=oprands[:string]
          inst<<str[1..-2]
        end

        oprands=oprands[:others]
      end
      @instructions<<inst
    }
  end
end