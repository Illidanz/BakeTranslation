pipenv run pyinstaller --clean --icon=icon.ico --add-binary "xdelta.exe;." --add-binary "sign_np.exe;." --add-binary "UMD-replace.exe;." --add-binary "armips.exe;." --add-data "bin_patch.asm;." --distpath . -F --hidden-import="pkg_resources.py2_warn" tool.py
