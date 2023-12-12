


with open("/Users/seblohier/6.111/6.111_fin_proj/mapgen/fullsauce.txt") as s:
    f = open("/Users/seblohier/6.111/6.111_fin_proj/data/map4.mem","a")
    for i in s:
        for j in i:
            if j=="-":
                f.write("A\n")
            elif j=="=":
                f.write("B\n")
            elif j!="\n":
                f.write(j+"\n")
            else:
                print(j)
            

    # for i in range(90):
    #     for j in range(160):
    #         if((i==80) and (j==150)):
    #             f.write("0\n")
    #         elif(wall(i,j)):
    #             f.write("1\n")
    #         elif(sand(i,j)):
    #             f.write("3\n")
    #         else:
    #             f.write("2\n")
    # f.close()



    