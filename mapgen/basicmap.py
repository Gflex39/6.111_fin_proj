f = open("map1.txt","a")
for i in range(128):
    for j in range(128):
        if((i==64 or i==63) and (j ==64 or j==63)):
            f.write("00\n")
        elif(j<90 and j>37 and i in {51,52,75,76}):
            f.write("01\n")
        elif(i>52 and i<75 and j in {38,39,88,89}):
            f.write("01\n")
        else:
            f.write("10\n")
f.close()