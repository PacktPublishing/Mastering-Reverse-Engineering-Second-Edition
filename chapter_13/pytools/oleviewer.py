
import olefile

ole = olefile.OleFileIO("samples/g.doc")
for d in ole.listdir():
    fpath = "/".join(d)
    print(fpath)

