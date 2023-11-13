import sys
import math

def main():
    with open(f'sin_lookup.mem', 'w') as f_sin:
        f_sin.write('\n'.join(["{0:#0{1}x}".format(int(math.sin(math.radians(angle))*256), 6)[2:] for angle in range(90)]))

    with open(f'cos_lookup.mem', 'w') as f_cos:
        f_cos.write('\n'.join(["{0:#0{1}x}".format(int(math.cos(math.radians(angle))*256), 6)[2:] for angle in range(90)]))


    print('done')





if __name__ == "__main__":
    main()
    


