# Source file
filename = "flower.hex"
# Result file
resultfilename = "result_hex.hex"
# Result file
resultfilename3hex = "result_3hex.hex"


file = open(filename, "rb")

resultFile = open(resultfilename, 'a')
result3hexFile = open(resultfilename3hex, 'a')


toHex = lambda x: "".join("0x{:02X}".format(ord(c)) for c in x)
index = 1
try:
    source = file.read()
    print("Len:", len(source))
    for i in range(0, len(source), 3):
        if (i + 2) < len(source):
            print("i=", i)
            hex1 = source[i]
            hex2 = source[i+1]
            hex3 = source[i+2]
            print(toHex(hex1) + ":" + toHex(hex2) + ":" + toHex(hex3) + " = " + str(ord(hex1)) + ":" + str(ord(hex2)) + ":" + str(ord(hex3)))


            y = 0.299 * ord(hex1) + 0.587 * ord(hex2) + 0.114 * ord(hex3) - 128
            yStr = chr(0)
            # Converting to unsigned byte
            if int(y) >= 0:
                yStr = chr(int(y))
            print("Y=" + str(y) + "; YByte=", yStr)
            resultFile.write(yStr)
            # Repeating 3 times
            result3hexFile.write(yStr)
            result3hexFile.write(yStr)
            result3hexFile.write(yStr)

            index += 1

finally:
    file.close()
    resultFile.close()

print("Calculations completed:", index)