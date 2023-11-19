f = open("map1.txt","a")
for i in range(90):
    for j in range(160):
        if((i==45) and (j==80)):
            f.write("0\n")
        elif(j<101 and j>59 and i in {34,35,54,55}):
            f.write("1\n")
        elif(i>35 and i<54 and j in {60,61,99,100}):
            f.write("1\n")
        else:
            f.write("2\n")
f.close()