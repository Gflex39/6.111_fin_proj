


with open("/Users/seblohier/6.111/6.111_fin_proj/mapgen/art.txt") as s:
    f = open("/Users/seblohier/6.111/6.111_fin_proj/mapgen/map3.mem","a")
    for i in s:
        for j in i:
            f.write(j+"\n")
            

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



    