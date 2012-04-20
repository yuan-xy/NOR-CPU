a = var
MOVi 1, REG0
MOVi 3, a
JEQi a, 3, :exit   
	MOVi 2, REG0	
label :exit	
	EXITi()
