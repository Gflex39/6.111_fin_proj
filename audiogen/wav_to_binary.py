import wave

w = wave.open("bounce.wav", "rb")
binary_data = w.readframes(w.getnframes())
with open(f'bounce.mem', 'w') as fout:
  fout.write('\n'.join(["{:02x}".format(elt) for elt in binary_data]))
w.close()