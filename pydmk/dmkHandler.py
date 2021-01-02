# dmkHandler class, released under the MIT license
# Author: G. Hovland, December 2020

import logging
from math import floor


class dmkHandler:
    '''Class for manipulating Dragondos disks on DMK format'''

    def toString(self, data):
        out = ""
        for i in range(len(data)):
            if data[i] > 0:
                out = out + chr(data[i])
            else:
                out = out + " "
        return out

    def filesize(self, data):
        y = (data[2] + data[5])*256 - 256 + data[12]
        return y

    def filesize_on_disk(self, data):
        y = (data[2] + data[5])*256
        return y

    def logical_sector_numbers(self, data, M, N):
        out = []
        getLSNs = True
        while getLSNs:
            if data[0] & 1 == 0:
                continuationBlock = False
                i1 = 12
                i2 = 24
            else:
                continuationBlock = True
                i1 = 0
                i2 = 7*3
            if data[0] & 32 == 0:
                getNextBlock = False
            else:
                getNextBlock = True

            for i in range(i1, i2, 3):
                x = data[i]*256 + data[i+1]
                L = data[i+2]
                if L > 0:
                    out.append(x)
                    out.append(L)

            if not getNextBlock:
                out.append(data[24])  # Number of bytes in last block
                getLSNs = False
            else:
                j = data[24]
                data = self.data[N+j*M:N+(j+1)*M]

        return out

    def getIndex(self, j, track, block, L, bytesLast):
        index = []
        LastBlock = False
        if j == L-1:
            LastBlock = True
        while block + j >= self.sectors:
            j = j - self.sectors
            track = track + 1

        if j < 9:
            i = 296 + track*self.track_length + (block+j)*676
        elif j < 9*2:
            i = 634 + track*self.track_length + (block+j-9)*676
        elif j < 9*3:
            i = 612 + track*self.track_length + (block+j-9)*676
        else:
            i = 950 + track*self.track_length + (block+j-9*2)*676

        index.append(i)
        if LastBlock:
            index.append(i + bytesLast)
        else:
            index.append(i + 256)
        return index

    def getData(self, LSN):
        out = b''  # Empty byte string
        for i in range(0, len(LSN)-1, 2):
            startTrack = floor(LSN[i] / self.sectors)
            startBlock = LSN[i] - startTrack*self.sectors
            L = LSN[i+1]
            if i == len(LSN)-3:
                bytesLast = LSN[-1]
            else:
                bytesLast = 256

            for j in range(L):
                index = self.getIndex(j, startTrack, startBlock, L, bytesLast)
                out = out + self.data[index[0]:index[1]]
        return out

    def __init__(self, filename):
        self.filename = filename
        self.N_header = 16
        self.N_idam = 64
        self.file_exists = False

        self.logger = logging.getLogger('mylogger')
        self.logger.setLevel(logging.WARNING)
        handler = logging.StreamHandler('')
        mystr = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        formatter = logging.Formatter(mystr)
        handler.setFormatter(formatter)
        self.logger.addHandler(handler)

        try:
            in_file = open(self.filename, "rb")
            self.file_exists = True
        except FileNotFoundError:
            self.logger.critical("File {} does not exist!"
                                 .format(self.filename))
            quit()

        if self.file_exists:
            self.header = in_file.read(self.N_header)
            in_file.close()

            self.cylinders = self.header[1]
            if self.header[4] & 16 == 0:  # 2 sided
                self.sectors = 36
                self.track_length = 6400*2
            else:
                self.sectors = 18
                self.track_length = 6400
            self.disk_size = self.cylinders*self.track_length

            in_file = open(self.filename, "rb")
            self.data = in_file.read(self.disk_size + self.N_header)
            in_file.close()

    def info(self):
        out = {
            "write_protect": self.data[0],
            "cylinders": self.cylinders,
            "sectors": self.sectors,
            "track_length": self.track_length,
            "option_flags": self.data[4],
            "reserved": self.data[5:12],
            "drive_type": self.data[12:16],
            "disk_size": self.disk_size
        }
        return out

    def dir(self):
        if self.sectors == 18:
            free_bytes = self.sectors*(self.cylinders-2)*256
        else:
            free_bytes = self.sectors*(self.cylinders-1)*256
        N = self.track_length*20 + 1648
        M = 25
        j = 0
        dirEnd = False
        filenames = []
        extensions = []
        filesizes = []
        LSNs = []
        while not dirEnd:
            header = self.data[N+j*M:N+(j+1)*M]
            j = j + 1
            entryUnused = False
            continuationEntry = False
            nextEntry = 0
            if header[0] & 8 == 8:
                dirEnd = True
            if header[0] & 128 == 128:
                entryUnused = True

            if not dirEnd and not entryUnused:
                filename = self.toString(header[1:8+1])
                filenames.append(filename)
                extension = self.toString(header[9:11+1])
                extensions.append(extension)
                filesize = self.filesize(header[12:25])
                filesize_on_disk = self.filesize_on_disk(header[12:25])
                filesizes.append(filesize)
                free_bytes = free_bytes - filesize_on_disk
                LSN = self.logical_sector_numbers(header, M, N)
                LSNs.append(LSN)

        out = {
            "free_bytes": free_bytes,
            "filenames": filenames,
            "extensions": extensions,
            "filesizes": filesizes,
            "LSNs": LSNs
        }
        return out

    def cat(self, filename):
        search = filename.split('.')
        mydir = self.dir()
        for i in range(len(mydir['filenames'])):
            file = mydir['filenames'][i].rstrip()
            ext = mydir['extensions'][i]
            if (file == search[0]) and (ext == search[1]):
                LSN = mydir['LSNs'][i]
                data = self.getData(LSN)
        return data
