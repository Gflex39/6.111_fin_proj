def wall(i,j):
    if i==0 or i==89 or j==0 or j==159: return True
    if i in {29,30,31} and j<100: return True
    if i in {59,60,61} and j>60: return True
    if j==140 and 75<i<85: return True
    return False

def sand(i,j):
    if (115<j<140 and i>60): return True
    if (60<j<80 and i<30): return True
    return False


f = open("map2.txt","a")
for i in range(90):
    for j in range(160):
        if((i==80) and (j==150)):
            f.write("0\n")
        elif(wall(i,j)):
            f.write("1\n")
        elif(sand(i,j)):
            f.write("3\n")
        else:
            f.write("2\n")
f.close()



    