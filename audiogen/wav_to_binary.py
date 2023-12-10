import wave

w = wave.open("hole.wav", "rb")
binary_data = w.readframes(w.getnframes())
with open(f'hole.mem', 'w') as fout:
  fout.write('\n'.join(["{:02x}".format(binary_data[i]) for i in range(0, 65536)]))
w.close()