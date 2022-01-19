
import oletools.olevba
import oletools.oleid
import zipfile
import hashlib
import sys
import os
import openpyxl
from argparse import ArgumentParser
from win32com.client import Dispatch


class FileInfo(object):
    def __init__(self) -> None:
        self.__init__ = None
        self.file_type = "Unknown"
        self.doc_type = "Unknown"
        self.size = None
        self.md5 = None
        self.sha512 = None
        self.has_hidden_sheet = None
        self.has_vba_macro = None
        self.has_xlm_macro = None
        self.vba_macro = None
        self.xlm_macro = None


class MacroLyzer(object):
    def __init__(self, filename=None) -> None:
        self.__init__ = None
        self.filename = os.path.abspath(filename)
        self.file_valid = False if not self._is_valid_file(filename) else True
        self.file_info = FileInfo()
        self.xl_app = None
        self.word_app = None
        self.xl_app = None
        self.word_app = None

    def _win32com_app(self):
        try:
            if self.file_info.doc_type == "XL":
                self.xl_app = Dispatch("Excel.Application")
            elif self.file_info.doc_type == "DOC":
                self.xl_app = Dispatch("Word.Application")
        except Exception as e:
            print("[X] ERROR: {0}".format(str(e)))
        
        finally:
            return
    
    def _is_valid_file(self, filename):
        ret = False
        try:
            fullpath = self.filename
            if os.path.isfile(fullpath) and os.path.exists(fullpath):
                ret = True

        except Exception as e:
            print("[X] ERROR: {0}".format(str(e)))
        
        finally:
            return ret

    def get_file_type(self):
        try:
            with open(self.filename,"rb") as mf:
                d = mf.read(4)
                if d[0:4] == b'\xD0\xCF\x11\xE0':
                    self.file_info.file_type = "OLE"
                elif d[0:2] == b'PK':
                    self.file_info.file_type = "ZIP"

            if self.file_info.file_type == "ZIP":
                zf = zipfile.ZipFile(self.filename)
                for z in zf.filelist:
                    if z.filename.startswith("word/"):
                        self.file_info.doc_type = "DOC"
                        break
                    if z.filename.startswith("xl/"):
                        self.file_info.doc_type = "XL"
                        break
            elif self.file_info.file_type == "OLE":
                oid = oletools.oleid.OleID(self.filename)
                i = oid.check()
                if i[2].value.lower().endswith(b" word"):
                    self.file_info.doc_type = "DOC"
                elif i[2].value.lower().endswith(b" excel"):
                    self.file_info.doc_type = "XL"

            self._win32com_app() 
        
        except Exception as e:
            print("[X] ERROR: {0}".format(str(e)))

        finally:
            return

    def get_file_info(self):
        try:
            self.file_info.size = os.path.getsize(self.filename)
            with open(self.filename, 'rb') as hf:
                self.file_info.md5 = hashlib.md5(hf.read()).hexdigest()
                self.file_info.sha512 = hashlib.sha512(hf.read()).hexdigest()
            
            self.get_file_type()

        except Exception as e:
            print("[X] ERROR: {0}".format(str(e)))
            
        finally:
            return

    def get_macros(self):
        try:
            vba = oletools.olevba.VBA_Parser(self.filename)
            self.file_info.vba_macro = vba.extract_all_macros()
            if self.file_info.vba_macro != None:
                self.file_info.has_vba_macro = True
            for m in self.file_info.vba_macro:
                print("[*] ----------VBA Source Code----------")
                print("{0}".format(m[3]))
                print("[*] -----------------------------------")

            self.file_info.has_xlm_macro = vba.detect_xlm_macros()
            if self.file_info.has_xlm_macro:
                self.file_info.xlm_macro = vba.xlm_macros
                print("[*] ------------XLM Macros-------------")
                for n in vba.xlm_macros:
                    print(n)
                print("[*] -----------------------------------")

        except Exception as e:
            print("[X] ERROR: {0}".format(str(e)))

        finally:
            return


    def get_xlf_openxml(self):
        try:
            xlwb = openpyxl.load_workbook(filename=self.filename, keep_vba=True)
            print("[*] ---------Excel Content Info--------")
            sheets = xlwb.worksheets
            dn = xlwb.defined_names
            print("[*] Defined Names: (Name, Reference-To)")
            for n in dn.definedName:
                print("[*] {0}, {1}".format(n.name, n.attr_text))

            print("[*]")
            
            print("[*] Worksheets: (Name (Sheet State))")
            for ws in sheets:
                print("[*] {0} ({1})".format(ws.title, ws.sheet_state))
            print("[*]")

            print("[*] FORMULA: (Sheet, Cell, Formula)")
            for ws in sheets:
                for r in ws.iter_rows():
                    for x in r:
                        if x.value != None:
                            if x.data_type == 'f':
                                print("[*] {0}, ${1}${2}, {3}".format(ws.title, x.column_letter, x.row, x.value))
            print("[*]")

            xlwb.close()
            print("[*] ----------------------------------")
        
        except Exception as e:
            print("[X] ERROR: {0}".format(str(e)))

        finally:
            return
    
    def process_file(self):
        try:
            self.get_file_info()
            self.get_macros()
            if self.file_info.file_type == "ZIP" and self.file_info.doc_type == "XL":
                self.get_xlf_openxml()
                
        except Exception as e:
            print("[X] ERROR: {0}".format(str(e)))

        finally:
            return

    def unhide_xlsheets(self):
        try:
            print("[*] -----------Worksheets------------")
            self.xl_app.DisplayAlerts = False
            wb = self.xl_app.Workbooks.Open(self.filename)

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
            
            print("[*] Changes in {0} are saved.".format(os.path.basename(self.filename)))
            print("[*]----------------------------------")
            
            wb.Close(SaveChanges=1)
            self.xl_app.Quit()
                    
        except Exception as e:
            print("[X] ERROR: {0}".format(str(e)))
        
        finally:
            return


    def close(self):
        if self.xl_app != None:
            self.xl_app.Quit()
        if self.word_app != None:
            self.word_app.Quit()



def parse_cmd():
    args = None
    try:
        parser = ArgumentParser(description='Tool to statically analyze macro documents.')
        parser.add_argument("fname", help="Target file to be analyzed.")
        parser.add_argument("--unhide", action="store_true", help="Option to unhide hidden Excel worksheets.")
        args = parser.parse_args()

    except Exception as e:
        print("[X] ERROR: {0}".format(str(e)))

    finally:
        return args, parser

if __name__ == "__main__":
    args, parser = parse_cmd()
    m = None
    try:
        m = MacroLyzer(args.fname)
        if m.file_valid:
            if args.unhide:
                m.get_file_info()
                if m.file_info.doc_type == "XL":
                    m.unhide_xlsheets()
                else:
                    print("[X] ERROR: {0} is not an Excel file.".format(args.fname))
                    parser.print_help()
            
            else:
                m.process_file()

    except Exception as e:
        print("[X] ERROR: {0}".format(str(e)))
        parser.print_help()
