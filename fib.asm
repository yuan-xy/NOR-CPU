
a = var
label :entry  
		MOVi 3, a
		PUSH a
		CALL :fib
		EXITi()
label :fib  
		ADDi SP, -3, REG0
		PUSH REG2
		PEEK REG0, REG2
		JNEQi REG2, 1, :not1
		MOVi 1, REG0
		POP REG2
		RET()
label :not1
		JNEQi REG1, 2, :not2
		MOVi 1, REG0
		POP REG2
		RET()
label :not2
		ADDi REG2, -1, REG0
		PUSH REG0
		CALL :fib
		MOV REG0, REG1
		ADDi REG2, -2, REG0
		PUSH REG0
		CALL :fib
		ADD REG0, REG1, REG0
		POP REG2
		RET()			
		