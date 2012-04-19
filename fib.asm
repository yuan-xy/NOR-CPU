
c = var
label :entry  
		PUSH const(13)
		CALL :fib
		EXITi()
label :fib  
		ADDi SP, -3, REG0
		PEEK REG0, c
		ADDi c, 1, REG0
		RET()