# pydmk is released under the MIT license
# Author: G. Hovland, December 2020
#
# Reference: http://dragon32.info/info/drgndos.html
# The DMK disk format used by pydmk has been
# tested with SuperDOS E6 for the Dragon 32/64

import sys
import click
from dmkHandler import dmkHandler


def bytesToString(data):
    out = ""
    for i in range(len(data)):
        out = out + str(data[i]) + " "
    return out


@click.group()
@click.version_option("0.0.2")
def main():
    """A Python tool for manipulating Dragondos DMK disk files"""
    pass


@main.command()
@click.argument('dmk_file', required=True)
def diskinfo(**kwargs):
    """Get information about the disk"""
    mydisk = dmkHandler(kwargs.get("dmk_file"))
    data = mydisk.diskinfo()
    print("Disk Info")
    print("---------")
    print("Write-protect       : " + str(data['write_protect']))
    print("Number of tracks    : " + str(data['cylinders']))
    print("Number of sectors   : " + str(data['sectors']))
    print("Track length        : " + str(data['track_length']))
    print("Option flags        : " + str(f'{data["option_flags"]:08b}'))
    print("Reserved            : " + bytesToString(data['reserved']))
    print("Drive type          : " + bytesToString(data['drive_type']))
    print("Disk size           : " + str(data['disk_size']))
    pass


@main.command()
@click.argument('dmk_file', required=True)
def dir(**kwargs):
    """Show the disk directory"""
    mydisk = dmkHandler(kwargs.get("dmk_file"))
    data = mydisk.dir()
    print("Directory Listing")
    print("-----------------")
    N = len(data['filenames'])
    for i in range(N):
        print("{}.{}   {}".format(data['filenames'][i].ljust(8),
              data['extensions'][i], data['filesizes'][i]))
    print("FREE BYTES " + str(data['free_bytes']))
    pass


@main.command()
@click.argument('dmk_file', required=True)
@click.argument('filename', required=True)
def cat(**kwargs):
    """Display a file on screen"""
    mydisk = dmkHandler(kwargs.get("dmk_file"))
    data = mydisk.cat(kwargs.get("filename"))
    print(data.decode('cp437'))  # Use IBM extended ASCII, Code Page 437
    pass


@main.command()
@click.argument('dmk_file', required=True)
@click.argument('filename', required=True)
def fileinfo(**kwargs):
    """Shows file header"""
    mydisk = dmkHandler(kwargs.get("dmk_file"))
    data = mydisk.fileinfo(kwargs.get("filename"))
    if len(data) > 0:
        print("File Info")
        print("---------")
        print("File Name           : " + kwargs.get("filename"))
        print("File Type           : " + data['filetype'])
        if data['filetype'] == "BAS":
            print("Load Address        : " + str(data['load_address']))
            print("File Length         : " + str(data['file_length']))
        elif data['filetype'] == "BIN":
            print("Load Address        : " + str(data['load_address']))
            print("File Length         : " + str(data['file_length']))
            print("Exec Address        : " + str(data['exec_address']))
    else:
        print("File {} does not exist.".format(kwargs.get("filename")))
    pass


@main.command()
@click.argument('dmk_file', required=True)
@click.argument('filename', required=True)
def file2cas(**kwargs):
    """Creates CAS file from file on disk"""
    mydisk = dmkHandler(kwargs.get("dmk_file"))
    mydisk.file2cas(kwargs.get("filename"))
    pass


if __name__ == '__main__':
    args = sys.argv
    if "--help" in args or len(args) == 1:
        print("pydmk")
    main()
