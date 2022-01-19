
import openpyxl
import xlrd2
import zipfile
import oletools.olevba
import oletools.oleid
import hashlib
import sys
import os
from win32com.client import Dispatch

def get_doc_type(fname, ftype):
    doctype = "Unknown"
    if ftype == "ZIP":
        zf = zipfile.ZipFile(fname)
        for z in zf.filelist:
            if z.filename.startswith("word/"):
                doctype = "DOC"
                break
            if z.filename.startswith("xl/"):
                doctype = "XL"
                break
    elif ftype == "OLE":
        oid = oletools.oleid.OleID(fname)
        i = oid.check()
        if i[2].value.lower().endswith(b" word"):
            doctype = "DOC"
        elif i[2].value.lower().endswith(b" excel"):
            doctype = "XL"
            
    return doctype

def process_file(fname, ftype):
    dtype = get_doc_type(fname, ftype)
    print("[*] Type: {0}".format(dtype))
    if dtype == "Unknown":
        print("[X] ERROR: Unsupported Document Type.")
        return 1
    
    if dtype == "XL" and ftype == "ZIP":
        get_xlopenxml_info(fname)
        get_vba_macro(fname)
    
    if dtype == "XL" and ftype == "OLE":
        get_xlole_info(fname)
        get_vba_macro(fname)
    
    if dtype == "DOC":
        get_vba_macro(fname)


def file_info(fname):
    ftype = "Unknown"
    dtype = "Unknown"
    print("[*] Filename: {0}".format(os.path.basename(fname)))
    print("[*] Size: {0}".format(os.path.getsize(fname)))
    with open(fname,"rb") as mf:
        d = mf.read(4)
        if d[0:4] == b'\xD0\xCF\x11\xE0':
            ftype = "OLE"
        elif d[0:2] == b'PK':
            ftype = "ZIP"
        print("[*] MD5: {0}".format(hashlib.md5(mf.read()).hexdigest().upper()))
        print("[*] SHA-512: {0}".format(hashlib.sha512(mf.read()).hexdigest().upper()))
    
    return ftype        
     

def get_xlopenxml_info(fname):
    xlworkbook = openpyxl.load_workbook(filename=fname, keep_vba=True)
    print("[*] ---------Excel Content Info--------")
    sheets = xlworkbook.worksheets

    dn = xlworkbook.defined_names
    print("[*] Defined Names: (Name, Reference-To)")
    for n in dn.definedName:
        print("[*]   {0} -> {1}".format(n.name, n.attr_text))

    print("[*]")
    print("[*] Worksheets: (Name (Sheet State))")
    for ws in sheets:
        print("[*] {0}{1} ({2}) - Embedded FORMULA".format(" "*2,ws.title, ws.sheet_state))
        for r in ws.iter_rows():
            for x in r:
                if x.value != None:
                    if x.data_type == 'f':
                        print("[*] {0}${1}${2} -> {3}".format(" "*4,x.column_letter, x.row, x.value))
        print("[*]")

    xlworkbook.close()

def get_xlole_info(fname):
    print("[*] ---------Excel Content Info--------")
    xlbook = xlrd2.open_workbook(fname)
    ws = xlbook.sheets()
    print("[*] Worksheets: (Name (Sheet State))")
    sheet_state = 0
    for s in ws:
        if s.visibility == 0:
            sheet_state = "visible"
        elif s.visibility == 1:
            sheet_state = "hidden"
        elif s.visibility == 2:
            sheet_state = "very hidden"
        print("[*] {0}{1} ({2})".format(" "*2, s.name, sheet_state))
        for r in s.get_rows():
            for v in r:
                if v.ctype == 4:
                    print("[*] {0}R{1}C{2} -> {3}".format(" "*4, v.row+1, v.column+1, v.formula))
                elif v.ctype == 1:
                    print("[*] {0}R{1}C{2} -> {3}".format(" "*4, v.row+1, v.column+1, v.value))



def get_vba_macro(fname):
    vba = oletools.olevba.VBA_Parser(fname)
    macros = vba.extract_all_macros()
    for m in macros:
        print("[*] ----------VBA Source Code----------")
        print("{0}".format(m[3]))
        print("[*] -----------------------------------")

    if vba.detect_xlm_macros():
        print("[*] ------------XLM Macros-------------")
        for n in vba.xlm_macros:
            print(n)
        print("[*] -----------------------------------")


def unhide_xlsheets(fname):
    ftype = file_info(fname)
    print("[*] -----------Worksheets------------")
    xl = Dispatch('Excel.Application')
    xl.DisplayAlerts = False
    wb = xl.Workbooks.Open(os.path.abspath(fname))

    for ws in wb.Sheets:
        sheet_status = "visible"
        if ws.Visible == 0:
            print("[*] {0} (hidden)".format(ws.Name))
            ws.Visible = -1
            print("[*] {0} (now visible)".format(ws.Name))
        elif ws.Visible == 1:
            print("[*] {0} (very hidden)".format(ws.Name))
            ws.Visible = -1
            print("[*] {0} (now visible)".format(ws.Name))
        else:
            print("[*] {0} (visible)".format(ws.Name))
        

    print("[*]----------------------------------")
    
    wb.Close(SaveChanges=1)
    xl.Quit()


if __name__ == "__main__":
    if len(sys.argv) == 2:
        mfile = sys.argv[1]
        ftype = file_info(mfile)
        process_file(mfile, ftype)
    elif "--unhide" in sys.argv and len(sys.argv) == 3:
        for cmd_args in sys.argv[1:]:
            if os.path.isfile(cmd_args):
                unhide_xlsheets(cmd_args)
        
    else:
        print("[X] ERROR: Please input target document file.")
        print("[*] Usage: python amacro.py <target_document>")



