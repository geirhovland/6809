## pydmk

pydmk is a Python tool for manipulating SuperDOS E6 dmk disks
for the Dragon 32/64 8-bit computer.

Calls using included example disks:

```
python3 pydmk --help
python3 pydmk --version

# 40 tracks, single sided disk
python3 pydmk.py info FEdit.dmk
python3 pydmk.py dir FEdit.dmk
python3 pydmk.py cat FEdit.dmk INTRO.DOC

# 40 tracks, 2-sided disk
python3 pydmk.py info FEdit_40_2.dmk
python3 pydmk.py dir FEdit_40_2.dmk
python3 pydmk.py cat FEdit_40_2.dmk INTRO.DOC

# 80 tracks, single sided disk
python3 pydmk.py info FEdit_80_1.dmk
python3 pydmk.py dir FEdit_80_1.dmk
python3 pydmk.py cat FEdit_80_1.dmk INTRO.DOC

# 80 tracks, 2-sided disk
python3 pydmk.py info FEdit_80_2.dmk
python3 pydmk.py dir FEdit_80_2.dmk
python3 pydmk.py cat FEdit_80_2.dmk INTRO.DOC

# Conversion DMK -> CAS
python3 pydmk.py fileinfo FEdit.dmk FEDIT.BIN
python3 pydmk.py file2cas FEdit.dmk FEDIT.BIN
```
