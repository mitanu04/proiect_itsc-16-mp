import sys

if __name__ == '__main__':
    file_input = open("RISC_input.txt",'r')
    file_output = open("RISC_MC.txt",'w+')
    commands = file_input.readlines()
    command_list=["LDW","STW","MOV","HLT","RST","INT","IN","OUT","CH",
                "RET","ADD","SUB","MUL","DIV","MVN","OR","AND","ORN","ANDN",
                "EOR","EON","LSL","LSR","ASR","REV","J","JZ","JNZ","JC",
                "JNS","JO","JNO","JP","JNP","JG","JL","JNG","JNL","CMP",
                "MOD"]
            
    regs_list=["R0","R1","R2","R3","R4","R5","R6","R7"]
    getbinary = lambda x, n: format(x, 'b').zfill(n)
    
    jump_instructions={
       "J":25,"JZ":26,"JNZ":27,"JC":28,
       "JNS":29,"JO":30,"JNO":31,"JP":32,
       "JNP":33,"JG":34,"JL":35,"JNG":36,"JNL":37
    }
    
    for command in commands:
        if command.strip():
            words = command.split(" ")
            if words[0] == 'IN':
                print("INPUT NOT WORKING D:\nPLEASE USE MOV INSTEAD.")
                exit(1)
            if words[0] == 'HLT':
                file_output.write('0000110000000000')
                exit(1)
            elif words[0] in jump_instructions:
                command_number=jump_instructions[words[0]]
                file_output.write(getbinary(command_number, 6))
                file_output.write('1')
                command_number=int(words[2])
                file_output.write(getbinary(command_number, 9)+'\n')
            else:
                if words[0] in command_list:
                    command_number=command_list.index(words[0])
                    file_output.write(getbinary(command_number, 6))
                else :
                    print("OPERATION UNKNOWN: "+str(words[0]))
                    exit(1)
                
                if words[1] == 'r':
                    file_output.write('0')
                    if (words[2].strip() in regs_list) and (words[3].strip() in regs_list) :
                        command_number=regs_list.index(str(words[2].strip()))
                        file_output.write(getbinary(command_number, 3))
                        command_number=regs_list.index(str(words[3].strip()))
                        file_output.write(getbinary(command_number, 3))
                        file_output.write('000'+'\n')
                    else: 
                        print("REGS UNKNOWN: ---"+str(words[2])+"------"+str(words[3].strip())+"---")
                        exit(1)
                elif words[1] == 'i':
                    file_output.write('1')
                    if words[2].strip() in regs_list :
                        command_number=regs_list.index(str(words[2].strip()))
                        file_output.write(getbinary(command_number, 3))
                        
                        command_number=words[3].strip("#")
                        file_output.write(getbinary(int(command_number), 6)+'\n')
                else : 
                    print("PREFIX UNKNOWN: "+str(words[1]))
                    exit(1)
    sys.exit(0)